`default_nettype none 
module exec_stage(
   // clock and reset    
   input  wire          clk,
   input  wire          rst,

   // Interface with id stage
   input  wire  [31:0]  reg_a_id_r,
   input  wire  [31:0]  reg_b_id_r,
   input  wire  [4:0]   reg_wr_addr_id_r,
   input  wire  [31:0]  imm_ext_id_r,
   input  wire  [4:0]   sa_id_r,
   input  wire  [31:0]  pc_plus_1_id_r,
   output wire  [31:0]  exec_out_fw, 

   // Interface with mem stage
   output reg   [31:0]  exec_out_ex_r,        
   output reg   [31:0]  reg_b_ex_r,        
   output reg   [4:0]   reg_wr_addr_ex_r,

   // Interface with wb stage
   input  wire  [31:0]  reg_wr_data_wb,
   
   // Interface wth control 
   input  wire  [1:0]   src_a_mux,
   input  wire  [1:0]   src_b_mux,
   input  wire          jal_sel_ex,
   input  wire          alu_a_mux_sel_ex,
   input  wire          alu_b_mux_sel_ex,
   input  wire  [3:0]   alu_ctrl_ex,
   output wire          alu_zero_ex,
   output wire  [4:0]   reg_wr_addr_ex
);

   wire [31:0]  alu_a;
   wire [31:0]  alu_b;
   wire [31:0]  alu_result;
   wire         alu_overflow;
   wire         alu_zero;
   reg  [31:0]  src_a;
   reg  [31:0]  src_b;
   

   alu32  alu32_inst (
      .a          ( alu_a          ), //i
      .b          ( alu_b          ), //i
      .alu_ctrl   ( alu_ctrl_ex    ), //i
      .alu_result ( alu_result     ), //o
      .alu_zero   ( alu_zero       ), //o
      .alu_overflow ( alu_overflow )  //o
   );

   assign   alu_zero_ex =  alu_zero ; 
   
   assign   alu_a =  alu_a_mux_sel_ex ? sa_id_r       : src_a; 
   assign   alu_b =  alu_b_mux_sel_ex ? imm_ext_id_r  : src_b;
 
   // ******************************************************
   //       Forwarding Unit 
   // ******************************************************      
   always @(*) begin 
      casez(src_a_mux ) 
         2'b1?   :  src_a =  exec_out_fw ; 
         2'b01   :  src_a =  reg_wr_data_wb;
         default :  src_a =  reg_a_id_r;
      endcase
   end

   always @(*) begin 
      casez(src_b_mux ) 
         2'b1?   :  src_b =  exec_out_fw ; 
         2'b01   :  src_b =  reg_wr_data_wb;
         default :  src_b =  reg_b_id_r;
      endcase
   end


   //--------------------------------------------------------

   assign   reg_wr_addr_ex = reg_wr_addr_id_r | {5{jal_sel_ex}}; 
   always @( posedge clk ) begin 
      if ( rst ) begin 
        reg_b_ex_r         <= 'h0; 
        reg_wr_addr_ex_r   <= 'h0;
        exec_out_ex_r      <= 'h0;
      end else begin 
         reg_b_ex_r        <= src_b; 
         reg_wr_addr_ex_r  <= reg_wr_addr_ex ; 
         if ( jal_sel_ex ) begin    
`ifdef DELAYED_BRANCH          
           exec_out_ex_r   <= pc_plus_1_id_r + 'h4; 
`else 
           exec_out_ex_r   <= pc_plus_1_id_r; 
`endif
         end else begin 
           exec_out_ex_r   <= alu_result; 
         end
      end
   end

   assign exec_out_fw  = exec_out_ex_r ; 
   
endmodule 
