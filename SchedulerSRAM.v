module SchedulerSRAM (
    input clk,
    input reset_n,
    input clr,
    input wen,
    input [3:0] read_address,
    input [11:0] packet,
    output [255:0] out
);

    reg [255:0] memory [0:15]; // Internal memroy of the Core SRAM 
    
    wire [3:0] write_address;
    
    integer i;

    assign write_address = packet[3:0] + read_address + 1;

    always@(posedge clk, negedge reset_n) begin
        if(~reset_n) begin
            for(i = 0; i < 16; i = i + 1)begin
                memory[i] <= 0;
            end
        end
        else begin
            if(clr) begin
                memory[read_address] <= 0;
            end
            if(wen) begin
                memory[write_address][packet[11:4]] <= 1'b1;
            end
        end
    end

    assign out = memory[read_address];
endmodule
