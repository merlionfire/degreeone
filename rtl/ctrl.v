`default_nettype none
module ctrl(

   // clock and reset    
   input  wire          clk,
   input  wire          rst,
    
   // interface with gen_pc module
   output wire          stall_pc,
   output wire  [2:0]   npc_mux_sel,

   // interface with if stage
   output wire          stall_id,
   output wire          flush_id,

   // interface with id stage
   input  wire  [31:0]  instr_r,
   input  wire          rd_a_equ_rd_b_id,
   output wire          sext_sel_id,
   output wire          reg_wr_addr_rt_sel,
   output wire          reg_a_comp_mux,
   output wire          reg_b_comp_mux,

   // interface with exe stage 
   input  wire          alu_zero_ex,
   input  wire  [4:0]   reg_wr_addr_ex,
   output reg   [3:0]   alu_ctrl_ex,
   output reg           jal_sel_ex,
   output reg           alu_a_mux_sel_ex,
   output reg           alu_b_mux_sel_ex,
   output reg   [1:0]   src_a_mux,
   output reg   [1:0]   src_b_mux,

   // interface with mem stage 
   input  wire  [4:0]   reg_wr_addr_ex_r,
   output reg           mem_wr_en_mm,
   
   // interface with wb stage 
   output reg           reg_wr_en_wb,
   output reg           lw_sel_wb

);

   `include "opcode_def.vh" 
   parameter  NOP       =  0;
   parameter  SHIFT     =  1; 
   parameter  JR        =  2; 
   parameter  SYSCALL   =  3; 
   parameter  ARITH_IMM =  4; 
   parameter  LW        =  5;
   parameter  SW        =  6;
   parameter  BEQ       =  7;
   parameter  BNE       =  8;
   parameter  LUI       =  9;
   parameter  JUMP      =  10; 
   parameter  JAL       =  11;
   parameter  MFC0      =  12;
   parameter  MTC0      =  13;
   parameter  ERET      =  14; 

   wire [4:0]    rs;
   wire [4:0]    rt;
   wire [5:0]    opcode;
   wire [5:0]    func;
   wire          reg_rd_en; 
   reg  [3:0]    alu_ctrl;
   reg           sext_sel;
   reg           shift_sel;
   reg           unknown_instr;
   reg  [ERET:0] i; 

   reg           reg_wr_en_ex;
   reg           reg_wr_en_mm;
   reg           lw_sel_ex;
   reg           lw_sel_mm;
   reg           mem_wr_en_ex;
   wire          hazard_susp_with_ex;
   wire          hazard_susp_with_mem;
   wire          hazard_with_ex_for_reg_a;
   wire          hazard_with_ex_for_reg_b;
   wire          hazard_with_mem_for_reg_a;
   wire          hazard_with_mem_for_reg_b;
   wire          reg_a_conflict_with_ex;
   wire          reg_a_conflict_with_mem;
   wire          reg_b_conflict_with_ex;
   wire          reg_b_conflict_with_mem;
   wire          load_use_occur;
   wire          jr_addr_sel;
   wire          jal_j_addr_sel;
   wire          beq_bne_addr_sel;
   wire          flush_ex;
   wire          imm_ext_sel;
   wire          compare_delay ; 

   assign rs     =   instr_r[25:21];
   assign rt     =   instr_r[20:16]; 
   assign opcode =   instr_r[31:26];
   assign func   =   instr_r[5:0]; 


    always @(*) begin 
      alu_ctrl    =  'bx ;       
      sext_sel    = 1'b0; 
      shift_sel   = 1'b0;
      unknown_instr = 1'b0 ; 
      i  =  'h0; 
      case ( opcode ) 

         OP_R_TYPE   :  begin 
               case ( func ) 
                  OP_FUNC_ADD  :  alu_ctrl =  ALU_CTRL_ADD ; 
                  OP_FUNC_SUB  :  alu_ctrl =  ALU_CTRL_SUB ; 
                  OP_FUNC_AND  :  alu_ctrl =  ALU_CTRL_AND ; 
                  OP_FUNC_OR   :  alu_ctrl =  ALU_CTRL_OR  ; 
                  OP_FUNC_XOR  :  alu_ctrl =  ALU_CTRL_XOR ; 
                  OP_FUNC_SLL  :  begin 
                        if ( instr_r[25:6] == 'h0 ) begin 
                           i[NOP]   =  1'b1; 
                        end else begin 
                           alu_ctrl    =  ALU_CTRL_SLL ; 
                           i[SHIFT]    =  1'b1;
                           shift_sel   =  1'b1;
                        end
                  end      
                  OP_FUNC_SRL  :  begin 
                        alu_ctrl =  ALU_CTRL_SRL ; 
                        i[SHIFT]    =  1'b1;
                        shift_sel   =  1'b1;
                  end      
                  OP_FUNC_SRA  :  begin
                        alu_ctrl =  ALU_CTRL_SRA ; 
                        i[SHIFT]    =  1'b1;
                        shift_sel   =  1'b1;
                  end      
                  OP_FUNC_JR   :  i[JR]  =  1'b1 ; 
                  OP_FUNC_SYSCALL : i[SYSCALL] =  1'b1 ; 
                  default      :   unknown_instr = 1'b1 ; 
               endcase 
         end
         OP_ADDI  : begin 
               i[ARITH_IMM]   =  1'b1 ;  
               sext_sel       =  1'b1 ; 
               alu_ctrl       =  ALU_CTRL_ADD ; 
         end 
         OP_ANDI  : begin 
               i[ARITH_IMM]   =  1'b1 ;  
               alu_ctrl       =  ALU_CTRL_AND ; 
         end 
         OP_ORI  : begin 
               i[ARITH_IMM]   =  1'b1 ;  
               alu_ctrl       =  ALU_CTRL_OR ; 
         end 
         OP_XORI  : begin 
               i[ARITH_IMM]   =  1'b1 ;  
               alu_ctrl       =  ALU_CTRL_XOR ; 
         end 
         OP_LW    : begin 
               i[LW]          =  1'b1;
               sext_sel       =  1'b1 ; 
               alu_ctrl       =  ALU_CTRL_ADD ; 
         end
         OP_SW    : begin 
               i[SW]          =  1'b1;
               sext_sel       =  1'b1 ; 
               alu_ctrl       =  ALU_CTRL_ADD ; 
         end
         OP_BEQ   : begin 
               i[BEQ]         =  1'b1;
               sext_sel       =  1'b1 ; 
         end
         OP_BNE  : begin 
               i[BNE]         =  1'b1;
               sext_sel       =  1'b1 ; 
         end
         OP_LUI   : begin
               i[LUI]         =  1'b1;
               alu_ctrl       =  ALU_CTRL_LUI ;
         end
         OP_J     : begin
               i[JUMP]        =  1'b1;
         end
         OP_JAL   : begin
               i[JAL]         =  1'b1;
         end
         /*
         OP_C0  : begin
            case ( rs ) 
                  OP_RS_MFC0  :  i[MFC0]  = 1'b1 ;        
                  OP_RS_MTC0  :  i[MTC0]  = 1'b1 ; 
                  OP_RS_ERET  :  i[ERET]  = ( func == OP_FUNC_ERET ) ? 1'b1 : 1'b0 ;  
                  default     :  unknown_instr = 1'b1 ; 
            endcase    
         end
         */
         default : unknown_instr = 1'b1 ; 
      endcase
   end

   //*******************************************
   //     Data Hazard Detect Unit
   //*******************************************

   assign reg_rd_en   = ~( i[JUMP] | i[JAL] ) ;  
   assign hazard_susp_with_ex  =  reg_rd_en && reg_wr_en_ex ; 
   assign hazard_susp_with_mem =  reg_rd_en && reg_wr_en_mm ; 

   assign reg_a_conflict_with_ex   =  ( rs == reg_wr_addr_ex ) ; 
   assign reg_a_conflict_with_mem  =  ( rs == reg_wr_addr_ex_r ) ; 

   assign reg_b_conflict_with_ex   =  ( rt == reg_wr_addr_ex ); 
   assign reg_b_conflict_with_mem  =  ( rt == reg_wr_addr_ex_r ) ; 

   assign hazard_with_ex_for_reg_a  =  hazard_susp_with_ex && reg_a_conflict_with_ex ; 
   assign hazard_with_ex_for_reg_b  =  hazard_susp_with_ex && reg_b_conflict_with_ex ; 

   assign hazard_with_mem_for_reg_a =  hazard_susp_with_mem && reg_a_conflict_with_mem;
   assign hazard_with_mem_for_reg_b =  hazard_susp_with_mem && reg_b_conflict_with_mem;

   // load-use 
   assign load_use_occur =  reg_rd_en && lw_sel_ex && ( reg_a_conflict_with_ex | reg_b_conflict_with_ex )  ; 

   always @(posedge clk ) begin 
      if ( rst ) begin 
         src_a_mux   <= 'h0; 
         src_b_mux   <= 'h0; 
      end else begin 
         src_a_mux   <= { hazard_with_ex_for_reg_a, hazard_with_mem_for_reg_a };
         src_b_mux   <= { hazard_with_ex_for_reg_b, hazard_with_mem_for_reg_b };
      end

   end

   //*******************************************
   //     Branch Hazard Detect Unit
   //*******************************************

   assign jr_addr_sel    =  i[JR] ;  
   assign jal_j_addr_sel   =  i[JAL] | i[JUMP] ;    
   assign beq_bne_addr_sel  = ( i[BEQ] & rd_a_equ_rd_b_id ) | (i[BNE] & ~rd_a_equ_rd_b_id ) ;  

   assign npc_mux_sel =  { beq_bne_addr_sel, jr_addr_sel, jal_j_addr_sel } ;       

   assign reg_a_comp_mux   =  hazard_with_mem_for_reg_a  ; 
   assign reg_b_comp_mux   =  hazard_with_mem_for_reg_b  ; 

   // Conidtion: 
   //   1) Regiger conflict between beq/bne and previous instruction
   //
   //          hazard_with_ex_for_reg_a | hazard_with_ex_for_reg_b 
   //   2) Regiger conflict between beq/bne and LW at previous 2nd  instruction
   //
   //       lw    $1, addr                lw    $1, addr
   //       add   $4, $5,  $6     =>      addr  $4, $5,  $6  
   //       beq   $1, $4, target          beq   stalled
   //                                     beq   $1, $4,  target
   //
   //      expression :  hazard_with_mem_for_reg_a | hazard_with_mem_for_reg_b ) & lw_sel_mm 
   //
   //
   // Solution : stall pipeline and flush exe stage at the next cycle  
   // Remark :
   //    If privous instruction is "LW", 2 stall cycles are needed.  
   //       lw    $1, addr        =>      lw    $1, addr
   //       beq   $1, $0,  target         beq   stalled
   //                                     beq   stalled
   //                                     beq   $1, $0,  target
   assign compare_delay =  ( hazard_with_ex_for_reg_a | hazard_with_ex_for_reg_b | ( hazard_with_mem_for_reg_a | hazard_with_mem_for_reg_b ) & lw_sel_mm ) & ( i[BEQ] | i[BNE] ) ;  

   // Stall singal for respective stages
   // "Stall" frozes pipeline and keeps output as previous cycle 
   assign stall_pc   =  load_use_occur | compare_delay ;
   assign stall_id   =  load_use_occur | compare_delay; 


   // Flush singal for respective stages
   assign flush_ex   =  load_use_occur | compare_delay; 

   // Assertion of "flush_id" indicates NOP will be inserted into ID stage at
   // next cycle.
`ifdef DELAYED_BRANCH          
   assign flush_id   = 0 ;  
`else
   assign flush_id   =  ( ~compare_delay) && ( jr_addr_sel | jal_j_addr_sel | beq_bne_addr_sel );     
`endif



   assign   imm_ext_sel   =  i[ARITH_IMM] | i[LW] | i[LUI] | i[SW] ; 

   //*******************************************
   //     ID stage control signals
   //*******************************************
   assign   sext_sel_id =  sext_sel; 
   //assign   reg_wr_addr_rt_sel = arith_imm_sel | lw_sel | lui_sel | mfc0_sel; 
   assign   reg_wr_addr_rt_sel = i[ARITH_IMM] | i[LW] | i[LUI] ; 
   //*******************************************
   //     EXE stage control signals
   //*******************************************
   always @( posedge clk ) begin  
      if (rst | stall_id ) begin 
         alu_ctrl_ex       <= 'h0;
         alu_a_mux_sel_ex  <= 'h0; 
         alu_b_mux_sel_ex  <= 'h0; 
         jal_sel_ex        <= 'h0; 
         mem_wr_en_ex      <= 'h0;
         reg_wr_en_ex      <= 'h0;
         lw_sel_ex         <= 'h0;
      end else begin
         alu_ctrl_ex       <= alu_ctrl;
         alu_a_mux_sel_ex  <= shift_sel; 
         alu_b_mux_sel_ex  <= imm_ext_sel ; 
         jal_sel_ex        <= i[JAL]; 
         mem_wr_en_ex      <= i[SW] & ( ~ flush_ex ) ;
         reg_wr_en_ex      <= ~ ( i[NOP] |  i[JUMP] | i[BEQ] | i[BNE] | i[SW] | i[JR] | flush_ex ) ;
         lw_sel_ex         <= i[LW] ; 
      end
   end

   //*******************************************
   //     MEM stage control signals
   //*******************************************
   always @( posedge clk ) begin  
      if (rst) begin 
         mem_wr_en_mm     <= 1'b0;
         reg_wr_en_mm     <= 1'b0;
         lw_sel_mm        <= 1'b0; 
      end else begin
         mem_wr_en_mm     <= mem_wr_en_ex;
         reg_wr_en_mm     <= reg_wr_en_ex;
         lw_sel_mm        <= lw_sel_ex; 
      end
   end

   //*******************************************
   //    WB stage control signals
   //*******************************************

   always @( posedge clk ) begin  
      if (rst) begin 
         reg_wr_en_wb     <= 1'b0; 
         lw_sel_wb        <= 1'b0; 
      end else begin
         reg_wr_en_wb     <= reg_wr_en_mm;
         lw_sel_wb        <= lw_sel_mm; 
      end
   end

endmodule
