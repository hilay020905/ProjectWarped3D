module zbuffer (
    input clk,
    input [255:0] data,
    output reg signed [15:0] x,
    output reg signed [15:0] y,
    output reg signed [15:0] z,
    output reg [15:0] red,
    output reg [15:0] green,
    output reg [15:0] blue
);
    always @(posedge clk) begin
        x <= data[255:240];
        y <= data[239:224];
        z <= data[223:208];
        red <= data[63:48];
        green <= data[47:32];
        blue <= data[31:16];
    end
endmodule