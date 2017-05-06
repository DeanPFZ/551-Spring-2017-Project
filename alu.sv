module alu(Accum, Pcomp, Pterm, Fwd, A2D_res, Error, Intgrl,
			Icomp, Iterm, src1sel, src0sel, multiply, sub,
			mult2, mult4, saturate, dst);
			
	
   //ALU Input port definitions
   input [15:0] Accum, Pcomp;
   input unsigned [13:0] Pterm;
   input unsigned [11:0] Fwd, A2D_res;
   input signed [11:0] Error, Intgrl, Icomp, Iterm;
   input [2:0] 	       src1sel, src0sel;
   input 	       multiply, sub, mult2, mult4, saturate;
   
   //ALU output data 
   output [15:0]       dst;
   
   wire signed [29:0]  MulOut;
   wire [15:0] 	       src1, src0_initial, src0_mul, src0, AluOut, AluOutSat, MulSat;
   wire signed [14:0]  mulsrc1, mulsrc0;
   
   //ALU Src1 data
   assign src1 = ((src1sel == 3'b000) ? Accum :
		  (src1sel == 3'b001) ? {4'b0000,Iterm} :
		  (src1sel == 3'b010) ? {{4{Error[11]}},Error} :
		  (src1sel == 3'b011) ? {{8{Error[11]}},Error[11:4]} :
		  (src1sel == 3'b100) ? {4'b0000,Fwd} : 16'b0);
   
   //ALU Src0 before mul,sub control 
   
   assign src0_initial = ((src0sel == 3'b000) ? {4'b0000, A2D_res} :
			  (src0sel == 3'b001) ? {{4{Intgrl[11]}},Intgrl} :
			  (src0sel == 3'b010) ? {{4{Icomp[11]}},Icomp} :
			  (src0sel == 3'b011) ? Pcomp :
			  (src0sel == 3'b100) ? {2'b00, Pterm} : 16'b0);
   
   //ALU Src0 data after mulitply
   
   assign src0_mul = ((mult2) ? (src0_initial << 1) :
		      (mult4) ? (src0_initial << 2) : src0_initial);
   
   //ALU final Src0 data
   
   assign src0 = ((sub) ? (~src0_mul) : src0_mul);
   
   //ALU result
   assign AluOut = src1 + src0 + sub;
   
   //ALU saturate
   assign AluOutSat = ((saturate) ? ((AluOut[15]) ? ((&AluOut[14:11] == 1'b0 ? 16'hF800: AluOut)) :
				     ((AluOut > 16'h07FF) ? 16'h07FF : AluOut)) : AluOut); // FIXME
   
   //Multiply Output
   assign mulsrc1 = src1[14:0];
   assign mulsrc0 = src0[14:0];
   assign MulOut = mulsrc1 * mulsrc0;
   assign MulSat = ((~MulOut[29] ? ((MulOut[28:26] > 4'b0) ? 16'h3FFF: MulOut[27:12]) : 
	             (&MulOut[28:26] == 1'b0 ? 16'hC000 : MulOut[27:12]))); //FIXME
   
   //Final ALU Output
   assign dst = (multiply) ? MulSat : AluOutSat;
   
   
endmodule
