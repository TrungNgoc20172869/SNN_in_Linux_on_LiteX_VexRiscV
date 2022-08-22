module Scheduler (
    input clk,
    input reset_n,
    input wen,
    input set,
    input clr,
    input [11:0] packet,
    output [255:0] axon_spikes,
    output reg error
);
    
    wire [3:0] read_address;
    // wire read_equal_write;
    // wire read_equal_write_and_not_set;
    
    // assign read_equal_write = read_address == (packet[3:0] + read_address + 1) ? 1'b1 : 1'b0;
    // assign read_equal_write_and_not_set = read_equal_write & ~set;
    // assign error = read_equal_write_and_not_set & wen;
    always @(*) begin
        error = (read_address == (packet[3:0] + read_address + 1) ? 1'b1 : 1'b0) & ~set & wen;
    end
    SchedulerSRAM SRAM (
        .packet(packet),
        .clr(clr),
        .read_address(read_address),
        .reset_n(reset_n),
        .wen(wen),
        .out(axon_spikes),
        .clk(clk)
    );
    
    Counter counter (
        .reset_n(reset_n),
        .wen(set),
        .clk(clk),
        .out(read_address)
    );
    
endmodule