module barcode(clk, rst_n, BC, clr_ID_vld, ID_vld, ID);

input BC, clr_ID_vld, clk, rst_n;
output logic ID_vld;
output logic [7:0] ID;
logic [21:0] cnt, duration;
logic [3:0] bit_cnt;
logic start, counting, clr_cnt, save, shift, done, BC_falling_edge;
logic BC_1, BC_2, BC_flopped; 
logic BC_set, BC_clr, BC_temp;
typedef enum reg[1:0] {IDLE,COUNT,DURATION,SHIFT} state_t;
state_t state, nxt_state;


// double flops for BC
always_ff  @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		BC_1 <= 1'b0;
		BC_2 <= 1'b0;
	end
	else begin
		BC_1 <= BC;
		BC_2 <= BC_1;
	end
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		BC_flopped <= 1'b0;
	else
		BC_flopped <= BC_2;
end

// save the previous BC_flopped value to detect falling edge
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		BC_temp <= 1'b0;
	else 
		BC_temp <= BC_flopped;
end

assign BC_falling_edge = BC_temp & ~BC_flopped; // detect the falling edge of BC

// count for the time of the low duration
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n || start || clr_cnt)
		cnt <= 22'b000000;
	else if (counting)
		cnt <= cnt + 1;
	else
		cnt <= cnt;
end

// capture the time of saving the BC value 
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n || done)
		duration <= 22'h000000;
	else if (save)
		duration <= cnt;
	else
		duration <= duration;
end

// count fot the bit shifted
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n || start || done)
		bit_cnt <= 4'h0;
	else if (shift)
		bit_cnt <= bit_cnt + 1;
	else
		bit_cnt <= bit_cnt;
end

// output ID
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		ID <= 8'h00;
	else if (shift)
		ID <= {ID[6:0], BC_flopped};
	else
		ID <= ID;
end

// output valid
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n || clr_ID_vld)
		ID_vld <= 1'b0;
	//The upper 2-bits are used as an integrity check and must be 2?b00 for the ID to be considered valid.
	else if (done && (ID[7:6] == 2'b00))
		ID_vld <= 1'b1;
	else
		ID_vld <= ID_vld;
end

// state transition
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

// state machine
always_comb begin
	nxt_state = IDLE;
	start = 0;
	counting = 0;
	save = 0;
	clr_cnt = 0;
	shift = 0;
	done = 0;
	case (state)
		IDLE: begin
			if (BC_falling_edge && !ID_vld) begin
				start = 1;		// START BIT
				nxt_state = COUNT;
			end
			else begin
				nxt_state = IDLE;
			end
		end
		COUNT: begin
			if (BC_flopped) begin
				save = 1;		// THE END OF THE START BIT
				nxt_state = DURATION;
			end
			else begin
				counting = 1;
				nxt_state = COUNT;
			end
		end
		DURATION: begin
			if (BC_falling_edge && bit_cnt < 4'h8) begin
				clr_cnt = 1;
				nxt_state = SHIFT;
			end
			else if (bit_cnt >= 4'h8) begin
				clr_cnt = 1;
				done = 1;
				nxt_state = IDLE;
			end
			else begin
				nxt_state = DURATION;
			end
		end
		SHIFT: begin
			if (cnt == duration) begin
				shift = 1;
				nxt_state = DURATION;
			end
			else begin
				counting = 1;
				nxt_state = SHIFT;
			end
		end
	endcase
end


endmodule
