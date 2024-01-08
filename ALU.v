// Module: ALU.v
// Desc:   32-bit ALU for the RISC-V Processor
// Inputs: 
//    A: 32-bit value
//    B: 32-bit value
//    ALUop: Selects the ALU's operation 
// 						
// Outputs:
//    Out: The chosen function mapped to A and B.

`include "Opcode.vh"
`include "ALUop.vh"

module ALU(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUop,
    output [31:0] out
);

    // Implement your ALU here, then delete this comment

reg [31:0] Out;
assign out = Out;

always @(ALUop, A, B) begin
    case (ALUop)
      `ALU_ADD:   Out = A + B;
      `ALU_SUB:   Out = A - B;
      `ALU_AND:   Out = A & B;
      `ALU_OR:   Out = A | B;
      `ALU_XOR:   Out = A ^ B;
      `ALU_SLT:   Out = ($signed(A) < $signed(B)) ? 1 : 0;
      `ALU_SLTU:  Out = (A < B) ? 1 : 0;
      `ALU_SLL:   Out = A << B[4:0];
      `ALU_SRA:   Out = $signed(A) >>> B[4:0];
      `ALU_SRL:   Out = A >> B[4:0];
      `ALU_COPY_B:  Out = B;
      10: Out = 1310;
      default: Out = 0;
    endcase
  end
endmodule
