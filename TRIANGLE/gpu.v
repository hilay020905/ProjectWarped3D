module gpu (
    input clk,
    input [15:0] t_pc,
    input [15:0] l_pc,
    input [15:0] p_pc,
    output [255:0] r_ret_regs,
    output reg [23:0] pixel,
    output reg [9:0] counterX,
    output reg [9:0] counterY,
    output reg terminated,
    output reg write_done
);
    reg [19:0] term_counter = 20'd10000;
    
    // Terminate after write phase
    always @(posedge clk) begin
        if (write_done && term_counter > 0) begin
            term_counter <= term_counter - 1;
        end
    end
    assign terminated = write_done && term_counter == 0;

    // Framebuffer memory
    wire [18:0] framebuffer_mem_read, framebuffer_mem_waddr;
    wire [23:0] framebuffer_mem_out, framebuffer_mem_wdata;
    wire framebuffer_mem_writing;
    framebuffer_mem framebuffer_mem (
        .clk(clk),
        .read0(framebuffer_mem_read),
        .out0(framebuffer_mem_out),
        .writing(framebuffer_mem_writing),
        .waddr(framebuffer_mem_waddr),
        .wdata(framebuffer_mem_wdata)
    );

    // Triangle vertices (counterclockwise): (270,190), (370,190), (320,290)
    reg [9:0] writeX = 0;
    reg [9:0] writeY = 0;
    reg write_state = 0;
    wire [9:0] offsetX = writeX + 10'd270; // x=270 to 369
    wire [9:0] offsetY = writeY + 10'd190; // y=190 to 289
    /* verilator lint_off WIDTHEXPAND */
    wire signed [15:0] v0_x = 16'sd270; // Bottom-left
    wire signed [15:0] v0_y = 16'sd190;
    wire signed [15:0] v1_x = 16'sd370; // Bottom-right
    wire signed [15:0] v1_y = 16'sd190;
    wire signed [15:0] v2_x = 16'sd320; // Top
    wire signed [15:0] v2_y = 16'sd290;
    wire signed [15:0] px = {{6{offsetX[9]}}, offsetX}; // Sign-extend to 16 bits
    wire signed [15:0] py = {{6{offsetY[9]}}, offsetY};
    // Edge equations: -(x - x0)(y1 - y0) + (y - y0)(x1 - x0) for positive inside
    wire signed [31:0] edge1 = -($signed(px - v0_x) * $signed(v1_y - v0_y)) + ($signed(py - v0_y) * $signed(v1_x - v0_x));
    wire signed [31:0] edge2 = -($signed(px - v1_x) * $signed(v2_y - v1_y)) + ($signed(py - v1_y) * $signed(v2_x - v1_x));
    wire signed [31:0] edge3 = -($signed(px - v2_x) * $signed(v0_y - v2_y)) + ($signed(py - v2_y) * $signed(v0_x - v2_x));
    wire inside_triangle = (edge1 >= 0) && (edge2 >= 0) && (edge3 >= 0);
    /* verilator lint_on WIDTHEXPAND */
    assign framebuffer_mem_writing = (write_state && writeX < 100 && writeY < 100 && inside_triangle);
    assign framebuffer_mem_waddr = (offsetY * 19'd640) + {{9{1'b0}}, offsetX};
    assign framebuffer_mem_wdata = 24'hff0000; // Red
    assign framebuffer_mem_read = (counterY * 19'd640) + {{9{1'b0}}, counterX};

    // Write logic
    always @(posedge clk) begin
        if (!write_done) begin
            if (write_state) begin
                if (writeX < 99) begin
                    writeX <= writeX + 1;
                end else begin
                    writeX <= 0;
                    if (writeY < 99) begin
                        writeY <= writeY + 1;
                    end else begin
                        writeY <= 0;
                        write_state <= 0;
                        write_done <= 1;
                    end
                end
`ifdef VERILATOR
                if (offsetX == 320 && offsetY == 240) begin
                    $display("Test (320,240): inside=%b, edge1=%d, edge2=%d, edge3=%d", 
                             inside_triangle, edge1, edge2, edge3);
                end
                if (framebuffer_mem_writing) begin
                    $display("FB write: addr=%d, x=%d, y=%d, data=%h, inside=%b, edge1=%d, edge2=%d, edge3=%d", 
                             framebuffer_mem_waddr, offsetX, offsetY, framebuffer_mem_wdata, inside_triangle, edge1, edge2, edge3);
                end
`endif
            end else begin
                write_state <= 1;
            end
        end
        pixel <= framebuffer_mem_out;
    end

    // Display logic
    initial begin
        counterX = 0;
        counterY = 0;
        write_done = 0;
    end
    always @(posedge clk) begin
        if (write_done) begin
            if (counterX == 639) begin
                counterX <= 0;
                if (counterY == 479)
                    counterY <= 0;
                else
                    counterY <= counterY + 1;
            end else begin
                counterX <= counterX + 1;
            end
`ifdef VERILATOR
            if (counterX == 320 && counterY == 240) begin
                $display("Test read (320,240): addr=%d, out=%h", framebuffer_mem_read, framebuffer_mem_out);
            end
            if (counterX >= 270 && counterX < 370 && counterY >= 190 && counterY < 290) begin
                $display("FB read: addr=%d, x=%d, y=%d, out=%h", framebuffer_mem_read, counterX, counterY, framebuffer_mem_out);
            end
`endif
        end
    end

    // Unused signals
    assign r_ret_regs = 0;
endmodule