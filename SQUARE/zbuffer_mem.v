module zbuffer_mem (
    input clk,
    input [18:0] read0,
    output reg [15:0] out0,
    input [18:0] read1,
    output reg [15:0] out1,
    input writing,
    input [18:0] waddr,
    input [15:0] wdata
);
    reg [15:0] data [0:307199]; // 640x480 z-buffer

    integer i;
    initial begin
        for (i = 0; i < 307200; i = i + 1)
            data[i] = 16'hffff;
    end

    always @(posedge clk) begin
        out0 <= data[read0];
        out1 <= data[read1];
        if (writing)
            data[waddr] <= wdata;
    end
endmodule