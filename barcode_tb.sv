module barcode_tb();

logic clk, rst_n, BC, clr_ID_vld, send, BC_done;
logic [21:0] period;
logic [7:0] station_ID;
wire [7:0] ID;
wire ID_vld;

barcode_mimic BARCODE_MIMIC(.clk(clk),.rst_n(rst_n),.period(period),.send(send),.station_ID(station_ID),.BC_done(BC_done),.BC(BC));

barcode BARCODE(.clk(clk),.rst_n(rst_n),.BC(BC),.clr_ID_vld(clr_ID_vld),.ID_vld(ID_vld),.ID(ID));

initial begin
	clk = 0;
	rst_n = 0;
	clr_ID_vld = 0;
	send = 0;
	period = 22'h000111;
	station_ID = 8'b11111111;
	repeat (2)@(negedge clk);
	rst_n = 1;
// test 1, station_ID = 0xFF; Since the upper 2 bit is not 2'b00, so the ID is not valid
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 2, station_ID = 0x01;
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID =  8'b00000001;
	@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 3, station_ID = 0x04;
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID = 8'b00000100;
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 4, station_ID = 0x1F;
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID = 8'b00011111;
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 5, station_ID = 0x20;
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID = 8'b00100000;
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 6, station_ID = 0x40;
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID = 8'b01000000;
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

// test 7, station_ID = 0x81; Since the upper 2 bit is not 2'b00, so the ID is not valid
	@(posedge BC_done);
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b1;
	repeat (2)@(negedge clk);
	clr_ID_vld = 1'b0;
	repeat (2)@(negedge clk);
	station_ID = 8'b10000001;
	repeat (2)@(negedge clk);
	send = 1;
	@(negedge clk);
	send = 0;

	$stop;

end

always
	#5 clk <= ~clk;

endmodule
