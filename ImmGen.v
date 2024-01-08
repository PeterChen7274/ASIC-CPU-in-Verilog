`include "Opcode.vh"

module ImmGen(
    input [31:0] Instruction,
    output [31:0] imm_out
);

reg [31:0] Imm_out;
assign imm_out = Imm_out;

always @(Instruction) begin
  Imm_out = 0;
  case (Instruction[6:0])
    `OPC_LUI: Imm_out = Instruction[31:12] << 12;
    `OPC_AUIPC: Imm_out = Instruction[31:12] << 12;

    `OPC_JAL: begin
        Imm_out[31:12] = {Instruction[31], Instruction[19:12], Instruction[20], Instruction[30:21]}; 
        Imm_out = $signed(Imm_out) >>> 11;
    end

    `OPC_JALR:begin
        Imm_out = $signed(Instruction[31:20]);
    end

    `OPC_BRANCH: begin
        Imm_out[31:20] = {Instruction[31], Instruction[7], Instruction[30:25], Instruction[11:8]};
        Imm_out = $signed(Imm_out) >>> 19;
    end
    `OPC_STORE: Imm_out = $signed({Instruction[31:25], Instruction[11:7]});
  
    `OPC_LOAD: begin
        Imm_out = $signed(Instruction[31:20]);
    end

    `OPC_ARI_ITYPE: begin
        case (Instruction[14:12])
            1: Imm_out[4:0] = Instruction[24:20];
            5: Imm_out[4:0] = Instruction[24:20];

            default: Imm_out= $signed(Instruction[31:20]);
        endcase
    end

    default: Imm_out = 0;
  endcase
end

endmodule