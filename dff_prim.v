// dff_prim.v
// Behavioral equivalent of the Altera DFF primitive used in Eddy_c.bdf.
// Positive-edge D flip-flop with active-low asynchronous clear (clrn)
// and preset (prn).  Matches Quartus DFF semantics (clrn has priority).
// Unused clrn/prn are tied to 1'b1 by the instantiations in Eddy_c.v.
module dff_prim (
    input  wire d,
    input  wire clk,
    input  wire clrn,
    input  wire prn,
    output reg  q
);
    always @(posedge clk or negedge clrn or negedge prn) begin
        if (!clrn)
            q <= 1'b0;
        else if (!prn)
            q <= 1'b1;
        else
            q <= d;
    end
endmodule
