// Dual-clock shadow RAM for deterministic DAC playback.
// The legacy single-port DAC_RAM remains the SPI readback copy. This memory is
// written by the same interface but has an independent clk64 read port, so
// command changes cannot stop or re-clock the playback data path.
module dac_play_ram (
    input  wire        wclk,
    input  wire        wren,
    input  wire [13:0] waddr,
    input  wire [13:0] wdata,
    input  wire        rclk,
    input  wire [13:0] raddr,
    output reg  [13:0] rdata
);
    (* ramstyle = "M9K", ram_init_file = "DAC1.mif" *)
    reg [13:0] mem [0:16383];

    always @(posedge wclk)
        if (wren)
            mem[waddr] <= wdata;

    always @(posedge rclk)
        rdata <= mem[raddr];
endmodule
