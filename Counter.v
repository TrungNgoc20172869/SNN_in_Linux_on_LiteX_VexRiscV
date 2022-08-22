module Counter(
    input reset_n,
    input wen,
    input clk,
    output reg [3:0] out
);
    always@(negedge clk, negedge reset_n) begin
        if(~reset_n) out <= 4'b1111;
        else if(wen) begin
            out <= out + 1;
        end
    end
   
endmodule
