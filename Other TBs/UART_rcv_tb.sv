module UART_rx_tb();

//initial parameters
logic clk, rst_n, RX, rx_rdy_clr, trmt;
logic [7:0] tx_data, rx_data;
logic tx_done, rx_rdy;

//instantiate 
UART_tx iUART_TX(.trmt(trmt), .clk(clk), .rst_n(rst_n), .tx_data(tx_data), .tx_done(tx_done), .TX(RX));

UART_rcv iUART_RCV(.clk(clk), .rst_n(rst_n), .rx_rdy(rx_rdy), .rx_rdy_clr(rx_rdy_clr), .rx_data(rx_data), .RX(RX));

//set clock
always #2 clk = ~clk;

//set intial value
initial begin
clk = 0;
rst_n = 0;
trmt = 0;
rx_rdy_clr = 0;

#500
rst_n = 1;


#100000
tx_data = 8'h35;
#10000
trmt = 1;
#10000
trmt = 0;

#100000
tx_data = 8'h35;
#10000
trmt = 1;
#10000
trmt = 0;

#100000
tx_data = 8'h18;
#10000
trmt = 1;
#10000
trmt = 0;

#100000
tx_data = 8'hF8;
#10000
trmt = 1;
#10000
trmt = 0;

#100000
tx_data = 8'h97;
#10000
trmt = 1;
#10000
trmt = 0;
end

endmodule
