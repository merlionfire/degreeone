`default_nettype none
module mem_stage(
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // Interface with exec stage
   input  wire  [31:0]  exec_out_ex_r,        
   input  wire  [31:0]  reg_b_ex_r,       
   input  wire  [4:0]   reg_wr_addr_ex_r,
   //
   // Interface with wb stage
   output reg   [31:0]  exec_out_mm_r,        
   output reg   [31:0]  mem_out_mm_r,        
   output reg   [4:0]   reg_wr_addr_mm_r,
  
   // Interface with id stage ( internal forewarding ) 
   
   // Interface with control
   input  wire          mem_wr_en_mm,
   output wire  [4:0]   reg_wr_addr_mm

);
 
   wire [31:0]   data_addr; 
   wire [31:0]   data_in; 
   wire [31:0]   data_out; 

   data_ram  data_ram_inst (
      .clk       ( clk           ), //i
      .data_w_en ( mem_wr_en_mm  ), //i
      .data_addr ( data_addr     ), //i
      .data_in   ( data_in       ), //i
      .data_out  ( data_out      )  //o
   );

   // ------ Data memory interface --------------------------
   //
   assign data_addr  =  exec_out_ex_r ; 
   assign data_in    =  reg_b_ex_r;  

  
   always @( posedge clk ) begin 
      if ( rst ) begin 
        reg_wr_addr_mm_r   <= 'h0; 
        exec_out_mm_r      <= 'h0;
        mem_out_mm_r       <= 'h0; 
      end else begin 
        reg_wr_addr_mm_r   <= reg_wr_addr_ex_r ; 
        exec_out_mm_r      <= exec_out_ex_r;
        mem_out_mm_r       <= data_out;
      end
   end

   assign   reg_wr_addr_mm =  reg_wr_addr_ex_r ; 

endmodule 
