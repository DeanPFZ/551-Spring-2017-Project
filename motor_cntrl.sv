module motor_cntrl(clk, rst_n, lft, rht, fwd_lft, rev_lft, fwd_rht, rev_rht);
input [10:0] lft, rht;
input clk, rst_n;
output logic fwd_lft, rev_lft, fwd_rht, rev_rht;

logic sign_lft, sign_rht, dir_lft, dir_rht;
logic [9:0] abs_lft, abs_rht;

reg [10:0] left, right;
//reg declear
reg [9:0] cnt;

//free running counter
always@(posedge clk, negedge rst_n)
  if(~rst_n)
	cnt<=10'b0;
  else 
	cnt<=cnt+1'b1;


always@(posedge clk, negedge rst_n)
  begin
    if(~rst_n) begin
      left<= 11'b0;
      right<= 11'b0;
     end
    else if(cnt == 10'b11_1111_1110) begin
      left<= lft;
      right<=rht;
     end
  end

assign sign_lft = lft[10];
assign sign_rht = rht[10];
assign abs_lft = !sign_lft ? lft[9:0] : (left[10:0]== 11'b100_0000_0000) ? 10'b11_1111_1111 : (~left[9:0] + 1'b1);
assign abs_rht = !sign_rht ? rht[9:0] :(right[10:0] == 11'b100_0000_0000) ? 10'b11_1111_1111 : (~right[9:0] + 1'b1);

pwm iLEFT(.duty(abs_lft), .PWM_sig(dir_lft), .clk(clk), .rst_n(rst_n));
pwm iRIGHT(.duty(abs_rht), .PWM_sig(dir_rht), .clk(clk), .rst_n(rst_n));


assign fwd_lft =  (~rst_n) ? 1 : ((lft == 11'h000) ? 1:((sign_lft) ? 0 : dir_lft));
assign rev_lft =  (~rst_n) ? 1 : ((lft == 11'h000) ? 1:((!sign_lft) ?  0: dir_lft));
assign fwd_rht =  (~rst_n) ? 1 : ((rht == 11'h000) ? 1:((sign_rht) ? 0 : dir_rht));
assign rev_rht =  (~rst_n) ? 1 : ((rht == 11'h000) ? 1:((!sign_rht) ?  0 : dir_rht));

endmodule