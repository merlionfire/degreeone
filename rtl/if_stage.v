`default_nettype none 


module if_stage (
   
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // instruction rom interface 
   input  wire  [31:0]  pc,
   output reg   [31:0]  instr_r,
   output reg   [31:0]  pc_plus_1_if_r,

   // interface with pc_gen 
   output wire  [31:0]   pc_plus_1_if, 
   
   // interface with control 
   input  wire          stall_id,
   input  wire          flush_id
);

   wire  [31:0]   instr; 

   instr_rom  instr_rom_inst (
      .pc     ( pc     ), //i
      .instr  ( instr  )  //o
   );

   always @(posedge clk ) begin 
      if (rst | flush_id ) begin 
         instr_r  <= 'h0 ;   // inset NOP instruction 
      end else begin 
         if ( ~ stall_id ) begin  
            instr_r  <= instr ; 
         end
      end 
   end 

   assign pc_plus_1_if   =  pc + 4'h4 ; 

   always @(posedge clk ) begin 
      if (  rst  ) begin 
        pc_plus_1_if_r <= 'h0 ; 
      end else begin 
         if ( ~stall_id ) begin 
            pc_plus_1_if_r <= pc_plus_1_if ; 
         end
      end 
   end 

endmodule 
