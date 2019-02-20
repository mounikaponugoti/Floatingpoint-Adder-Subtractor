module fp_controlpath(
// Testbench ----> Controlpath
			input logic clk, reset,
			input logic in_sel,				    // Select line to to do Addition/subtraction    0 - Addition, 	1 - Subtraction
			input logic rtaken, 				// Result is taken
			input logic iready,				    // Input is ready
// Datapath -----> Controlpath
			input logic A_zero, B_zero,			// A is Zero , B is Zero
			input logic A_normal, B_normal,		// A is Normal, B is normal
			input logic A_Inf, B_Inf,			// A is infinite, B is infinite
			input logic A_Subnormal, B_Subnormal,// A is Subnormal, B is subnormal
			input logic A_NaN, B_NaN,			// A is NaN ( not a number) , B is NaN
			input logic sub_zero,				// Subtraction is zero		
			input logic Add_23, Add_24,			// Add[23] , Add[24] (Checking this bits to normalize the output)
			input logic Eout_1, Eout_255,		// Eout is 1 , Eout is 255 (Checking underflow and overflow in exponents)	
			input logic Sub_23, Sub_24, 		// Sub[23] , Sub[24] (Checking this bits to normalize the output and to deside the output sign)
			input logic EA_eq_EB,				// Checking both inputs exponents are equal or not
			input logic As_xor_Bs,				// Doing xor operation between Input A sign and Input B sign
			input logic Add_done, Sub_done,		// Addition done , Subtraction done
// Controlpath -----> Datapath
			output reg [2:0] out_sel,			// output selection line
			output logic  [2:0] Eout_sel,		// output exponential selection line
			output logic outs_sel,				// output sign selection line
			output logic ma_sel, mb_sel,		// Input A, Input B implicit selection lines
			output logic Eout_en,				// Output exponential enable
			output logic outs_en,				// Output sign selection enable
			output logic [1:0] Sub_sel,			// Subtraction selection
			output logic Add_sel,				// Addition selection
			output logic A_en, B_en, out_en,	// Mantissa A, Mantissa B, output enables
			output logic Add_en, Sub_en,		// Addition enable, Subtraction enable
// Controlpath -----> Testbench			
			output logic uready, 				// Unit is ready
			output logic rready,				// Result is ready
			output reg NaN_out, 				// Output is NaN(Not a Number)
			output reg Inf_out,				    // Output is infinite
			output reg Error_out				// Error in inputs
     );

reg [2:0] state;
logic [2:0] state_next;
logic NaN,NaN_en,mux_sel_en,Inf, Inf_en,Error_en,Error;
logic [2:0] mux_out_sel;

always @(posedge clk, posedge reset) // state register
  begin
    if (reset)      
       state = 0;
    else 
       state = state_next;
  end

always @(posedge clk)
   begin 
     if(reset)
         NaN_out = 0;
     else if(NaN_en)  
         NaN_out = NaN; 
     else 
        NaN_out = NaN_out; 
  end 

always @(posedge clk)
   begin 
      if(reset) 
        Inf_out = 0; 
      else if(Inf_en)  
        Inf_out = Inf; 
      else 
        Inf_out = Inf_out;
   end 

always @(posedge clk)
  begin 
     if(reset) 
         Error_out = 0; 
     else if(Error_en)  
         Error_out = Error; 
     else 
         Error_out = Error_out;
   end

always @(posedge clk)
  begin 
     if(reset) 
        out_sel = 0; 
     else if(mux_sel_en) 
        out_sel = mux_out_sel ;
     else 
        out_sel = out_sel;
  end 
parameter s0= 0;
parameter s1= 1;
parameter s2= 2;
parameter s3= 3;
parameter s4= 4;
parameter s5= 5;
parameter s6= 6;
parameter s7= 7;

always_comb
begin
case (state) 
s0: begin 
      if(reset) 									// Resetting
        begin
          state_next = s0;
          uready = 1'b0; rready = 1'b0;
          NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
          A_en = 1'b0; B_en = 1'b0; out_en = 1'b0;
          Eout_en = 1'b0;
          outs_en = 1'b0; outs_sel = 1'b0;
          ma_sel = 1'b0;  mb_sel = 1'b0; 
          Add_en = 1'b0;  Sub_en = 1'b0;
          NaN_en = 1'b0;  Inf_en = 1'b0; Error_en = 1'b0;
          mux_sel_en = 1'b0; mux_out_sel = 3'd0;
        end
     else
         begin										// Sending unit ready signal and waiting for inputs
          state_next = s1;
          uready = 1'b1; rready = 1'b0;
          NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
          A_en = 1'b0; B_en = 1'b0; out_en = 1'b1; 
          Eout_en = 1'b0;
          outs_en = 1'b1; outs_sel = 1'b0;
          ma_sel = 1'b0; mb_sel = 1'b0;
          Add_en = 1'b0; Sub_en = 1'b0;
          NaN_en = 1'b1; Inf_en = 1'b1; Error_en = 1'b1;
          mux_sel_en = 1'b1; mux_out_sel = 3'd0;
       end 
  end
s1: begin							
       if (!iready) 
         begin  
          state_next = s1;
          uready = 1'b1; rready = 1'b0;
          NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
          A_en = 1'b0; B_en = 1'b0; out_en = 1'b0;
          Eout_en = 1'b0; 
          outs_sel = 1'b0; outs_en = 1'b1;
          ma_sel = 1'b0; mb_sel = 1'b0;
          Add_en = 1'b0; Sub_en = 1'b0; 
          NaN_en = 1'b1; Inf_en = 1'b1; Error_en = 1'b1;
          mux_sel_en = 1'b1; mux_out_sel = 3'd0;
         end
      else 
        begin 
          state_next = s2; 								// Reading inputs
          uready = 1'b0; rready = 1'b0; 
          NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
          A_en = 1'b1; B_en = 1'b1; out_en = 1'b1; 
          Eout_en = 1'b1; Eout_sel = 3'd1;
          outs_sel = 1'b0; outs_en = 1'b1;
          ma_sel = 1'b0; mb_sel = 1'b0;
          Add_en = 1'b0; Sub_en = 1'b0;
          NaN_en = 1'b0; Inf_en = 1'b0; Error_en = 1'b0;
          mux_sel_en = 1'b1; mux_out_sel = 1'b0; 
        end
  end
s2: begin
      if(A_NaN ||  B_NaN || (B_Inf && A_Inf))  		  // If any input is NaN or both inputs are Infinite, setting output as NaN
        begin	
          state_next = s6; 
	  uready = 1'b0; rready = 1'b0; 
	  NaN = 1'b1; Inf = 1'b0; Error = 1'b0;
          A_en = 1'b0; B_en = 1'b0; out_en = 1'b1; 
	  Eout_en = 1'b0;
          outs_sel = 1'b0; outs_en = 1'b0;
          ma_sel = 1'b0; mb_sel = 1'b0; 
          Add_en = 1'b0; Sub_en = 1'b0;
          NaN_en = 1'b1; Inf_en = 1'b0; Error_en = 1'b0;
          mux_sel_en = 1'b1; mux_out_sel = 3'd0; 
         end
     else if( A_Inf || B_Inf)						 // If any input is Infinite , setting output as Infinite
         begin
          state_next = s7; 
          uready=1'b0;rready = 1'b0; 
	  NaN = 1'b0; Inf = 1'b1; Error = 1'b0;
	  A_en = 1'b0; B_en = 1'b0; out_en = 1'b1; 
	  Eout_en=1'b0; 
	  outs_sel = 1'b0; outs_en = 1'b0;
	  ma_sel = 1'b0; mb_sel = 1'b0;
	  Add_en = 1'b0; Sub_en = 1'b0;
	  NaN_en = 1'b0; Inf_en = 1'b1; Error_en = 1'b0;
	  mux_sel_en = 1'b1; mux_out_sel = 3'd0; 
        end
     else if( B_zero && A_zero)						// If both inputs are zero output is zero
        begin
          state_next = s6; 
	  uready = 1'b0;rready = 1'b0; 
	  NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
	  A_en = 1'b0; B_en = 1'b0; out_en = 1'b1;
	  Eout_en=1'b0; 
	  outs_sel = 1'b0; outs_en = 1'b0;
	  ma_sel = 1'b0; mb_sel = 1'b0;
	  Add_en = 1'b0; Sub_en = 1'b0;
	  Inf_en = 1'b0; NaN_en = 1'b0;  Error_en = 1'b0;
	  mux_out_sel = 3'd0; mux_sel_en = 1'b1;
        end
     else if(B_zero) 								// If input B is zero, for any operation output is B
        begin
          state_next = s6; 
          A_en = 1'b0; B_en = 1'b0; out_en = 1'b1; 
 	  uready = 1'b0;rready = 1'b0; 
	  NaN = 1'b1; Inf = 1'b0; Error = 1'b0;
          Eout_en = 1'b0;  
	  outs_sel = 1'b0; outs_en = 1'b0; 
	  ma_sel = 1'b0; mb_sel = 1'b0; 
	  Add_en = 1'b0; Sub_en = 1'b0;
	  Inf_en = 1'b0; NaN_en = 1'b0; Error_en = 1'b0;
	  mux_out_sel = 3'd1; mux_sel_en = 1'b1;
         end
     else if(A_zero) 									
       begin 
          if(!in_sel) 									// If input A is zero, for addition Output is B 
            begin 
             state_next = s6;
	     uready = 1'b0; rready = 1'b0; 
	     NaN = 1'b0; Inf=1'b0; Error = 1'b0;
             A_en = 1'b0; B_en = 1'b0; out_en = 1'b1;
	     Eout_en=1'b0;
	     outs_sel = 1'b0; outs_en = 1'b0;
             ma_sel = 1'b0; mb_sel = 1'b0;
             Add_en = 1'b0; Sub_en = 1'b0;
             Inf_en = 1'b0; NaN_en = 1'b0; Error_en = 1'b0;
             mux_out_sel = 3'd2; mux_sel_en = 1'b1;
 	    end
          else if(in_sel)								// If input A is zero, for Subtraction output is -B
            begin
             state_next = s6; 
	     uready = 1'b0; rready = 1'b0; 
	     NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
             A_en = 1'b0; B_en = 1'b0; out_en = 1'b1;  
	     Eout_en = 1'b0;
             outs_en = 1'b0; outs_sel = 1'b0;
	     ma_sel = 1'b0; mb_sel = 1'b0; 
	     Add_en = 1'b0; Sub_en = 1'b0;
	     Inf_en = 1'b0; NaN_en = 1'b0; Error_en = 1'b0;
	     mux_out_sel = 3'd3; mux_sel_en = 1'b1;
            end 
      end
    else if((A_normal&&B_normal) || (A_Subnormal&&B_Subnormal)) 
        begin
           if(EA_eq_EB) 
              begin
        	if(As_xor_Bs~^in_sel)							// Addition
           	   begin  uready = 1'b0; rready = 1'b0; 
		    A_en = 1'b1; B_en = 1'b1; out_en = 1'b0;
                    NaN = 1'b0; Inf = 1'b0; Error = 1'b0; 
                    Eout_sel = 3'd1; Eout_en=1'b1;
		    outs_sel = 1'b0; outs_en = 1'b1; 
	 	    Inf_en = 1'b0; NaN_en = 1'b0; Error_en = 1'b0;
		    mux_sel_en = 1'b1; mux_out_sel = 3'd0;		
                       if(A_normal&& B_normal) 
                         begin 
			  state_next = s3; 
			  Add_sel = 1'd0;
			  ma_sel = 1'b1; mb_sel = 1'b1; 
			  Add_en = 1'b0; Sub_en = 1'b0;
                         end
                       else if(A_Subnormal&& B_Subnormal)
                         begin 
			  state_next = s3;
                          Add_sel = 1'd0;  
			  ma_sel = 1'b0; mb_sel = 1'b0; 
			  Add_en = 1'b0; Sub_en = 1'b0;
                         end 
                     end
                 else   								// Subtraction (using 2's complement)
                  begin     
		  A_en = 1'b1; B_en = 1'b1; out_en = 1'b0; 
		  NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
		  uready = 1'b0; rready = 1'b0; 
		  Eout_en = 1'b1; Eout_sel = 3'd1;
		  outs_en = 1'b1; outs_sel = 1'b0; 
		  Inf_en = 1'b0; NaN_en = 1'b0;Error_en = 1'b0;
		  mux_out_sel = 3'd0; mux_sel_en = 1'b1;
                     if(A_normal&& B_normal)  
                        begin 
			 state_next = s4; 
			 Sub_sel = 2'd1;
			 ma_sel = 1'b1; mb_sel = 1'b1; 
			 Add_en = 1'b0; Sub_en = 1'b0;
			end            
                     else if(A_Subnormal&& B_Subnormal)
                        begin 
			  state_next = s4;
			  Sub_sel = 2'd1;
			  ma_sel = 1'b0; mb_sel = 1'b0; 
			  Add_en = 1'b0; Sub_en=1'b0; 
                        end
                  end
              end 
           else 
		begin 
		  $display("Invalid Inputs ");
		  state_next = s6; 
		  Error_en = 1'b1;Error = 1'b1;
		  A_en = 1'b0; B_en = 1'b0; out_en = 1'b0;
		end
        end
    else 									// For invalid inputs
        begin 
          $display("Invalid Inputs ");
          state_next = s6;
	  Error_en = 1'b1; Error = 1'b1;
 	  A_en = 1'b0; B_en = 1'b0; out_en = 1'b0; 
	end
 end
s3: begin  
	  uready=1'b0; rready=1'b0;
	  NaN = 1'b0; Inf = 1'b0; Error = 1'b0;
	  Inf_en = 1'b0; NaN_en = 1'b0; Error_en = 1'b0;
  	  Add_en = 1'b1; Sub_en = 1'b0; 
	  Add_sel = 1'd0; 
	  A_en = 1'b1; B_en = 1'b1; out_en = 1'b0;
	  Eout_sel = 3'd1; Eout_en=1'b1;
	  outs_en = 1'b1; mux_sel_en = 1'b1;
              if(A_normal&& B_normal)
                  begin 
		     ma_sel = 1'b1; mb_sel = 1'b1;
                         if(Add_done)            
                             begin     
                                if(Add_24) 					// Normalizing Addition output for Normal numbers
                                   begin 
				    Eout_sel = 3'd3; Eout_en=1'b1;
				    Add_sel = 1'd1; 
                                    state_next = s5; mux_out_sel = 3'd0;
                                   end 
                                 else  
				   begin 
				    Eout_en=1'b0;
				    Add_en = 1'b0;
				    mux_out_sel = 3'd4; mux_sel_en = 1'b1;
				    state_next = s6; 
				  end
                              end  
                         else state_next = s3;
                  end
              else if(A_Subnormal&& B_Subnormal)				 // Normalizing Addition output for Sub Normal numbers
                  begin  
			ma_sel = 1'b0; mb_sel = 1'b0;
                           if(Add_done) 
                              begin  
				  if(Add_23)
                         	    begin
				     Eout_en=1'b1; Eout_sel = 3'd2;
                       		     state_next = s6; 
				     mux_out_sel = 3'd4; mux_sel_en = 1'b1;
                                    end 
                                  else 
                                    begin 
				     Eout_en=1'b0;
				     state_next = s6; 
				     mux_out_sel = 3'd4; mux_sel_en = 1'b1;
				    end 
                               end 
                          else state_next = s3;
                    end
     end
s4: begin 
	    uready = 1'b0; rready = 1'b0;
	    NaN = 1'b0; Inf = 1'b0; 
	    Add_en = 1'b0;Sub_en = 1'b1;
	    Sub_sel = 2'd1; 
	    A_en = 1'b1; B_en = 1'b1;out_en = 1'b0;
	    Eout_sel = 3'd1;Eout_en = 1'b0;
	    outs_en = 1'b0; Error_en = 1'b0;
                if(A_normal&& B_normal) 
                   begin
		     ma_sel = 1'b1;mb_sel = 1'b1;
                        if(Sub_done) 
                            begin 
			      if(sub_zero) 							// Checking  Subtraction is zero or not  
                                 begin
                    		     state_next = s6;
				  end 
                               else 
                                 begin 
                                    if(Sub_24) 			// Check for carry, if carry is 1 output is +ve else -ve
				        begin 
				 	 outs_sel = 1'b0;outs_en = 1'b1; 
				 	 mux_out_sel = 3'd0; mux_sel_en = 1'b1;
				 	 state_next = s5;
				       end 
			            else 
					begin 
				 	  outs_en = 1'b1; outs_sel = 1'b1;
					  Sub_sel = 2'd2;
				  	  state_next = s5;
				  	  mux_sel_en = 1'b1; mux_out_sel = 3'd0;
				         end 
                                 end 
                            end
                      else state_next = s4;
                   end
          else if(A_Subnormal&& B_Subnormal)
                begin  
		    ma_sel = 1'b0;mb_sel = 1'b0;
             		if(Sub_done)  
               		    begin    
                	      if(sub_zero)  				// Check  Subtraction is zero or not  
                 		  begin
                                    state_next = s6;
                                   end 
                              else
                      		 begin 
				    if(Sub_24) 							// Check for carry, if carry is 1 output is +ve else -ve
					 begin 
					   outs_sel = 1'b0;outs_en = 1'b1; 
					   mux_out_sel = 3'd0;mux_sel_en = 1'b0;
					   state_next = s5;
					 end 
                                     else
					  begin 
					    state_next = s5; 
					    Sub_sel = 2'd2;
					    outs_en = 1'b1;outs_sel = 1'b1;
					    mux_out_sel = 3'd0; mux_sel_en = 1'b0; 
					  end 
                   		 end
                	    end
                       else  state_next = s4;
                  end
 end 
s5: begin  
	 	 uready = 1'b0; rready = 1'b0;
		 A_en = 1'b0; B_en = 1'b0;out_en = 1'b0; 
		 Add_en = 1'b0; 
		 NaN_en = 1'b0; Inf_en = 1'b0; Error_en = 1'b0;
		 outs_en = 1'b0;
           if(Add_done) 
              begin
                     if(Eout_255) 					// Check exponent overflow in case of addition
                        begin 
			 NaN = 1'b1; Sub_en = 1'b0;
			 Inf_en = 1'b0; NaN_en = 1'b1; 
			 mux_out_sel = 3'd0; mux_sel_en = 1'b1;
			 state_next = s6;
			end 
                     else
			begin 
			  Add_sel = 2'd3; Sub_en = 1'b0;
			  state_next = s6;
			  mux_out_sel = 3'd4; mux_sel_en = 1'b1;  
			  Eout_en = 1'b0;
			end 
               end
          if(Sub_done) 
              begin 
                 if(A_normal&& B_normal) 
                     begin 
			 mux_sel_en = 1'b0;						// Normalizing subtraction output
                           if(Sub_23) 
                              begin 
				  state_next = s6;
				  mux_out_sel = 3'd5;mux_sel_en = 1'b1;
				  Eout_en = 1'b0; 
				  Sub_en = 1'b0;
				end 
                           else 
		   	      begin 
				Sub_sel = 2'd3;
				Eout_sel = 3'd4; Eout_en = 1'b1;
				Add_en = 1'b0; Sub_en = 1'b1;
			 	  if(Eout_1)						// Check for exponent underflow in case of subtraction
			   	      begin 
					state_next = s6; 
					mux_out_sel = 3'd5;mux_sel_en = 1'b1;
					Eout_sel = 1'b0;Eout_en = 1'b1;
					Sub_en = 1'b0;
			     	       end 
			  	 else state_next = s5;
                     	      end
                     end 
        	 else  if(A_Subnormal&& B_Subnormal)
                      begin 
			Sub_en = 1'b0; 
			mux_out_sel = 3'd5; mux_sel_en = 1'b1;
			state_next = s6; 
		      end
                 end
      end
s6: begin 										    // Set result is ready
          state_next = s7;
          uready=1'b0; rready=1'b1;
	  A_en = 1'b0; B_en = 1'b0; out_en = 1'b1;
	  Eout_en = 1'b0; outs_en = 1'b0; 
	  Add_en = 1'b0; Sub_en = 1'b0;
          NaN_en = 1'b0; Inf_en = 1'b0;Error_en = 1'b0;
	  mux_sel_en = 1'b0; 
     end 
s7: begin 
       if (rtaken)									// if result is taken waiting for next set of inputs
          begin 
       	    state_next = s0; 
	    uready = 1'b0; rready = 1'b0; 
       	    A_en = 1'b0; B_en = 1'b0; out_en = 1'b0;
            outs_en = 1'b1; outs_sel= 1'b0; 
            Add_en = 1'b0; Sub_en = 1'b0;
            NaN_en = 1'b0; Inf_en = 1'b0; Error_en = 1'b0;
	    mux_out_sel = 3'd0; mux_sel_en = 1'b1;
          end
       else 
           begin
            state_next = s7; 
	    uready = 1'b0; rready=1'b1; 
  	    A_en = 1'b0; B_en = 1'b0; out_en = 1'b0;
            Add_en = 1'b0; Sub_en = 1'b0;
  	    NaN_en = 1'b0; Inf_en = 1'b0; Error_en = 1'b0;
	    Eout_en = 1'b0; outs_en = 1'b0;
	    mux_sel_en = 1'b0;
         end 
   end
endcase	  
end
endmodule
       
 
