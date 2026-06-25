// ============================================================
// Eddy_c.v -- structural Verilog copy of Eddy_c.bdf (auto-generated)
// Source: tools/gen_verilog.py from the extracted schematic netlist.
// Leaf modules reused as-is (AHDL/VHDL/IP); primitives expanded inline.
// ============================================================

module Eddy_c (
    input   \16MHz ,
    output  ADC0_CLKN,
    output  ADC0_CLKP,
    output  ADC1_CLKN,
    output  ADC1_CLKP,
    output  ADC2_CLKN,
    output  ADC2_CLKP,
    output  ADC3_CLKN,
    output  ADC3_CLKP,
    input   [3:0] BRD,
    input   C0DCO,
    input   [13:0] C0D,
    input   C1DCO,
    input   [13:0] C1D,
    input   C2DCO,
    input   [13:0] C2D,
    input   C3DCO,
    input   [13:0] C3D,
    output  DAC_CLK,
    output  DAC_CLKN,
    output  DAC_CLKP,
    output  [3:0] DAC_CS,
    output  DAC_DATA,
    output  [13:0] DD,
    input   PA4,
    input   PA5,
    output  PB2,
    output  PB4,
    input   PB5,
    output  PB6,
    input   [10:0] PD,
    input   PE2,
    input   PE4,
    input   PE6,
    output  TEST0,
    output  TEST1,
    output  TEST10,
    output  TEST11,
    output  TEST12,
    output  TEST13,
    output  TEST14,
    output  TEST15,
    output  TEST2,
    output  TEST3,
    output  TEST4,
    output  TEST5,
    output  TEST6,
    output  TEST7,
    output  TEST8,
    output  TEST9
);

wire [13:0] ADC;
wire [13:0] ADC0;
wire [13:0] ADC1;
wire [13:0] ADC2;
wire [13:0] ADC3;
wire [13:0] dac_ram_q;
wire [13:0] dac_play_q;
wire EMPTY0;
wire EMPTY1;
wire EMPTY2;
wire EMPTY3;
wire FULL0;
wire FULL1;
wire FULL2;
wire FULL3;
wire MISO;
wire MOSI;
wire [2:0] MX_CTRL;
wire [15:0] O_DAT;
wire Read_DAC;
wire SCK;
wire SCK_I;
wire SS;
wire STLD;
wire Write_DAC;
wire a_en;
wire adc_clk0;
wire adc_clk1;
wire adc_clk2;
wire adc_clk3;
wire adc_start;
wire [13:0] addr;
wire addr_en;
wire adr_clr;
wire adr_en;
wire ccc;
wire clk;
wire clk50;
wire clk64;
wire clk_a0;
wire clk_a1;
wire clk_a2;
wire clk_in;
wire [7:0] clko;
wire clr_dac;
wire [3:0] cmd;
wire cmd1;
wire cmd10;
wire cmd11;
wire cmd12;
wire cmd13;
wire cmd14;
wire cmd15;
wire cmd15_i;
wire cmd2;
wire cmd3;
wire cmd5;
wire cmd6;
wire cmd7;
wire cmd9;
wire cmd_d;
wire cmd_dac;
wire cmd_w;
wire [15:0] cmp;
wire [15:0] cmpr;
wire [7:0] cnst;
wire [3:0] control;
wire d_run;
wire dac_play;
wire [15:0] delay;
wire [1:0] freq;
wire gn;
wire [15:0] mode;
wire four_point_sample;
wire four_point_sample0;
wire four_point_sample1;
wire four_point_sample2;
wire four_point_sample3;
wire out_addr;
wire q1;
wire q10;
wire q11;
wire q12;
wire q13;
wire q14;
wire q2;
wire q3;
wire q4;
wire q5;
wire q6;
wire q7;
wire q8;
wire q9;
wire read_d;
wire read_d0;
wire read_d1;
wire read_d2;
wire read_d3;
wire read_dd;
wire s1;
wire s_load;
wire s_read;
wire start;
wire [3:0] t_clk;
wire [13:0] usedw0;
wire uuy;
wire v0;
wire v1;
wire v2;
wire v3;
wire vc;
wire wr11;
wire wr12;
wire wr14;
wire wr9;
wire write_d;
wire write_di;
wire w_1;
wire w_2;
wire w_5;
wire w_6;
wire w_7;
wire w_8;
wire w_9;
wire w_10;
wire w_19;
wire w_21;
wire cap_wclk0;
wire cap_wclk1;
wire cap_wclk2;
wire cap_wclk3;
wire cap_wen0;
wire cap_wen1;
wire cap_wen2;
wire cap_wen3;
wire spi_word_commit;
wire dac_spi_write;
wire dac_spi_read;

reg [13:0] adc0_in;
reg [13:0] adc1_in;
reg [13:0] adc2_in;
reg [13:0] adc3_in;
reg [13:0] adc0_sample;
reg [13:0] adc1_sample;
reg [13:0] adc2_sample;
reg [13:0] adc3_sample;
reg [13:0] dac_out;
reg [13:0] dac_play_addr;
reg [13:0] dac_test_sample;
reg [13:0] dac_spi_addr = 14'd0;
reg [1:0] cap_reset0 = 2'b11;
reg [1:0] cap_reset1 = 2'b11;
reg [1:0] cap_reset2 = 2'b11;
reg [1:0] cap_reset3 = 2'b11;
// Comparator threshold is independent from the 14-bit DAC sample code.
// Accept every documented value 0..16384 exactly; 16384 is one count above
// DAC full scale and therefore intentionally never satisfies DAC>=threshold.
reg [14:0] cmpr_reg = 15'd8192;

// Capture a completed 16-bit SPI word exactly once on the 16th rising SCK
// edge. The completed word remains stable until the next full frame, while a
// toggle transfers the event into clk64. This is the proven structure used by
// spi_block_eddy in the original project and avoids the old delayed-PA4 race.
reg [15:0] spi_rx_shift = 16'd0;
reg [15:0] spi_word_spi = 16'd0;
reg [4:0]  spi_rx_count = 5'd0;
reg        spi_word_toggle = 1'b0;
reg [15:0] spi_word_hold = 16'd0;
reg        spi_word_commit_reg = 1'b0;
(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *)
reg [2:0] spi_toggle_sync = 3'b000;

always @(posedge SCK or posedge PA4) begin
    if (PA4) begin
        spi_rx_shift <= 16'd0;
        spi_rx_count <= 5'd0;
    end else if (spi_rx_count < 5'd16) begin
        spi_rx_shift <= {spi_rx_shift[14:0], MOSI};
        spi_rx_count <= spi_rx_count + 5'd1;

        if (spi_rx_count == 5'd15) begin
            spi_word_spi    <= {spi_rx_shift[14:0], MOSI};
            spi_word_toggle <= ~spi_word_toggle;
        end
    end
end

always @(posedge clk) begin
    spi_toggle_sync <= {spi_toggle_sync[1:0], spi_word_toggle};
    spi_word_commit_reg <= spi_toggle_sync[1] ^ spi_toggle_sync[2];

    if (spi_toggle_sync[1] ^ spi_toggle_sync[2])
        spi_word_hold <= spi_word_spi;
end

assign spi_word_commit = spi_word_commit_reg;
assign dac_spi_write   = spi_word_commit & cmd1;
assign dac_spi_read    = spi_word_commit & cmd13;
assign cmpr            = {1'b0, cmpr_reg};

assign vc = 1'b1;
assign gn = 1'b0;

// =====================================================================
// NEW FEATURE (not in Eddy_c.bdf): ADC capture control --
//   sample-count limit + CONTINUOUS ping-pong (double-buffer) + test mode.
//   cmd10            -> sample-count register nsamp (0..16384).
//   mode[14] (cmd9)  -> continuous mode (two banks, write never stops).
//   mode[15] (cmd9)  -> test mode: channel 0 records the DAC value.
//   Captured count   = nsamp in both modes. In 4-point mode the sample clock
//                      is sparse (four delayed samples per selected period);
//                      nsamp is still the number of RAM words requested by STM.
//   Continuous bank size = count/2.  The 4 ADC buffers are `adc_chan`
//   (true dual-port RAM): write in the ADC clock domain, read in clk64.
//   PB2/PB6 = single-shot "ready" / continuous "current write bank".
//   Status (cmd4): [7]=bank (ch0), [3:0]=ready/bank per channel.
// =====================================================================
// write+read registers (cmd10/11/12/14) are READ by sending the dummy word
// 0xFFFF; gate their write-enable so a read does NOT overwrite the register.
// (0xFFFF is out of range for nsamp/threshold/reset-addr; harmless guard.)
wire        not_rd = (spi_word_hold != 16'hFFFF);
wire        wr10 = cmd10 & spi_word_commit & not_rd;
reg  [14:0] nsamp;
always @(posedge clk) if (wr10) nsamp <= spi_word_hold[14:0];

wire        cont      = mode[14];             // continuous mode
wire [14:0] cap_total = nsamp;                // command 10 always specifies RAM words
wire [13:0] cap_half  = cap_total[14:1];      // bank size = count/2

wire bank0, bank1, bank2, bank3;        // current write bank per channel (synced to clk64)
wire ready0, ready1, ready2, ready3;    // single-shot filled / continuous bank flag

// AD9649 specifies that CMOS DATA is valid on the rising edge of DCO. Capture
// that edge, as in the original design. These registers are intentionally not
// forced into the IOEs: the DCO global-clock insertion delay otherwise creates
// an input hold violation. A falling-edge holding register then gives the M9K
// write port a full half-cycle before the next rising DCO edge.
always @(posedge C0DCO) adc0_in <= C0D;
always @(posedge C1DCO) adc1_in <= C1D;
always @(posedge C2DCO) adc2_in <= C2D;
always @(posedge C3DCO) adc3_in <= C3D;

always @(negedge C0DCO) adc0_sample <= adc0_in;
always @(negedge C1DCO) adc1_sample <= adc1_in;
always @(negedge C2DCO) adc2_sample <= adc2_in;
always @(negedge C3DCO) adc3_sample <= adc3_in;

// Command 15 asserts every capture-domain reset immediately. Deassertion is
// released through two local DCO edges so adc_chan pointer/bank registers meet
// recovery/removal and all four-point controllers restart deterministically.
always @(posedge C0DCO or posedge cmd15)
    if (cmd15) cap_reset0 <= 2'b11;
    else       cap_reset0 <= {cap_reset0[0], 1'b0};
always @(posedge C1DCO or posedge cmd15)
    if (cmd15) cap_reset1 <= 2'b11;
    else       cap_reset1 <= {cap_reset1[0], 1'b0};
always @(posedge C2DCO or posedge cmd15)
    if (cmd15) cap_reset2 <= 2'b11;
    else       cap_reset2 <= {cap_reset2[0], 1'b0};
always @(posedge C3DCO or posedge cmd15)
    if (cmd15) cap_reset3 <= 2'b11;
    else       cap_reset3 <= {cap_reset3[0], 1'b0};

// Digital DAC-loopback test: sample DD on the opposite edge of the same DCO
// that clocks channel-0 RAM. Keeping one real clock source removes the former
// clk64/C0DCO clock mux and its hold-unsafe path into the RAM write controls.
always @(negedge C0DCO) dac_test_sample <= DD;

// ---- Four-point threshold capture ------------------------------------------
// Required behavior: the current ADC word detects the threshold crossing and
// delay zero stores that same word.  No DAC/ADC latency compensation is needed,
// because both the comparison and the stored value use the same ADC sample.
// ----------------------------------------------------------------------------
// Four-point capture: each four_point_channel buffers its 4 points and streams
// them out as (wdata,wen). 4-point mode uses that; full-form (mode[7]) and ch0
// test mode (mode[15]) capture the live sample on every DCO clock instead.
wire [13:0] fp_wdata0, fp_wdata1, fp_wdata2, fp_wdata3;
wire        fp_wen0, fp_wen1, fp_wen2, fp_wen3;
wire        fp_active0 = ~mode[7] & ~mode[15];   // ch0 four-point active
wire        fp_active  = ~mode[7];               // ch1..3 four-point active
wire [13:0] wdata0 = mode[15] ? dac_test_sample : (fp_active0 ? fp_wdata0 : adc0_sample);
wire [13:0] wdata1 = fp_active ? fp_wdata1 : adc1_sample;
wire [13:0] wdata2 = fp_active ? fp_wdata2 : adc2_sample;
wire [13:0] wdata3 = fp_active ? fp_wdata3 : adc3_sample;
// RAM write clocks are always real converter/system clocks. Four-point mode
// uses four_point_sample only as a synchronous write-enable. The former design
// routed that pulse through a LUT/global-clock mux; in hardware this could turn
// a sparse point selector into an invalid/glitching RAM clock and fill memory
// with the complete waveform.
//
// Every RAM always stays in its own source-synchronous DCO domain. This removes
// the former C1/C2/C3 multi-bit CDC into C0DCO.
assign cap_wclk0 = C0DCO;
assign cap_wclk1 = C1DCO;
assign cap_wclk2 = C2DCO;
assign cap_wclk3 = C3DCO;

assign cap_wen0 = v0 & (fp_active0 ? fp_wen0 : 1'b1);
assign cap_wen1 = v1 & (fp_active  ? fp_wen1 : 1'b1);
assign cap_wen2 = v2 & (fp_active  ? fp_wen2 : 1'b1);
assign cap_wen3 = v3 & (fp_active  ? fp_wen3 : 1'b1);
assign four_point_sample = fp_wen0;

// Use the combinational decode of the confirmed command for the ADC read path.
// The legacy cmd3 register is clocked by clko[0] and can lag cmd_reg by up to one
// divided-clock period. During that gap O_DAT already selects ADC data, while
// adc_chan has not preloaded RAM[0] yet; an early CS edge then shifts a stale
// first word. q3 changes immediately after cmd_reg is accepted, giving the
// synchronous M9K read port a full clk64 cycle to preload address zero.
wire adc_read_cmd = q3;
wire rd0 = read_d0 & adc_read_cmd;
wire rd1 = read_d1 & adc_read_cmd;
wire rd2 = read_d2 & adc_read_cmd;
wire rd3 = read_d3 & adc_read_cmd;

adc_chan inst3 (
    .wclk(cap_wclk0), .wen(cap_wen0), .wdata(wdata0), .clr(cap_reset0[1]), .cont(cont),
    .half(cap_half), .nsize(cap_total),
    .rclk(clk), .rstart(adc_read_cmd), .rden(rd0), .rdata(ADC0[13:0]),
    .wbank_r(bank0), .ready_r(ready0)
);
pll_16_100 inst4 (
    .inclk0(\16MHz ),
    .c0(clk64),
    .c1()
);
lpm_counter0 inst6 (
    .clock(clk64),
    .q(clko[7:0])
);
ALT_OUTBUF_DIFF inst7 ( .i(w_5), .o(ADC0_CLKP), .obar(ADC0_CLKN) );
// PCB wiring of the AD9744 LFCSP is single-ended:
//   FPGA R22 (net DC-) -> AD9744 pin 12 CLK+ (the active clock input)
//   FPGA R21 (net DC+) -> AD9744 pin 13 CLK- (must float in this mode)
// CMODE is tied to CLKCOM/GND on the board. Launch DD on rising clk64 and
// clock the DAC from inverted clk64 so its rising capture edge is half a cycle
// later, while leaving the unused CLK- input undriven as required by AD9744.
// A DDIO output forwards the clock through the I/O register instead of general
// routing, minimizing jitter and fixing its phase relative to the DD IOEs.
altddio_out #(
    .width(1),
    .power_up_high("OFF"),
    .oe_reg("UNREGISTERED"),
    .extend_oe_disable("OFF"),
    .intended_device_family("Cyclone IV E")
) dac_clk_forward (
    .datain_h(1'b0),
    .datain_l(1'b1),
    .outclock(clk64),
    .outclocken(1'b1),
    .aset(1'b0),
    .aclr(1'b0),
    .sset(1'b0),
    .sclr(1'b0),
    .oe(1'b1),
    .dataout(DAC_CLKN),
    .oe_out()
);
assign DAC_CLKP = 1'bz;
assign uuy = 1'b0;   // WIRE inst9
assign TEST0 = addr[0];   // WIRE inst10
assign cmd_w = cmd1 | cmd14 | cmd9 | cmd11 | cmd12 | cmd10;   // OR6 inst11 (gn->cmd10: enable write strobe for the cmd10 sample-count register)
assign clk = clk64;   // GLOBAL inst12
constA5 inst13 (
    .result(cnst[7:0])
);
DAC_RAM inst14 (
    .data(spi_word_hold[13:0]),
    .wren(dac_spi_write),
    .address(addr[13:0]),
    .inclock(clk),
    .q(dac_ram_q)
);
// Independent read port for playback. The legacy DAC_RAM clock is multiplexed
// for SPI access; using it as the live DAC source stopped/rephased the waveform
// whenever STM selected another command.
dac_play_ram inst14_play (
    .wclk(clk),
    .wren(dac_spi_write),
    .waddr(addr),
    .wdata(spi_word_hold[13:0]),
    .rclk(clk64),
    .raddr(dac_play_addr),
    .rdata(dac_play_q)
);
// AD9744 latches on the rising edge of physical CLK+ (FPGA DAC_CLKN). That
// clock is inverted clk64, so rising-edge DD registers get a half-cycle window.
always @(posedge clk64) dac_out <= dac_play_q;
assign DD = dac_out;

// Dedicated synchronous playback address. The original circuit compared the
// shared SPI/playback counter, synchronized the compare through another clock
// domain and only then asynchronously cleared the counter. At 64 MHz that
// allowed addresses beyond cmp to reach the DAC once per loop. Those unwritten
// locations appeared as exact zero samples. Keep command-14 semantics
// inclusive: cmp=16383 plays all 16384 words, cmp=0 repeats address zero.
always @(posedge clk64) begin
    if (!dac_play)
        dac_play_addr <= 14'd0;
    else if (dac_play_addr >= cmp[13:0])
        dac_play_addr <= 14'd0;
    else
        dac_play_addr <= dac_play_addr + 14'd1;
end

assign Write_DAC = dac_spi_write;
assign Read_DAC  = dac_spi_read;
assign ccc       = dac_spi_write | dac_spi_read;
assign addr      = dac_spi_addr;
hex_ff inst22 (
    .data(spi_word_hold[15:0]),
    .clock(clk),
    .enable(wr14),
    .q(cmp[15:0])
);
// DAC RAM access no longer shares its read port with playback, therefore its
// SPI-side clock must never be switched by d_run. This keeps writes/readback
// deterministic even while continuous excitation is active.
assign clk_in = clk;
mux16_8 inst24 (
    .data7x(cmpr[15:0]),   // cmd12 read-back: comparator threshold
    .data6x({cnst[7:0], bank0, freq[1:0], d_run, ready3, ready2, ready1, ready0}),  // status: [7]=bank(ch0), [3:0]=ready/bank per ch
    .data5x({1'b0, nsamp}),   // cmd10 read-back: sample-count register
    .data4x(delay[15:0]),
    .data3x({gn, gn, ADC[13:0]}),
    .data2x(cmp[15:0]),
    .data1x({gn, gn, dac_ram_q}),
    // Bit 13 is a read-only build marker for this hardware-validation image.
    // The actual internal mode register is unchanged; mode[1:0]/[7]/[14]/[15]
    // Command 0 must return the mode register exactly as written. Do not mix
    // build markers or threshold state into the protocol register.
    .data0x(mode[15:0]),
    .sel(MX_CTRL[2:0]),
    .result(O_DAT[15:0])
);
dc16 inst25 (
    .data(cmd[3:0]),
    .eq0(),
    .eq1(q1),
    .eq2(q2),
    .eq3(q3),
    .eq4(q4),
    .eq5(q5),
    .eq6(q6),
    .eq7(q7),
    .eq8(q8),
    .eq9(q9),
    .eq10(q10),
    .eq11(q11),
    .eq12(q12),
    .eq13(q13),
    .eq14(q14),
    .eq15(w_19)
);
amp_spi_router inst_amp_spi_router (
    .spi_sck(PE2),
    .spi_mosi(PE6),
    .spi_cs_n(PE4),
    .channel(control[1:0]),
    .amp_sck(DAC_CLK),
    .amp_data(DAC_DATA),
    .amp_cs_n(DAC_CS[3:0])
);
assign cmd_dac = cmd1 | cmd13 | cmd2;   // OR3 inst27
assign cmd_d = cmd1 | cmd13;   // OR2 inst28
assign clk_a0 = four_point_sample & v0;   // actual four-point write-enable debug
mux21 inst30 (
    .data1(read_d0),
    .data0(clk_a0),
    .sel(adc_read_cmd),
    .result(adc_clk0)
);
assign wr14 = cmd14 & spi_word_commit & not_rd;
assign clr_dac = adr_clr;   // SPI address reset; playback wraps synchronously above
hex_ff inst33 (
    .data(spi_word_hold[15:0]),
    .clock(clk),
    .enable(wr11),
    .q(delay[15:0])
);
assign addr_en = 1'b1;   // retained for debug compatibility
// Keep the waveform clock running after cmd6 even when STM changes the command
// to cmd3/status/etc. The original cmd2-only clock stopped the DAC as soon as
// another command was selected, so continuous excitation was not continuous.
assign dac_play = cmd2 | d_run;
assign TEST1 = read_dd;   // WIRE inst35
dc_24 inst36 (
    .data(control[1:0]),
    .enable(read_dd),
    .eq0(read_d0),
    .eq1(read_d1),
    .eq2(read_d2),
    .eq3(read_d3)
);
// Entering any DAC-RAM command starts its SPI address at zero. Playback has a
// separate address now, so this reset is valid even while continuous DAC runs.
assign adr_clr = w_6;
assign w_5 = clk50 & 1'b1;   // AND2 inst38
t_count inst40 (
    .clock(clk50),
    .aclr(adr_clr),
    .q(t_clk[3:0])
);
assign write_d = s_load & cmd_w;   // AND2 inst41
assign read_dd = w_21 & s_read;   // AND2 inst42
assign w_2 = ~(clk & cmd_d);   // NAND2 inst43
assign TEST2 = write_d;   // WIRE inst44
assign TEST3 = 1'b0;   // WIRE inst45 (MISO->TEST3 mirror removed: let QH pack into PB4 IOE register for max SPI speed)
ALT_OUTBUF_DIFF inst46 ( .i(w_5), .o(ADC1_CLKP), .obar(ADC1_CLKN) );
ALT_OUTBUF_DIFF inst47 ( .i(w_5), .o(ADC2_CLKP), .obar(ADC2_CLKN) );
ALT_OUTBUF_DIFF inst48 ( .i(w_5), .o(ADC3_CLKP), .obar(ADC3_CLKN) );
assign PB4 = MISO;   // WIRE inst49
mux13_4 inst50 (
    .data3x(ADC3[13:0]),
    .data2x(ADC2[13:0]),
    .data1x(ADC1[13:0]),
    .data0x(ADC0[13:0]),
    .sel(control[1:0]),
    .result(ADC[13:0])
);
assign wr11 = cmd11 & spi_word_commit & not_rd;
dff_prim inst52 ( .d(q1), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd1) );
dff_prim inst53 ( .d(w_19), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd15) );
dff_prim inst54 ( .d(q2), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd2) );
assign a_en = 1'b1;
dff_prim inst56 ( .d(q10), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd10) );
dff_prim inst57 ( .d(1'b0), .clk(1'b0), .clrn(cmd15_i), .prn(start), .q(v0) );  // capture armed by cmd2, reset by cmd15 (adc_chan handles stop/wrap)
dff_prim inst58 ( .d(q3), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd3) );
assign w_8 = 1'b0;
assign w_9 = 1'b0;
dff_prim inst61 ( .d(q14), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd14) );
// ===== Command confirm strobe (PD[7] = pin W13) — NEW, not in Eddy_c.bdf =====
// The STM writes the 4 command bits PD[3:0] atomically (BSRR), then pulses PD7
// high to confirm. Latch cmd[3:0] on the RISING edge of PD7 so a command takes
// effect only when confirmed (glitch-free; no false triggers while PD changes).
// PD7 is double-synchronized to clk first; cmd is held until the next confirm.
reg [2:0] pd7_sync = 3'b000;
reg [3:0] cmd_reg = 4'd0;
reg       d_run_state = 1'b0;
wire      cmd_accept = pd7_sync[1] & ~pd7_sync[2];

always @(posedge clk) begin
    pd7_sync <= {pd7_sync[1:0], PD[7]};

    if (cmd_accept) begin
        cmd_reg <= PD[3:0];

        // Commands 6/7 are persistent state changes.  The previous circuit
        // stored this bit in a DFF whose clock was tied permanently high and
        // drove its asynchronous preset/clear from short generated pulses.
        // That structure is not a reliable FPGA state element: in hardware
        // command 2 could keep the DAC running temporarily, but d_run stayed
        // zero and the waveform stopped as soon as command 4/3 was selected.
        case (PD[3:0])
            4'd6: d_run_state <= 1'b1;
            4'd7: d_run_state <= 1'b0;
            default: d_run_state <= d_run_state;
        endcase
    end
end

// One address increment per completed SPI word. Entering command 1 or 13
// resets the shared SPI-side DAC address before STM starts the transfer.
always @(posedge clk) begin
    if (cmd_accept && ((PD[3:0] == 4'd1) || (PD[3:0] == 4'd13)))
        dac_spi_addr <= 14'd0;
    else if (dac_spi_write || dac_spi_read)
        dac_spi_addr <= dac_spi_addr + 14'd1;
end

assign cmd[3:0] = cmd_reg;   // was: assign cmd[3:0] = PD[3:0] (WIRE inst62)
assign d_run = d_run_state;
assign control[3:0] = PD[7:4];   // WIRE inst63
dff_prim inst64 ( .d(q5), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd5) );
adc_chan inst66 (
    .wclk(cap_wclk1), .wen(cap_wen1), .wdata(wdata1), .clr(cap_reset1[1]), .cont(cont),
    .half(cap_half), .nsize(cap_total),
    .rclk(clk), .rstart(adc_read_cmd), .rden(rd1), .rdata(ADC1[13:0]),
    .wbank_r(bank1), .ready_r(ready1)
);
adc_chan inst67 (
    .wclk(cap_wclk2), .wen(cap_wen2), .wdata(wdata2), .clr(cap_reset2[1]), .cont(cont),
    .half(cap_half), .nsize(cap_total),
    .rclk(clk), .rstart(adc_read_cmd), .rden(rd2), .rdata(ADC2[13:0]),
    .wbank_r(bank2), .ready_r(ready2)
);
adc_chan inst68 (
    .wclk(cap_wclk3), .wen(cap_wen3), .wdata(wdata3), .clr(cap_reset3[1]), .cont(cont),
    .half(cap_half), .nsize(cap_total),
    .rclk(clk), .rstart(adc_read_cmd), .rden(rd3), .rdata(ADC3[13:0]),
    .wbank_r(bank3), .ready_r(ready3)
);
assign clk_a1 = v1 & cap_wen1;   // retained legacy debug net
assign clk_a2 = v2 & cap_wen2;   // retained legacy debug net
assign w_10 = v3 & cap_wen3;   // retained legacy debug net
dff_prim inst72 ( .d(1'b0), .clk(1'b0), .clrn(cmd15_i), .prn(start), .q(v1) );
dff_prim inst73 ( .d(1'b0), .clk(1'b0), .clrn(cmd15_i), .prn(start), .q(v2) );
dff_prim inst74 ( .d(1'b0), .clk(1'b0), .clrn(cmd15_i), .prn(start), .q(v3) );
mux21 inst75 (
    .data1(read_d3),
    .data0(w_10),
    .sel(adc_read_cmd),
    .result(adc_clk3)
);
mux21 inst76 (
    .data1(read_d2),
    .data0(clk_a2),
    .sel(adc_read_cmd),
    .result(adc_clk2)
);
mux21 inst77 (
    .data1(read_d1),
    .data0(clk_a1),
    .sel(adc_read_cmd),
    .result(adc_clk1)
);
mux4_1 inst78 (
    .data3(clko[2]),
    .data2(clko[1]),
    .data1(clko[0]),
    .data0(clk64),
    .sel(freq[1:0]),
    .result(clk50)
);
assign freq[0] = PD[8];   // WIRE inst79
assign freq[1] = PD[9];   // WIRE inst80
dff_prim inst81 ( .d(q11), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd11) );
assign MOSI = PB5;   // WIRE inst83
assign SCK = PA5;   // WIRE inst84
dff_prim inst85 ( .d(q6), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd6) );
dff_prim inst86 ( .d(q7), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd7) );
assign PB2 = ready0;      // ch0: single-shot "ready" (filled to N) / continuous "current write bank" number
assign PB6 = ready0;      // same ch0 ready/bank flag (PB6=Y14)
mx_ctrl inst88 (
    .cmd(cmd[3:0]),
    .mux_ctrl(MX_CTRL[2:0])
);
dff_prim inst89 ( .d(q13), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd13) );
assign STLD = write_d | read_dd;   // OR2 inst90
imp_former1 inst91 (
    .clk(clko[0]),
    .in_sgn(cmd_dac),
    .out_imp(w_6)
);
imp_former1 inst92 (
    .clk(clk64),
    .in_sgn(PA4),
    .out_imp(s_load)
);
imp_former1 inst93 (
    .clk(clko[0]),
    .in_sgn(cmd2),
    .out_imp(adc_start)
);
imp_former1 inst96 (
    .clk(clk64),
    .in_sgn(SS),
    .out_imp(s_read)
);
// --- SPI high-speed fix (intentional deviation from Eddy_c.bdf) --------------
// Original schematic loaded the MISO 74165s with STLD = (write_d | read_dd),
// a ~1-cycle pulse generated in the clk64 domain ~1 clk64 AFTER chip-select
// asserts. At high SCK the first SCK edge arrives before that load pulse, so the
// shift register still holds stale/zero data -> STM reads 0 (works only at low
// SCK). Fix: preload the response while the bus is idle (STLD = PA4 = ~SS, the
// chip-select-deasserted level). The 74165 async parallel-load is level-sensitive,
// so O_DAT is held on the MISO outputs before the first SCK edge at any speed.
// (Was: .STLD(STLD) on both 74165 instances.)
\74165_a  inst97 (
    .SER(1'b0),
    .CLK(SCK_I),
    .ENA(SS),
    .STLD(PA4),
    .D(O_DAT[7:0]),
    .QH(s1)
);
\74165_a  inst98 (
    .SER(s1),
    .CLK(SCK_I),
    .ENA(SS),
    .STLD(PA4),
    .D(O_DAT[15:8]),
    .QH(MISO)
);
assign TEST4 = d_run;   // WIRE inst100
assign TEST5 = DD[0];   // WIRE inst101
assign TEST6 = clr_dac;   // WIRE inst102
assign TEST7 = clk_a0;   // WIRE inst103
assign TEST8 = addr_en;   // WIRE inst104
assign TEST9 = mode[7];   // WIRE inst105
assign TEST10 = ccc;   // WIRE inst106
assign TEST11 = adc_start;   // WIRE inst107
assign TEST12 = SCK;   // WIRE inst108
assign TEST13 = SS;   // WIRE inst109
assign out_addr = 1'b0;
assign TEST14 = Read_DAC;   // WIRE inst111
assign TEST15 = Write_DAC;   // WIRE inst112
dff_prim inst113 ( .d(q12), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd12) );
// Store every valid threshold exactly. Command-12 reads shift 0xFFFF into MOSI;
// not_rd prevents that dummy word from changing the register. Any other value
// above 16384 is invalid and leaves the last valid threshold unchanged.
always @(posedge clk) begin
    if (wr12 && (spi_word_hold <= 16'd16384))
        cmpr_reg <= spi_word_hold[14:0];
end
assign wr12 = cmd12 & spi_word_commit & not_rd;
four_point_channel inst_four_point0 (
    .clk(C0DCO),
    .reset(cap_reset0[1]),
    .enable(v0 & ~mode[7]),
    .threshold(cmpr_reg),
    .delay0(delay[7:0]),
    .delay1(delay[15:8]),
    .mode_div(mode[1:0]),
    .adc_sample(adc0_sample),
    .wdata(fp_wdata0),
    .wen(fp_wen0)
);
four_point_channel inst_four_point1 (
    .clk(C1DCO),
    .reset(cap_reset1[1]),
    .enable(v1 & ~mode[7]),
    .threshold(cmpr_reg),
    .delay0(delay[7:0]),
    .delay1(delay[15:8]),
    .mode_div(mode[1:0]),
    .adc_sample(adc1_sample),
    .wdata(fp_wdata1),
    .wen(fp_wen1)
);
four_point_channel inst_four_point2 (
    .clk(C2DCO),
    .reset(cap_reset2[1]),
    .enable(v2 & ~mode[7]),
    .threshold(cmpr_reg),
    .delay0(delay[7:0]),
    .delay1(delay[15:8]),
    .mode_div(mode[1:0]),
    .adc_sample(adc2_sample),
    .wdata(fp_wdata2),
    .wen(fp_wen2)
);
four_point_channel inst_four_point3 (
    .clk(C3DCO),
    .reset(cap_reset3[1]),
    .enable(v3 & ~mode[7]),
    .threshold(cmpr_reg),
    .delay0(delay[7:0]),
    .delay1(delay[15:8]),
    .mode_div(mode[1:0]),
    .adc_sample(adc3_sample),
    .wdata(fp_wdata3),
    .wen(fp_wen3)
);
dff_prim inst142 ( .d(q9), .clk(clko[0]), .clrn(1'b1), .prn(1'b1), .q(cmd9) );
hex_ff inst143 (
    .data(spi_word_hold[15:0]),
    .clock(clk),
    .enable(wr9),
    .q(mode[15:0])
);
assign wr9 = cmd9 & spi_word_commit & not_rd;
assign adr_en = ~(cmd1 | cmd13 | adr_clr);   // NOR3 inst145
assign read_d = ~read_dd;   // NOT 151
assign start = ~adc_start;   // NOT 152
assign cmd15_i = ~cmd15;   // NOT 153
assign SS = ~PA4;   // NOT 155
assign w_7 = ~d_run;   // NOT 158
assign SCK_I = ~SCK;   // NOT 159
assign write_di = ~write_d;   // NOT 160
assign w_21 = ~cmd_w;   // NOT 161

endmodule
