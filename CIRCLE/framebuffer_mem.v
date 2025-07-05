module framebuffer_mem (
    input clk,
    input [18:0] read0,
    output reg [23:0] out0,
    input writing,
    input [18:0] waddr,
    input [23:0] wdata
);
    reg [23:0] mem [0:307199]; // 640 * 480
    initial begin
        integer i;
        for (i = 0; i < 307200; i = i + 1)
            mem[i] = 24'h000000; // Initialize to black
    end
    always @(posedge clk) begin
        out0 <= mem[read0]; // Read
        if (writing) begin
            mem[waddr] <= wdata; // Write
            $display("FB mem write: addr=%d, data=%h", waddr, wdata);
        end
    end
endmodule