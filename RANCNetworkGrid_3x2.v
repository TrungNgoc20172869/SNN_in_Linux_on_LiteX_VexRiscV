module RANCNetworkGrid_3x2 #(
    parameter GRID_DIMENSION_X = 3,
    parameter GRID_DIMENSION_Y = 2,
    parameter OUTPUT_CORE_X_COORDINATE = 2,
    parameter OUTPUT_CORE_Y_COORDINATE = 1
)(
    input clk,
    input reset_n,
    input tick,
    input input_buffer_empty,
    input [29:0] packet_in,

    output [7:0] packet_out,
    output packet_out_valid,
    output ren_to_input_buffer,
    output grid_controller_error,
    output scheduler_error,
    output [2:0] grid_state,
    output forward_north_local_buffer_empty_all
);

    localparam NUM_CORES = GRID_DIMENSION_X * GRID_DIMENSION_Y;
    localparam OUTPUT_CORE = OUTPUT_CORE_X_COORDINATE + OUTPUT_CORE_Y_COORDINATE * GRID_DIMENSION_X;
    // Wires for Errors:
    wire [NUM_CORES - 1:0] grid_controller_errors;
    wire [NUM_CORES - 1:0] scheduler_errors;
    
    // Wires for Eastward Routing Communication
    wire [NUM_CORES - 1:0] ren_east_bus;
    wire [NUM_CORES - 1:0] empty_east_bus;
    
    // Wires for Westward Routing Communication
    wire [NUM_CORES - 1:0] ren_west_bus;
    wire [NUM_CORES - 1:0] empty_west_bus;
    
    // Wires for Northward Routing Communication
    wire [NUM_CORES - 1:0] ren_north_bus;
    wire [NUM_CORES - 1:0] empty_north_bus;
    
    // Wires for Southward Routing Communication
    wire [NUM_CORES - 1:0] ren_south_bus;
    wire [NUM_CORES - 1:0] empty_south_bus;
    
    // Wires for packets
    wire [29:0] east_out_packets [NUM_CORES - 1:0];
    wire [29:0] west_out_packets [NUM_CORES - 1:0];
    wire [20:0] north_out_packets [NUM_CORES - 1:0];
    wire [20:0] south_out_packets [NUM_CORES - 1:0];
    
    wire  [2:0] grid_state_reg [NUM_CORES - 2:0];
    wire [NUM_CORES -2 :0] forward_north_local_buffer_empty ;
    assign grid_state = grid_state_reg[NUM_CORES - 2];
    genvar curr_core;
    
    assign grid_controller_error = | grid_controller_errors;  // OR all TC errors to get final grid_controller_error
    assign scheduler_error = | scheduler_errors;                // OR all SCH errors to get final scheduler error
    assign ren_to_input_buffer = ren_west_bus[0];               // Read enable to the buffer that stores the input packets
    assign forward_north_local_buffer_empty_all = & forward_north_local_buffer_empty;
    for (curr_core = 0; curr_core < GRID_DIMENSION_X * GRID_DIMENSION_Y; curr_core = curr_core + 1) begin : gencore
        localparam right_edge = curr_core % GRID_DIMENSION_X == (GRID_DIMENSION_X - 1);
        localparam left_edge = curr_core % GRID_DIMENSION_X == 0;
        localparam top_edge = curr_core / GRID_DIMENSION_X == (GRID_DIMENSION_Y - 1);
        localparam bottom_edge = curr_core / GRID_DIMENSION_X == 0;
        
        if (curr_core != OUTPUT_CORE) begin
            Core_3x2 #(
                .CORE_NUMBER(curr_core)
            )
            Core (
                .clk(clk),
                .tick(tick),
                .reset_n(reset_n),
                .ren_in_west(left_edge ? 1'b0 : ren_east_bus[curr_core - 1]),
                .ren_in_east(right_edge ? 1'b0 : ren_west_bus[curr_core + 1]),
                .ren_in_north(top_edge ? 1'b0 : ren_south_bus[curr_core + GRID_DIMENSION_X]),
                .ren_in_south(bottom_edge ? 1'b0 : ren_north_bus[curr_core - GRID_DIMENSION_X]),
                .empty_in_west(curr_core == 0 ? input_buffer_empty : left_edge ? 1'b1 : empty_east_bus[curr_core - 1]),
                .empty_in_east(right_edge ? 1'b1 : empty_west_bus[curr_core + 1]),
                .empty_in_north(top_edge ? 1'b1 : empty_south_bus[curr_core + GRID_DIMENSION_X]),
                .empty_in_south(bottom_edge ? 1'b1 : empty_north_bus[curr_core - GRID_DIMENSION_X]),
                .east_in(right_edge ? {30{1'b0}} : west_out_packets[curr_core + 1]),
                .west_in(curr_core == 0 ? packet_in : left_edge ? {30{1'b0}} : east_out_packets[curr_core - 1]),
                .north_in(top_edge ? {21{1'b0}} : south_out_packets[curr_core + GRID_DIMENSION_X]),
                .south_in(bottom_edge ? {21{1'b0}}: north_out_packets[curr_core - GRID_DIMENSION_X]),
                .ren_out_west(ren_west_bus[curr_core]),
                .ren_out_east(ren_east_bus[curr_core]),
                .ren_out_north(ren_north_bus[curr_core]),
                .ren_out_south(ren_south_bus[curr_core]),
                .empty_out_west(empty_west_bus[curr_core]),
                .empty_out_east(empty_east_bus[curr_core]),
                .empty_out_north(empty_north_bus[curr_core]),
                .empty_out_south(empty_south_bus[curr_core]),
                .east_out(east_out_packets[curr_core]),
                .west_out(west_out_packets[curr_core]),
                .north_out(north_out_packets[curr_core]),
                .south_out(south_out_packets[curr_core]),
                .grid_controller_error(grid_controller_errors[curr_core]),
                .scheduler_error(scheduler_errors[curr_core]),
                .grid_state (grid_state_reg[curr_core]),
                .forward_north_local_buffer_empty(forward_north_local_buffer_empty[curr_core])
            );
        end
        else begin
            OutputBus #(
                .NUM_OUTPUTS(250)
            ) OutputBus (
                .clk(clk),
                .reset_n(reset_n),
                .ren_in_west(left_edge ? 1'b0 : ren_east_bus[curr_core - 1]),
                .ren_in_east(right_edge ? 1'b0 : ren_west_bus[curr_core + 1]),
                .ren_in_north(top_edge ? 1'b0 : ren_south_bus[curr_core + GRID_DIMENSION_X]),
                .ren_in_south(bottom_edge ? 1'b0 : ren_north_bus[curr_core - GRID_DIMENSION_X]),
                .empty_in_west(curr_core == 0 ? input_buffer_empty : left_edge ? 1'b1 : empty_east_bus[curr_core - 1]),
                .empty_in_east(right_edge ? 1'b1 : empty_west_bus[curr_core + 1]),
                .empty_in_north(top_edge ? 1'b1 : empty_south_bus[curr_core + GRID_DIMENSION_X]),
                .empty_in_south(bottom_edge ? 1'b1 : empty_north_bus[curr_core - GRID_DIMENSION_X]),
                .ren_out_west(ren_west_bus[curr_core]),
                .ren_out_east(ren_east_bus[curr_core]),
                .ren_out_north(ren_north_bus[curr_core]),
                .ren_out_south(ren_south_bus[curr_core]),
                .empty_out_west(empty_west_bus[curr_core]),
                .empty_out_east(empty_east_bus[curr_core]),
                .empty_out_north(empty_north_bus[curr_core]),
                .empty_out_south(empty_south_bus[curr_core]),
                .east_in(right_edge ? {30{1'b0}} : west_out_packets[curr_core + 1]),
                .west_in(curr_core == 0 ? packet_in : left_edge ? {30{1'b0}} : east_out_packets[curr_core - 1]),
                .north_in(top_edge ? {21{1'b0}} : south_out_packets[curr_core + GRID_DIMENSION_X]),      // North In From Next North's South Out
                .south_in(bottom_edge ? {21{1'b0}} : north_out_packets[curr_core - GRID_DIMENSION_X]),      // South In From Next South's North Out
                .east_out(east_out_packets[curr_core]),     // East Out, Next East's West In
                .west_out(west_out_packets[curr_core]),     // West Out, Next West's East In
                .north_out(north_out_packets[curr_core]),    // North Out, Next North's South In
                .south_out(south_out_packets[curr_core]),    // South Out, Next South's North In
                .packet_out(packet_out),
                .packet_out_valid(packet_out_valid),
                .grid_controller_error(grid_controller_errors[curr_core]),
                .scheduler_error(scheduler_errors[curr_core])
            );
        end
    end 

    
endmodule