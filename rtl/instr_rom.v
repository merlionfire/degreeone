module instr_rom (
   input  wire  [31:0]   pc,
   output wire  [31:0]   instr
);       

   parameter   INSTR_NUM_BITS_WIDTH = 20 ; 
   localparam  INSTR_NUM       = 2 ** INSTR_NUM_BITS_WIDTH   ; 
   reg   [31:0]   instr_mem [0: INSTR_NUM-1] ; 
   
   initial begin 
      // Test test.asm
      //$readmemh("../asm/final.mif", instr_mem, 0, 40  ) ; 
      // Test exception.asm   
      $readmemh("../fw/final.mif", instr_mem ) ; 
      $display("Memory intialization is completed" ) ; 
   end 

   assign   instr = instr_mem[ pc[INSTR_NUM_BITS_WIDTH+1:2] ] ; 


endmodule    
   


