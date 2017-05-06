module cmd_cntrl_tb();
logic clr_cmd_rdy, in_transit, go, buzz, buzz_n, clr_ID_vld,cmd_rdy, OK2Move, ID_vld, clk, rst_n;
logic [7:0]cmd, ID;

cmd_cntrl iDUT(.clr_cmd_rdy(clr_cmd_rdy), .in_transit(in_transit), .go(go), .buzz(buzz),
               .buzz_n(buzz_n), .clr_ID_vld(clr_ID_vld), .cmd(cmd), .cmd_rdy(cmd_rdy), 
               .OK2Move(OK2Move), .ID(ID), .ID_vld(ID_vld), .clk(clk), .rst_n(rst_n));

always #5 clk = ~clk;

initial begin
cmd_rdy = 0;
OK2Move = 0;
ID_vld = 0;
clk = 0;
rst_n = 0;

cmd = 8'b0;
ID = 8'b0;

#50000
rst_n = 1;

#1000
OK2Move = 1;

#500
cmd = 8'h1A;
#200
cmd_rdy = 1;

#100000
ID = 8'h53;
#20000
ID_vld = 1;


#100000
ID_vld = 0;
cmd_rdy = 0;

#500
cmd = 8'h67;
#200
cmd_rdy = 1;


#50000
ID = 8'h2E;
#20000
ID_vld = 1;


#10000

OK2Move = 0;
#100000

$stop;
end



endmodule
