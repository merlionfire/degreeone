`default_nettype none
module pc_gen(
   // clock and reset    
   input  wire  clk,
   input  wire  rst,

   // Interface with branch_predictor 
   input  wire          jump_taken_predict,  
   input  wire  [31:2]  jump_target_predict,

   // Interface with id_stage
   input  wire  [31:0]  jal_j_addr_id,
   input  wire  [31:0]  beq_bne_addr_id,
   input  wire  [31:0]  jr_addr_id,
   input  wire  [31:0]  cond_jump_addr_id,
   input  wire  [31:0]  uncond_jump_addr_id,
   input  wire  [31:0]  pc_plus_1_id_r,

   // Interface with if_stage 
   input  wire  [31:0]  pc_plus_1_if,
   output reg   [31:0]  pc,    

   // Interface with controller 
   input  wire          stall_pc,
   input  wire          cond_jump_taken_ex,
   input  wire          uncond_jump_predict_fail_id,
   input  wire          cond_jump_predict_fail_ex
);

   reg  [31:0] pc_nxt ; 
   reg  [31:0] cond_jump_addr_ex;

   always @( posedge clk ) begin 
      if ( rst ) begin 
        cond_jump_addr_ex  <= 'h0 ; 
      end else begin 
        cond_jump_addr_ex  <= cond_jump_addr_id ; 
      end
   end

   always @(*) begin 
      if ( cond_jump_predict_fail_ex ) begin 
         if ( cond_jump_taken_ex ) begin
            pc_nxt = cond_jump_addr_ex ; 
         end else begin 
            pc_nxt = pc_plus_1_id_r;
         end
      end else if ( uncond_jump_predict_fail_id ) begin 
         pc_nxt = uncond_jump_addr_id; 
      end else if ( jump_taken_predict ) begin 
         pc_nxt = { jump_target_predict, 2'b00 } ;  
      end else begin
         pc_nxt = pc_plus_1_if; 
      end
   end 

   /*
   always @(*) begin 
      pc_nxt = pc_plus_1_if ; 
      if ( branch_predict_fail ) begin 
         casez( npc_mux_sel ) 
            3'b1?? : pc_nxt = beq_bne_addr_id ; 
            3'b?1? : pc_nxt = jr_addr_id ; 
            3'b??1 : pc_nxt = jal_j_addr_id; 
         endcase
      end else if ( jump_taken_predict ) begin 
         pc_nxt = [jump_target,2'b00]; 
      end   
   end 
   */
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

