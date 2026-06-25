//-----------------------------------------------------------------------------
// four_point_channel
//
// Per-AD9649-DCO four-point acquisition for ONE channel.
//
// Definition (matches the host's A0..A3 = the four points of a group):
//   point0 = adc_sample at (rising  threshold crossing + delay0)
//   point1 = adc_sample at (rising  threshold crossing + delay1)
//   point2 = adc_sample at (falling threshold crossing + delay0)
//   point3 = adc_sample at (falling threshold crossing + delay1)
// They are captured into 4 registers and then written to RAM in that fixed
// order. Therefore:
//   * delay0 moves points 0 AND 2, delay1 moves points 1 AND 3;
//   * if delay0 == delay1 the pairs are IDENTICAL (point0==point1, point2==point3)
//     because the same sample is latched into both registers.
// A group repeats every mode_div = 1/4/16/64 signal periods, and the very first
// group is armed only on a RISING crossing so points line up period-to-period.
//
// The comparator runs directly on this channel's ADC samples.  The sample that
// first crosses the threshold is delay 0; delay N is exactly N following DCO
// samples.
//
// Target: Cyclone IV / Quartus II 13.1, Verilog-2001.
//-----------------------------------------------------------------------------
module four_point_channel (
    input  wire        clk,           // AD9649 DCO
    input  wire        reset,         // async assert, sync release
    input  wire        enable,
    input  wire [13:0] adc_sample,    // compared and captured on this DCO edge
    input  wire [14:0] threshold,
    input  wire [7:0]  delay0,
    input  wire [7:0]  delay1,
    input  wire [1:0]  mode_div,
    output wire [13:0] wdata,         // point data to RAM
    output wire        wen            // RAM write strobe
);
    // ---- reset / enable synchronizers -----------------------------------
    reg reset_s1, reset_s2;
    always @(posedge clk or posedge reset)
        if (reset) begin reset_s1 <= 1'b1; reset_s2 <= 1'b1; end
        else       begin reset_s1 <= 1'b0; reset_s2 <= reset_s1; end

    reg enable_s1, enable_s2, enable_s3;
    always @(posedge clk or posedge reset)
        if (reset) begin enable_s1<=1'b0; enable_s2<=1'b0; enable_s3<=1'b0; end
        else       begin enable_s1<=enable; enable_s2<=enable_s1; enable_s3<=enable_s2; end

    // ---- stable-bus config CDC (frozen while disabled) ------------------
    reg [14:0] thr_s1, thr_s2, thr_a;
    reg [7:0]  d0_s1, d0_s2, d0_a;
    reg [7:0]  d1_s1, d1_s2, d1_a;
    reg [1:0]  md_s1, md_s2, md_a;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            thr_s1<=0; thr_s2<=0; thr_a<=0;
            d0_s1<=0; d0_s2<=0; d0_a<=0;
            d1_s1<=0; d1_s2<=0; d1_a<=0;
            md_s1<=0; md_s2<=0; md_a<=0;
        end else begin
            thr_s1<=threshold; thr_s2<=thr_s1;
            d0_s1<=delay0;     d0_s2<=d0_s1;
            d1_s1<=delay1;     d1_s2<=d1_s1;
            md_s1<=mode_div;   md_s2<=md_s1;
            if (!enable_s3) begin
                thr_a<=thr_s2; d0_a<=d0_s2; d1_a<=d1_s2; md_a<=md_s2;
            end
        end
    end

    wire ctrl_en = enable_s3 & ~reset_s2;

    // ---- crossing detect ------------------------------------------------
    // Compare consecutive ADC words.  The current word is both the crossing
    // word and the delay-0 capture, so no extra sample is skipped.
    reg        primed;
    reg [13:0] prev_adc;
    wire rise_x = primed &&
                  ({1'b0, prev_adc} <  thr_a) &&
                  ({1'b0, adc_sample} >= thr_a);
    wire fall_x = primed &&
                  ({1'b0, prev_adc} >  thr_a) &&
                  ({1'b0, adc_sample} <= thr_a);

    wire [8:0] D0 = {1'b0, d0_a};
    wire [8:0] D1 = {1'b0, d1_a};
    wire [7:0] period_m = (md_a==2'd0) ? 8'd1  :
                          (md_a==2'd1) ? 8'd4  :
                          (md_a==2'd2) ? 8'd16 : 8'd64;

    // A selected rising crossing launches the rising pair. The first falling
    // crossing after it independently launches the falling pair. Separate
    // timers are essential: a long rising delay is allowed to extend beyond
    // the falling crossing without losing or rebinding that crossing.
    reg        group_active;
    reg        fall_bound;
    reg [8:0]  rise_age;
    reg [8:0]  fall_age;
    reg        p0_pending, p1_pending, p2_pending, p3_pending;
    reg [13:0] p0, p1, p2, p3;
    reg        writing;
    reg [1:0]  wi;
    reg [7:0]  periods_left;

    // Fixed host order: A0/A1 are the rising pair, A2/A3 the falling pair.
    assign wen = writing;
    assign wdata = (wi == 2'd0) ? p0 :
                   (wi == 2'd1) ? p1 :
                   (wi == 2'd2) ? p2 : p3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            primed<=0; prev_adc<=0;
            group_active<=0; fall_bound<=0;
            rise_age<=0; fall_age<=0;
            p0_pending<=0; p1_pending<=0; p2_pending<=0; p3_pending<=0;
            p0<=0; p1<=0; p2<=0; p3<=0;
            writing<=0; wi<=0; periods_left<=0;
        end else if (!ctrl_en) begin
            primed<=0; prev_adc<=adc_sample;
            group_active<=0; fall_bound<=0;
            rise_age<=0; fall_age<=0;
            p0_pending<=0; p1_pending<=0; p2_pending<=0; p3_pending<=0;
            writing<=0; wi<=0; periods_left<=0;
        end else begin
            prev_adc <= adc_sample;
            if (!primed)
                primed <= 1'b1;

            // Count every signal period independently of capture/write state.
            if (rise_x && (periods_left != 8'd0))
                periods_left <= periods_left - 8'd1;

            // Start a group only on the selected rising crossing.
            if (rise_x && (periods_left == 8'd0) &&
                !group_active && !writing) begin
                group_active <= 1'b1;
                fall_bound   <= 1'b0;
                rise_age     <= 9'd0;
                p0_pending   <= (D0 != 9'd0);
                p1_pending   <= (D1 != 9'd0);
                p2_pending   <= 1'b0;
                p3_pending   <= 1'b0;
                if (D0 == 9'd0) p0 <= adc_sample;
                if (D1 == 9'd0) p1 <= adc_sample;
                periods_left <= period_m - 8'd1;
            end else if (group_active && (p0_pending || p1_pending)) begin
                rise_age <= rise_age + 9'd1;
                if (p0_pending && ((rise_age + 9'd1) == D0)) begin
                    p0 <= adc_sample;
                    p0_pending <= 1'b0;
                end
                if (p1_pending && ((rise_age + 9'd1) == D1)) begin
                    p1 <= adc_sample;
                    p1_pending <= 1'b0;
                end
            end

            // Bind exactly the first falling crossing following group start.
            if (group_active && !fall_bound && fall_x) begin
                fall_bound <= 1'b1;
                fall_age   <= 9'd0;
                p2_pending <= (D0 != 9'd0);
                p3_pending <= (D1 != 9'd0);
                if (D0 == 9'd0) p2 <= adc_sample;
                if (D1 == 9'd0) p3 <= adc_sample;
            end else if (group_active && fall_bound &&
                         (p2_pending || p3_pending)) begin
                fall_age <= fall_age + 9'd1;
                if (p2_pending && ((fall_age + 9'd1) == D0)) begin
                    p2 <= adc_sample;
                    p2_pending <= 1'b0;
                end
                if (p3_pending && ((fall_age + 9'd1) == D1)) begin
                    p3 <= adc_sample;
                    p3_pending <= 1'b0;
                end
            end

            // Start streaming after all four registers are complete. One extra
            // DCO cycle here is intentional and does not change the apertures.
            if (group_active && fall_bound &&
                !p0_pending && !p1_pending &&
                !p2_pending && !p3_pending && !writing) begin
                writing <= 1'b1;
                wi <= 2'd0;
                group_active <= 1'b0;
            end else if (writing) begin
                if (wi == 2'd3) begin
                    writing <= 1'b0;
                    wi <= 2'd0;
                end else begin
                    wi <= wi + 2'd1;
                end
            end
        end
    end
endmodule
