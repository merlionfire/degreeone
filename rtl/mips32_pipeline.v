`default_nettype none


module mips32_pipeline(
   input wire    clk,
   input wire    rst
);



wire [31:0] pc;
wire [31:0] instr_r;
wire [31:0] pc_plus_1_if_r;
wire [31:0] pc_plus_1_if;
wire        flush_id;

wire [4:0]  reg_ra_a;
wire [4:0]  reg_ra_b;
wire [31:0] reg_rd_a;
wire [31:0] reg_rd_b;
wire [31:0] reg_a_id_r;
wire [31:0] reg_b_id_r;
wire [4:0]  reg_wr_addr_id_r;
wire [4:0]  sa_id_r;
wire [31:0] imm_ext_id_r;
wire [31:0] pc_plus_1_id_r;
wire [31:0] jal_j_addr_id;
wire [31:0] beq_bne_addr_id;
wire [31:0] jr_addr_id;
wire [31:0] exec_out_fw;
wire        sext_sel_id;
wire        reg_wr_addr_rt_sel; 
wire        reg_a_comp_mux;
wire        reg_b_comp_mux;
wire        rd_a_equ_rd_b_id;
wire        jr_sel;
wire        jal_j_sel;

wire [31:0] exec_out_ex_r;
wire [31:0] reg_b_ex_r;
wire [4:0]  reg_wr_addr_ex_r;
wire [31:0] reg_wr_data_wb;
wire [1:0]  src_a_mux;
wire [1:0]  src_b_mux;
wire [4:0]  reg_wr_addr_ex;
wire        jal_sel_ex;
wire [3:0]  alu_ctrl_ex;
wire        alu_zero_ex;
wire        mem_wr_en_mm;
wire [31:0] exec_out_mm_r;
wire [31:0] mem_out_mm_r;
wire [4:0]  reg_wr_addr_mm_r;
wire [4:0]  reg_wr_addr_mm;

wire        stall_pc;
wire        stall_id; 
wire        alu_a_mux_sel_ex;
wire        alu_b_mux_sel_ex;
wire        reg_wr_en_wb;
wire        lw_sel_wb;

wire [4:0]  reg_wr_addr_wb;

wire        jump_taken_predict;
wire        cond_jump_taken_exr;
wire        uncond_jump_instr; 
wire        cond_jump_instr;
wire [31:2] jump_target_predict;
wire [31:0] cond_jump_addr_id;
wire [31:0] uncond_jump_addr_id;
wire        uncond_jump_predict_fail_id;
wire        cond_jump_predict_fail_ex;
wire        cond_jump_taken_ex;

pc_gen  pc_gen_inst (
   .clk                         ( clk                         ), //i
   .rst                         ( rst                         ), //i
   .jump_taken_predict          ( jump_taken_predict          ), //i
   .jump_target_predict         ( jump_target_predict         ), //i
   .jal_j_addr_id               ( jal_j_addr_id               ), //i
   .beq_bne_addr_id             ( beq_bne_addr_id             ), //i
   .jr_addr_id                  ( jr_addr_id                  ), //i
   .cond_jump_addr_id           ( cond_jump_addr_id           ), //i
   .uncond_jump_addr_id         ( uncond_jump_addr_id         ), //i
   .pc_plus_1_id_r              ( pc_plus_1_id_r              ), //i
   .pc_plus_1_if                ( pc_plus_1_if                ), //i
   .pc                          ( pc                          ), //o
   .stall_pc                    ( stall_pc                    ), //i
   .cond_jump_taken_ex          ( cond_jump_taken_ex          ), //i
   .uncond_jump_predict_fail_id ( uncond_jump_predict_fail_id ), //i
   .cond_jump_predict_fail_ex   ( cond_jump_predict_fail_ex   )  //i
);

if_stage  if_stage_inst (
   .clk            ( clk            ), //i
   .rst            ( rst            ), //i
   .pc             ( pc             ), //i
   .instr_r        ( instr_r        ), //o
   .pc_plus_1_if_r ( pc_plus_1_if_r ), //o
   .pc_plus_1_if   ( pc_plus_1_if   ), //o
   .stall_id       ( stall_id       ), //i
   .flush_id       ( flush_id       )  //i
);


id_stage  id_stage_inst (
   .clk                 ( clk                 ), //i
   .rst                 ( rst                 ), //i
   .instr_r             ( instr_r             ), //i
   .pc_plus_1_if_r      ( pc_plus_1_if_r      ), //i
   .reg_ra_a            ( reg_ra_a            ), //o
   .reg_ra_b            ( reg_ra_b            ), //o
   .reg_rd_a            ( reg_rd_a            ), //i
   .reg_rd_b            ( reg_rd_b            ), //i
   .reg_a_id_r          ( reg_a_id_r          ), //o
   .reg_b_id_r          ( reg_b_id_r          ), //o
   .reg_wr_addr_id_r    ( reg_wr_addr_id_r    ), //o
   .sa_id_r             ( sa_id_r             ), //o
   .imm_ext_id_r        ( imm_ext_id_r        ), //o
   .pc_plus_1_id_r      ( pc_plus_1_id_r      ), //o
   .jal_j_addr_id       ( jal_j_addr_id       ), //o
   .cond_jump_addr_id   ( cond_jump_addr_id   ), //o
   .uncond_jump_addr_id ( uncond_jump_addr_id ), //o
   .jr_addr_id          ( jr_addr_id          ), //o
   .exec_out_fw         ( exec_out_fw         ), //i
   .jr_sel              ( jr_sel              ), //i
   .jal_j_sel           ( jal_j_sel           ), //i
   .sext_sel_id         ( sext_sel_id         ), //i
   .reg_wr_addr_rt_sel  ( reg_wr_addr_rt_sel  ), //i
   .reg_a_comp_mux      ( reg_a_comp_mux      ), //i
   .reg_b_comp_mux      ( reg_b_comp_mux      ), //i
   .cond_jump_instr     ( cond_jump_instr     ), //i
   .rd_a_equ_rd_b_id    ( rd_a_equ_rd_b_id    )  //o
);

exec_stage  exec_stage_inst (
   .clk              ( clk              ), //i
   .rst              ( rst              ), //i
   .reg_a_id_r       ( reg_a_id_r       ), //i
   .reg_b_id_r       ( reg_b_id_r       ), //i
   .reg_wr_addr_id_r ( reg_wr_addr_id_r ), //i
   .imm_ext_id_r     ( imm_ext_id_r     ), //i
   .sa_id_r          ( sa_id_r          ), //i
   .pc_plus_1_id_r   ( pc_plus_1_id_r   ), //i
   .exec_out_fw      ( exec_out_fw      ), //o 
   .exec_out_ex_r    ( exec_out_ex_r    ), //o
   .reg_b_ex_r       ( reg_b_ex_r       ), //o
   .reg_wr_addr_ex_r ( reg_wr_addr_ex_r ), //o
   .reg_wr_data_wb   ( reg_wr_data_wb   ), //i
   .src_a_mux        ( src_a_mux        ), //i
   .src_b_mux        ( src_b_mux        ), //i
   .jal_sel_ex       ( jal_sel_ex       ), //i
   .alu_a_mux_sel_ex ( alu_a_mux_sel_ex ), //i
   .alu_b_mux_sel_ex ( alu_b_mux_sel_ex ), //i
   .alu_ctrl_ex      ( alu_ctrl_ex      ), //i
   .alu_zero_ex      ( alu_zero_ex      ), //o
   .reg_wr_addr_ex   ( reg_wr_addr_ex   )  //o
);

mem_stage  mem_stage_inst (
   .clk              ( clk              ), //i
   .rst              ( rst              ), //i
   .exec_out_ex_r    ( exec_out_ex_r    ), //i
   .reg_b_ex_r       ( reg_b_ex_r       ), //i
   .reg_wr_addr_ex_r ( reg_wr_addr_ex_r ), //i
   .exec_out_mm_r    ( exec_out_mm_r    ), //o
   .mem_out_mm_r     ( mem_out_mm_r     ), //o
   .reg_wr_addr_mm_r ( reg_wr_addr_mm_r ), //o
   .mem_wr_en_mm     ( mem_wr_en_mm     ), //i
   .reg_wr_addr_mm   ( reg_wr_addr_mm   )  //o
);


wb_stage  wb_stage_inst (
   .exec_out_mm_r    ( exec_out_mm_r  ), //i
   .mem_out_mm_r     ( mem_out_mm_r   ), //i
   .reg_wr_addr_mm_r ( reg_wr_addr_mm_r), //i
   .reg_wr_addr_wb   ( reg_wr_addr_wb ), //o
   .reg_wr_data_wb   ( reg_wr_data_wb ), //o
   .lw_sel_wb        ( lw_sel_wb      )  //i
);

reg_file  reg_file_inst (
   .clk       ( clk       ), //i
   .rst       ( rst       ), //i
   .reg_ra_a  ( reg_ra_a  ), //i
   .reg_ra_b  ( reg_ra_b  ), //i
   .reg_rd_a  ( reg_rd_a  ), //o
   .reg_rd_b  ( reg_rd_b  ), //o
   .reg_wa_c  ( reg_wr_addr_wb ), //i
   .reg_w_en  ( reg_wr_en_wb   ), //i
   .reg_wd_c  ( reg_wr_data_wb )  //i
);


ctrl  ctrl_inst (
   .clk                         ( clk                         ), //i
   .rst                         ( rst                         ), //i
   .stall_pc                    ( stall_pc                    ), //o
   .uncond_jump_predict_fail_id ( uncond_jump_predict_fail_id ), //o
   .cond_jump_predict_fail_ex   ( cond_jump_predict_fail_ex   ), //o
   .stall_id                    ( stall_id                    ), //o
   .flush_id                    ( flush_id                    ), //o
   .instr_r                     ( instr_r                     ), //i
   .rd_a_equ_rd_b_id            ( rd_a_equ_rd_b_id            ), //i
   .sext_sel_id                 ( sext_sel_id                 ), //o
   .reg_wr_addr_rt_sel          ( reg_wr_addr_rt_sel          ), //o
   .reg_a_comp_mux              ( reg_a_comp_mux              ), //o
   .reg_b_comp_mux              ( reg_b_comp_mux              ), //o
   .jr_sel                      ( jr_sel                      ), //o
   .jal_j_sel                   ( jal_j_sel                   ), //o
   .alu_zero_ex                 ( alu_zero_ex                 ), //i
   .reg_wr_addr_ex              ( reg_wr_addr_ex              ), //i
   .alu_ctrl_ex                 ( alu_ctrl_ex                 ), //o
   .jal_sel_ex                  ( jal_sel_ex                  ), //o
   .alu_a_mux_sel_ex            ( alu_a_mux_sel_ex            ), //o
   .alu_b_mux_sel_ex            ( alu_b_mux_sel_ex            ), //o
   .src_a_mux                   ( src_a_mux                   ), //o
   .src_b_mux                   ( src_b_mux                   ), //o
   .reg_wr_addr_ex_r            ( reg_wr_addr_ex_r            ), //i
   .mem_wr_en_mm                ( mem_wr_en_mm                ), //o
   .reg_wr_en_wb                ( reg_wr_en_wb                ), //o
   .lw_sel_wb                   ( lw_sel_wb                   ), //o
   .jump_taken_predict          ( jump_taken_predict          ), //i
   .uncond_jump_instr           ( uncond_jump_instr           ), //o
   .cond_jump_instr             ( cond_jump_instr             ), //o
   .cond_jump_taken_ex          ( cond_jump_taken_ex          )  //o
);

branch_predictor  branch_predictor_inst (
   .clk                 ( clk                 ), //i
   .rst                 ( rst                 ), //i
   .pc                  ( pc                  ), //i
   .jump_taken_predict  ( jump_taken_predict  ), //o
   .jump_target_predict ( jump_target_predict ), //o
   .cond_jump_taken_ex  ( cond_jump_taken_ex  ), //i
   .uncond_jump_instr   ( uncond_jump_instr   ), //i
   .cond_jump_instr     ( cond_jump_instr     ), //i
   .stall_pc            ( stall_pc            ), //i
   .cond_jump_addr_id   ( cond_jump_addr_id   ), //i
   .uncond_jump_addr_id ( uncond_jump_addr_id )  //i
);

`ifdef SVA 
   `include "checker.v"
`endif

endmodule 
