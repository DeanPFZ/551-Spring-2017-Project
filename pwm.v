module pwm(PWM_sig, duty, clk, rst_n);

//initialize the variables
output reg PWM_sig;
input [9:0] duty;
input clk, rst_n;
reg [9:0] cnt;
wire d, set, reset;

//set or reset the PWM signal
assign set = &cnt;
assign reset = (cnt == duty);
assign d =
	(set)? 1:
	(reset)? 0:
	PWM_sig;
//change the output
always @(posedge clk, negedge rst_n)
    if(!rst_n)
	PWM_sig <= 1'b1;
    else
	PWM_sig <= d;

//generate the count
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		cnt <= 10'b0;
	else
		cnt <= cnt + 1'b1;

endmodule