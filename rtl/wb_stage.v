`default_nettype none
module wb_stage(

   // Interface with mem stage
   input wire   [31:0]  exec_out_mm_r,        
   input wire   [31:0]  mem_out_mm_r,        
   input wire   [4:0]   reg_wr_addr_mm_r,

   // Interface with registers 
   output wire  [4:0]   reg_wr_addr_wb,
   output reg   [31:0]  reg_wr_data_wb,
   //
   // Interface with control 
   input  wire          lw_sel_wb
);


   // reg_wa_c : 
   //    rt    -- addi/andi/ori/xori 
   //          -- lw  
   //          -- lui  
   //    31    -- jal       
   //    rd    -- other

   // reg_wd_c : 
   //    data_ram_data_out    -- lw          
   //    plus+2               -- jal                     
   //    alu_result           -- other 
   /*    
   assign   reg_wd_c =  jal_sel  ?  pc_plus_2   :
                        lw_sel   ?  data_out    :  alu_result ; 
   */
   always @(*) begin 
      if ( lw_sel_wb ) begin
         reg_wr_data_wb =  mem_out_mm_r;
      end else begin 
         reg_wr_data_wb =  exec_out_mm_r ; 
      end
   end

   assign   reg_wr_addr_wb =  reg_wr_addr_mm_r ; 


endmodule 
