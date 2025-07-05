module hvsync_generator (
    input clk,
    output reg hsync,
    output reg vsync,
    output reg [9:0] hpos,
    output reg [9:0] vpos
);
    initial begin
        hpos = 0;
        vpos = 0;
        hsync = 0;
        vsync = 0;
    end

    always @(posedge clk) begin
        if (hpos < 800) hpos <= hpos + 1;
        else begin
            hpos <= 0;
            if (vpos < 525) vpos <= vpos + 1;
            else vpos <= 0;
        end
        hsync <= (hpos >= 656 && hpos < 752);
        vsync <= (vpos >= 490 && vpos < 492);
    end
endmodule