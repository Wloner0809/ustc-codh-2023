module ID_EX(
    input [31:0] IF_ID_PC,
    input ALUAsrc,
    input [1:0] ALUBsrc,
    input [3:0] ALUop,
    input MemRead,
    input MemWrite,
    input MemtoReg,
    input [2:0] Branch,
    input RegWrite,
    input [31:0] RD1, RD2,
    input [4:0] RS1, RS2, RD,
    input [31:0] IMM,
    input [31:0] IF_ID_Inst,
    // input stall,
    input ID_EX_Flush,
    input clk,
    input rstn,
    input cache_stall,
    output reg [31:0] ID_EX_PC,
    output reg ID_EX_ALUAsrc,
    output reg [1:0] ID_EX_ALUBsrc,
    output reg [3:0] ID_EX_ALUop,
    output reg ID_EX_MemRead,
    output reg ID_EX_MemWrite,
    output reg ID_EX_MemtoReg,
    output reg [2:0] ID_EX_Branch,
    output reg ID_EX_RegWrite,
    output reg [31:0] ID_EX_RD1,
    output reg [31:0] ID_EX_RD2,
    output reg [4:0] ID_EX_RS1,
    output reg [4:0] ID_EX_RS2,
    output reg [4:0] ID_EX_RD,
    output reg [31:0] ID_EX_IMM,
    output reg [31:0] ID_EX_Inst
    );


    reg [31:0] ID_EX_PC_tmp;
    reg ID_EX_ALUAsrc_tmp;
    reg [1:0] ID_EX_ALUBsrc_tmp;
    reg [3:0] ID_EX_ALUop_tmp;
    reg ID_EX_MemRead_tmp;
    reg ID_EX_MemWrite_tmp;
    reg ID_EX_MemtoReg_tmp;
    reg [2:0] ID_EX_Branch_tmp;
    reg ID_EX_RegWrite_tmp;
    reg [31:0] ID_EX_RD1_tmp;
    reg [31:0] ID_EX_RD2_tmp;
    reg [4:0] ID_EX_RS1_tmp;
    reg [4:0] ID_EX_RS2_tmp;
    reg [4:0] ID_EX_RD_tmp;
    reg [31:0] ID_EX_IMM_tmp;
    reg [31:0] ID_EX_Inst_tmp;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ID_EX_PC <= 32'b0;
            ID_EX_ALUAsrc <= 1'b0;
            ID_EX_ALUBsrc <= 2'b0;
            ID_EX_ALUop <= 4'b0;
            ID_EX_MemRead <= 1'b0;
            ID_EX_MemWrite <= 1'b0;
            ID_EX_MemtoReg <= 1'b0;
            ID_EX_Branch <= 3'b0;
            ID_EX_RegWrite <= 1'b0;
            ID_EX_RD1 <= 32'b0;
            ID_EX_RD2 <= 32'b0;
            ID_EX_RS1 <= 5'b0;
            ID_EX_RS2 <= 5'b0;
            ID_EX_RD <= 5'b0;
            ID_EX_IMM <= 32'b0;
            ID_EX_Inst <= 32'b0;
        end
        else if(cache_stall) begin
            if(ID_EX_PC == 0) begin
                ID_EX_PC <= ID_EX_PC_tmp;
                ID_EX_ALUAsrc <= ID_EX_ALUAsrc_tmp;
                ID_EX_ALUBsrc <= ID_EX_ALUBsrc_tmp;
                ID_EX_ALUop <= ID_EX_ALUop_tmp;
                ID_EX_MemRead <= ID_EX_MemRead_tmp;
                ID_EX_MemWrite <= ID_EX_MemWrite_tmp;
                ID_EX_MemtoReg <= ID_EX_MemtoReg_tmp;
                ID_EX_Branch <= ID_EX_Branch_tmp;
                ID_EX_RegWrite <= ID_EX_RegWrite_tmp;
                ID_EX_RD1 <= ID_EX_RD1_tmp;
                ID_EX_RD2 <= ID_EX_RD2_tmp;
                ID_EX_RS1 <= ID_EX_RS1_tmp;
                ID_EX_RS2 <= ID_EX_RS2_tmp;
                ID_EX_RD <= ID_EX_RD_tmp;
                ID_EX_IMM <= ID_EX_IMM_tmp;
                ID_EX_Inst <= ID_EX_Inst_tmp;
            end
            else begin
                ID_EX_PC <= ID_EX_PC;
                ID_EX_ALUAsrc <= ID_EX_ALUAsrc;
                ID_EX_ALUBsrc <= ID_EX_ALUBsrc;
                ID_EX_ALUop <= ID_EX_ALUop;
                ID_EX_MemRead <= ID_EX_MemRead;
                ID_EX_MemWrite <= ID_EX_MemWrite;
                ID_EX_MemtoReg <= ID_EX_MemtoReg;
                ID_EX_Branch <= ID_EX_Branch;
                ID_EX_RegWrite <= ID_EX_RegWrite;
                ID_EX_RD1 <= ID_EX_RD1;
                ID_EX_RD2 <= ID_EX_RD2;
                ID_EX_RS1 <= ID_EX_RS1;
                ID_EX_RS2 <= ID_EX_RS2;
                ID_EX_RD <= ID_EX_RD;
                ID_EX_IMM <= ID_EX_IMM;
                ID_EX_Inst <= ID_EX_Inst;
            end
        end
        else if(ID_EX_Flush) begin
            ID_EX_PC <= 32'b0;
            ID_EX_ALUAsrc <= 1'b0;
            ID_EX_ALUBsrc <= 2'b0;
            ID_EX_ALUop <= 4'b0;
            ID_EX_MemRead <= 1'b0;
            ID_EX_MemWrite <= 1'b0;
            ID_EX_MemtoReg <= 1'b0;
            ID_EX_Branch <= 3'b0;
            ID_EX_RegWrite <= 1'b0;
            ID_EX_RD1 <= 32'b0;
            ID_EX_RD2 <= 32'b0;
            ID_EX_RS1 <= 5'b0;
            ID_EX_RS2 <= 5'b0;
            ID_EX_RD <= 5'b0;
            ID_EX_IMM <= 32'b0;
            ID_EX_Inst <= 32'b0;

            ID_EX_PC_tmp <= ID_EX_PC;
            ID_EX_ALUAsrc_tmp <= ID_EX_ALUAsrc;
            ID_EX_ALUBsrc_tmp <= ID_EX_ALUBsrc;
            ID_EX_ALUop_tmp <= ID_EX_ALUop;
            ID_EX_MemRead_tmp <= ID_EX_MemRead;
            ID_EX_MemWrite_tmp <= ID_EX_MemWrite;
            ID_EX_MemtoReg_tmp <= ID_EX_MemtoReg;
            ID_EX_Branch_tmp <= ID_EX_Branch;
            ID_EX_RegWrite_tmp <= ID_EX_RegWrite;
            ID_EX_RD1_tmp <= ID_EX_RD1;
            ID_EX_RD2_tmp <= ID_EX_RD2;
            ID_EX_RS1_tmp <= ID_EX_RS1;
            ID_EX_RS2_tmp <= ID_EX_RS2;
            ID_EX_RD_tmp <= ID_EX_RD;
            ID_EX_IMM_tmp <= ID_EX_IMM;
            ID_EX_Inst_tmp <= ID_EX_Inst;
        end
        else begin
            ID_EX_PC <= IF_ID_PC;
            ID_EX_ALUAsrc <= ALUAsrc;
            ID_EX_ALUBsrc <= ALUBsrc;
            ID_EX_ALUop <= ALUop;
            ID_EX_MemRead <= MemRead;
            ID_EX_MemWrite <= MemWrite;
            ID_EX_MemtoReg <= MemtoReg;
            ID_EX_Branch <= Branch;
            ID_EX_RegWrite <= RegWrite;
            ID_EX_RD1 <= RD1;
            ID_EX_RD2 <= RD2;
            ID_EX_RS1 <= RS1;
            ID_EX_RS2 <= RS2;
            ID_EX_RD <= RD;
            ID_EX_IMM <= IMM;
            ID_EX_Inst <= IF_ID_Inst;
        end
    end
endmodule
