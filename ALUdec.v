// Module: ALUdecoder
// Desc:   Sets the ALU operation
// Inputs: opcode: the top 6 bits of the instruction
//         funct: the funct, in the case of r-type instructions
//         add_rshift_type: selects whether an ADD vs SUB, or an SRA vs SRL
// Outputs: ALUop: Selects the ALU's operation
//

`include "Opcode.vh"
`include "ALUop.vh"

module ALUdec(
  input [6:0] opcode,
  input [2:0] funct,
  input add_rshift_type,
  output [3:0] aLUop
);

reg [3:0] ALUop;
assign aLUop = ALUop;

always @(opcode, funct, add_rshift_type) begin
  case (opcode)
  `OPC_LUI: ALUop = 10;
  `OPC_AUIPC: ALUop = 0;

  `OPC_JAL: ALUop = 0;
  `OPC_JALR: ALUop = 0;

  `OPC_BRANCH: ALUop = 0;

  `OPC_STORE: ALUop = 0;
  `OPC_LOAD: ALUop = 0;

  `OPC_ARI_RTYPE: begin
    case (funct)
    `FNC_ADD_SUB: begin
      if (add_rshift_type == 0) begin
        ALUop = 0;
      end else begin
        ALUop = 1;
      end
    end
    `FNC_SLL: ALUop = 7;
    `FNC_SLT: ALUop = 5;
    `FNC_SLTU: ALUop = 6;
    `FNC_XOR: ALUop = 4;
    `FNC_OR: ALUop = 3;
    `FNC_AND: ALUop = 2;
    `FNC_SRL_SRA: begin
      if (add_rshift_type == 0) begin
        ALUop = 9;
      end else begin
        ALUop = 8;
      end
    end
    endcase
  end
  `OPC_ARI_ITYPE: begin
    case (funct)
    `FNC_ADD_SUB: begin
      ALUop = 0;
    end
    `FNC_SLL: ALUop = 7;
    `FNC_SLT: ALUop = 5;
    `FNC_SLTU: ALUop = 6;
    `FNC_XOR: ALUop = 4;
    `FNC_OR: ALUop = 3;
    `FNC_AND: ALUop = 2;
    `FNC_SRL_SRA: begin
      if (add_rshift_type == 0) begin
        ALUop = 9;
      end else begin
        ALUop = 8;
      end
    end
    endcase
  end
  `OPC_CSR: ALUop = 10;
  default: ALUop = 15;
  endcase
end

  // Implement your ALU decoder here, then delete this comment

endmodule
