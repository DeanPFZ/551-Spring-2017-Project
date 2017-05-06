module SPI_mstr16(MOSI, SS_n, SCLK, done, rd_data, MISO, wrt, cmd, clk, rst_n);

//initialize variables
output reg MOSI, SCLK;
output reg SS_n, done;
output reg [15:0] rd_data;

input MISO, wrt, clk, rst_n;
input [15:0] cmd;

reg [4:0] counter, ss_n_cnt;
reg rst_c, enable;
reg [15:0] shifter;

always @(posedge clk) begin
	//reset all output
	if(!rst_n) begin
		MOSI <= 0;
		SCLK <= 1;
		SS_n <= 1;
		done <= 0;
		rd_data <= 16'h0000;
		shifter <= 0;
	end
	else if(wrt) begin
		SS_n <= 0;
		shifter <= cmd;
	end
	else if(done) begin
		SS_n <= 1;
		done <= 0;
		ss_n_cnt <= 0;
	end
	else if(counter == 5'b10001)
		shifter <= {shifter[14:0], MISO};
	else if(ss_n_cnt == 16 && counter == 5'b10011)
		done <= 1;
	//set counter number
	if(rst_n ==0|| SS_n==1) counter <= 5'b11101;
	else counter <= counter + 1;
end

//set SCLK
always @(counter) SCLK = counter[4];

//at the 16 cycle, we need to stop
always @(posedge SCLK) begin
	if(!rst_n) ss_n_cnt = 0;
	else begin
		MOSI <= shifter[15];
		ss_n_cnt <= ss_n_cnt + 1;
	end
end

always @(posedge done) rd_data <= shifter;

endmodule