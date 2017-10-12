module data_ram  (
   input  wire           clk,
   input  wire           data_w_en,
   input  wire  [31:0]   data_addr,
   input  wire  [31:0]   data_in,
   output wire  [31:0]   data_out
);       

   parameter   DEPTH_NUM_BITS_WIDTH = 7 ; 
   localparam  DEPTH_NUM       = 2 ** DEPTH_NUM_BITS_WIDTH   ; 

   reg   [31:0]   data_mem [0: DEPTH_NUM-1] ; 

   always @( posedge clk ) begin 
      if ( data_w_en ) begin 
         data_mem[ data_addr[DEPTH_NUM_BITS_WIDTH-1:2] ] <= data_in ;  
      end
   end 

   assign data_out = data_mem[ data_addr[DEPTH_NUM_BITS_WIDTH-1:2] ] ; 
   
   integer i ; 
   initial begin 
      for ( i = 0 ; i < DEPTH_NUM ; i = i + 1 ) 
         data_mem[i] =  0 ; 
   end   

endmodule    
   


