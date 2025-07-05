module queue (
    input clk,
    input [255:0] in_data,
    input enqueue,
    output reg [255:0] out_data,
    output reg empty,
    input dequeue,
    output reg full
);
    reg [255:0] data [0:15];
    reg [3:0] front, rear;
    initial begin
        front = 0;
        rear = 0;
        empty = 1;
        full = 0;
    end

    always @(posedge clk) begin
        if (enqueue && !full) begin
            data[rear] <= in_data;
            rear <= rear + 1;
            empty <= 0;
            if (rear + 1 == front) full <= 1;
        end
        if (dequeue && !empty) begin
            out_data <= data[front];
            front <= front + 1;
            full <= 0;
            if (front + 1 == rear) empty <= 1;
        end
    end
endmodule