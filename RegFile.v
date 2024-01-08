module RegFile(
    input clk,
    input rst,
    input [4:0] addr1,
    input [4:0] addr2,
    input [4:0] addr3,
    input we,
    input [31:0] DataW,
    output [31:0] DataA,
    output [31:0] DataB
);

reg [31:0] regs [31:0];
assign DataA = regs[addr1];
assign DataB = regs[addr2];

always @(posedge clk) begin
    if (rst) begin
        regs[0] <= 0;
        regs[1] <= 0;
        regs[2] <= 0;
        regs[3] <= 0;
        regs[4] <= 0;
        regs[5] <= 0;
        regs[6] <= 0;
        regs[7] <= 0;
        regs[8] <= 0;
        regs[9] <= 0;
        regs[10] <= 0;
        regs[11] <= 0;
        regs[12] <= 0;
        regs[13] <= 0;
        regs[14] <= 0;
        regs[15] <= 0;
        regs[16] <= 0;
        regs[17] <= 0;
        regs[18] <= 0;
        regs[19] <= 0;
        regs[20] <= 0;
        regs[21] <= 0;
        regs[22] <= 0;
        regs[23] <= 0;
        regs[24] <= 0;
        regs[25] <= 0;
        regs[26] <= 0;
        regs[27] <= 0;
        regs[28] <= 0;
        regs[29] <= 0;
        regs[30] <= 0;
        regs[31] <= 0;
    end else begin
        assert (regs[0] == 0);
        if (we == 1) begin
            if (addr3 != 0) begin
                regs[addr3] <= DataW;
            end
        end
    end
end

endmodule