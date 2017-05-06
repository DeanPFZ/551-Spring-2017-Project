module SPI_mstr16(clk, rst_n, wrt, cmd, done, rd_data, SCLK, SS_n, MOSI, MISO);

input clk, rst_n, wrt;  
input [15:0] cmd;
input MISO;
output logic done;
output logic [15:0] rd_data;
output logic SCLK, SS_n, MOSI;

//declaration
logic [4:0] counter1;
logic [1:0] state;
localparam idle = 2'b00;
localparam start_task = 2'b01;
localparam transmitting = 2'b10;
localparam end_task = 2'b11;

wire time_out;
reg [2:0] counter2;
reg [15:0] shifter_MOSI;
reg [15:0] shifter_MISO;
wire load;
wire shift;
//reg [1:0] shift_delay;
reg [3:0] shifter_counter;
//wait_timer
always@(posedge clk, negedge rst_n) begin
 if(~rst_n) begin
  counter2 <= 3'b0;
 end
 else if((state == start_task)||(state == end_task))
  counter2 <= counter2 + 1'b1;
 else
  counter2 <= 3'b0;
end 

assign time_out = (counter2 >= 3'b111);

//task
always@(posedge clk, negedge rst_n) begin
 if(~rst_n) begin
   SS_n <= 1'b1;
 end
 else if (state == start_task) begin
  SS_n <= 1'b0;
 end
 else if ((state == end_task)&&(time_out))
  SS_n <= 1'b1;
end

//shifting
always@(posedge clk, negedge rst_n) begin
 if(~rst_n||(state == start_task)) begin
  shifter_counter <= 4'h0;
 end
 else if((state == transmitting)&&(counter1 == 5'b11111)) begin
  shifter_counter <= shifter_counter + 1'b1;
 end
end

//state
always@(posedge clk, negedge rst_n)begin
 if(~rst_n) begin
  state <= idle;
 end
 else if((wrt)&&(state == idle))
  state <= start_task;
 else if((state == start_task )&&(time_out))
  state <= transmitting;
 else if ((state == transmitting)&&(shifter_counter == 4'b1111)&&(SCLK))
  state <= end_task;
 else if((state == end_task)&&(time_out))
  state <= idle;
end

//create SCLK
assign SCLK = counter1[4];

always@(posedge clk, negedge rst_n)begin
 if (~rst_n) begin
  	counter1 <= 5'b11111;
  end
  else if((state == start_task )&&(time_out)) begin
        counter1 <= 5'b0;
  end
  else if (state == transmitting) begin
  	counter1 <= counter1 + 1'b1;
  end
end

assign load = (state == start_task);
assign shift = ((state == transmitting)&&(counter1 == 5'b10010));
//MOSI and MISO
always@(posedge clk, negedge rst_n) begin
 if(~rst_n) 
  shifter_MOSI <= 16'b0; 
 else if(load)
  shifter_MOSI <= cmd;
 else if(shift) //shifter left
  shifter_MOSI <= {shifter_MOSI[14:0], 1'b0};
end

assign MOSI = shifter_MOSI[15];



always@(posedge clk, negedge rst_n) begin
 if(~rst_n) 
  shifter_MISO <= 16'b0;
 else if ((state == transmitting)&&(counter1 == 5'b01111)) 
  shifter_MISO <= {shifter_MISO[14:0], MISO}; 
end

//done and dataout
always@(posedge clk, negedge rst_n) begin
 if(~rst_n || wrt)
   done <= 1'b0;
 else if((state == end_task)&&(counter2 == 3'b100)) 
   done <= 1'b1;
end

assign rd_data = shifter_MISO;

endmodule