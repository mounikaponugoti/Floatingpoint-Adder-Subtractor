// Floating-point adder and subtractor top module
module fp_top( 
		input  clk, reset, 
		input  in_sel,					 // Input to select addition or subtraction (0 - addition , 1- subtraction)
		input  rtaken, 					 // Sent by interfaced module after taking output
		input  logic iready,			 // To indicates readiness of inputs
		input  logic [31:0] opA, opB,    // Input operands
		output logic [31:0] rout, 	     // Output
		output reg NaN_out, Inf_out,	 // Special output signals to indicate output is Not a Number (NaN) Or infinity (Inf)
 		output reg Error_out,			 // If inputs are not valid this signal asserted
		output logic rready, uready		 // Output signals to indicate unit is ready and output is ready
	 );			

logic  [2:0] out_sel,Eout_sel;
logic outs_sel, ma_sel,mb_sel;
logic [1:0] Sub_sel;
logic  Add_sel;
logic A_zero, B_zero,A_normal,B_normal,A_Inf, B_Inf, A_Subnormal, B_Subnormal, A_NaN, B_NaN, As_xor_Bs,sub_zero,Add_done, Sub_done, EA_eq_EB ;
logic A_en, B_en,Add_en, Sub_en,out_en,Add_23,Add_24,Eout_1,Eout_255,Sub_23,Sub_24,Eout_en,outs_en;

fp_datapath datapath(   .clk (clk), .reset(reset), .in_A(opA), .in_B(opB), .rout(rout), 
                        .out_sel(out_sel) , .A_en(A_en), .B_en(B_en), .out_en(out_en),
                        .Add_done(Add_done),  .Add_en(Add_en), .Sub_en(Sub_en), 
                        .Sub_done(Sub_done), .A_zero(A_zero), .B_zero(B_zero), .A_normal(A_normal),
                        .B_normal(B_normal), .A_Inf(A_Inf), .B_Inf(B_Inf), .A_Subnormal(A_Subnormal), 
                        .B_Subnormal(B_Subnormal), .A_NaN(A_NaN), .B_NaN(B_NaN),.sub_zero(sub_zero), 
                        .As_xor_Bs(As_xor_Bs), .Eout_sel(Eout_sel),.outs_sel(outs_sel), .Add_sel(Add_sel),
                        .Sub_sel(Sub_sel),.Add_23(Add_23), .Add_24(Add_24), .Eout_1(Eout_1), .Eout_255(Eout_255), 
                        .Sub_23(Sub_23), .Sub_24(Sub_24), .ma_sel(ma_sel), .mb_sel(mb_sel), .Eout_en(Eout_en) , 
                        .outs_en(outs_en), .EA_eq_EB( EA_eq_EB )
                    );

fp_controlpath controlpath( .clk (clk), .reset(reset),.in_sel(in_sel),.rtaken(rtaken),.iready(iready), 
                            .A_zero(A_zero), .B_zero(B_zero), .A_normal(A_normal), .B_normal(B_normal),
                            .A_Inf(A_Inf), .B_Inf(B_Inf), .A_Subnormal(A_Subnormal), .B_Subnormal(B_Subnormal),
                            .A_NaN(A_NaN), .B_NaN(B_NaN),.sub_zero(sub_zero), .As_xor_Bs(As_xor_Bs), .out_sel(out_sel),
                            .A_en(A_en), .B_en(B_en), .out_en(out_en), .Add_done(Add_done),.Add_en(Add_en),
                            .Sub_en(Sub_en), .Sub_done(Sub_done), .uready(uready), .rready(rready),.NaN_out(NaN_out), 
                            .Inf_out(Inf_out),  .Eout_sel(Eout_sel),.outs_sel(outs_sel), .Add_sel(Add_sel),.Sub_sel(Sub_sel),
                            .Add_23(Add_23), .Add_24(Add_24), .Eout_1(Eout_1), .Eout_255(Eout_255), .Sub_23(Sub_23), .Sub_24(Sub_24),
                            .ma_sel(ma_sel),.mb_sel(mb_sel), .Eout_en(Eout_en) , .outs_en(outs_en), .EA_eq_EB( EA_eq_EB ) , .Error_out(Error_out)
                            );

endmodule
