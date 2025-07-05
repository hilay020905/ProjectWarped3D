module regs (
    input clk,
    input [255:0] in_data,
    input writing,
    output reg [255:0] out_data
);
    reg [31:0] data [0:7];
    integer i;

    always @(posedge clk) begin
        if (writing) begin
            for (i = 0; i < 8; i = i + 1)
                data[i] <= in_data[(32*(8-i-1)+31)-:32];
        end
        for (i = 0; i < 8; i = i + 1)
            out_data[(32*(8-i-1)+31)-:32] <= data[i];
    end
endmodule