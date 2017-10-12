module reg_file (
   // clock and reset    
   input    wire         clk,
   input    wire         rst,
   //  register read interface
   input    wire [4:0]   reg_ra_a,   
   input    wire [4:0]   reg_ra_b,   
   output   wire [31:0]  reg_rd_a,  
   output   wire [31:0]  reg_rd_b,  
   //  register write interface 
   input    wire         reg_w_en,
   input    wire [4:0]   reg_wa_c,
   input    wire [31:0]  reg_wd_c  
); 

   reg   [31:0]  register  [1:31] ; 

   assign reg_rd_a =  |reg_ra_a ? register[reg_ra_a] : 'b0; 
   assign reg_rd_b =  |reg_ra_b ? register[reg_ra_b] : 'b0; 

   always @( negedge clk ) begin 
      if ( rst ) begin 
         integer i  ; 
         for ( i = 1 ;  i <= 31 ; i = i + 1 ) begin 
            register[i] <= 'b0; 
         end    
      end else if ( reg_w_en & ( |reg_wa_c ) ) begin 
            register[reg_wa_c] <= reg_wd_c ; 
      end 
   end

endmodule 

