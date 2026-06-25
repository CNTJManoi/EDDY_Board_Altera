//-----------------------------------------------------------------------------
// four_point_ctrl
//
// Real-time four-point acquisition trigger (deterministic rising-start order).
//
// Per the measurement definition: when the signal crosses the threshold going
// UP, a group starts -> two points are taken (at delay0 and delay1 after the
// rising crossing). Then on the NEXT crossing going DOWN, two more points are
// taken (at delay0/delay1 after the falling crossing). That is the 4-point
// group. The whole group then repeats every mode_div periods.
//
//   mode_div = 0 -> every period
//   mode_div = 1 -> every 4 periods
//   mode_div = 2 -> every 8 periods
//   mode_div = 3 -> every 16 periods
//
// KEY: the FIRST group is armed ONLY on a rising crossing, and each falling
// pair is bound to the rising pair that started its group. This removes the old
// failure where independent rising/falling counters could start on a falling
// crossing or drift apart, making the captured values jump up/down period to
// period.
//-----------------------------------------------------------------------------
module four_point_ctrl (
    input  wire        clk,        // ADC sampling clock (DCO)
    input  wire        reset,      // command 15 / disabled
    input  wire        enable,     // command 2 active, mode[7] == 0
    input  wire        high_level, // (aligned) DAC >= threshold
    input  wire        low_level,  // (aligned) DAC <= threshold
    input  wire [7:0]  delay0,
    input  wire [7:0]  delay1,
    input  wire [1:0]  mode_div,
    output wire        sample_enable
);
    reg       primed;
    reg       high_q;
    reg       low_q;
    reg       armed;        // first rising crossing has occurred
    reg       expect_fall;  // a rising group launched; its falling not yet taken
    reg [7:0] rise_cnt;     // rising crossings (= periods) since last group start

    wire high_now = high_level;
    wire low_now  = low_level;
    // A crossing is the rising edge of the (registered) inclusive level, so it is
    // detected exactly one clk after the level changes -- glitch-free.
    wire high_cross = primed & high_now & ~high_q;   // signal crossed UP
    wire low_cross  = primed & low_now  & ~low_q;    // signal crossed DOWN

    // periods between 4-point groups: 1 / 4 / 16 / 64
    wire [7:0] period_m = (mode_div == 2'd0) ? 8'd1  :
                          (mode_div == 2'd1) ? 8'd4  :
                          (mode_div == 2'd2) ? 8'd16 :
                                               8'd64;

    // Start a group on a rising crossing: the very first one (arming), then once
    // every period_m rising crossings.  rise_cnt is tested BEFORE its update.
    wire group_start = high_cross & (~armed | (rise_cnt >= period_m));
    // The falling pair of a group is the first DOWN crossing after its rising.
    wire fall_point  = low_cross & expect_fall;

    always @(posedge clk) begin
        if (reset) begin
            primed      <= 1'b0;
            high_q      <= 1'b0;
            low_q       <= 1'b0;
            armed       <= 1'b0;
            expect_fall <= 1'b0;
            rise_cnt    <= 8'd0;
        end else if (!enable) begin
            // prime the level history so the first enabled edge cannot look like
            // a crossing if the signal already sits above/below the threshold.
            primed      <= 1'b0;
            high_q      <= high_now;
            low_q       <= low_now;
            armed       <= 1'b0;
            expect_fall <= 1'b0;
            rise_cnt    <= 8'd0;
        end else begin
            high_q <= high_now;
            low_q  <= low_now;
            if (!primed) begin
                primed <= 1'b1;
            end else begin
                if (high_cross) begin
                    if (group_start) begin
                        armed       <= 1'b1;
                        rise_cnt    <= 8'd1;   // this rising = period 1 of next cycle
                        expect_fall <= 1'b1;   // bind the next DOWN crossing to it
                    end else begin
                        rise_cnt <= rise_cnt + 8'd1;
                    end
                end
                if (fall_point)
                    expect_fall <= 1'b0;       // falling pair taken; close the group
            end
        end
    end

    wire enable_rising;
    wire enable_falling;

    // Rising pair: two points at delay0/delay1 after the group's rising crossing.
    four_point_delay_pair rising_pair (
        .clk(clk),
        .reset(reset | ~enable),
        .launch(group_start),
        .delay0(delay0),
        .delay1(delay1),
        .sample_enable(enable_rising)
    );

    // Falling pair: two points at delay0/delay1 after the bound falling crossing.
    four_point_delay_pair falling_pair (
        .clk(clk),
        .reset(reset | ~enable),
        .launch(fall_point),
        .delay0(delay0),
        .delay1(delay1),
        .sample_enable(enable_falling)
    );

    // Synchronous RAM write-enable, asserted before the clk edge on which the
    // selected sample is stored.  Never used as a generated clock.
    assign sample_enable = enable_rising | enable_falling;
endmodule


// Two delayed write-enables launched by one threshold crossing. Delays are
// measured in ADC clock periods. delay=0 enables the crossing clock edge.
//
// A launch produces the requested aperture strobes. If delay0 == delay1 there
// is one physical aperture; the active four_point_channel stores that same ADC
// word into both point registers before writing two RAM words. This legacy
// helper therefore must not invent a delay0+1 aperture.
module four_point_delay_pair (
    input  wire       clk,
    input  wire       reset,
    input  wire       launch,
    input  wire [7:0] delay0,
    input  wire [7:0] delay1,
    output wire       sample_enable
);
    wire [8:0] d0     = {1'b0, delay0};
    wire [8:0] d1_eff = {1'b0, delay1};

    reg       active;
    reg [8:0] age;
    reg       pending0;
    reg       pending1;

    wire [8:0] next_age = age + 9'd1;
    // delay==0 point is captured on the launch clock edge itself.
    wire fire0_now = launch & (d0     == 9'd0);
    wire fire1_now = launch & (d1_eff == 9'd0);
    wire due0 = active & pending0 & (next_age == d0);
    wire due1 = active & pending1 & (next_age == d1_eff);

    // Combinational w.r.t. state stable before clk; sampled by adc_chan as a
    // normal synchronous write-enable on the next clk edge.
    assign sample_enable = fire0_now | fire1_now | due0 | due1;

    always @(posedge clk) begin
        if (reset) begin
            active   <= 1'b0;
            age      <= 9'd0;
            pending0 <= 1'b0;
            pending1 <= 1'b0;
        end else begin
            if (launch) begin
                age      <= 9'd0;
                pending0 <= (d0     != 9'd0);   // a non-zero-delay point is still due
                pending1 <= (d1_eff != 9'd0);
                active   <= (d0 != 9'd0) | (d1_eff != 9'd0);
            end else if (active) begin
                age <= next_age;

                if (due0)
                    pending0 <= 1'b0;
                if (due1)
                    pending1 <= 1'b0;

                if ((!pending0 | due0) & (!pending1 | due1))
                    active <= 1'b0;
            end
        end
    end
endmodule
