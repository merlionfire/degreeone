
module alu32 (
   input  wire [31:0] a,
   input  wire [31:0] b,
   input  wire [3:0]  alu_ctrl,
   output reg  [31:0] alu_result,    
   output wire        alu_zero,    
   output reg         alu_overflow    
);

`include "opcode_def.vh" 

   wire sub, c_out ;  
   wire [31:0] z ; 

   function [31:0] shift32 ( input [31:0] d, input [4:0] offset, input right, input arith ); 
      reg msb ; 
      reg [31:0] d4_in, d4_in_left, d4_in_right, s4_out ; 
      reg [31:0] d3_in, d3_in_left, d3_in_right, s3_out ; 
      reg [31:0] d2_in, d2_in_left, d2_in_right, s2_out ; 
      reg [31:0] d1_in, d1_in_left, d1_in_right, s1_out ; 
      reg [31:0] d0_in, d0_in_left, d0_in_right, s0_out ; 
      begin 
         msb = d[31] & arith ;    
         d4_in =  d ; 
         d4_in_left  = { d4_in[15:0], 16'h00 }  ; 
         d4_in_right = { { 16{msb} }, d4_in[31:16] } ;  
         s4_out = offset[4] ? ( right ? d4_in_right : d4_in_left)  : d4_in ; 

         d3_in =  s4_out ; 
         d3_in_left  = { d3_in[23:0], 8'h00 }  ; 
         d3_in_right = { { 8{msb} } , d3_in[31:8] };  
         s3_out = offset[3] ? ( right ? d3_in_right : d3_in_left)  : d3_in ; 

         d2_in =  s3_out ; 
         d2_in_left  = { d2_in[27:0], 4'h0 }  ; 
         d2_in_right = { { 4{msb} } , d2_in[31:4] };  
         s2_out = offset[2] ? ( right ? d2_in_right : d2_in_left)  : d2_in ; 

         d1_in =  s2_out ; 
         d1_in_left  = { d1_in[29:0], 2'b00 }  ; 
         d1_in_right = { { 2{msb} } , d1_in[31:2] };  
         s1_out = offset[1] ? ( right ? d1_in_right : d1_in_left)  : d1_in ; 

         d0_in =  s1_out ; 
         d0_in_left  = { d0_in[30:0], 1'b0 }  ; 
         d0_in_right = { msb , d0_in[31:1] };  
         s0_out = offset[0] ? ( right ? d0_in_right : d0_in_left)  : d0_in ; 

         shift32 = s0_out ; 

      end
   endfunction   

   assign sub = alu_ctrl[2] ; 

   assign alu_zero = ~( | alu_result ) ;  

   // --- Overflow generation ( signature method ) :
   //    True tale ( for addition ) :
   //       A[31] | B[31] | Z[31]  | Overflow 
   //    -------------------------------------
   //         0       0       0    |    0   
   //         0       0       1    |    1   
   //         1       1       0    |    1   
   //         1       1       1    |    0   
   //
   //assign alu_overflow  =  ( (  alu_ctrl == ALU_CTRL_ADD ) & ( ( ~a[31] & ~b[31] & z[31] ) | ( a[31] &  b[31] & ~z[31] ) ) ) |     
   //                        ( (  alu_ctrl == ALU_CTRL_SUB ) & ( ( ~a[31] &  b[31] & z[31] ) | ( a[31] & ~b[31] & ~z[31] ) ) ) ;     
   always @(*) begin 
      alu_overflow   = 1'b0  ;  
      case (alu_ctrl ) 
         ALU_CTRL_ADD :  begin 
            if ( ( ~a[31] & ~b[31] & z[31] ) | ( a[31] &  b[31] & ~z[31] ) ) begin 
               alu_overflow = 1'b1 ; 
            end    
         end
         ALU_CTRL_SUB :  begin 
            if ( ( ~a[31] &  b[31] & z[31] ) | ( a[31] & ~b[31] & ~z[31] ) ) begin 
               alu_overflow = 1'b1 ; 
            end
         end 
      endcase    
   end

   adder  #(32) adder_inst (
      .a     ( a       ), //i
      .b     ( b ^ {32{sub} } ), //i
      .c_in  ( sub     ), //i
      .z     ( z       ), //o
      .c_out ( c_out   )  //o
   );

   always @(*) begin 
      case ( alu_ctrl )
         4'b0000, 4'b0100 : alu_result = z  ; 
         4'b0001 : alu_result = a & b ; 
         4'b0101 : alu_result = a | b ; 
         4'b0010 : alu_result = a ^ b ;
         4'b0110 : alu_result = { b[15:0], 16'h0000 } ; 
         4'b0011, 4'b0111, 4'b1111 : alu_result = shift32(b, a[4:0], alu_ctrl[2], alu_ctrl[3] )   ; 
         default : alu_result = 'bx ; 
       endcase 
   end    


endmodule 
