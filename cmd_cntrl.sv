module cmd_cntrl(clr_cmd_rdy, in_transit, go, buzz, buzz_n, clr_ID_vld, cmd, cmd_rdy, OK2Move, ID, ID_vld, clk, rst_n);

output logic clr_cmd_rdy, in_transit, go, buzz, buzz_n, clr_ID_vld;
input cmd_rdy, OK2Move, ID_vld, clk, rst_n;
input [7:0] cmd, ID;

logic clr_in_transit,set_in_transit,gogogo,latch_ID, en;
logic [5:0] destID;
logic [15:0] buzz_cnt;

typedef enum reg {STOP, GO} state_t;
state_t state, nxt_state;

assign gogogo = (cmd[7:6]==2'b01)? 1:(cmd[7:6]==2'b00)? 0 :gogogo;

always @(posedge clk, negedge rst_n)	begin
  if (!rst_n)
    destID <= 6'h00;
  else if (gogogo)
    destID <= cmd[5:0];
  else
    destID <= destID;
end

always @(posedge clk, negedge rst_n)	begin
	if(!rst_n || clr_in_transit)
	   in_transit <= 0;
	else if(set_in_transit)
	  in_transit <= 1;
	else
	  in_transit <= in_transit;
end



always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)	state <= STOP;
	else	state <= nxt_state;

always_comb begin
	clr_cmd_rdy = 0;
	clr_in_transit = 0;
	set_in_transit = 0;
	clr_ID_vld = 0;
	latch_ID = 0;

	case(state)
	STOP:
		if(cmd_rdy && gogogo)	begin
			latch_ID = 1;
			nxt_state = GO;
		end
		else	nxt_state = STOP;
	GO:	
		if(cmd_rdy && !gogogo)	begin
			clr_cmd_rdy = 1;
			clr_in_transit = 1;//*
			nxt_state = STOP;
		end
		else if(cmd_rdy && gogogo)	begin
			clr_cmd_rdy = 1;
			set_in_transit = 1;
			latch_ID = 1;
			nxt_state = GO;
		end
		else if(ID_vld && ID[5:0] != destID)	begin
			clr_ID_vld = 1;
			nxt_state = GO;
		end
		else if(ID_vld && ID[5:0] == destID)	begin
			clr_ID_vld = 1;
			clr_in_transit = 1;//*
			nxt_state = STOP;
		end
		else	nxt_state = GO;
	endcase
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    buzz_cnt <= 16'h0000;
  else if (~OK2Move && in_transit)
    buzz_cnt <= 16'h0000;
  else if (buzz_cnt == 16'h303)
    buzz_cnt <= buzz_cnt + 1;
  else
    buzz_cnt <= buzz_cnt;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    buzz <= 1'b0; // The initial value doesn't really matter, but always good to initialize.
    buzz_cnt <= 16'h0000; // What should INIT_VALUE be?
  end
  else begin
    if (en) // Increase when enabled
      buzz_cnt <= buzz_cnt + 1'b1;
    if (buzz_cnt >= 16'h1869) // 50% duty
        buzz <= 1'b1;
    else
        buzz <= 1'b0;
    end
    if (buzz_cnt == 16'h30D3) // Don't just let it overflow. What should EXP_VALUE be?
        buzz_cnt <= 16'h0000;
 end


assign buzz_n = (en)? ~buzz : buzz; // Inversion only when enabled to vibrate.

assign go = in_transit && OK2Move;
assign en = in_transit && ~OK2Move;

endmodule