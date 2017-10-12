
`timescale 1ns / 100ps

module tb () ;

   logic clk  = 1'b0 ; 
   logic rst  = 1'bx ; ; 

   
   mips32_pipeline  mips32_pipeline_inst (
      .clk      ( clk      ), //i
      .rst      ( rst      ) //i
   );


   always #10ns clk = ~ clk ; 

   initial begin 
      $timeformat(-9,0,"ns",7);  
      /*      
        unit      is the base that time is to be displayed in, from 0 to -15
        precision is the number of decimal points to display.
        "unit"    is a string appended to the time, such as " ns".
        minwidth  is the minimum number of characters that will be displayed.
        
        0 =   1 sec
        -1 = 100 ms
        -2 =  10 ms
        -3 =   1 ms 
        -4 = 100 us
        -5 =  10 us
        -6 =   1 us 
        -7 = 100 ns
        -8 =  10 ns
        -9 =   1 ns 
        -10 = 100 ps
        -11 =  10 ps
        -12 =   1 ps 
        -13 = 100 fs
        -14 =  10 fs
        -15 = 1 fs 
      */
   end

   initial begin 
      repeat  (3) @( posedge clk ) ; 
      rst =   1'b1 ; 
      // reset dut 
      repeat  (8) @( posedge clk ) ; 
      #5 rst = 1'b0 ;      
      
      repeat (100) @( posedge clk ) ;  
      $finish ; 
   end


  /* 
   initial begin 
      #1.1us  intr   =  1'b1 ; 
      #20     intr   =  1'b0 ; 
   end
*/
   /*-----------------------------------------------------------------*/
   /*-------------------- FSDB dumper  -------------------------------*/ 
   /*-----------------------------------------------------------------*/

   initial begin
        $fsdbDumpfile("cosim_verdi.fsdb");
        $fsdbDumpvars();
   end


  endmodule 
