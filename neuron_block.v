// `timescale 1ns / 1ps
module neuron_block(
    input clk,
    input reset_n,
    input signed [8:0] leak,
    input [35:0] weights,
    input signed [8:0] positive_threshold,
    input signed [8:0] negative_threshold,
    input signed [8:0] reset_potential,
    input signed [8:0] current_potential,
    input [1:0] neuron_instruction,
    input reset_mode,
    input new_neuron,
    input process_spike,
    input reg_en,
    output signed [8:0] potential_out,
    output spike_out
);

wire signed [8:0] weight;
reg signed [8:0] integrated_potential;
wire signed [8:0] leaked_potential;

assign weight = process_spike ? weights[9*(4-neuron_instruction)-1 -: 9] : 9'd0;
// always @(process_spike, weights, neuron_instruction) begin
//     if(process_spike) begin
//         case(neuron_instruction)
//         2'b00: weight = weights[35:27];
//         2'b01: weight = weights[26:18];
//         2'b10: weight = weights[17:9];
//         2'b11: weight = weights[8:0];
//         default: weight = 0;
//         endcase
//     end
//     else weight = 0;
// end

always @(posedge clk, negedge reset_n) begin
    if(~reset_n) integrated_potential <= 0;
    else begin
        if(new_neuron) integrated_potential <= current_potential;
        else if(reg_en) integrated_potential <= integrated_potential + weight;
    end
end
//gán giá trị mức reset âm và dương dựa vào reset_mode
reg signed [8:0] positive_reset_value;
reg signed [8:0] negative_reset_value;
always@(reset_mode, reset_potential, leaked_potential, positive_threshold, negative_threshold) begin
    case(reset_mode)
        // Hard reset
        0: begin
            positive_reset_value = reset_potential;
            negative_reset_value = -reset_potential;
        end
        // Linear reset
        1: begin
            positive_reset_value = leaked_potential - positive_threshold;
            negative_reset_value = leaked_potential + negative_threshold;
        end
        default: begin
            positive_reset_value = 0;
            negative_reset_value = 0;
        end
    endcase
end

//mô tả lại mạch trong kiến trúc
assign leaked_potential = integrated_potential + leak;
assign spike_out = (leaked_potential >= positive_threshold);
assign potential_out = spike_out ? positive_reset_value : (leaked_potential < negative_threshold) ? negative_reset_value : leaked_potential;

endmodule
