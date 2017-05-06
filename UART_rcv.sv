module uart_rcv(rst_n, clk, rdy, clr_rdy, rx_data, RX);

input rst_n, clk, clr_rdy;
input logic RX;
output logic rdy;
output [7:0] rx_data;

logic set_rdy;//, rst_rdy;
logic load, shift, clear, receiving;
logic [9:0] rx_shft_reg;
logic [11:0] baud_cnt;
logic [3:0] bit_cnt;

typedef enum reg {IDLE, RECEIVE} state_t;
state_t state, nxt_state;

// state machine -> load, receiving

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin
	nxt_state = IDLE;
	load = 0;
	//rst_rdy = 0;
	set_rdy = 0;
	receiving = 0;

	case (state)

		IDLE: begin
			if (!RX) begin
				nxt_state = RECEIVE;
				//rst_rdy = 1;
				load = 1;
			end else begin
				nxt_state = IDLE;
			end
		end

		RECEIVE: begin

			if (bit_cnt == 10) begin
				set_rdy = 1;
				nxt_state = IDLE;
			end else begin
				receiving = 1;
				nxt_state = RECEIVE;
			end
		end

	endcase

end


// mux -> FF -> bit_cnt (same as transmittor)

always_ff @(posedge clk) begin
	if (load)
		bit_cnt <= 4'h0;
	else if (shift)
		bit_cnt <= bit_cnt + 1;
  else
    bit_cnt <= bit_cnt;
end

// mux -> FF -> shift

always_ff @(posedge clk) begin
	if (load)
		baud_cnt <= 12'h000;
	else if (clear)
		baud_cnt <= 12'h000;
	else if (receiving)
  	baud_cnt <= baud_cnt + 1;
  else
    baud_cnt <= baud_cnt;
end

assign shift = (baud_cnt == 12'd1302) ? 1'b1 : 1'b0;
assign clear = (baud_cnt == 12'd2604) ? 1'b1 : 1'b0;

// mux -> FF -> rx_data

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    rx_shft_reg <= 10'h3FF;
	else if (load)
		rx_shft_reg <= 10'h3FF;
  else if (shift)
		rx_shft_reg <= {RX, rx_shft_reg[9:1]};
  else
    rx_shft_reg <= rx_shft_reg;
end

assign rx_data = rx_shft_reg[8:1];

// mux -> FF -> rdy

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    rdy <= 0;
	else if (clr_rdy)
    rdy <= 0;
	else if (set_rdy)
		rdy <= 1;
  else
    rdy <= rdy;

end

endmodule
