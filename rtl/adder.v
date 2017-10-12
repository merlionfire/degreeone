
module adder #( parameter N = 32 ) ( 
      input    wire  [N-1:0]   a,
      input    wire  [N-1:0]   b,
      input    wire            c_in,
      output   wire  [N-1:0]   z,
      output   wire            c_out
);      

`ifdef SIM
   assign   { c_out, z } = { 1'b0, a } + { 1'b0, b } + c_in ; 

`else
   wire g, p ; 

   add_nb #( N ) add_nb_inst  (
         .a ( a ),
         .b ( b ),
         .c_in ( c_in ),
         .z ( z ),
         .g_out ( g ),
         .p_out ( p ) 
   ) ; 

   assign c_out   =  g | p & c_in ; 
`endif

endmodule 


module add_1b ( 
   input    wire  a,
   input    wire  b,
   input    wire  c,
   output   wire  z,
   output   wire  g, 
   output   wire  p 
);      

   assign z = a ^ b ^ c ;
   assign g = a & b ; 
   assign p = a | b ; 

endmodule


module gp_gen (
   input    wire [1:0]  g,
   input    wire [1:0]  p,
   input    wire        c_in,
   output   wire        c_out,
   output   wire        g_out, 
   output   wire        p_out 
);      

   assign g_out   =  g[1] | p[1] & g[0] ; 
   assign p_out   =  p[1] & p[0] ; 
   assign c_out   =  g[0] | p[0] & c_in ; 
  
endmodule

/*
module add_2b (
   input    wire [1:0]  a,
   input    wire [1:0]  b,
   input    wire        c_in,
   output   wire [1:0]  z,
   output   wire        g_out, 
   output   wire        p_out, 
);      

   wire [1:0] g, p ; 
   wire [1:0] c;
   wire c_out; 

   assign c[0] = c_in ; 
   assign c[1] = c_out ; 

   add_1b add_1b_0 (
         .a ( a[0] ),
         .b ( b[0] ),
         .c ( c[0] ),
         .z ( z[0] ),
         .g ( g[0] ),
         .p ( p[0] ) 
   ) ; 


   add_1b add_1b_1 (
         .a ( a[1] ),
         .b ( b[1] ),
         .c ( c[1] ),
         .z ( z[1] ),
         .g ( g[1] ),
         .p ( p[1] ) 
   ) ; 

   gp_gen gp_gen_inst (
         .g     ( g     ),
         .p     ( p     ),
         .c_in  ( c_in  ),
         .c_out ( c_out ),
         .g_out ( g_out ),
         .p_out ( p_out ) 
   ) 

endmodule 


module add_4b (
   input    wire [3:0]  a,
   input    wire [3:0]  b,
   input    wire        c_in,
   output   wire [3:0]  z,
   output   wire        g_out, 
   output   wire        p_out, 
);      

   wire [1:0] g, p ; 
   wire [1:0] c;
   wire c_out; 

   assign c[0] = c_in ; 
   assign c[1] = c_out ; 

   add_2b add_2b_0 (
         .a ( a[1:0] ),
         .b ( b[1:0] ),
         .c ( c[0] ),
         .z ( z[1:0] ),
         .g ( g[0] ),
         .p ( p[0] ) 
   ) ; 


   add_2b add_2b_1 (
         .a ( a[3:2] ),
         .b ( b[2:2] ),
         .c ( c[1] ),
         .z ( z[3:2] ),
         .g ( g[1] ),
         .p ( p[1] ) 
   ) ; 

   gp_gen gp_gen_inst (
         .g     ( g     ),
         .p     ( p     ),
         .c_in  ( c_in  ),
         .c_out ( c_out ),
         .g_out ( g_out ),
         .p_out ( p_out ) 
   ) 

endmodule 
*/

module add_nb #( parameter N = 32 ) (
   input    wire [ N-1 : 0 ]  a,
   input    wire [ N-1 : 0 ]  b,
   input    wire              c_in,
   output   wire [ N-1 : 0 ]  z,
   output   wire              g_out, 
   output   wire              p_out 
);      

   localparam N_DIV_2 = N / 2 ;

   wire [ 1 : 0] g, p ; 
   wire [ 1 : 0] c;
   wire c_out; 

   assign c[0] = c_in ; 
   assign c[1] = c_out ; 

generate 
   if ( N == 2 ) begin  

      add_1b add_1b_0 (
            .a ( a[0] ),
            .b ( b[0] ),
            .c ( c[0] ),
            .z ( z[0] ),
            .g ( g[0] ),
            .p ( p[0] ) 
      ) ; 


      add_1b add_1b_1 (
            .a ( a[1] ),
            .b ( b[1] ),
            .c ( c[1] ),
            .z ( z[1] ),
            .g ( g[1] ),
            .p ( p[1] ) 
      ) ; 

   end else begin  

      add_nb #( N_DIV_2 ) add_nb_0 (
            .a ( a[N_DIV_2-1:0] ),
            .b ( b[N_DIV_2-1:0] ),
            .c_in ( c[0] ),
            .z ( z[ N_DIV_2-1 : 0] ),
            .g_out ( g[0] ),
            .p_out ( p[0] ) 
      ) ; 

      add_nb #( N_DIV_2 ) add_nb_1 (
            .a ( a[ N-1 : N_DIV_2 ] ),
            .b ( b[ N-1 : N_DIV_2 ]  ),
            .c_in ( c[1] ),
            .z ( z[ N-1 : N_DIV_2]  ),
            .g_out ( g[1] ),
            .p_out ( p[1] ) 
      ) ; 

   end 

endgenerate 

   gp_gen gp_gen_inst (
         .g     ( g     ),
         .p     ( p     ),
         .c_in  ( c_in  ),
         .c_out ( c_out ),
         .g_out ( g_out ),
         .p_out ( p_out ) 
   ); 

endmodule 
