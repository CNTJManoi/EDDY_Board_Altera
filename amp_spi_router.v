//-----------------------------------------------------------------------------
// Transparent STM32 SPI4 -> LTC2640 router.
//
// STM32:
//   PE2 = SPI4_SCK, PE6 = SPI4_MOSI, PE4 = software CS (active low)
//   PD[5:4] = amplifier channel 0..3
//
// LTC2640:
//   SCK and SDI are shared by all four devices.
//   Only the selected active-low CS/LD output follows PE4.
//-----------------------------------------------------------------------------
module amp_spi_router (
    input  wire       spi_sck,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    input  wire [1:0] channel,
    output wire       amp_sck,
    output wire       amp_data,
    output reg  [3:0] amp_cs_n
);
    assign amp_sck  = spi_sck;
    assign amp_data = spi_mosi;

    always @* begin
        amp_cs_n = 4'b1111;
        if (!spi_cs_n) begin
            case (channel)
                2'd0: amp_cs_n = 4'b1110;
                2'd1: amp_cs_n = 4'b1101;
                2'd2: amp_cs_n = 4'b1011;
                2'd3: amp_cs_n = 4'b0111;
                default: amp_cs_n = 4'b1111;
            endcase
        end
    end
endmodule
