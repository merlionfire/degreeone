module pc_gen(
   // clock and reset    
   input  wire  clk,
   input  wire  rst,

   // Interface with id_stage
   input  wire  [31:0]  jal_j_addr_id,
   input  wire  [31:0]  beq_bne_addr_id,
   input  wire  [31:0]  jr_addr_id,

   // Interface with if_stage 
   input  wire  [31:0]  pc_plus_1_if,
   output reg   [31:0]  pc,    

   // Interface with controller 
   input  wire          stall_pc,
   input  wire  [2:0]   npc_mux_sel
);
   reg  [31:0] pc_nxt ; 


   always @(*) begin 
      casez( npc_mux_sel ) 
         3'b1?? : pc_nxt = beq_bne_addr_id ; 
         3'b?1? : pc_nxt = jr_addr_id ; 
         3'b??1 : pc_nxt = jal_j_addr_id; 
         3'b000 : pc_nxt = pc_plus_1_if ; 
      endcase 
   end 
/*
   always @( posedge clk ) begin 
      if ( rst ) begin 
         pc <= 'b0 ; 
      end else begin 
         if ( ~stall_pc ) begin 
            if ( exc ) begin     // execption has higher priority.  
               pc <= EXC_BASE ; 
            end else begin 
               pc <= pc_nxt ; 
            end 
         end
       end    
   end 
*/
   always @( posedge clk ) begin 
      if ( rst ) begin 
         pc <= 'b0 ; 
      end else begin 
         if ( ~stall_pc ) begin 
            pc <= pc_nxt ; 
         end
       end    
   end 
endmodule

