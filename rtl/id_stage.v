module id_stage(
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // Interface with if  stage
   input  wire  [31:0]  instr_r,
   input  wire  [31:0]  pc_plus_1_if_r,

   // Interface with registers 
   output wire  [4:0]  reg_ra_a,
   output wire  [4:0]  reg_ra_b,
   input  wire  [31:0] reg_rd_a,
   input  wire  [31:0] reg_rd_b,

   // Interface with exe stage
   output reg   [31:0]  reg_a_id_r,
   output reg   [31:0]  reg_b_id_r,
   output reg   [4:0]   reg_wr_addr_id_r,
   output reg   [4:0]   sa_id_r,
   output reg   [31:0]  imm_ext_id_r,
   output reg   [31:0]  pc_plus_1_id_r,

   // Interface with pc_gen
   output wire  [31:0]  jal_j_addr_id,
   output wire  [31:0]  beq_bne_addr_id,
   output wire  [31:0]  jr_addr_id,
    
   // Internal forwarding signals from other stage 
   input  wire  [31:0]  exec_out_fw,

   // Interface with ctrl 
   input  wire          sext_sel_id,
   input  wire          reg_wr_addr_rt_sel, 
   input  wire          reg_a_comp_mux,
   input  wire          reg_b_comp_mux,
   output wire          rd_a_equ_rd_b_id
);

   wire [4:0]    rs;
   wire [4:0]    rd;
   wire [4:0]    rt;
   wire [4:0]    sa;
   wire [15:0]   imm;
   wire [25:0]   jump_target; 
   wire [31:0]   reg_a_data_new;    
   wire [31:0]   reg_b_data_new;    

   // ------ Instruction extract  --------------------------
   
   assign rs     =   instr_r[25:21];
   assign rt     =   instr_r[20:16]; 
   assign rd     =   instr_r[15:11]; 
   assign sa     =   instr_r[10:6] ; 
   assign imm    =   instr_r[15:0] ; 
   assign jump_target  = instr_r[25:0] ; 

   // ------ Register file interface ------------------------

   assign reg_ra_a   =   rs ;
   assign reg_ra_b   =   rt ; 

   // Internal forwarded signals from exe_stage and mem_stage 
   always @( posedge clk ) begin 
      if ( rst ) begin 
        reg_a_id_r   <= 'h0 ; 
        reg_b_id_r   <= 'h0 ; 
      end else begin 
        reg_a_id_r  <= reg_rd_a;    
        reg_b_id_r  <= reg_rd_b;    
      end
   end

   wire [31:0] imm_ext;
   wire        sext ; 

   assign sext    =  sext_sel_id & imm[15] ;  
   assign imm_ext = { {16{sext}}, imm } ;  

   always @( posedge clk ) begin 
      if ( rst ) begin 
        pc_plus_1_id_r     <= 'h0 ; 
        imm_ext_id_r       <= 'h0 ; 
        sa_id_r            <= 'h0 ; 
        reg_wr_addr_id_r   <= 'h0 ; 
      end else begin 
        pc_plus_1_id_r     <= pc_plus_1_if_r ; 
        imm_ext_id_r       <= imm_ext ; 
        sa_id_r            <= sa ; 
        reg_wr_addr_id_r   <= reg_wr_addr_rt_sel ?  rt : rd ; 
      end
   end

   // path to NPC muxplexer   
   assign beq_bne_addr_id = pc_plus_1_if_r + { imm_ext[29:0], 2'b00}  ; 
   assign jr_addr_id      = reg_rd_a;
   assign jal_j_addr_id   = { pc_plus_1_if_r[31:28], jump_target,  2'b00 };


   assign reg_a_data_new   = ( reg_a_comp_mux ) ? exec_out_fw : reg_rd_a ; 
   assign reg_b_data_new   = ( reg_b_comp_mux ) ? exec_out_fw : reg_rd_b ; 

   assign rd_a_equ_rd_b_id   = ( reg_a_data_new == reg_b_data_new ) ? 1'b1 : 1'b0 ;    


endmodule 
