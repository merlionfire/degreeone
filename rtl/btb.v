
module btb(
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // Status    
   input  wire  [31:2]  pc,
   input  wire          jump_taken_predict;  
   output wire  [31:2]  jump_target_predict,
   
   // Update 
   input  wire          cond_jump_taken_ex,  
   input  wire          uncond_jump_instr,
   input  wire          cond_jump_instr,

):

   parameter   PC_BITS_WIDTH    =  32-2;
   parameter   TAG_BITS_WIDTH   =  PC_BITS_WIDTH ;  
   parameter   TARGET_BIT_WIDTH =  PC_BITS_WIDTH; 
   parameter   BTB_BITS_WIDTH   =  TAG_BITS_WIDTH + TARGET_BIT_WIDTH + 2 ;   
   parameter   INDEX_BITS_WIDTH =  8 ; 
   parameter   ENTRY_NUM        =  2 ** INDEX_BITS_WIDTH ; 

   input  wire  [31:2]  jump_instr_pc;

   reg [BTB_BITS_WIDTH-1:0]  branch_traget_table [0: ENTRY_NUM-1] ;  


   wire  [INDEX_BITS_WIDTH-1:0]  btx_idx; 
   wire  [TAG_BITS_WIDTH-1:0]    tag;
   wire                          valid, uncond_jump; 

   always @( posedge clk ) begin
      if ( rst ) begin 
      end else begin 
          pc_branch_instr_id   <= pc ;  
          cond_jump_instr_ex   <= cond_jump_instr ; 
          pht_idx_id <= pht_idx;  
          pht_idx_ex <= pht_idx_id;  

      end
   end 

   // ***********************************************
   //    BTB hit/miss detector 
   // ***********************************************

   assign   pc_branch_instr <= pc ;  

   assign   btb_entry_update = { pc_branch_instr, 
                                 uncond_jump_addr_id | cond_jump_addr_id,
                                 1'b1, uncond_jump_instr
                               };     
   assign   btb_update_idx  = pc_branch_instr[INDEX_BITS_WIDTH-1:0];
   assign   btb_update  =  uncond_jump_instr | cond_jump_instr ;

   assign   btx_idx     =  pc[INDEX_BITS_WIDTH-1:0]; 
   assign   btb_entry   =  branch_traget_table[btx_idx];
   assign   { tag,jump_target_predict,valid,uncond_jump} = btb_entry; 

   assign   btb_hit   = ( ( tag == pc ) && valid ) ? 1'b1 : 1'b0 ; 

   always @( posedge clk ) begin
      if ( rst ) begin 
         genvar i 
            for ( i=0; i< ENTRY_NUM ; i++) begin 
               branch_traget_table[i]  <= 'h0; 
            end 
         endgenerate
      end else begin 
         if ( btb_update ) begin 
            branch_traget_table[btb_update_idx] <= btb_entry_update ; 
         end 
      end
   end 

   // ***********************************************
   //    Gshare Predictor 
   // ***********************************************
  
   parameter   GHR_BITS_WIDTH    =  8;
   parameter   PHT_ENTRY_NUM     =  2 ** GHR_BITS_WIDTH;   


   reg   [1:0] pattern_his_table [0:PHT_ENTRY_NUM-1] ;

   reg   [GHR_BITS_WIDTH-1:0]  global_his_reg ; 

   wire  [GHR_BITS_WIDTH-1:0]  pht_idx; 


   assign   pht_idx  =  pc[GHR_BITS_WIDTH-1:0] ^ global_his_reg ;  

   assign   gshare_taken   =  pattern_his_table[pht_idx][1] ; 
   assign   bits_cnt       =  pattern_his_table[pht_idx] ;

   parameter   STRONG_NOTAKEN = 2'b00 ; 
   parameter   WEAK_NOTAKEN   = 2'b01 ; 
   parameter   WEAK_TAKEN     = 2'b10 ; 
   parameter   STRONG_TAKEN   = 2'b11 ; 

   always (*) begin 
      case ( { bits_cnt_ex, cond_jump_taken_ex }  ) ; 
         { STRONG_NOTAKEN, 1'b0 }  : bits_cnt_nxt = STRONG_NOTAKEN ;             
         { STRONG_NOTAKEN, 1'b1 }  : bits_cnt_nxt = WEAK_NOTAKEN ;             
         { WEAK_NOTAKEN,   1'b0 }  : bits_cnt_nxt = STRONG_NOTAKEN ;    
         { WEAK_NOTAKEN,   1'b1 }  : bits_cnt_nxt = WEAK_TAKEN;    
         { WEAK_TAKEN,     1'b1 }  : bits_cnt_nxt = STRONG_TAKEN ;    
         { WEAK_TAKEN,     1'b0 }  : bits_cnt_nxt = WEAK_NOTAKEN;    
         { STRONG_TAKEN,   1'b1 }  : bits_cnt_nxt = STRONG_TAKEN ;             
         { STRONG_TAKEN,   1'b0 }  : bits_cnt_nxt = WEAK_TAKEN ;             
      endcase 
   end

   always @( posedge clk ) beign 
      if (rst) begin 
      end else begin 
         bits_cnt_id <= bits_cnt ;  
         bits_cnt_ex <= bits_cnt_id ;  
         if ( cond_jump_instr_ex ) begin 
            pattern_his_table[pht_idx_ex] <= bits_cnt_nxt ;  
            global_his_reg <= { global_his_reg[GHR_BITS_WIDTH-2:1], cond_jump_taken_ex } ;  
         end
      end
   end

   // ***********************************************
   //    NPC Mux 
   // ***********************************************
   assign jump_taken_predict =  ( gshare_taken || uncond_jump ) && btb_hit; 


endmodule 
