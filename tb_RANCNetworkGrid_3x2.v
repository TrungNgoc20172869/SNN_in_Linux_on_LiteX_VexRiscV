

// //Feed đầu mỗi tick

// module tb_RANCNetworkGrid_3x2;

// parameter NUM_OUTPUT = 250; // Số spike bắn ra
// parameter NUM_PICTURE = 10000; // Số ảnh test
// parameter NUM_PACKET = 1541670; // số lượng input packet trong file


// reg clk, reset_n, tick, input_buffer_empty;
// reg [29:0] packet_in;
// wire [7:0] packet_out;
// wire packet_out_valid, ren_to_input_buffer, token_controller_error, scheduler_error;

// RANCNetworkGrid_3x2 uut(
//     clk, reset_n, tick, input_buffer_empty, packet_in, packet_out, packet_out_valid, ren_to_input_buffer, token_controller_error, scheduler_error
// );

// initial begin
//     clk = 0;
//     forever #5 clk = ~clk;
// end
// initial begin
//     reset_n = 0; @(negedge clk); reset_n = 1;
// end


// // đọc số lượng packet trong mỗi tick
// reg [10:0] num_pic [0:NUM_PICTURE - 1];
// initial $readmemh("tb_num_inputs.txt", num_pic);

// // đọc tất cả các packet
// reg [29:0] packet [0:NUM_PACKET - 1];
// initial $readmemb("tb_input.txt", packet);




// integer i = 0;
// integer numline = 0; 
// integer index_end = 0;//345216;

// /////////////////////////
// always@(posedge clk) begin
//     if(ren_to_input_buffer) begin
//         packet_in <= packet[i + index_end];
//         i <= i + 1;
//     end
// end
// always @(negedge clk) begin
//     if(numline == NUM_PICTURE) input_buffer_empty <= 1;
//     else if(i == num_pic[numline]) begin
//         input_buffer_empty <= 1;
//     end
    
// end

// // log spike ra
// reg [NUM_OUTPUT - 1:0] spike_out;
// always @(packet_out_valid, tick) begin
//     if(tick) spike_out = {NUM_OUTPUT{1'b0}};
//     if(packet_out_valid) begin
//         spike_out[249 - packet_out] = 1'b1;
//     end
// end


// reg [NUM_OUTPUT - 1:0] output_file [0:NUM_PICTURE - 1];
// // định nghĩa hoạt động 1 vài tín hiệu và log lại output
// initial begin
//     input_buffer_empty = 0;
//     tick = 0; repeat(4000) @(negedge clk);
//     forever begin
//         tick = 1;// kích hoạt tính toán
//         index_end = index_end + i; // bắt đầu đưa packet vào từ vị trí của packet cuối cùng
//         i = 0; 
//         if(numline >= 1) output_file[numline - 2] = spike_out; //do mạng này có 2 layer
//         numline = numline + 1; // số thứ tự của ảnh, đưa ảnh tiếp theo vào
//         input_buffer_empty = 0; // bắt đầu đưa packet vào
//         @(negedge clk);
//         tick = 0;
//         repeat(1004) @(negedge clk); // thời gian đủ để tính toán và 
//     end
// end


// reg finish;
// initial finish = 0;
// always @(numline) begin
//     if(numline == NUM_PICTURE + 2) begin //do mạng này có 2 layer
//         repeat(50) @(negedge clk);
//         $writememb("output.txt", output_file);
//         finish = 1;
//         #(20);
//         $stop;
//     end
// end

// ///////compare with output from software////////////////////////////
// reg [NUM_OUTPUT - 1:0] output_soft [0:NUM_PICTURE - 1];
// reg wrong;
// initial wrong = 0;
// initial $readmemb("simulator_output.txt", output_soft);
// integer in, j;
// always @(finish) begin
//     if(finish) begin
//         for(in = 0; in < NUM_PICTURE; in = in + 1) begin
//             for(j = 0; j < NUM_OUTPUT; j = j + 1) begin
//                 if(output_file[in][j] != output_soft[in][j]) begin
//                     $display("Error at neuron %d, picture %d", j, in);
//                     wrong = 1;
//                 end
//             end
//         end
//     end
// end
// always @(finish) begin
//     if(finish) begin
//         #1; if(~wrong) $display("Test pass without error");
//     end
    
// end

// endmodule


//module test packet cua anh chang lang tu tai hoa
module tb_load_2;
parameter NUM_OUTPUT = 250; // Số spike bắn ra
parameter NUM_PICTURE = 100; // Số ảnh test
parameter NUM_PACKET = 13910; // số lượng input packet trong file


reg clk, reset_n, sys_rst, csr_rst;
wire tick, input_buffer_empty;
wire [29:0] packet_in;
wire [7:0] packet_out;
wire packet_out_valid, ren_to_input_buffer, grid_controller_error, scheduler_error;
wire complete;

reg start;
wire [NUM_OUTPUT - 1:0] spike_out;
wire [2:0] state;
wire [2:0] grid_state;
wire forward_north_local_buffer_empty_all;

RANCNetworkGrid_3x2 uut(
    clk, reset_n, tick, input_buffer_empty, packet_in, packet_out, packet_out_valid, ren_to_input_buffer, grid_controller_error, scheduler_error, grid_state, forward_north_local_buffer_empty_all
);

tick_gen tick_dut(
    clk, reset_n, state, grid_state, input_buffer_empty, forward_north_local_buffer_empty_all, complete, tick
);

load_packet #(30,NUM_PACKET,NUM_PICTURE) packet_loader (
    clk, reset_n, start, ren_to_input_buffer, tick, packet_out_valid, packet_out, grid_state, input_buffer_empty, complete, state, spike_out, packet_in
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
initial begin
    sys_rst = 1;
    csr_rst = 0; @(negedge clk); sys_rst = 0;
    #50 csr_rst = 1;
end

always @(sys_rst, csr_rst) begin
    reset_n = sys_rst | csr_rst;
end


initial begin
    #100 start = 1;
    #10 start = 0;
    #1200000 $finish();
end

reg [NUM_OUTPUT - 1: 0] output_file [0:NUM_PICTURE - 1];
reg [NUM_OUTPUT - 1: 0] output_soft [0:NUM_PICTURE - 1];
always @ (*) begin 
    if (tick && packet_loader.ptr_pic_reg >= 4) 
        output_file [packet_loader.ptr_pic_reg - 4] = spike_out;
end 



// integer i, j;
always @ (*) begin 
    if (packet_loader.ptr_pic_reg == 104) begin 
        $writememb ("output_with_loader_tick_gen.txt",output_file);
    end 
end
//         $readmemb ("simulator_output.txt",output_soft);
       

//         for(i = 0; i < NUM_PICTURE; i = i + 1) begin
//             for(j = 0; j < NUM_OUTPUT; j = j + 1) begin
//                 if(output_file[i][j] != output_soft[i][j]) begin
//                     $display("Error at neuron %d, picture %d", j, i);
//         end
//     end
// end
// end 
// end           
endmodule