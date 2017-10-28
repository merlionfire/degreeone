
   // *********************************************************
   //  Branch Predictor checker  
   // *********************************************************
   //
   // ---------------------------------------------------------
   //    SVA for key signals   
   // ---------------------------------------------------------

`define M_REG     reg_file_inst.register  
`define M_MEM     mem_stage_inst.data_ram_inst.data_mem     
`define M_ROM     if_stage_inst.instr_rom_inst.instr_mem     
`define MSG_ERR   $fatal

   `include "opcode_def.vh" 
   parameter  NOP       =  0;
   parameter  ARITH     =  1; 
   parameter  JR        =  2; 
   parameter  SLL       =  3; 
   parameter  SRL       =  4; 
   parameter  SRA       =  5;
   parameter  ADDI      =  6;
   parameter  ANDI      =  7;
   parameter  ORI       =  8;
   parameter  XORI      =  9;
   parameter  JUMP      =  10; 
   parameter  JAL       =  11;
   parameter  BEQ       =  12;
   parameter  BNE       =  13;
   parameter  ERET      =  14; 
   parameter  LUI       =  15;
   parameter  LW        =  16;
   parameter  SW        =  17;
   parameter  EOF       =  19; 

   typedef logic [4:0]  reg_addr_t ; 
   typedef logic [31:0] data_t; 
   typedef logic [4:0]  sa_t;
   typedef logic [5:0]  func_t;
   typedef logic [15:0] imm_t;
   typedef logic [31:0] mem_addr_t ;

   reg_addr_t  regs_wr_q[$]; 
   reg_addr_t  regs_rd_q[$]; 
   logic    [EOF:0]  instr_found ; 

   wire [5:0]    opcode;
   wire [5:0]    func;
   wire [4:0]    rs;
   wire [4:0]    rd;
   wire [4:0]    rt;
   wire [4:0]    sa;
   wire [15:0]   imm;
   wire [25:0]   jump_target; 
   // ------ Instruction extract  --------------------------
   
   assign opcode =   instr_r[31:26];
   assign func   =   instr_r[5:0]; 
   assign rs     =   instr_r[25:21];
   assign rt     =   instr_r[20:16]; 
   assign rd     =   instr_r[15:11]; 
   assign sa     =   instr_r[10:6] ; 
   assign imm    =   instr_r[15:0] ; 
   assign jump_target  = instr_r[25:0] ; 



   task add_regs_wr ( reg_addr_t reg_addr ) ; 
      regs_wr_q.push_back(reg_addr) ; 
   endtask 

   task add_regs_rd ( reg_addr_t reg_addr ) ; 
      regs_rd_q.push_back(reg_addr) ; 
   endtask 

   task record_regs_access( reg_addr_t reg_wr_addr = 0, reg_rd_1_addr = 0 , reg_rd_2_addr = 0 ) ; 
      add_regs_wr(reg_wr_addr) ; 
      add_regs_rd(reg_rd_1_addr) ; 
      add_regs_rd(reg_rd_2_addr) ; 
   endtask 

   task update_regs_q(); 
      if ( regs_wr_q.size() > 0 ) regs_wr_q.pop_front ; 
      regs_rd_q =   {} ; 
   endtask 

   task report_err(); 
      $display("[DEBUG] ERROR : @%t Unknow instruction 0x%h", $time, instr_r); 
      #10;
   endtask 


   // Decode function and put src and dest register number into seperate
   // queues. 
   always @( negedge clk) begin
      if (rst) begin
         regs_wr_q = {} ; 
         regs_rd_q = {} ; 
      end else if ( instr_r == 'h0) begin 
         instr_found   <= 'b1;
         update_regs_q();
      end else begin
         update_regs_q();
         instr_found   <= 'b0;
         case ( opcode ) 
            OP_R_TYPE   :  begin 
               casez ( { sa,func} ) 
                  {5'h0,OP_FUNC_ADD},
                  {5'h0,OP_FUNC_SUB},
                  {5'h0,OP_FUNC_AND},
                  {5'h0,OP_FUNC_OR},
                  {5'h0,OP_FUNC_XOR} :    begin instr_found[ARITH] <= 1'b1; record_regs_access(rd,rs,rt); end
                  {5'h??,OP_FUNC_SLL}:    begin instr_found[SLL]   <= 1'b1; record_regs_access(rd,rt); end
                  {5'h??,OP_FUNC_SRL}:    begin instr_found[SRL]   <= 1'b1; record_regs_access(rd,rt); end
                  {5'h??, OP_FUNC_SRA}:   begin instr_found[SRA]   <= 1'b1; record_regs_access(rd,rt); end
                  {5'h0,OP_FUNC_JR} : begin
                     if ( {rt,rd} == 'h0 ) begin instr_found[JR]   <= 1'b1; record_regs_access(.reg_rd_1_addr(rs)); end
                     else begin report_err(); end
                  end
                  default :   report_err();
               endcase
            end
            OP_ADDI : begin instr_found[ADDI]   <= 1'b1; record_regs_access(rt,rs); end
            OP_ANDI : begin instr_found[ANDI]   <= 1'b1; record_regs_access(rt,rs); end
            OP_ORI  : begin instr_found[ORI]    <= 1'b1; record_regs_access(rt,rs); end
            OP_XORI : begin instr_found[XORI]   <= 1'b1; record_regs_access(rt,rs); end
            OP_LW   : begin instr_found[LW]     <= 1'b1; record_regs_access(rt,rs); end
            OP_SW   : begin instr_found[SW]     <= 1'b1; record_regs_access(0,rs,rt); end
            OP_LUI  : begin instr_found[LUI]    <= 1'b1; record_regs_access(rt,rs); end 
            OP_J    : begin instr_found[JUMP]   <= 1'b1; end 
            OP_JAL  : begin instr_found[JAL]    <= 1'b1; record_regs_access(31); end 
            OP_BEQ  : begin instr_found[BEQ]    <= 1'b1; record_regs_access(0,rs,rt); end 
            OP_BNE  : begin instr_found[BNE]    <= 1'b1; record_regs_access(0,rs,rt); end 
            default :   report_err(); 
         endcase 
      end
   end 

   function automatic logic [31:0] reg_val ( input logic [4:0] addr ) ; 
      reg_val  =  ( addr ==  5'h00 ) ? 'h0 : `M_REG[addr] ; 
   endfunction 

   function automatic logic [31:0] mem_val ( input logic [31:0] addr ) ; 
      mem_val  =  `M_MEM[addr[31:2]] ; 
   endfunction 

   function automatic logic [31:0] rom_val ( input logic [31:0] addr ) ; 
      rom_val  =  `M_ROM[addr[31:2]] ; 
   endfunction 

   function automatic logic [31:0] extimm ( input logic [15:0] imm ) ; 
      for ( int i = 0 ; i < 32 ; i++ ) begin 
         if ( i > 15 ) begin 
            extimm[i] = imm[15] ; 
         end else begin
            extimm[i] = imm[i]; 
         end
      end
   endfunction 

   function automatic logic [31:0] op_arith( input logic [31:0] a, logic [31:0] b, logic [5:0] func) ; 
      case (func) 
         OP_FUNC_ADD :  op_arith   =  a + b ; 
         OP_FUNC_SUB :  op_arith   =  a - b ; 
         OP_FUNC_AND :  op_arith   =  a & b ;
         OP_FUNC_OR  :  op_arith   =  a | b ;
         OP_FUNC_XOR :  op_arith   =  a ^ b ;
         OP_FUNC_SLL :  op_arith   =  a << b ;  
         OP_FUNC_SRL :  op_arith   =  a >> b ;  
         OP_FUNC_SRA :  begin
               op_arith   =  {32{a[31]}} ; 
               for ( int i = b, j=0 ; i <=31 ; i++, j++ ) begin 
                  op_arith[j]   =  a[i] ; 
               end
         end
         default :      op_arith   =  '1 ;  
      endcase 
   endfunction 

   function automatic data_t reg_arith( input reg_addr_t a, reg_addr_t b, logic [5:0] func= OP_FUNC_ADD);
         //$display("reg[%h]=0x%h, reg[%h]=0x%h, func=0x%h", a,reg_val(a), b,reg_val(b),  func);
         reg_arith   =  op_arith( reg_val(a), reg_val(b), func ) ;    
         //$display("reg[%h]=0x%h, reg[%h]=0x%h, func=0x%h, reg_arith = 0x%h", a,reg_val(a), b,reg_val(b),  func, reg_arith );
   endfunction 

   function automatic logic [31:0] reg_imm_arith( input logic [4:0] addr, logic [15:0] imm, logic [5:0] func= OP_FUNC_ADD);
       if ( func == OP_FUNC_ADD ) begin // Only addi needs to sign extension  
          reg_imm_arith  =  op_arith( reg_val(addr), extimm(imm), func ) ; 
       end else begin
          reg_imm_arith  =  op_arith( reg_val(addr), {16'h0000,imm }, func ) ; 
       end
   endfunction 

   task print_err ( input string property_name, string tag="ASS ERR");
      $error("[%s] @%t: %s\tviolate", tag, $time, property_name ) ;    
   endtask 

   task print_pass ( input string property_name, string tag="ASS PASS");
      $display("[%s] @%t: %s\tpass", tag, $time, property_name ) ;    
   endtask 

   function automatic bit compare( input data_t a, b ) ;  
      if ( a == b ) return 1'b1 ; 
      else begin  
         $display("[ASS INFO] @%t: <0x%h> observed inequal to <0x%h> expected",$time, a, b) ; 
         return 1'b0;
      end
   endfunction 
   // *********************************************************
   //  Reboot check
   // *********************************************************
   sequence reset_seq ; 
      rst[*2:100] ##1 $fell(rst);       
   endsequence

   property COLD_BOOT ;
      @( posedge clk ) $rose(rst) |-> reset_seq;  
   endproperty 

   cold_boot : assert property ( COLD_BOOT ) else `MSG_ERR("[ASST ERR] COLD_BOOT: Reset signal is NOT hold more than 2 cycles or NOT deasserted") ;
   cov_cold_boot : cover property(COLD_BOOT) ;  
    

   // *********************************************************
   //  Instruction check without hazard
   //  - Test basic instruction 
   //  - No any harzard exsits
   // *********************************************************
   
   sequence s_instr(instr) ; 
      instr_found[instr] & (~stall_id) & (~ctrl_inst.flush_ex); /* if flush_ex(stall_id), discard this instruction at next stage*/ 
   endsequence


   property instr_valid;
      @(posedge clk) disable iff (rst)
      $onehot0(instr_found)  ;  
   endproperty

   assert property(instr_valid) else $error("[ASS ERR] multiple instructions are decoded"); 

   // ---------------------------------------
   // Instruction : arith : add/sub/and/or/xor 
   // ---------------------------------------
   property p_inst_arith;
      logic [4:0]    r_dest;
      logic [4:0]    r_src_1;
      logic [4:0]    r_src_2;
      data_t         src_data1;
      data_t         src_data2;
      logic [5:0]    m_func; 
      @( posedge clk ) disable iff ( rst  ) 
         ( s_instr(ARITH),
           r_dest = rd, r_src_1 = rs, r_src_2 = rt, m_func = func 
           /*,$display("rs= 0x%h, rt= 0x%h, func = 0x%h, value = 0x%h", rs, rt, func, value)*/
         ) |-> ##2 ( 1'b1, src_data1 = reg_val(r_src_1) , src_data2 = reg_val(r_src_2) ) 
               ##1 compare(reg_val(r_dest),op_arith(src_data1,src_data2,m_func) );  

   endproperty

   a_instr_arith : assert property( p_inst_arith ) else print_err("<arith>") ;
   c_instr_arith : cover  property( p_inst_arith ) print_pass("<arith>") ;  

   // ---------------------------------------
   // Instruction : sll 
   // ---------------------------------------
   property p_inst_sll;
      data_t        data; 
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      sa_t          m_sa;
      func_t        m_func; 
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(SLL),
           r_dest = rd, r_src = rt, m_sa = sa, m_func = func 
         ) |-> ##2 (1'b1, data =  reg_val(r_src) ) 
               ##1 compare( reg_val(r_dest), op_arith(data, m_sa, m_func ) ) ; 
   endproperty

   a_instr_sll : assert property( p_inst_sll ) else print_err("<sll> ") ;
   c_instr_sll : cover  property( p_inst_sll ) print_pass("<sll> ") ;  

   // ---------------------------------------
   // Instruction : srl 
   // ---------------------------------------
   property p_inst_srl;
      data_t        data; 
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      sa_t          m_sa;
      func_t        m_func; 
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(SRL),
           r_dest = rd, r_src = rt, m_sa = sa, m_func = func 
         ) |-> ##2 (1'b1, data =  reg_val(r_src) ) 
               ##1 compare( reg_val(r_dest), op_arith(data, m_sa, m_func ) ) ; 
   endproperty

   a_instr_srl : assert property( p_inst_srl ) else print_err("<srl> ") ;
   c_instr_srl : cover  property( p_inst_srl ) print_pass("<srl> ") ;  

   // ---------------------------------------
   // Instruction : sra 
   // ---------------------------------------
   property p_inst_sra;
      data_t        data; 
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      sa_t          m_sa;
      func_t        m_func; 
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(SRA),
           r_dest = rd, r_src = rt, m_sa = sa, m_func = func 
         ) |-> ##2 (1'b1, data =  reg_val(r_src) ) 
               ##1 compare( reg_val(r_dest), op_arith(data, m_sa, m_func ) ) ; 
   endproperty

   a_instr_sra : assert property( p_inst_sra ) else print_err("<sra> ") ;
   c_instr_sra : cover  property( p_inst_sra ) print_pass("<sra> ") ;  

   // ---------------------------------------
   // Instruction : jr 
   // ---------------------------------------
   property p_inst_jr;
      logic [31:0]   jump_addr; 
      @( posedge clk ) disable iff ( rst ) 
         (  s_instr(JR),
            jump_addr = reg_val(rs) 
         ) |-> ##1 ( pc == jump_addr ) ; 
   endproperty

   a_instr_jr : assert property( p_inst_jr ) else print_err("<jr> ") ;
   c_instr_jr : cover  property( p_inst_jr ) print_pass("<jr> ") ;  

   // ---------------------------------------
   // Instruction : ADDI 
   // ---------------------------------------
   property p_inst_addi;
      logic [31:0]   value ; 
      logic [4:0]    reg_addr;
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(ADDI),
           value = reg_imm_arith(rs,imm ), reg_addr = rt
           /*, $displww("rs= 0x%h, rt= 0x%h, func = 0x%h, value = 0x%h, reg[rs] = 0x%h", rs, rt, func, value, reg_val(rs))*/
         ) |-> ##3 ( reg_val(reg_addr) == value ) ;           
   endproperty 

   a_instr_addi : assert property( p_inst_addi ) else print_err("<addi> ") ;
   c_instr_addi : cover  property( p_inst_addi ) print_pass("<addi> ");  

   // ---------------------------------------
   // Instruction : andi 
   // ---------------------------------------
   property p_inst_andi;
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      imm_t         m_imm;
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(ANDI),
           r_dest = rt, r_src = rs, m_imm = imm 
         ) |-> ##3  compare(reg_val(r_dest), reg_imm_arith(r_src,m_imm,OP_FUNC_AND )) ;           
   endproperty 

   a_instr_andi : assert property( p_inst_andi ) else print_err("<andi> ") ;
   c_instr_andi : cover  property( p_inst_andi ) print_pass("<andi> ");  

   // ---------------------------------------
   // Instruction : ori 
   // ---------------------------------------
   property p_inst_ori;
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      imm_t         m_imm;
      @( posedge clk ) disable iff ( rst ) 
         (  s_instr(ORI),
           r_dest = rt, r_src = rs, m_imm = imm 
         ) |-> ##3  compare(reg_val(r_dest), reg_imm_arith(r_src,m_imm,OP_FUNC_OR )) ;           
   endproperty 

   a_instr_ori : assert property( p_inst_ori ) else print_err("<ori> ") ;
   c_instr_ori : cover  property( p_inst_ori ) print_pass("<ori> ");  

   // ---------------------------------------
   // Instruction : xori 
   // ---------------------------------------
   property p_inst_xori;
      reg_addr_t    r_dest;
      reg_addr_t    r_src;
      imm_t         m_imm;
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(XORI),
           r_dest = rt, r_src = rs, m_imm = imm 
         ) |-> ##3  compare(reg_val(r_dest), reg_imm_arith(r_src,m_imm,OP_FUNC_XOR )) ;           
   endproperty 

   a_instr_xori : assert property( p_inst_xori ) else print_err("<xori>") ;
   c_instr_xori : cover  property( p_inst_xori ) print_pass("<xori> ");  

   // ---------------------------------------
   // Instruction : lui 
   // ---------------------------------------
   property p_inst_lui;
      reg_addr_t    r_dest;
      imm_t         m_imm;
      @(posedge clk ) disable iff (rst ) 
         ( s_instr(LUI),
           r_dest = rt, m_imm = imm
         ) |-> ##3 compare(reg_val(r_dest), {m_imm,16'h0000} ) ; 
   endproperty
   
   a_inst_lui  :  assert property (p_inst_lui ) else print_err("<lui>") ;
   c_inst_lui  :  cover property(p_inst_lui) print_pass("<lui>"); 

   // ---------------------------------------
   // Instruction : SW 
   // ---------------------------------------
   property p_inst_sw;
      reg_addr_t    r_src_1;
      reg_addr_t    r_src_2;
      imm_t         m_imm;
      @( posedge clk ) disable iff ( rst ) 
         ( s_instr(SW), 
           r_src_1 = rs, r_src_2 = rt, m_imm = imm  
           /*,$display("rs= 0x%h, rt= 0x%h, value = 0x%h, reg[rs] = 0x%h, m_addr = 0x%h", rs, rt,value,reg_val(rs), m_addr)*/
         ) |-> ##3 compare(mem_val(reg_imm_arith(r_src_1,m_imm)),reg_val(r_src_2));
   endproperty 

   a_instr_sw : assert property( p_inst_sw ) else print_err("<sw>") ;
   c_instr_sw : cover  property( p_inst_sw ) print_pass("<sw>");  

   // ---------------------------------------
   // Instruction : LW 
   // ---------------------------------------
   property p_inst_lw;
      logic [31:0]   value; 
      logic [31:0]   m_addr; 
      logic [4:0]    r_addr; 
      reg_addr_t    r_src;
      reg_addr_t    r_dest;
      imm_t         m_imm;
      @(posedge clk ) disable iff (rst)
         ( s_instr(LW), 
           r_dest = rt, r_src = rs, m_imm=imm
         ) |-> ##3 compare(reg_val(r_dest), mem_val(reg_imm_arith(r_src, m_imm )) ); 
   endproperty

   a_inst_lw : assert property(p_inst_lw) else print_err("<lw>") ; 
   c_inst_lw : cover  property(p_inst_lw) print_pass("<lw>"); 

   // ---------------------------------------
   // Instruction : beq 
   // ---------------------------------------
   property p_inst_beq;
      logic [31:0]   jump_addr; 
      logic [31:0]   npc;
      reg_addr_t     r_src_2;
      reg_addr_t     r_src_1;
      @( posedge clk ) disable iff ( rst ) 
          ( s_instr(BEQ), 
            r_src_1  =  rs, r_src_2 =  rt, jump_addr = pc_plus_1_if_r + {extimm(imm),2'b00} , npc = pc_plus_1_if_r  
            /*,$display("jump_addr = 0x%h, npc=0x%h", jump_addr, npc)*/ 
          ) |-> ##3 ( ( reg_val(r_src_1) == reg_val(r_src_2) ) ? 
                      ( instr_r == rom_val(jump_addr)   /* prediction fails and 2 following instrs are flushed */
                        || $past(instr_r,2) == rom_val(jump_addr) ) : /* prediction success and followed instr is from jump target*/
                      ( $past(instr_r,2) == rom_val(npc) )       /* if no jump, instruction following was not flushed 2 cycles ealier when it is at ID stage.*/    
                    ); 
   endproperty 
   a_inst_beq : assert property(p_inst_beq) else print_err("<beq>") ; 
   c_inst_beq : cover  property(p_inst_beq) print_pass("<beq>"); 

   // ---------------------------------------
   // Instruction : bne 
   // ---------------------------------------
   property p_inst_bne;
      logic [31:0]   jump_addr; 
      logic [31:0]   npc;
      reg_addr_t     r_src_2;
      reg_addr_t     r_src_1;
      @( posedge clk ) disable iff ( rst ) 
          ( s_instr(BNE), 
            r_src_1  =  rs, r_src_2 =  rt, jump_addr = pc_plus_1_if_r + {extimm(imm),2'b00} , npc = pc_plus_1_if_r  
            /*,$display($time,  " <bne> rs= 0x%h, rt= 0x%h, func = 0x%h, jump_addr = 0x%h, reg[rs] = 0x%h, reg[rt] = 0x%h", rs, rt, func, jump_addr, reg_val(rs), reg_val(rt) )*/
          ) |-> ##3 ( ( reg_val(r_src_1) != reg_val(r_src_2) ) ? 
                      ( instr_r == rom_val(jump_addr)   /* prediction fails and 2 following instrs are flushed */
                        || $past(instr_r,2) == rom_val(jump_addr) ) /* prediction success and followed instr is from jump target*/ :
                      ($past(instr_r,2) == rom_val(npc) )   /* if no jump, instruction following was not flushed 2 cycles ealier when it is at ID stage.*/    
                    ); 
   endproperty 

   a_inst_bne : assert property(p_inst_bne) else print_err("<bne>") ; 
   c_inst_bne : cover  property(p_inst_bne) print_pass("<bne>"); 

   // ---------------------------------------
   // Instruction : J 
   // Comment:
   // *) If jump target is not in BTB because this jump instruction is first-run or BTB entry is
   //    overrided, fetch address of jump target shows up 1 cycle later because one 
   //    NOP buble is inserted. So one cycle later to check PC.
   // *) If jump instruction is hit in BTB, the corresponding jump target
   //    should be shown on fetech PC at the same time. So check PC within same
   //    cycle.  
   // ---------------------------------------
   property p_inst_j;
      logic [31:0]   jump_addr; 
      @( posedge clk ) disable iff ( rst ) 
          ( s_instr(JUMP),
            jump_addr = { pc_plus_1_if_r[31:28], jump_target,2'b00} 
          ) |-> ##[0:1] ( compare( pc, jump_addr ) ) ;           
   endproperty 

   a_instr_j: assert property( p_inst_j ) else print_err("<J>") ;
   c_instr_j : cover  property( p_inst_j ) print_pass("<J>");  


   // ---------------------------------------
   // Instruction : JAL
   // ---------------------------------------
   property p_inst_jal;
      logic [31:0]   jump_addr; 
      logic [31:0]   return_addr; 
      @( posedge clk ) disable iff ( rst ) 
          ( s_instr(JAL),
            jump_addr = { pc_plus_1_if_r[31:28], jump_target,2'b00}, 
`ifdef DELAYED_BRANCH          
            return_addr =  pc_plus_1_if_r + 4   
`else    
            return_addr =  pc_plus_1_if_r    
`endif
          ) |-> ##1 ( pc == jump_addr ) ##2 ( reg_val(5'd31) == return_addr) ;           
   endproperty 

   a_instr_jal: assert property( p_inst_jal ) else print_err("<JAL>") ;
   c_instr_jal: cover  property( p_inst_jal ) print_pass("<JAL>");  
   

   
