module fp_datapath( 
// testbench -----> Datapath
			input logic  clk, reset,
			input logic [31:0] in_A, in_B,      // Input A, Input B
 // Controlpath -----> Datapath 
			input reg [2:0] out_sel,            // To select output
			input logic [2:0] Eout_sel,			// To select output exponential
			input logic outs_sel, 				// To select output sign
			input logic ma_sel, mb_sel,			// To select implicit bit
			input logic [1:0] Sub_sel,			// Selection line to Mux to select Subtraction or Shift or Complement
			input logic  Add_sel,				// Selection line to Mux to select Addition or Shift
			input logic A_en, B_en,out_en,		// Enable signals to load input registers and output register
			input logic Add_en, Sub_en,			// Enable signals to load Add and Subtract registers
			input logic Eout_en,				// Enable signal to load Exponential register
			input logic outs_en,				// Enable signal to load output sign
// Datapath -----> testbench
			output logic [31:0] rout,			// Final output
// Datapath ----> controlpath
			output logic A_zero, B_zero,  		// Checking for Special cases in Input A and Input B
			output logic A_normal,B_normal,
			output logic A_Inf,B_Inf, 
			output logic A_Subnormal, B_Subnormal,
			output logic A_NaN, B_NaN,
			output logic Add_done, Sub_done,	// Used to get correct Addition/Subtraction values  (because may add before adding implicit bit that doesn't require)
			output logic sub_zero,				// Used to check output of subtraction if it is zero to skip shifting 
			output logic EA_eq_EB,				// To check given inputs having equal exponentials or not (because this unit supports inputs with equal exponentials only)
			output logic As_xor_Bs, 			// Used to take decision on operation and output sign
			output logic Add_23, Add_24,		// Used to check overflows and to normalize output
			output logic Eout_1, Eout_255,		// Used to check exponential underflow and overflow respectively
			output logic Sub_23, Sub_24 		// Used to check output sign (i.e if input A < input B) and to normalize the output
               );

reg [23:0] MA, MB;   
logic [23:0]Mb; 
logic [24:0] Add_mux_out,Sub_mux_out;
logic [24:0] MA_mux_out,MB_mux_out;
reg [24:0] Add,Sub;
reg [7:0] Eout;
logic [7:0] Emux_out;
logic [7:0] EA,EB;
logic As, Bs;
reg outs; 
logic [31:0] mux_out;
logic outs_mux_out;

always@(posedge clk) // register for input A
  begin 
      if(reset) 
          begin  
            MA = 0;
            EA = 0; 
            As = 0;
          end    
      else if (A_en)
          begin 
            MA = MA_mux_out;
            EA = in_A[30:23]; 
            As = in_A[31]; 
          end
      else  MA =  MA;
  end

always@(posedge clk) // Register for input B
  begin 
     if(reset) 
        begin 
          MB = 0; 
          EB = 0; 
          Bs = 0;
        end 
     else if (B_en)
         begin 
           MB = MB_mux_out; 
           EB = in_B[30:23]; 
           Bs = in_B[31];
         end
     else MB =  MB;
  end

always@(*) // Output register
   begin 
     if(reset) 
         rout = 0;  
     else if (out_en)
         rout = mux_out; 
   end

always@(*)  // Check status of input A
   begin
     if(EA == 0 && MA == 0)
          A_zero = 1'b1; 
     else A_zero = 1'b0;
  
     if ( EA==0 && MA> 0)
          A_Subnormal = 1'b1; 
     else A_Subnormal = 1'b0;

     if ( EA > 0 && EA <255 && MA >= 0)
          A_normal = 1'b1;  
     else A_normal = 1'b0;
  
     if(EA==255 && MA==0)
          A_Inf = 1'b1;  
     else A_Inf = 1'b0;

     if(EA==255 && MA>0)
          A_NaN = 1'b1;
     else A_NaN = 1'b0; 
  end

always@(*)  // Check status of input A
   begin
    if(EB == 0 && MB == 0)
         B_zero = 1'b1; 
    else B_zero = 1'b0;

    if ( EB==0 && MB> 0)
         B_Subnormal = 1'b1;
    else B_Subnormal = 1'b0;

    if ( EB > 0 && EB <255 && MB >= 0)
         B_normal = 1'b1; 
    else B_normal = 1'b0;

    if(EB==255 && MB==0)
         B_Inf = 1'b1;
    else B_Inf = 1'b0;

    if(EB==255 && MB>0)
         B_NaN = 1'b1;
    else B_NaN = 1'b0; 
  end

always@(posedge clk) // add register
   begin 
     if(reset) 
         begin 
          Add = 0;  
          Add_done = 1'b0; 
         end
     else if(Add_en) 
         begin  
          Add = Add_mux_out;
          Add_done = 1'b1;
         end
     else Add = Add;
  end

always@(posedge clk)  // Register to store subtraction output
  begin 
     if(reset) 
        begin 
          Sub = 0;
          Sub_done = 1'b0;
        end
    else if(Sub_en)  
        begin  
          Sub = Sub_mux_out; 
          Sub_done = 1'b1; 
        end
    else   Sub =  Sub;
  end

always@(posedge clk)   // Register for output sign
  begin 
    if(reset)  
         outs=0;
    else if(outs_en)   
         outs =  outs_mux_out; 
    else outs = outs; 
  end

always@(posedge clk)   // Register for output exponent
  begin 
     if(reset)
        Eout =0;  
     else if(Eout_en)
        Eout = Emux_out; 
     else  Eout = Eout;
  end

assign As_xor_Bs = (As^Bs);    // sign logic used to select output sign and to select Addition or subtraction
assign Mb = ~MB;		
assign sub_zero = (Sub[23:0]==0);  
assign Add_23 = (Add[23]==1);	
assign Add_24 = (Add[24]==1);
assign Eout_255 = (Eout==255);
assign Eout_1 = (Eout==1);
assign Sub_23 = (Sub[23]==1);
assign Sub_24 = (Sub[24]==1);
assign EA_eq_EB = (EA == EB);

always@(*)   // Mux to select implicit bit for Input B
    begin 
	if(mb_sel==0)  
		MB_mux_out =in_B[22:0];
	else if(mb_sel==1)  
		MB_mux_out = {1'b1,in_B[22:0]};
    end

always@(*)   // Mux to select implicit bit for Input A
   begin 
	if(ma_sel==0)
		 MA_mux_out =in_A[22:0]; 
	else if(ma_sel==1) 
		 MA_mux_out = {1'b1,in_A[22:0]}; 
    end

always@(*)    // Mux to select sign of output
   begin 
	if(outs_sel==0)  
		outs_mux_out = As; 
	else if(outs_sel==1) 
		outs_mux_out = !As; 
   end
always@(*)   // Mux to select subtraction or shift or complement of subtraction if Input B is greater
   begin 
	if(Sub_sel==0)
                Sub_mux_out = 0;
	else if(Sub_sel==1) 
		Sub_mux_out = MA+Mb+1;
	else if(Sub_sel==2)  
		Sub_mux_out = {Sub[24], ~Sub[23:0]+1};
	else if(Sub_sel==3)  
		Sub_mux_out = {Sub[24],Sub[23:0] << 1};
   end

always@(*)  // Mux to select addition or shift
  begin 
	if(Add_sel==0)
		Add_mux_out =MA+MB; 
	else if(Add_sel==1) 
		 Add_mux_out =Add >>1;
   end

always@(*)     // Mux to select output exponent and to increase or decrease exponents
   begin 
	if(Eout_sel==0) 
		Emux_out = 0; 
	else if(Eout_sel==1) 
                Emux_out = EA;
	else if(Eout_sel==2) 
                Emux_out = 1;
	else if(Eout_sel==3) 
		Emux_out = Eout+1;
	else if(Eout_sel==4)
		Emux_out = Eout-1; 
    end

always@(*)        // Mux to select Which output to send to output Register
    begin 
	if(out_sel==0)
		 mux_out = 0;
	else if(out_sel==1)
		 mux_out = in_A;
	else if(out_sel==2) 
		 mux_out = in_B;
	else if(out_sel==3) 
		 mux_out = {!Bs,in_B[30:0]};
	else if(out_sel==4)
		  mux_out = {outs,Eout[7:0],Add[22:0]};
	else if(out_sel==5)
		  mux_out = {outs,Eout[7:0],Sub[22:0]};
   end
endmodule
