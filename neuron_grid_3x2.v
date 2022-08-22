module neuron_grid_3x2 #(
    parameter CORE_NUMBER = 0
)(
    input local_buffers_full,
    input clk,
    input reset_n,
    input tick,
    input [255:0] axon_spikes,
    output error,
    output scheduler_set,
    output scheduler_clr,
    // output spike_out,
    output [29:0] packet_out,
    output done,
    output spike_out_valid,
    output [2:0] grid_state
);


neuron_grid_controller controller(
    .tick(tick),
    .done_axon(done_axon),
    .clk(clk),
    .reset_n(reset_n),
    .process_spike(process_spike),
    .scheduler_clr(scheduler_clr),
    .scheduler_set(scheduler_set),
    .initial_axon_num(initial_axon_num),
    .inc_axon_num(inc_axon_num),
    .new_neuron(new_neuron),
    .update_potential(update_potential),
    .done(done),
    .error(error),

    .inc_neuron_num(inc_neuron_num), .init_neuron_num(init_neuron_num), .shot(shot),
    .local_buffers_full(local_buffers_full), .nb_finish_spike(nb_finish_spike),
    .grid_state(grid_state)
);

neuron_grid_datapath_3x2 #(
    .CORE_NUMBER(CORE_NUMBER)
) datapath(
    .axon_spikes(axon_spikes),
    .update_potential(update_potential),
    .clk(clk),
    .reset_n(reset_n),
    .initial_axon_num(initial_axon_num),
    .inc_axon_num(inc_axon_num),
    .new_neuron(new_neuron),
    .process_spike(process_spike),
    // .spike_out(spike_out),
    .packet_out(packet_out),
    .done_axon(done_axon),

    .inc_neuron_num(inc_neuron_num), .init_neuron_num(init_neuron_num), .shot(shot),
    .local_buffers_full(local_buffers_full), .nb_finish_spike(nb_finish_spike),
    .spike_out_valid(spike_out_valid)
);

endmodule

