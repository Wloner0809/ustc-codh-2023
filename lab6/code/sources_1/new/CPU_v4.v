`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/29 20:43:40
// Design Name: 
// Module Name: CPU_v4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_v4(
    input cpu_clk,
    input cpu_rstn,
    input [4:0] rra0,
    input [31:0] dra0,
    output [31:0] rrd0,
    output [31:0] drd0,
    output [31:0] ctr_debug,
    output [31:0] npc,
    output [31:0] pc,
    output [31:0] ir,
    output [31:0] pc_id,
    output [31:0] ir_id,
    output [31:0] pc_ex,
    output [31:0] ir_ex,
    output [31:0] rrd1,
    output [31:0] rrd2,
    output [31:0] imm,
    output [31:0] ir_mem,
    output [31:0] res,
    output [31:0] dwd,
    output [31:0] ir_wb,
    output [31:0] res_wb,
    output [31:0] drd,
    output [31:0] rwd,
    //下面的与IO相关
    output [7:0] io_addr,
    output [31:0] io_dout,
    output io_we,
    output io_rd,
    input [31:0] io_din
    );

    //变量声明
    reg [31:0] PC;
    reg [31:0] NPC;
    //PC计算操作数之一
    reg [31:0] NPC_src;
    reg [1:0] cnt;
    //暂停一周期的信号
    wire stall;
    //PC运算的选择信号
    wire PCAsrc;
    wire PCBsrc;
    //Forward模块
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;
    //jal、jalr的处理
    reg [31:0] pre_inst;
    reg [31:0] pre_mem_reg_wd;
    reg [4:0] pre_mem_wb_rd;


    //IF阶段
    wire [31:0] IF_ID_PC;
    wire [31:0] IF_ID_Inst;
    wire [31:0] Inst;
    wire IF_ID_Flush;
    //ID阶段
    wire [31:0] ID_EX_Inst;
    wire [31:0] ID_EX_PC;
    wire ID_EX_Flush;
    wire ID_EX_ALUAsrc;
    wire [1:0] ID_EX_ALUBsrc;
    wire [3:0] ID_EX_ALUop;
    wire ID_EX_MemRead;
    wire ID_EX_MemWrite;
    wire ID_EX_MemtoReg;
    wire [2:0] ID_EX_Branch;
    wire ID_EX_RegWrite;
    wire [31:0] ID_EX_RD1;
    wire [31:0] ID_EX_RD2;
    wire [4:0] ID_EX_RS1;
    wire [4:0] ID_EX_RS2;
    wire [4:0] ID_EX_RD;
    wire [31:0] ID_EX_IMM; 
        //用于Control模块
    wire ALUAsrc;
    wire [1:0] ALUBsrc;
    wire [3:0] ALUop;
    wire MemRead;
    wire MemWrite;
    wire MemtoReg;
    wire [2:0] Branch;
    wire RegWrite;
        //用于RF模块
    wire [31:0] rd1;
    wire [31:0] rd2;
        //用于Imm_Gen模块
    wire [31:0] IMM;
    //EX阶段
    wire [31:0] EX_MEM_Inst;
    wire [31:0] EX_MEM_ALUout;
    wire [31:0] EX_MEM_RD2;
    wire EX_MEM_MemtoReg;
    wire EX_MEM_MemRead;
    wire EX_MEM_MemWrite;
    wire EX_MEM_RegWrite;
    wire [4:0] EX_MEM_RD;
    wire [31:0] RD1_true;
    wire [31:0] RD2_true;
        //用于ALU模块
    wire [31:0] ALUA;
    wire [31:0] ALUB;
    wire Zero;
    wire Less;
    wire [31:0] ALUout;
    //MEM阶段
    wire [31:0] MEM_WB_Inst;
    wire [31:0] MEMout;
    wire MEM_WB_MemtoReg;
    wire MEM_WB_RegWrite;
    wire [31:0] MEM_WB_ALUout;
    wire [31:0] MEM_WB_MEMout;
    wire [4:0] MEM_WB_RD;
    //WB阶段
    wire [31:0] MEM_WB_WD;


    wire cache_miss;
    
    //PC
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn)
            PC <= 32'h0;
        else if(stall | cache_miss)
            PC <= PC;
        else    
            PC <= NPC;
    end
    always @(*) begin
        case ({PCAsrc, PCBsrc})
            2'b00: begin
                NPC = (PC == 32'h0 | PC == 32'h4) ? (PC + 32'h4) : (NPC_src + 32'h4);
            end
            2'b10: begin
                //jal
                NPC = ID_EX_IMM + ID_EX_PC;
            end
            2'b11: begin
                //jalr
                NPC = (ID_EX_IMM + (((pre_inst[6:0] == 7'b1101111 | pre_inst[6:0] == 7'b1100111) & (ID_EX_RS1 == pre_mem_wb_rd)) ? pre_mem_reg_wd : (((ForwardA == 2'b10) ? EX_MEM_ALUout : ((ForwardA == 2'b01) ? MEM_WB_WD : ID_EX_RD1))))) & ~1;
            end
            default: begin
                NPC = 32'h00000000;
            end
        endcase
    end
    
    //判断stall结束与否
    reg pre_stall;
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn)
            pre_stall <= 0;
        else 
            pre_stall <= stall;
    end
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn) begin
            NPC_src <= 32'b0;
            cnt <= 0;
        end
        else if(ID_EX_Flush & IF_ID_Flush) begin
            NPC_src <= NPC;
            cnt <= 1;
        end
        else if(cnt == 1) begin
            NPC_src <= NPC_src + 32'h4;
            cnt <= 2;
        end
        else if(cnt == 2) begin
            NPC_src <= NPC_src + 32'h4;
            cnt <= 0;
        end
        else begin
            if(cache_miss) begin
                //cache_miss时NPC也要保持不变
                NPC_src <= NPC_src;
            end
            else if(stall) begin
                NPC_src <= NPC_src;
                cnt <= cnt;
            end
            else if(pre_stall) begin
                NPC_src <= NPC_src + 4;
                cnt <= cnt;
            end
            else begin
                NPC_src <= NPC;
                // NPC_src <= ID_EX_PC + 32'hc;
                cnt <= 0;
            end
        end
    end

    //指令存储器
    //test variable
    wire [31:0] test1;
    Instruction_memory IR(
        .a(10'b0),              // input wire [9 : 0] a
        .d(32'b0),              // input wire [31 : 0] d
        .dpra(PC[9:0] >> 2),    // input wire [9 : 0] dpra
        .clk(cpu_clk),              // input wire clk
        .we(1'b0),              // input wire we
        .spo(test1),             // output wire [31 : 0] spo
        .dpo(Inst)              // output wire [31 : 0] dpo
    );

    //IF/ID寄存器
    IF_ID IF_ID_dut(
        .PC(PC),
        .Inst(Inst),
        .stall(stall),
        .IF_ID_Flush(IF_ID_Flush),
        .clk(cpu_clk),
        .rstn(cpu_rstn),
        .IF_ID_PC(IF_ID_PC),
        .IF_ID_Inst(IF_ID_Inst),
        .cache_stall(cache_miss)
    );

    //Control模块产生控制信号
    Control Control_dut(
        .Instruction(IF_ID_Inst),
        .ALUAsrc(ALUAsrc),
        .ALUBsrc(ALUBsrc),
        .ALUop(ALUop),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .Branch(Branch),
        .RegWrite(RegWrite)
    );

    //寄存器堆
    //test variable
    wire [31:0] test2;
    Register_File Register_File_dut(
        .clk(cpu_clk),
        .ra1(IF_ID_Inst[19:15]),
        .ra2(IF_ID_Inst[24:20]),
        .rd1(rd1),
        .rd2(rd2),
        .wa(MEM_WB_RD),
        .wd(MEM_WB_WD),
        .we(MEM_WB_RegWrite),
        .ra3(rra0),
        .rd3(rrd0)
    );

    Imm_Gen Imm_Gen_dut(
        .Instruction(IF_ID_Inst),
        .imm(IMM)
    );

    //处理写入寄存器堆差一个时钟的问题
    wire [31:0] RD1_TRUE, RD2_TRUE;
    assign RD1_TRUE = (MEM_WB_RegWrite && IF_ID_Inst[19:15] == MEM_WB_RD) ? MEM_WB_WD : rd1;
    assign RD2_TRUE = (MEM_WB_RegWrite && IF_ID_Inst[24:20] == MEM_WB_RD) ? MEM_WB_WD : rd2; 
    //ID/EX寄存器
    ID_EX ID_EX_dut(
        .IF_ID_PC(IF_ID_PC),
        .ALUAsrc(ALUAsrc),
        .ALUBsrc(ALUBsrc),
        .ALUop(ALUop),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .Branch(Branch),
        .RegWrite(RegWrite),
        .RD1(RD1_TRUE),
        .RD2(RD2_TRUE),
        .RS1(IF_ID_Inst[19:15]),
        .RS2(IF_ID_Inst[24:20]),
        .RD(IF_ID_Inst[11:7]),
        .IMM(IMM),
        // .stall(stall),
        .ID_EX_Flush(ID_EX_Flush),
        .clk(cpu_clk),
        .rstn(cpu_rstn),
        .ID_EX_PC(ID_EX_PC),
        .ID_EX_ALUAsrc(ID_EX_ALUAsrc),
        .ID_EX_ALUBsrc(ID_EX_ALUBsrc),
        .ID_EX_ALUop(ID_EX_ALUop),
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_MemWrite(ID_EX_MemWrite),
        .ID_EX_MemtoReg(ID_EX_MemtoReg),
        .ID_EX_Branch(ID_EX_Branch),
        .ID_EX_RegWrite(ID_EX_RegWrite),
        .ID_EX_RD1(ID_EX_RD1),
        .ID_EX_RD2(ID_EX_RD2),
        .ID_EX_RS1(ID_EX_RS1),
        .ID_EX_RS2(ID_EX_RS2),
        .ID_EX_RD(ID_EX_RD),
        .ID_EX_IMM(ID_EX_IMM),
        .IF_ID_Inst(IF_ID_Inst),
        .ID_EX_Inst(ID_EX_Inst),
        .cache_stall(cache_miss)
    );

    //Forward模块
    Forward Forward_dut(
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ID_EX_RS1(ID_EX_RS1),
        .ID_EX_RS2(ID_EX_RS2),
        .EX_MEM_RD(EX_MEM_RD),
        .MEM_WB_RD(MEM_WB_RD),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );

    //Hazard Unit
    Hazard_Unit Hazard_Unit_dut(
        .rs1(IF_ID_Inst[19:15]),
        .rs2(IF_ID_Inst[24:20]),
        .PCAsrc(PCAsrc),
        .PCBsrc(PCBsrc),
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_RD(ID_EX_RD),
        .ID_EX_Branch(ID_EX_Branch),
        .stall(stall),
        .IF_ID_Flush(IF_ID_Flush),
        .ID_EX_Flush(ID_EX_Flush)
    );


    //处理jal、jalr的相关
    //这里jal、jalr指令一定会产生Flush，暂停两个周期
    //所以在执行下一条指令时，jal、jalr刚好执行完毕
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn) begin
            pre_inst <= 32'b0;
            pre_mem_reg_wd <= 32'b0;
            pre_mem_wb_rd <= 5'b0;
        end
        else begin
            pre_inst <= MEM_WB_Inst;
            pre_mem_reg_wd <= MEM_WB_WD;
            pre_mem_wb_rd <= MEM_WB_RD;
        end
    end

    //选择操作数
    //其中的对应关系参照课本实现
    assign RD1_true = ((pre_inst[6:0] == 7'b1101111 | pre_inst[6:0] == 7'b1100111) & (ID_EX_RS1 == pre_mem_wb_rd)) ? pre_mem_reg_wd : ((ForwardA == 2'b00) ? ID_EX_RD1 : ((ForwardA == 2'b01) ? MEM_WB_WD : EX_MEM_ALUout));
    assign RD2_true = ((pre_inst[6:0] == 7'b1101111 | pre_inst[6:0] == 7'b1100111) & (ID_EX_RS2 == pre_mem_wb_rd)) ? pre_mem_reg_wd : ((ForwardB == 2'b00) ? ID_EX_RD2 : ((ForwardB == 2'b01) ? MEM_WB_WD : EX_MEM_ALUout));
    assign ALUA = ID_EX_ALUAsrc ? RD1_true : ID_EX_PC;
    assign ALUB = (ID_EX_ALUBsrc == 2'b00) ? RD2_true : ((ID_EX_ALUBsrc == 2'b01) ? 32'h00000004 : ID_EX_IMM);

    //ALU
    ALU ALU_dut(
        .a(ALUA),
        .b(ALUB),
        .f(ID_EX_ALUop),
        .y(ALUout),
        .Zero(Zero),
        .Less(Less)
    );

    //Branch
    Branch Branch_dut(
        .Zero(Zero),
        .Less(Less),
        .Branch(ID_EX_Branch),
        .PCAsrc(PCAsrc),
        .PCBsrc(PCBsrc)
    );

    // 写入数据存储器的数据
    wire [31:0] RD_DM_TRUE;
    assign RD_DM_TRUE = ((pre_inst[6:0] == 7'b1101111 | pre_inst[6:0] == 7'b1100111) & (ID_EX_RS2 == pre_mem_wb_rd)) ? pre_mem_reg_wd : (ForwardB == 2'b01) ? MEM_WB_WD : ((ForwardB == 2'b10) ? EX_MEM_ALUout : ID_EX_RD2);
    //EX/MEM寄存器
    EX_MEM EX_MEM_dut(
        .ID_EX_MemtoReg(ID_EX_MemtoReg),
        .ID_EX_RegWrite(ID_EX_RegWrite),
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_MemWrite(ID_EX_MemWrite),
        .ALUout(ALUout),
        .ID_EX_RD2(RD_DM_TRUE),
        .ID_EX_RD(ID_EX_RD),
        .clk(cpu_clk),
        .rstn(cpu_rstn),
        .EX_MEM_MemtoReg(EX_MEM_MemtoReg),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_MemRead(EX_MEM_MemRead),
        .EX_MEM_MemWrite(EX_MEM_MemWrite),
        .EX_MEM_ALUout(EX_MEM_ALUout),
        .EX_MEM_RD2(EX_MEM_RD2),
        .EX_MEM_RD(EX_MEM_RD),
        .ID_EX_Inst(ID_EX_Inst),
        .EX_MEM_Inst(EX_MEM_Inst),
        .cache_stall(cache_miss)
    );

    // //不加IO版
    // DCache DCache_dut(
    //     .clk(cpu_clk),
    //     .rstn(cpu_rstn),
    //     .addr(EX_MEM_ALUout[11 : 0]),
    //     .din(EX_MEM_RD2),
    //     .we_write(EX_MEM_MemWrite),
    //     .we_read(EX_MEM_MemRead),
    //     .dout(MEMout),
    //     .cache_miss(cache_miss),
    //     .sdu_addr(dra0[11 : 0]),
    //     .sdu_data(drd0)
    // );

    wire [31:0] cache_hit_cnt;
    wire [31:0] cache_miss_cnt;
    //在这个改变例化对象，即可实现对直接映射和组相联映射的测试
    Dcache_wrapper Dcache_wrapper_dut(
        .clk(cpu_clk),
        .rstn(cpu_rstn),
        .addr(EX_MEM_ALUout),
        .din(EX_MEM_RD2),
        .we_write(EX_MEM_MemWrite),
        .we_read(EX_MEM_MemRead),
        .sdu_addr(dra0[11:0]),
        .dout(MEMout),
        .cache_miss(cache_miss),
        .sdu_data(drd0),
        .io_addr(io_addr),
        .io_dout(io_dout),
        .io_we(io_we),
        .io_rd(io_rd),
        .io_din(io_din),
        .cache_hit_cnt(cache_hit_cnt),
        .cache_miss_cnt(cache_miss_cnt)
    );

    //MEM/WB寄存器
    MEM_WB MEM_WB_dut(
        .EX_MEM_MemtoReg(EX_MEM_MemtoReg),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_ALUout(EX_MEM_ALUout),
        .MEMout(MEMout),
        .EX_MEM_RD(EX_MEM_RD),
        .clk(cpu_clk),
        .rstn(cpu_rstn),
        .MEM_WB_MemtoReg(MEM_WB_MemtoReg),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_ALUout(MEM_WB_ALUout),
        .MEM_WB_MEMout(MEM_WB_MEMout),
        .MEM_WB_RD(MEM_WB_RD),
        .EX_MEM_Inst(EX_MEM_Inst),
        .MEM_WB_Inst(MEM_WB_Inst),
        .cache_stall(cache_miss)
    );

    //将EX_MEM段的寄存器写回
    assign MEM_WB_WD = ((MEM_WB_RD == EX_MEM_RD) && EX_MEM_RegWrite) ? (EX_MEM_MemtoReg ? EX_MEM_ALUout : MEMout) : (MEM_WB_MemtoReg ? MEM_WB_ALUout : MEM_WB_MEMout);


    //下面是CPU输出
    //EX阶段的控制信号
    assign ctr_debug = {18'b0, ID_EX_ALUAsrc, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg, ID_EX_RegWrite, ID_EX_ALUBsrc, ID_EX_ALUop, ID_EX_Branch};
    assign npc = NPC;
    assign pc = PC;
    assign ir = Inst;
    assign pc_id = IF_ID_PC;
    assign ir_id = IF_ID_Inst;
    assign pc_ex = ID_EX_PC;
    assign ir_ex = ID_EX_Inst;
    assign imm = IMM;
    assign ir_mem = EX_MEM_Inst;
    assign res = ALUout;
    assign dwd = RD_DM_TRUE;
    assign ir_wb = MEM_WB_Inst;
    assign res_wb = MEM_WB_ALUout;
    assign drd = MEM_WB_MEMout;
    assign rwd = MEM_WB_WD;
    assign rrd1 = cache_hit_cnt;
    assign rrd2 = cache_miss_cnt + cache_hit_cnt;

endmodule
