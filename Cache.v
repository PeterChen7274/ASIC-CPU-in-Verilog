`include "util.vh"
`include "const.vh"

module cache #
(
  parameter LINES = 64,
  parameter CPU_WIDTH = `CPU_INST_BITS,
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)
)
(
  input clk,
  input reset,

  input                       cpu_req_valid,
  output                      cpu_req_ready,
  input [WORD_ADDR_BITS-1:0]  cpu_req_addr,
  input [CPU_WIDTH-1:0]       cpu_req_data,
  input [3:0]                 cpu_req_write,

  output                      cpu_resp_valid,
  output [CPU_WIDTH-1:0]      cpu_resp_data,

  output                      mem_req_valid,
  input                       mem_req_ready,
  output [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,
  output                           mem_req_rw,
  output                           mem_req_data_valid,
  input                            mem_req_data_ready,
  output [`MEM_DATA_BITS-1:0]      mem_req_data_bits,
  // byte level masking
  output [(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,

  input                       mem_resp_valid,
  input [`MEM_DATA_BITS-1:0]  mem_resp_data
);

  // Implement your cache here, then delete this comment

  reg [2:0] s;
  //0: idle, 1: check valid, if hit instantly return, else also return if write, 2: missed read, wait for and eventually update cache with mem data, 3: wait for read mem trans, 4: wait for write mem trans; 
  wire [1:0] sa_num;
  wire [3:0] offset;
  wire [5:0] index;
  wire [15:0] tag;
  wire [31:0] din1, din2, din3, din4, din5, dout1, dout2, dout3, dout4, dout5, mem_data;
  wire we1, we2, we3, we4;
  reg we5, replace;
  reg [2:0] count;
  wire [3:0] wmask1, wmask2, wmask3, wmask4, wmask5;
  wire [5:0] addr5;
  wire [7:0] addr1, addr2, addr3, addr4;
  reg crr, crv, mrv, mrrw, mrdv;
  reg [CPU_WIDTH-1:0] crd;
  reg [WORD_ADDR_BITS-3: 0] mra;
  reg [`MEM_DATA_BITS-1:0] mrdb;
  reg [(`MEM_DATA_BITS/8)-1:0] mrdm;
  wire [127:0] mem1, mem2, mem3, mem4, mem_final;
  wire [15:0] valid_bits;

  assign offset = cpu_req_addr[3:0];
  assign index = cpu_req_addr[9:4];
  assign tag = cpu_req_addr[25:10];
  assign sa_num = offset - (offset/4) * 4;
  assign addr1 = index * 4 + offset/4;
  assign addr5 = index;
  assign din1 = (s == 3 || s == 5)? mem_final[31:0] : cpu_req_data;
  assign din2 = (s == 3 || s == 5)? mem_final[63:32] : cpu_req_data;
  assign din3 = (s == 3 || s == 5)? mem_final[95:64] : cpu_req_data;
  assign din4 = (s == 3 || s == 5)? mem_final[127:96] : cpu_req_data;
  assign valid_bits = (offset[3:2] == 0)? 15 : ((offset[3:2] == 1)? 240 : ((offset[3:2] == 2)? 3840 : ((offset[3:2] == 3)? 61440 : 0)));
  assign din5 = (replace == 0)? {(valid_bits) | dout5[31:16], tag} : {valid_bits, tag};
  assign we1 = (((s == 3 || s == 5) && count == 1) || (s == 4 && count == 2 && sa_num == 0))?  1: 0;
  assign we2 = (((s == 3 || s == 5) && count == 1) || (s == 4 && count == 2 && sa_num == 1))?  1: 0;
  assign we3 = (((s == 3 || s == 5) && count == 1) || (s == 4 && count == 2 && sa_num == 2))?  1: 0;
  assign we4 = (((s == 3 || s == 5) && count == 1) || (s == 4 && count == 2 && sa_num == 3))?  1: 0;
  assign wmask1 = (s == 3 || s == 5)? 15 : cpu_req_write;
  assign wmask2 = 15;
  assign cpu_req_ready = crr;
  assign cpu_resp_valid = crv;
  assign cpu_resp_data = crd;
  assign mem_req_valid = mrv;
  assign mem_req_addr = mra;
  assign mem_req_rw = mrrw;
  assign mem_req_data_valid = mrdv;
  assign mem_req_data_bits = mrdb;
  assign mem_req_data_mask = mrdm;
  assign mem1 = (count == 4)? mem_resp_data : mem1;
  assign mem2 = (count == 3)? mem_resp_data : mem2;
  assign mem3 = (count == 2)? mem_resp_data : mem3;
  assign mem4 = (count == 1)? mem_resp_data : mem4;
  assign mem_final = (mra[1:0] == 0)? mem1 : ((mra[1:0] == 1)? mem2 : ((mra[1:0] == 2)? mem3 : ((mra[1:0] == 3)? mem4 : 0)));
  assign mem_data = (sa_num == 0)? mem_final[31:0] : ((sa_num == 1)? mem_final[63:32] : ((sa_num == 2)? mem_final[95:64] : ((sa_num == 3)? mem_final[127:96] : 0)));

  sram22_256x32m4w8 sa (
  .clk(clk),
  .we(we1),
  .wmask(wmask1),
  .addr(addr1),
  .din(din1),
  .dout(dout1)
  );

  sram22_256x32m4w8 sb (
  .clk(clk),
  .we(we2),
  .wmask(wmask1),
  .addr(addr1),
  .din(din2),
  .dout(dout2)
  );

  sram22_256x32m4w8 sc (
  .clk(clk),
  .we(we3),
  .wmask(wmask1),
  .addr(addr1),
  .din(din3),
  .dout(dout3)
  );

  sram22_256x32m4w8 sd (
  .clk(clk),
  .we(we4),
  .wmask(wmask1),
  .addr(addr1),
  .din(din4),
  .dout(dout4)
  );

  sram22_64x32m4w8 meta (
  .clk(clk),
  .we(we5),
  .wmask(wmask2),
  .addr(addr5),
  .din(din5),
  .dout(dout5)
  );

  always @(posedge clk) begin
    if (reset) begin
      s <= 0; //idle
      crr <= 0;
      crv <= 0;
      crd <= 0;
      mrv <= 0;
      mra <= 0;
      mrrw <= 0;
      mrdv <= 0;
      mrdb <= 0;
      mrdm <= 0;
      we5 <= 0;
      replace <= 0;
    end else begin
    case (s)
    //idle
    0: begin
      crr <= 1;
      crv <= crv;
      crd <= crd;
      mrv <= 0;
      mra <= 0;
      mrrw <= 0;
      mrdv <= 0;
      mrdb <= 0;
      mrdm <= 0;
      we5 <= 0;
      replace <= 0;
      count <= 0;
      if (cpu_req_valid) begin
        crr <= 0;
        crd <= 0;
        crv <= 0;
        s <= 1;
      end 
    end

    1: begin
      if (dout5[16 + offset] == 1 && dout5[15:0] == tag) begin
        we5 <= 0;
        if (cpu_req_write == 0) begin
          case (sa_num)
            0: crd <= dout1;
            1: crd <= dout2;
            2: crd <= dout3;
            3: crd <= dout4;
          endcase 
          crv <= 1;
          crr <= 1;
          s <= 0;
        end else begin
          mrv <= 1;
          mra <= cpu_req_addr[WORD_ADDR_BITS-1:2]; 
          mrrw <= 1; 
          mrdv <= 1; 
          mrdb <= (cpu_req_addr[1:0] == 0)? cpu_req_data : ((cpu_req_addr[1:0] == 1)? cpu_req_data << 32 : ((cpu_req_addr[1:0] == 2)? cpu_req_data << 64 : ((cpu_req_addr[1:0] == 3)? cpu_req_data << 96 : 0))); 
          mrdm <= (cpu_req_addr[1:0] == 0)? cpu_req_write : ((cpu_req_addr[1:0] == 1)? cpu_req_write << 4 : ((cpu_req_addr[1:0] == 2)? cpu_req_write << 8 : ((cpu_req_addr[1:0] == 3)? cpu_req_write << 12 : 0)));
          s <= 6;
          count <= 4; 
        end
      end else begin 
        if (cpu_req_write == 0) begin
          if (mem_req_ready) begin
          s <= 2;
          mrrw <= 0; 
          mrdv <= 0;
          we5 <= 1;
          mrv <= 1;
          if (dout5[15:0] != tag) begin
            replace <= 1;
          end
          mra <= cpu_req_addr[WORD_ADDR_BITS-1:2];
          end
        end else begin
          if (mem_req_ready) begin
          s <= 2;
          mrrw <= 0; 
          mrdv <= 0;
          we5 <= 1;
          if (dout5[15:0] != tag) begin
            replace <= 1;
          end
          mrv <= 1;
          mra <= cpu_req_addr[WORD_ADDR_BITS-1:2];
          end
        end
      end
    end

    2: begin
      we5 <= 0;
      replace <= 0;
      if (mem_req_ready) begin
        if (cpu_req_write == 0) begin
          s <= 3;
        end else begin
          s <= 5;
        end
        count <= 4;
      end
    end

    6: begin
      we5 <= 0;
      replace <= 0;
      if (mem_req_data_ready) begin
        s <= 4;
        count <= 4;
      end
    end

    3: begin
      we5 <= 0;
      replace <= 0;
      count <= count - 1;
      mrv <= 0;
      if (count == 1) begin
        crr <= 1;
        crv <= 1;
        crd <= mem_data;
        s <= 0;
      end
    end

    4: begin
      count <= count - 1;
      we5 <= 0;
      replace <= 0;
      mrv <= 0;
      if (count == 1) begin
        crr <= 1;
        crv <= 1;
        crd <= (sa_num == 0)? dout1 : ((sa_num == 1)? dout2 : ((sa_num == 2)? dout3 : ((sa_num == 3)? dout4 : 0)));
        s <= 0;
      end
    end

    5: begin
      we5 <= 0;
      replace <= 0;
      mrv <= 0;
      if (count == 1) begin
        s <= 6;
        count <= 4;
        mrrw <= 1;
        mrdv <= 1;
        mrdb <= (cpu_req_addr[1:0] == 0)? cpu_req_data : ((cpu_req_addr[1:0] == 1)? cpu_req_data << 32 : ((cpu_req_addr[1:0] == 2)? cpu_req_data << 64 : ((cpu_req_addr[1:0] == 3)? cpu_req_data << 96 : 0))); 
        mrdm <= (cpu_req_addr[1:0] == 0)? cpu_req_write : ((cpu_req_addr[1:0] == 1)? cpu_req_write << 4 : ((cpu_req_addr[1:0] == 2)? cpu_req_write << 8 : ((cpu_req_addr[1:0] == 3)? cpu_req_write << 12 : 0)));
        mra <= cpu_req_addr[WORD_ADDR_BITS-1:2];
        mrv <= 1;
      end else begin
        count <= count - 1;
      end
    end
    endcase
  end
  end

endmodule
