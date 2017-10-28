`default_nettype  none  
module branch_predictor ( 
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // Status    
   input  wire  [31:0]  pc,
   output wire          jump_taken_predict,  
   output wire  [31:2]  jump_target_predict,
   
   // Update from ctrl 
   input  wire          cond_jump_taken_ex,  
   input  wire          uncond_jump_instr,
   input  wire          cond_jump_instr,
   input  wire          stall_pc,

   // interface with id stage 
   input  wire  [31:0]  cond_jump_addr_id,
   input  wire  [31:0]  uncond_jump_addr_id
); 

   parameter   PC_BITS_WIDTH     =  32-2;
   parameter   TAG_BITS_WIDTH    =  PC_BITS_WIDTH ;  
   parameter   TARGET_BITS_WIDTH =  PC_BITS_WIDTH; 
   parameter   BTB_BITS_WIDTH    =  TAG_BITS_WIDTH + TARGET_BITS_WIDTH + 2 ;   
   parameter   INDEX_BITS_WIDTH  =  8 ; 
   parameter   ENTRY_NUM         =  2 ** INDEX_BITS_WIDTH ; 
   parameter   GHR_BITS_WIDTH    =  8;
   parameter   PHT_ENTRY_NUM     =  2 ** GHR_BITS_WIDTH;   


   reg   [BTB_BITS_WIDTH-1:0]    branch_traget_table [0: ENTRY_NUM-1] ;  
   wire  [INDEX_BITS_WIDTH-1:0]  btb_idx; 
   wire  [BTB_BITS_WIDTH-1:0]    btb_entry; 
   wire  [TAG_BITS_WIDTH-1:0]    tag;
   wire                          valid, uncond_jump; 
   wire                          btb_hit; 
   wire                          btb_update;
   wire  [INDEX_BITS_WIDTH-1:0]  btb_update_idx; 
   wire  [BTB_BITS_WIDTH-1:0]    btb_entry_update; 
   reg   [31:2]                  pc_branch_instr_id;

   wire  [31:2]                  jump_target_update; 

   wire  [GHR_BITS_WIDTH-1:0]    pht_idx; 
   reg   [GHR_BITS_WIDTH-1:0]    pht_idx_id; 
   reg   [GHR_BITS_WIDTH-1:0]    pht_idx_ex; 

   reg   [1:0] pattern_his_table [0:PHT_ENTRY_NUM-1] ;
   reg   [GHR_BITS_WIDTH-1:0]    global_his_reg ; 
   wire                          gshare_taken;
   wire  [1:0] bits_cnt;
   reg   [1:0] bits_cnt_nxt;
   reg   [1:0] bits_cnt_id;
   reg   [1:0] bits_cnt_ex;
   wire                          gshare_update;

   reg   cond_jump_instr_ex;
   integer  i;

   always @( posedge clk ) begin
      if ( rst ) begin 
          pc_branch_instr_id  <= 'h0;  
          cond_jump_instr_ex  <= 'h0; 
          pht_idx_id          <= 'h0;  
          pht_idx_ex          <= 'h0;  
      end else begin 
          if ( !stall_pc ) pc_branch_instr_id  <= pc[31:2] ;  
          cond_jump_instr_ex  <= cond_jump_instr ; 
          pht_idx_id          <= pht_idx;  
          pht_idx_ex          <= pht_idx_id;  
      end
   end 

   // ***********************************************
   //    BTB hit/miss detector 
   // ***********************************************

   assign   jump_target_update = uncond_jump_addr_id[31:2] | cond_jump_addr_id[31:2] ;
   assign   btb_entry_update   = { pc_branch_instr_id, jump_target_update, 1'b1, uncond_jump_instr};     
   assign   btb_update_idx  = pc_branch_instr_id[2+:INDEX_BITS_WIDTH];
   assign   btb_update  =  uncond_jump_instr | cond_jump_instr ;

   assign   btb_idx     =  pc[INDEX_BITS_WIDTH-1:2]; 
   assign   btb_entry   =  branch_traget_table[btb_idx];
   assign   { tag,jump_target_predict,valid,uncond_jump} = btb_entry; 

   assign   btb_hit   = ( ( tag == pc[31:2] ) && valid ) ? 1'b1 : 1'b0 ; 

   always @( posedge clk ) begin
      if ( rst ) begin 
         for ( i=0; i< ENTRY_NUM ; i = i+1 ) begin 
            branch_traget_table[i]  <= 'h0; 
         end
      end else begin 
         if ( btb_update ) begin 
            branch_traget_table[btb_update_idx] <= btb_entry_update ; 
         end 
      end
   end 

   // ***********************************************
   //    Gshare Predictor 
   // ***********************************************
  


   assign   pht_idx  =  pc[GHR_BITS_WIDTH-1:2] ^ global_his_reg ;  

   assign   gshare_taken   =  pattern_his_table[pht_idx][1] ; 
   assign   bits_cnt       =  pattern_his_table[pht_idx] ;

   parameter   STRONG_NOTAKEN = 2'b00 ; 
   parameter   WEAK_NOTAKEN   = 2'b01 ; 
   parameter   WEAK_TAKEN     = 2'b10 ; 
   parameter   STRONG_TAKEN   = 2'b11 ; 

   always @(*) begin 
      case ( { bits_cnt_ex, cond_jump_taken_ex }  )  
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

   always @( posedge clk ) begin 
      if (rst) begin 
         bits_cnt_id    <= 'h0;  
         bits_cnt_ex    <= 'h0;  
         global_his_reg <= 'h0;               
         for ( i = 0 ; i < PHT_ENTRY_NUM; i = i+1 ) begin 
            pattern_his_table[i] <= 'h0;
         end 
      end else begin 
         bits_cnt_id <= bits_cnt ;  
         bits_cnt_ex <= bits_cnt_id ;  
         if ( gshare_update ) begin 
            pattern_his_table[pht_idx_ex] <= bits_cnt_nxt ;  
            global_his_reg                <= { global_his_reg[GHR_BITS_WIDTH-2:0], cond_jump_taken_ex } ;  
         end
      end
   end

   // ***********************************************
   //    NPC Mux 
   // ***********************************************
   assign jump_taken_predict =  ( gshare_taken || uncond_jump ) && btb_hit; 
   assign gshare_update      =  cond_jump_instr_ex;





endmodule 
