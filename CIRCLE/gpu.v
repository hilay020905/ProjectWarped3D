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

    // Circle: center (320,240), radius 50
    reg [9:0] writeX = 0;
    reg [9:0] writeY = 0;
    reg write_state = 0;
    wire [9:0] offsetX = writeX + 10'd270; // x=270 to 369
    wire [9:0] offsetY = writeY + 10'd190; // y=190 to 289
    /* verilator lint_off WIDTHEXPAND */
    wire signed [15:0] center_x = 16'sd320;
    wire signed [15:0] center_y = 16'sd240;
    wire signed [15:0] radius = 16'sd50;
    wire signed [15:0] px = {{6{offsetX[9]}}, offsetX}; // Sign-extend to 16 bits
    wire signed [15:0] py = {{6{offsetY[9]}}, offsetY};
    // Circle equation: (x - center_x)^2 + (y - center_y)^2 <= radius^2
    wire signed [31:0] dx = $signed(px - center_x);
    wire signed [31:0] dy = $signed(py - center_y);
    wire signed [31:0] dx_sq = dx * dx;
    wire signed [31:0] dy_sq = dy * dy;
    wire signed [31:0] radius_sq = radius * radius;
    wire inside_circle = (dx_sq + dy_sq) <= radius_sq;
    /* verilator lint_on WIDTHEXPAND */
    assign framebuffer_mem_writing = (write_state && writeX < 100 && writeY < 100 && inside_circle);
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
                    $display("Test (320,240): inside=%b, dx_sq=%d, dy_sq=%d, radius_sq=%d", 
                             inside_circle, dx_sq, dy_sq, radius_sq);
                end
                if (framebuffer_mem_writing) begin
                    $display("FB write: addr=%d, x=%d, y=%d, data=%h, inside=%b, dx_sq=%d, dy_sq=%d, radius_sq=%d", 
                             framebuffer_mem_waddr, offsetX, offsetY, framebuffer_mem_wdata, inside_circle, dx_sq, dy_sq, radius_sq);
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