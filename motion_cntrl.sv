module motion_cntrl(clk, rst_n, go, start_conv, chnnl, cnv_cmplt, A2D_res, IR_in_en, IR_mid_en, IR_out_en, LEDs, lft, rht);

input go, cnv_cmplt, clk, rst_n;
input logic[11:0] A2D_res;

output logic start_conv, IR_in_en, IR_mid_en, IR_out_en;
output logic [2:0] chnnl;
output logic [7:0] LEDs;
output logic [10:0] lft, rht;
logic [2:0] chnnl_counter;
logic timer_start, timer_clr; // start or clear timer
logic[12:0] timer4096;
logic chnnl_clr, chnnl_inc;
typedef enum reg[3:0] {IDLE, STTL, CALC_1, SHRT_WAIT, CALC_2, INTG, ICOMP, PCOMP, ACCUM_R, RIGHT, ACCUM_L, LEFT} state_t;
state_t state, nxt_state;

logic PWM, PWM_en, PWM_clr;
logic[7:0] PWM_counter;

logic[11:0] lft_reg, rht_reg;
logic [15:0]Pcomp;
logic [15:0]Accum;
logic [11:0]Icomp;
logic [13:0]Pterm;
logic [11:0]Iterm;
logic [11:0]Fwd;
logic [11:0]Error;
logic [11:0]Intgrl, Intgrl_temp;
logic [2:0]src1sel, src0sel;
logic multiply, sub, mult2, mult4, saturate;
logic [15:0] dst;

logic clr_Accum, dst_Accum, dst_Error, dst_Intgrl, dst_Icomp, dst_Pcomp, dst_rht_reg, dst_lft_reg; 
logic [1:0] int_dec;

alu iALU(dst, Accum, Pcomp, Icomp, Pterm, Iterm, Fwd, A2D_res, Error, Intgrl, src1sel, src0sel, multiply, sub, mult2, mult4, saturate);

assign lft = lft_reg[11:1];
assign rht = rht_reg[11:1];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		chnnl_counter <= 3'b000;
	else if(chnnl_clr)
		chnnl_counter <= 3'b000;
	else if(chnnl_inc)
		chnnl_counter <= chnnl_counter + 1'b1;
	else
		chnnl_counter <= chnnl_counter;
end

assign chnnl = (chnnl_counter == 3'h0)? 3'h1:
		(chnnl_counter == 3'h1)? 3'h0:
		(chnnl_counter == 3'h2)? 3'h4:
		(chnnl_counter == 3'h3)? 3'h2:
		(chnnl_counter == 3'h4)? 3'h3:
		(chnnl_counter == 3'h5)? 3'h7:
					3'h5; //should not happen

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		Pcomp <= 16'h0000;
	else if(dst_Pcomp)
		Pcomp <= dst;
	else
		Pcomp <= Pcomp;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		Accum <= 16'h0000;
	else if(clr_Accum)
		Accum <= 16'h0000;
	else if(dst_Accum)
		Accum <= dst;
	else
		Accum <= Accum;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		Icomp <= 12'h000;
	else if(dst_Icomp)
		Icomp <= dst;
	else
		Icomp <= Icomp;
end

assign LEDs = Error[11:4];
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		Error <= 12'h000;
	else if(dst_Error)
		Error <= dst;
	else
		Error <= Error;
end

assign dst2Int = &int_dec;

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)begin
		Intgrl <= 12'h000;
		Intgrl_temp <= 12'h000;
		int_dec <= 2'b00;
	end
	else if(dst_Intgrl) begin
		Intgrl_temp <= dst;
		int_dec <= int_dec + 1'b1;
		if(dst2Int) begin
			Intgrl <= Intgrl_temp;
		end
	end
	else begin
		Intgrl <= Intgrl;
		Intgrl_temp <= Intgrl_temp;
		int_dec <= int_dec;
	end
end

always_ff @(posedge clk, negedge rst_n) begin
  	if (!rst_n) begin
    		Pterm <= 14'h3680;
    		Iterm <= 12'h500;
  	end
  	else begin
    		Pterm <= 14'h3680;
    		Iterm <= 12'h500;
  	end
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n || timer_clr)
		timer4096 <= 12'h000;
	else if(timer_start)
		timer4096 <= timer4096 + 1'b1;
	else
		timer4096 <= timer4096;
end

assign PWM_en = &PWM_counter;
assign PWM_clr = (PWM_counter == 8'h8c) ? 1'b1:1'b0;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    PWM_counter <= 10'h3FF;
  else
    PWM_counter <= PWM_counter + 1'b1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		PWM <= 1'b0;
 	else if (PWM_clr)
    		PWM <= 1'b0;
  	else if (go && PWM_en)
    		PWM <= 1'b1;
  	else
    		PWM <= PWM;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rht_reg <= 12'h000;
	else if (!go)
		rht_reg <= 12'h000;
	else if (dst_rht_reg)
		rht_reg <= dst[11:0];
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		lft_reg <= 12'h000;
	else if (!go)
		lft_reg <= 12'h000;
	else if (dst_lft_reg)
		lft_reg <= dst[11:0];
end

always_ff @(posedge clk, negedge rst_n)begin
	if (!rst_n)
		Fwd <= 12'h000;
	else if (~go) 		// if go deasserted Fwd knocked down so
		Fwd <= 12'b000; 		// we accelerate from zero on next start.
	else if (dst_Intgrl & ~&Fwd[10:8]) 		// 43.75% full speed
		Fwd <= Fwd + 1'b1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

always_comb begin
	//default output
	nxt_state = IDLE;
  	start_conv = 1'b0;
  	timer_start = 1'b0;
  	timer_clr = 1'b0;
  	IR_in_en = 1'b0;
  	IR_mid_en = 1'b0;
  	IR_out_en = 1'b0;
  	chnnl_clr = 1'b0;
  	chnnl_inc = 1'b0;
  	src1sel = 1'b0;
  	src0sel = 1'b0;
  	multiply = 1'b0;
  	sub = 1'b0;
  	mult2 = 1'b0;
  	mult4 = 1'b0;
  	saturate = 1'b0;
  	clr_Accum = 1'b0;
  	dst_Accum = 1'b0; 
  	dst_Error = 1'b0; 
  	dst_Intgrl = 1'b0; 
  	dst_Icomp = 1'b0; 
  	dst_Pcomp = 1'b0; 
  	dst_rht_reg = 1'b0;
  	dst_lft_reg = 1'b0;

	case (state)
		IDLE: begin
			if(!go)
				nxt_state = IDLE;
			else begin
				chnnl_clr = 1'b1;
				clr_Accum = 1'b1;
				timer_start = 1'b1;
				case (chnnl_counter)
        				3'b000: IR_in_en = 1'b1;
        				3'b010: IR_mid_en = 1'b1;
        				3'b100: IR_out_en = 1'b1;
        				default: begin
          					IR_in_en = 1'b0;
         				 	IR_mid_en = 1'b0;
          					IR_out_en = 1'b0;
        					end
     				endcase
				nxt_state = STTL;
			end
		end
		STTL: begin
			if(timer4096[12] != 1'b1) begin
				timer_start = 1'b1; 
				nxt_state = STTL;
			end
			else begin
				start_conv = 1'b1;
				nxt_state = CALC_1;
			end				
		end
		CALC_1: begin
			if(cnv_cmplt) begin
				case (chnnl_counter)
        				3'b000: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						dst_Accum = 1'b1;
					end
        				3'b010: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						mult2 = 1'b1;
						dst_Accum = 1'b1;
					end
        				3'b100: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						mult4 = 1'b1;
						dst_Accum = 1'b1;
					end
     				endcase
				timer_clr = 1'b1;
				chnnl_inc = 1'b1;
				timer_start = 1'b1;
				nxt_state = SHRT_WAIT;	
			end
			else
				nxt_state = CALC_1;
		end
		SHRT_WAIT:begin
			if(timer4096[6] != 1'b1)begin
				timer_start = 1'b1;
				nxt_state = SHRT_WAIT;
			end
			else begin
				start_conv = 1'b1;
				nxt_state = CALC_2;
			end	
		end
		CALC_2: begin
			if(cnv_cmplt) begin
				case (chnnl_counter)
        				3'b001: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						sub = 1'b1;
						dst_Accum = 1'b1;
					end
        				3'b011: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						mult2 = 1'b1;
						sub = 1'b1;
						dst_Accum = 1'b1;
					end
        				3'b101: begin
						src1sel = 3'b000;
						src0sel = 3'b000;
						mult4 = 1'b1;
						sub = 1'b1;
						saturate = 1'b1;
						dst_Error = 1'b1;
					end
     				endcase
				timer_clr = 1'b1;
				chnnl_inc = 1'b1;
				timer_start = 1'b1;
				if(chnnl_counter != 3'b101) begin
					timer_start = 1'b1;
					case (chnnl_counter)
        					3'b000: IR_in_en = 1'b1;
        					3'b010: IR_mid_en = 1'b1;
        					3'b100: IR_out_en = 1'b1;
        					default: begin
          						IR_in_en = 1'b0;
         				 		IR_mid_en = 1'b0;
          						IR_out_en = 1'b0;
        					end
     					endcase
					nxt_state = STTL;
				end
				else 
					nxt_state = INTG;	
			end
			else begin
				nxt_state = CALC_2;
			end
		end
		INTG:begin
			src1sel = 3'b011; // Error>>4
        		src0sel = 3'b001; // Integrl
        		saturate = 1'b1;
        		dst_Intgrl = 1'b1;
        		nxt_state = ICOMP;
		end
		ICOMP:begin
			src1sel = 3'b001; // Iterm
        		src0sel = 3'b001; // Integrl
        		multiply = 1'b1;
        		dst_Icomp = 1'b1;
        		nxt_state = PCOMP;
		end
		PCOMP: begin
			src1sel = 3'b010; // Error
        		src0sel = 3'b100; // Pterm
        		multiply = 1'b1;
        		dst_Pcomp = 1'b1;
        		nxt_state = ACCUM_R;
		end
		ACCUM_R: begin
			src1sel = 3'b100; // Fwd
        		src0sel = 3'b011; // Pcomp
        		sub = 1'b1;
        		dst_Accum = 1'b1;
        		nxt_state = RIGHT;
		end
		RIGHT:begin
			src1sel = 3'b000; //Accum
			src0sel = 3'b010; //Icomp
			sub = 1'b1;
			saturate = 1'b1;
			dst_rht_reg = 1'b1;
			nxt_state = ACCUM_L;
		end
		ACCUM_L: begin
			src1sel = 3'b100; // Fwd
        		src0sel = 3'b011; // Pcomp
        		dst_Accum = 1'b1;
        		nxt_state = LEFT;
		end
		LEFT:begin
			src1sel = 3'b000; //Accum
			src0sel = 3'b010; //Icomp
			saturate = 1'b1;
			dst_lft_reg = 1'b1;
			nxt_state = IDLE;
		end
	endcase
end


endmodule


