module processor (
    input clk,
    output reg [15:0] curr_pc,
    input [31:0] instr,
    output [3:0] readreg0,
    input [31:0] in_reg0,
    output [3:0] readreg1,
    input [31:0] in_reg1,
    output reg_wen,
    output [3:0] reg_waddr,
    output [31:0] reg_wval,
    output [1:0] pred,
    input pred_val,
    output pred_wen,
    output [1:0] pred_waddr,
    output pred_wval,
    output [15:0] readmem0,
    input [31:0] in_mem0,
    output mem_wen,
    output [15:0] mem_waddr,
    output [31:0] mem_wval,
    output queue_wen,
    output [3:0] queue_number,
    output reg request_new_pc,
    input set_pc,
    input [15:0] new_pc
);
    reg [15:0] pc;
    initial begin
        pc = 0;
        request_new_pc = 1;
    end

    assign curr_pc = set_pc ? new_pc : pc;
    assign readreg0 = instr[23:20];
    assign readreg1 = instr[19:16];
    assign reg_waddr = instr[15:12];
    assign reg_wen = (instr[28:24] == 5'd12); // LI instruction
    assign reg_wval = {{16{1'b0}}, instr[15:0]};
    assign pred = instr[31:30];
    assign pred_wen = 0;
    assign pred_waddr = 0;
    assign pred_wval = 0;
    assign readmem0 = pc; // Read vertex memory
    assign mem_wen = 0;
    assign mem_waddr = 0;
    assign mem_wval = 0;
    assign queue_wen = (instr[28:24] == 5'd15); // STOREQI to zbuffer_queue
    assign queue_number = 4; // zbuffer_queue

    always @(posedge clk) begin
        if (set_pc && request_new_pc) begin
            pc <= new_pc;
            request_new_pc <= 0;
        end else if (instr[28:24] == 5'd16) begin // END
            request_new_pc <= 1;
        end else if (pc < 8) begin
            pc <= pc + 1;
        end
    end
endmodule