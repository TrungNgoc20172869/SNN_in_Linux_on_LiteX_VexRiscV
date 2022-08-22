//////////////////////////////////////////////////////////////////////////////////
// Core.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Contains all the modules for a single RANC core.
//////////////////////////////////////////////////////////////////////////////////

module Core_3x2 #(
    parameter CORE_NUMBER     = 0
)(
    input clk,
    input tick,
    input reset_n,
    input ren_in_west,
    input ren_in_east,
    input ren_in_north,
    input ren_in_south,
    input empty_in_west,
    input empty_in_east,
    input empty_in_north,
    input empty_in_south,
    input [29:0] east_in,
    input [29:0] west_in,
    input [20:0] north_in,
    input [20:0] south_in,
    output ren_out_west,
    output ren_out_east,
    output ren_out_north,
    output ren_out_south,
    output empty_out_west,
    output empty_out_east,
    output empty_out_north,
    output empty_out_south,
    output [29:0] east_out,
    output [29:0] west_out,
    output [20:0] north_out,
    output [20:0] south_out,
    output grid_controller_error,
    output scheduler_error, 
    output [2:0] grid_state,
    output forward_north_local_buffer_empty               
);
    
    wire [255:0] axon_spikes;
    wire [29:0] spike_out_packet;
    wire [11:0] scheduler_packet;
    
Scheduler Scheduler (
    .clk(clk),
    .reset_n(reset_n),
    .wen(scheduler_wen),
    .set(scheduler_set),
    .packet(scheduler_packet),
    .axon_spikes(axon_spikes),
    .error(scheduler_error),
    .clr(scheduler_clr)
);

neuron_grid_3x2 #(
    .CORE_NUMBER(CORE_NUMBER)
)
neuron_grid(
    .local_buffers_full(local_buffers_full),
    .clk(clk),
    .reset_n(reset_n),
    .tick(tick),
    .axon_spikes(axon_spikes),
    .error(grid_controller_error),
    .scheduler_set(scheduler_set),
    .scheduler_clr(scheduler_clr),
    .done(done),
    .packet_out(spike_out_packet),
    .spike_out_valid(spike_out_valid),
    .grid_state(grid_state)
);


Router Router (
    .clk(clk),
    .reset_n(reset_n),
    .din_local(spike_out_packet),
    .din_local_wen(spike_out_valid),
    .din_west(west_in),
    .din_east(east_in),
    .din_north(north_in),
    .din_south(south_in),
    .ren_in_west(ren_in_west),
    .ren_in_east(ren_in_east),
    .ren_in_north(ren_in_north),
    .ren_in_south(ren_in_south),
    .empty_in_west(empty_in_west),
    .empty_in_east(empty_in_east),
    .empty_in_north(empty_in_north),
    .empty_in_south(empty_in_south),
    .dout_west(west_out),
    .dout_east(east_out),
    .dout_north(north_out),
    .dout_south(south_out),
    .dout_local(scheduler_packet),
    .dout_wen_local(scheduler_wen),
    .ren_out_west(ren_out_west),
    .ren_out_east(ren_out_east),
    .ren_out_north(ren_out_north),
    .ren_out_south(ren_out_south),
    .empty_out_west(empty_out_west),
    .empty_out_east(empty_out_east),
    .empty_out_north(empty_out_north),
    .empty_out_south(empty_out_south),
    .local_buffers_full(local_buffers_full),
    .forward_north_local_buffer_empty(forward_north_local_buffer_empty)
);

endmodule
