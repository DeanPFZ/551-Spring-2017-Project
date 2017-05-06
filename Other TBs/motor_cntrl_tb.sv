module motor_cntrl_tb();

logic clk, rst_n;
logic [10:0] lft, rht;
wire fwd_lft, rev_lft, fwd_rht, rev_rht;

motor_cntrl iDUT(clk, rst_n, lft, rht, fwd_lft, rev_lft, fwd_rht, rev_rht);

initial begin
	clk = 0;
	rst_n = 0;
	rht = 11'hF00;		// right reverse
	lft = 11'h0FF;		// left forward
	@(negedge clk);
	rst_n = 1;
	repeat(1000) @(posedge clk);
	@(negedge clk);
	rst_n = 0;
	rht = 11'h1FF;		// right forward
	@(negedge clk);
	rst_n = 1;
	repeat(1000) @(posedge clk);
	@(negedge clk);
	rst_n = 0;
	lft = 11'h700;		// left reverse
	@(negedge clk);
	rst_n = 1;
	repeat(1000) @(posedge clk);
	@(negedge clk);
	rst_n = 0;
	// braking mode
	lft = 11'h000;
	rht = 11'h000;
	@(negedge clk);
	rst_n = 1;
	repeat(1000) @(posedge clk);
 	$stop;
end
	
always
	#5 clk = ~clk;

endmodule

