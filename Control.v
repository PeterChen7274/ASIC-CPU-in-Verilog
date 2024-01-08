`include "Opcode.vh"

module Control(
    input [31:0] Instruction,
    output [1:0] wBSel,
    output regWEn,
    output memRW,
    output [3:0] aLUop,
    output aSel,
    output bSel,
    output pCsel
);


reg [1:0] WBSel;
reg RegWEn;
reg MemRW;
reg ASel;
reg BSel;
reg PCsel;

assign wBSel = WBSel;
assign regWEn = RegWEn;
assign memRW = MemRW;
assign aSel = ASel;
assign bSel = BSel;
assign pCsel = PCsel;

ALUdec ALUCtr(
  .opcode(Instruction[6:0]),
  .funct(Instruction[14:12]),
  .add_rshift_type(Instruction[30]),
  .aLUop(aLUop)
);


always @(Instruction) begin
    if (Instruction[6:0] == `OPC_JAL || Instruction[6:0] == `OPC_JALR) begin
        PCsel = 1;
    end else begin
        PCsel = 0;
    end
    if (Instruction[6:0] == `OPC_ARI_RTYPE) begin
        BSel = 0;
    end else begin
        BSel = 1;
    end
    if (Instruction[6:0] == `OPC_ARI_RTYPE || Instruction[6:0] == `OPC_ARI_ITYPE || Instruction[6:0] == `OPC_LOAD || Instruction[6:0] == `OPC_STORE || Instruction[6:0] == `OPC_JALR) begin
        ASel = 0;
    end else begin
        ASel = 1;
    end
    if (Instruction[6:0] == `OPC_STORE || Instruction[6:0] == `OPC_CSR) begin
        MemRW = 1;
    end else begin
        MemRW = 0;
    end
    if (Instruction[6:0] == `OPC_JAL || Instruction[6:0] == `OPC_JALR || Instruction[6:0] == `OPC_ARI_RTYPE || Instruction[6:0] == `OPC_ARI_ITYPE || Instruction[6:0] == `OPC_LOAD || Instruction[6:0] == `OPC_AUIPC || Instruction[6:0] == `OPC_LUI) begin
        RegWEn = 1;
        if (Instruction[6:0] == `OPC_ARI_ITYPE || Instruction[6:0] == `OPC_ARI_RTYPE || Instruction[6:0] == `OPC_AUIPC || Instruction[6:0] == `OPC_LUI) begin
            WBSel = 0;
        end else begin
            if (Instruction[6:0] == `OPC_LOAD) begin
                WBSel = 1;
            end else begin
                WBSel = 2;
            end
        end
    end else begin
        RegWEn = 0;
    end
end

endmodule