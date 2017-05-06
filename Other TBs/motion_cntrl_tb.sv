module motion_cntrl_tb();

reg clk;
reg rst_n;		
reg go;			//go signal
reg cnv_cmplt;		//indicate conversion complete
reg [11:0] A2D_res;	//A2D conversion result

wire start_conv;	//start conversion signal
wire [2:0] chnnl;	//channels for conversion 
wire IR_in_en;		//inner IR sensors
wire IR_mid_en;		//middle IR sensors
wire IR_out_en;		//outer IR sensors
wire [7:0] LEDs;	
wire [10:0] lft;
wire [10:0] rht;	//left and right monitor

/* Instantiate motion controller */
motion_cntrl iDUT(.clk(clk),.rst_n(rst_n),.go(go),.start_conv(start_conv),.chnnl(chnnl),.cnv_cmplt(cnv_cmplt), .A2D_res(A2D_res),.IR_in_en(IR_in_en),.IR_mid_en(IR_mid_en),.IR_out_en(IR_out_en), .LEDs(LEDs),.lft(lft),.rht(rht));

initial begin

    //reset
    cnv_cmplt = 0;
    rst_n = 0;
    #20;
    rst_n = 1; //deassert reset
    #20;

    //Inner IR sensor
    go = 1;
    A2D_res = 12'h123;
    #100000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100;
    A2D_res = 12'h100;
    #10000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100;
    
    //Middle IR sensor
    A2D_res = 12'h456;
    #100000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100;
    A2D_res = 12'h200;
    #10000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100;

    //Outer IR sensor
    A2D_res = 12'h789;
    #100000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100;
    A2D_res = 12'h300;
    #10000;
    cnv_cmplt = 1;
    #20;
    cnv_cmplt = 0;
    #100000;

    $stop;
    
end

//clock period = 10
initial clk = 0;
always #5 clk = ~clk;

endmodule

