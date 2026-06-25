//-----------------------------------------------------------------------------
// adc_chan -- per-ADC-channel capture buffer, single-shot + continuous ping-pong.
// One inferred true dual-port M9K RAM (16384x14): write port in the ADC sample
// clock domain, read port in the system clk64 domain.
//
//   cont = 0 : SINGLE-SHOT   -- fill N samples (nsize) then stop until clr.
//   cont = 1 : CONTINUOUS    -- two banks of N/2 (half); write wraps and NEVER
//                               stops (overwrites unread data = no acquisition
//                               gaps). PB2/status track the current write bank.
//
// CDC: only wbank and wfull cross wclk->rclk (multi-FF). waddr is never read
// from the rclk domain. In continuous mode the completed bank is snapshotted
// when rstart rises; later bank flips never disturb an active SPI read.
// RAM access blocks are reset-free for clean M9K mapping.
// Target: Cyclone IV E EP4CE115F23C8, Quartus 13.1, Verilog-2001.
//-----------------------------------------------------------------------------
module adc_chan (
    // -------- WRITE domain (wclk = ADC sample clock) --------
    input  wire        wclk,
    input  wire        wen,     // capture active (sample valid this wclk)
    input  wire [13:0] wdata,   // ADC sample
    input  wire        clr,     // async reset of pointers/bank (cmd15)
    input  wire        cont,    // 1 = continuous ping-pong, 0 = single-shot
    input  wire [13:0] half,    // bank size = N/2; 0 => 8192
    input  wire [14:0] nsize,   // total N = 2*half; 0 => 16384
    // -------- READ domain (rclk = clk64) --------
    input  wire        rclk,
    input  wire        rstart,  // rising edge starts a coherent bank read
    input  wire        rden,    // 1-clk read strobe: advance to next sample
    output reg  [13:0] rdata,   // current sample to SPI (registered RAM read)
    output reg         wbank_r, // current WRITE bank (0/1), synced to rclk -> PB2/status
    output reg         ready_r  // single-shot: filled; continuous: follows write bank
);
    reg [13:0] mem [0:16383];

    //========================= WRITE control (wclk) ==========================
    reg  [13:0] waddr;
    reg         wbank;
    reg         wfull;
    wire [13:0] hsize = (half  == 14'd0)  ? 14'd8192  : half;
    wire [14:0] tsize = (nsize == 15'd0)  ? 15'd16384 : nsize;
    // continuous wraps at exactly 2*hsize so the two banks are always symmetric
    // (even if N is odd); single-shot stops at the requested total N (tsize).
    wire [14:0] wrap_n = cont ? {hsize, 1'b0} : tsize;
    wire        at_top = ({1'b0, waddr} == (wrap_n - 15'd1));   // last sample index
    wire        write_allowed = cont | ~wfull;
    wire        do_write = wen & write_allowed;

    // RAM write port -- clean (reset-free) for M9K inference
    always @(posedge wclk)
        if (do_write) mem[waddr] <= wdata;

    always @(posedge wclk or posedge clr) begin
        if (clr) begin
            waddr <= 14'd0;
            wbank <= 1'b0;
            wfull <= 1'b0;
        end else if (do_write) begin
            if (cont) begin
                // continuous: wrap, never stop; flag the half being written
                waddr <= at_top ? 14'd0 : (waddr + 14'd1);
                wbank <= at_top ? 1'b0  : (((waddr + 14'd1) >= hsize) ? 1'b1 : 1'b0);
            end else begin
                // single-shot: stop at the last sample
                if (at_top) wfull <= 1'b1;
                else        waddr <= waddr + 14'd1;
            end
        end
    end

    //========================= READ control (rclk) ===========================
    reg  [13:0] raddr;
    reg  [13:0] hsize_r;
    reg         rstart_q;
    reg         wbank_s1, wbank_s2;
    reg         wfull_s1, wfull_s2;
    wire [13:0] rbase = wbank_s2 ? 14'd0 : hsize_r;           // base of completed bank
    wire        read_start = rstart & ~rstart_q;
    wire [13:0] read_base  = cont ? rbase : 14'd0;
    // rdata is preloaded while SPI CS is inactive.  Therefore an rden pulse
    // occurring during the current SPI word must fetch the NEXT word, not
    // re-read the current raddr.  Otherwise word 0 is stale and every valid
    // sample is shifted by one transaction.
    wire [13:0] ram_raddr = read_start ? read_base :
                            rden       ? (raddr + 14'd1) :
                                         raddr;

    // RAM read port -- clean (reset-free) for M9K inference
    always @(posedge rclk)
        rdata <= mem[ram_raddr];

    always @(posedge rclk or posedge clr) begin
        if (clr) begin
            raddr    <= 14'd0;
            hsize_r  <= 14'd8192;
            rstart_q <= 1'b0;
            wbank_s1 <= 1'b0; wbank_s2 <= 1'b0; wbank_r <= 1'b0;
            wfull_s1 <= 1'b0; wfull_s2 <= 1'b0;
            ready_r  <= 1'b0;
        end else begin
            hsize_r  <= (half == 14'd0) ? 14'd8192 : half;
            rstart_q <= rstart;
            wbank_s1 <= wbank;   wbank_s2 <= wbank_s1;
            wbank_r  <= wbank_s2;
            wfull_s1 <= wfull;   wfull_s2 <= wfull_s1;

            // Snapshot the completed bank once, at the start of cmd3. The
            // writer may wrap many times while STM reads; do not jump raddr.
            if (read_start)
                raddr <= read_base;
            else if (rden)
                raddr <= raddr + 14'd1;

            ready_r <= cont ? wbank_s2 : wfull_s2;
        end
    end
endmodule
