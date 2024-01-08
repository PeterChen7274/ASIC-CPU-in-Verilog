`include "Opcode.vh"

module BranchComp(
    input clk,
    input [31:0] Instruction,
    output BrLT,
    output BrEq,
    input [31:0] A,
    input [31:0] B
);

wire BrUn;
reg b1, b2;
assign BrUn = Instruction[13];
assign BrLT = (BrUn)? ((A < B)? 1: 0) : (($signed(A) < $signed(B))? 1: 0);
assign BrEq = (A == B)? 1: 0;
// assign BrLT = b1;
// assign BrEq = b2;

// always @(posedge clk) begin
//     if (BrUn) begin
//         b1 <= (A < B)? 1: 0;
//     end else begin
//         b1 <= ($signed(A) < $signed(B))? 1: 0;
//     end
//     b2 <= (A == B)? 1: 0;
// end

endmodule