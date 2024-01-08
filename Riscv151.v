`include "const.vh"
`include "Opcode.vh"

module Riscv151(
    input clk,
    input reset,

    // Memory system ports
    output [31:0] dcache_addr,
    output [31:0] icache_addr,
    output [3:0] dcache_we,
    output dcache_re,
    output icache_re,
    output [31:0] dcache_din,
    input [31:0] dcache_dout,
    input [31:0] icache_dout,
    input stall,
    output [31:0] csr

);

  // Implement your core here, then delete this comment
  reg [31:0] pc1, pc2, pc3;
  wire [31:0] A_mux, B_mux, ins1;
  reg [31:0] ins2;
  wire [31:0] DataA, DataB, forward_A, forward_B;
  reg [31:0] DataW, ALUOut2;
  wire [31:0] Imm_out;
  wire [31:0] ALUOut;
  wire BrEq, BrLT;
  wire PCsel, ASel, BSel, MemRW, RegWEn;
  reg PCsel2, RegWEn2;
  wire [1:0] WBSel;
  reg [1:0] WBSel2;
  wire [3:0] ALUop;
  wire [4:0] addr1, addr2, addr3;
  wire [31:0] din;
  wire branch;
  reg branch2, stall2;
  wire [31:0] d;
  wire [31:0] wbd;

  assign icache_addr = (branch || PCsel == 1)? ALUOut:((stall)? pc1: pc1 + 4);
  assign d = dcache_dout >> ALUOut2[1:0] * 8;
  assign dcache_din = (stall)? dcache_din :(ins1[6:0] == `OPC_CSR)? csr: forward_B << ALUOut[1:0] * 8;
  assign dcache_addr = (stall)? dcache_addr : ALUOut;
  assign dcache_we = (stall)? dcache_we :(ins1[6:0] == `OPC_STORE)? ((ins1[14:12] == 0)? 1 << ALUOut[1:0] : ((ins1[14:12] == 1)? 3 << ALUOut[1:0]: 15)): 0;
  assign icache_re = ~stall;
  assign dcache_re = (stall)? dcache_re :(ins1[6:0] == `OPC_LOAD)? 1: 0;
  assign addr3 = ins2[11:7];
  assign addr1 = ins1[19:15];
  assign addr2 = ins1[24:20];
  assign csr = (ins1[6:0] == `OPC_CSR)? ((ins1[14:12] == 5)? ins1[19:15]: forward_A): 0;
  assign ins1 = (stall)? 0 : icache_dout;
  assign forward_A = (addr1 == addr3 && RegWEn2)? wbd: DataA;
  assign forward_B = (addr2 == addr3 && RegWEn2)? wbd: DataB;
  assign A_mux = (ASel)? pc1 : ((addr1 == 0)? 0 :forward_A);
  assign B_mux = (BSel)? Imm_out: ((addr2 == 0)? 0 :forward_B);
  assign branch = (ins1[6:0] == `OPC_BRANCH)? ((BrEq && ins1[14:12] == 0)? 1: ((BrEq == 0 && ins1[14:12] == 1)? 1 : ((BrLT && (ins1[14:12] == 4 || ins1[14:12] == 6))? 1: (((ins1[14:12] == 5 || ins1[14:12] == 7) && BrLT == 0)? 1: 0)))): 0;
  assign wbd = (WBSel2 == 1)? ((ins2[14:12] == 0)? {{24{d[7]}}, d[7:0]}: ((ins2[14:12] == 4)? d[7:0]: ((ins2[14:12] == 1)? {{16{d[15]}}, d[15:0]} : ((ins2[14:12] == 5)? d[15:0]: dcache_dout)))) : DataW;

  RegFile regs(
    .rst(reset),
    .clk(clk),
    .addr1(addr1),
    .addr2(addr2),
    .addr3(addr3),
    .we(RegWEn2),
    .DataW(wbd),
    .DataA(DataA),
    .DataB(DataB)
  );

  Control control (
    .Instruction(ins1),
    .wBSel(WBSel),
    .regWEn(RegWEn),
    .memRW(MemRW),
    .aLUop(ALUop),
    .aSel(ASel),
    .bSel(BSel),
    .pCsel(PCsel)
  );

  ImmGen Immediate (
    .Instruction(ins1),
    .imm_out(Imm_out)
  );

  ALU Alu( 
    .A(A_mux),
    .B(B_mux),
    .ALUop(ALUop),
    .out(ALUOut)
  );

   BranchComp Bran(
     .clk(clk),
     .Instruction(ins1),
     .BrLT(BrLT),
     .BrEq(BrEq),
     .A(forward_A),
     .B(forward_B)
   );

  assert property (@(posedge clk) (reset == 1)|=> (pc1 == `PC_RESET - 4));

  assert property (
  @(posedge clk) disable iff (reset) 
    (ins1[6:0] == `OPC_STORE) |-> 
    ((dcache_we == 15 && ins1[14:12] == 2) || 
     ((dcache_we == 1 || dcache_we == 2 || dcache_we == 4 || dcache_we == 8) && ins1[14:12] == 0) || 
     ((dcache_we == 3 || dcache_we == 6 || dcache_we == 12) && ins1[14:12] == 1))
  );

  assert property (
  @(posedge clk) disable iff (reset) 
    (ins2[6:0] == `OPC_LOAD) |-> 
    (((wbd[31:8] == 16777215 || wbd[31:8] == 0) && (ins2[14:12] == 4 || ins2[14:12] == 0)) || 
     ((wbd[31:16] == 65535 || wbd[31:16] == 0) && (ins2[14:12] == 1 || ins2[14:12] == 5)) || 
     (ins2[14:12] == 2))
  );


  always @(posedge clk) begin
    if (reset == 1) begin
      pc1 <= `PC_RESET - 4;
      pc2 <= 0;
      pc3 <= 0;
    end else begin
      if (PCsel == 1) begin
        pc1 <= ALUOut;
      end else begin
        if (branch == 1) begin
          pc1 <= ALUOut;
        end else begin
          if (stall) begin
            pc1 <= pc1;
          end else begin
            pc1 <= pc1 + 4;
          end
        end
      end
      if (WBSel == 0) begin
        DataW <= ALUOut;
      end else begin
        if (WBSel == 2) begin
        DataW <= pc1 + 4;
      end
      end
      pc2 <= pc1;
      pc3 <= pc2;
      if (stall) begin
        ins2 <= ins2;
      end else begin
        ins2 <= ins1;
      end
      PCsel2 <= PCsel;
      if (stall && WBSel2 == 1) begin
        RegWEn2 <= RegWEn2;
      end else begin
        RegWEn2 <= RegWEn;
      end
      if (stall) begin
        WBSel2 <= WBSel2;
      end else begin
        WBSel2 <= WBSel;
      end
      if (stall) begin
        ALUOut2 <= ALUOut2;
      end else begin
        ALUOut2 <= ALUOut;
      end
      branch2 <= branch;
      //stall2 <= stall;
    end 
  end

endmodule
