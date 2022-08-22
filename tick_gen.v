module tick_gen (
    input       clk,
    input       reset_n,
    input [2:0] state,
    input [2:0] grid_state,
    input       input_buffer_empty,
    input       forward_north_local_buffer_empty_all,
    input       complete,
    output      tick
);
    localparam  [1:0]   IDLE      = 2'b00,
                        TICK1     = 2'b01,
                        TICK2     = 2'b10;

    reg [2:0]   cnt_reg, cnt_next;
    reg [31:0]  cnt2_reg, cnt2_next;
    reg         tick_reg, tick_next;
    reg [1:0]   state_tick_reg, state_tick_next;

    always @(posedge clk) begin
        if (!reset_n) begin
            tick_reg    <= 0;
            cnt_reg     <= 0;
            cnt2_reg    <= 0;
            state_tick_reg   <= IDLE;
        end
        else begin
            tick_reg    <= tick_next;
            cnt_reg     <= cnt_next;
            cnt2_reg    <= cnt2_next;
            state_tick_reg   <= state_tick_next;
        end
    end

    always @(*) begin
        tick_next = 1'b0;
        cnt_next = cnt_reg;
        cnt2_next = cnt2_reg;
        case (state_tick_reg)
            IDLE:begin
                if(!input_buffer_empty)
                    state_tick_next = TICK1;
                else
                    state_tick_next = IDLE;
            end
            TICK1:begin
                if (input_buffer_empty && grid_state == 0)begin
                    if (cnt_reg == 7) begin 
                        tick_next   = 1;
                        cnt_next    = 0;
                    end 
                    else if (forward_north_local_buffer_empty_all) begin 
                        cnt_next <= cnt_reg + 1'b1;
                    end
        
                    else if (!forward_north_local_buffer_empty_all) begin 
                        cnt_next <= cnt_reg - 1'b1;
                    end
                end
                if (state == 3'b100) begin
                    state_tick_next = TICK2;
                end
                else
                    state_tick_next = TICK1;
            end
            TICK2:begin
                if (complete)
                    state_tick_next  = IDLE;
                else begin
                    state_tick_next  = TICK2;
                    if (cnt2_reg == 32'h3ec) begin
                        tick_next = 1'b1;
                        cnt2_next = 0;
                    end
                    else
                        cnt2_next = cnt2_reg + 1'b1;
                end
            end
        endcase
    end

    assign tick = tick_reg;

endmodule




