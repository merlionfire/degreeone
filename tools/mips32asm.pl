#!/usr/bin/perl -w 

#---------------------------------------------------------------------------------
# FILE         : mips32asm
# DESCRIPTION  : This is a assembler in perl script to convert MIP32 assembly code to 
#                MIPS32 machine code.   
# AUTHOR       : Merlionfire 
# Created      : NOV-29-2014
#---------------------------------------------------------------------------------

use strict ; 

#---------------------------------------------------------------------------------
#  Usage 
#---------------------------------------------------------------------------------
my $usage = " 
USAGE: $0 <asm_file_name> 

"; 


#---------------------------------------------------------------------------------
#  Global vars
#---------------------------------------------------------------------------------

my %func = ( 
      'ADD'    => 0b10_0000,
      'SUB'    => 0b10_0010,
      'DIV'    => 0b01_1010,
      'AND'    => 0b10_0100,
      'OR'     => 0b10_0101,
      'XOR'    => 0b10_0110,
      'SLL'    => 0b00_0000,
      'SRL'    => 0b00_0010,
      'SRA'    => 0b00_0011,
      'JR'     => 0b00_1000,
      'MFC0'   => 0b0_0000,
      'MTC0'   => 0b0_0100
);       

my %opcode = (
      'ADDI'   => 0b00_1000,
      'ANDI'   => 0b00_1100,
      'ORI'    => 0b00_1101,
      'XORI'   => 0b00_1110,
      'LW'     => 0b10_0011,
      'SW'     => 0b10_1011,
      'BEQ'    => 0b00_0100,
      'BNE'    => 0b00_0101,  
      'LUI'    => 0b00_1111,
      'J'      => 0b00_0010,
      'JAL'    => 0b00_0011
); 

my %c0_reg = (
      'STATUS' => 12,
      'CAUSE'  => 13,
      'EPC'    => 14
);      

use constant ARITH_FORM       => "000000%05b%05b%05b00000%06b" ;  
use constant SHIFT_FORM       => "00000000000%05b%05b%05b%06b" ;  
use constant DIV_FORM         => "000000%05b%05b0000000000%06b" ;  
use constant JR_FORM          => "000000%05b000000000000000%06b" ;  
use constant IMM_FORM         => "%06b%05b%05b%016b" ;  
use constant LW_OFFSET_FORM   => "%06b%05b%05b%016b" ;  
use constant BEQ_OFFSET_FORM  => "%06b%05b%05b<%s>" ;  
use constant LUI_FORM         => "%06b00000%05b%016b" ;  
use constant J_FORM           => "%06b<%s>" ;  
use constant MFC0_FORM        => "010000%05b%05b%05b00000000000" ; 

use constant CODE_NOP         => "00000000000000000000000000000000" ; 
use constant CODE_ERET        => "01000010000000000000000000011000" ; 
use constant CODE_SYSCALL     => "00000000000000000000000000001100" ; 

#---------------------------------------------------------------------------------
#  Main
#---------------------------------------------------------------------------------
die $usage if @ARGV == 0 ; 

my $miffile = "final.mif" ; 
my $tempfile = "final.temp" ; 
my $asmfile = $ARGV[0]; 
my $cur_label = ''; 
my $addr = 0; 
my %labels = () ; 
my %constant_table = (); 


open ( ASMF, "<", "$asmfile" ) or die " Can't open $asmfile: $!\n"; 
open ( TEPF, ">", "$tempfile" ) or die " Can't create $tempfile: $!\n"; 


while ( <ASMF> ) {

   next if ( /^\s*\/\// )  ;  # skip comments pre_fixed by  "//" 
   next if ( /^\s*$/ )     ;  # skip blank lines 

   if ( /^\s*(\w+)\s*=\s*(\w+)\s*$/ ) {
      my $value = $2 ; 
      my $label = $1 ; 
      if ( $value =~ /^\d+$/ ) {
           $value = sprintf( "0x%x", $value ) ; 
      } elsif ( $value =~ /^0x[\dA-Fa-f]+$/ ) { 
         ; 
      } else {
         report_error()  ; 
      }
      $constant_table{uc($label)}  = $value;  
      next ;    
   }


   if ( s/^\s*(\w+)\s*:// ) {
      $cur_label = uc($1) ;  
      next if /^\s*$/;
   }  

   if ( /^\s*nop\s*$/i ) {   # nop
      printf TEPF CODE_NOP ; 
      printf TEPF  "    //$_" ; 
   } elsif ( /^\s*(add|sub|and|or|xor) \s*(.*)/i ) {   # add/sub/and/or/xor rd, rs, rt 
      my $func   = $func{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*r(\d+)\s*,\s*r(\d+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 3 ;  # check if 3 registers options 
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[1] > 31 ) or ( $reg_list[2] > 31 ) ; # check reg number withinn [0,31]   
      printf TEPF ARITH_FORM , $reg_list[1], $reg_list[2], $reg_list[0]  , $func ; 
      printf TEPF  "    //$_" ; 
   
   } elsif ( /^\s*(sll|srl|sra)\s*(.*)/i ) {   # sll/srl/sra/ rd, rt, sa    
      my $func   = $func{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*r(\d+)\s*,\s*(\d+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 3 ;  # check if 3 options 
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[1] > 31 ) or ( $reg_list[2] > 31 ) ; # check reg number and sa withinn [0,31]   
      printf TEPF SHIFT_FORM, $reg_list[1], $reg_list[0], $reg_list[2] , $func ; 
      printf TEPF  "    //$_" ; 
   
   } elsif  ( /^\s*(jr)\s*(.*)/i ) {   # jr  rs     
      my $func   = $func{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 1 ;  # check if 3 options 
      report_error() if ( $reg_list[0] > 31 ) ;  # check reg number and sa withinn [0,31]   
      printf TEPF JR_FORM, $reg_list[0] , $func ; 
      printf TEPF  "    //$_" ; 
   
   }  elsif ( /^\s*(addi|andi|ori|xori) \s*(.*)/i ) {   # addi/andi/ori/xori rt, rs, imm 
      my $opcode   = $opcode{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*r(\d+)\s*,\s*([-+]?\w+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 3 ;  # check if 3 registers options 
      if ( $reg_list[2] =~ /^[-+]?\d+$/ ) {   #match dexcimal like -abc, abc and check if it is beyond limition.  
         $reg_list[2]  &= 0xFFFF ;            
      } elsif ( $reg_list[2] =~ /^0x[0-9a-f]{1,4}$/i ) {  # match hexcimal like 0xA, 0xAB, 0xABC or 0xABCD 
         $reg_list[2]   =  hex($reg_list[2]) ; 
      } else {
         report_error() ;  
      }
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[1] > 31 )  ; # check reg number withinn [0,31]   
      printf TEPF IMM_FORM , $opcode, $reg_list[1], $reg_list[0], $reg_list[2] ; 
      printf TEPF  "    //$_" ; 
   
   }  elsif ( /^\s*(lw|sw) \s*(.*)/i ) {   # lw rt, offset(rs) 
      my $opcode   = $opcode{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*([-+]?\w+)\s*\(\s*r(\d+)\s*\)\s*$/i  ) ; 
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[2] > 31 )  ; # check reg number withinn [0,31]   
      if ( $reg_list[1] =~ /^[-+]?\d+$/ ) {   #match dexcimal like -abc, abc and check if it is beyond limition.  
         $reg_list[1]  &= 0xFFFF ;  # temoparily skip checking if it is beyond limitation          
      } elsif ( $reg_list[1] =~ /^0x[0-9a-f]{1,4}$/i ) {  # match hexcimal like 0xA, 0xAB, 0xABC or 0xABCD 
         $reg_list[1]   =  hex($reg_list[1]) ; 
      
      }else {
         my $offset = $constant_table{uc($reg_list[1])}  ; 
         if ( defined( $offset ) ) {
            if ( $offset =~ /^0x[0-9a-f]{1,4}$/i ) {
               $reg_list[1]   =  hex($offset) ; 
            } else {
               report_error() ;  
            }
         } else {
            report_error() ;  
         }    
      }
      printf TEPF  LW_OFFSET_FORM , $opcode, $reg_list[2], $reg_list[0], $reg_list[1] ; 
      printf TEPF  "    //$_" ; 
   
   } elsif ( /^\s*(beq|bne)\s+(.*)/i ) {   # beq/bne rs, rt, label 
      my $opcode   = $opcode{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*r(\d+)\s*,\s*(\w+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 3 ;  # check if 3 registers options 
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[1] > 31 )  ; # check reg number withinn [0,31]   
      
      printf TEPF BEQ_OFFSET_FORM , $opcode, $reg_list[0], $reg_list[1], "$addr," . uc($reg_list[2])  ; 
      printf TEPF  "    //$_" ; 
   
   }  elsif ( /^\s*lui\s+(.*)/i  ) {     # lui rt, imm 
      my $opcode   = $opcode{'LUI'} ;  
      my @reg_list = ( $1 =~ /^r(\d+)\s*,\s*([-+]?\w+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 2 ;  # check if 2  options 
      report_error() if ( $reg_list[0] > 31 )  ; # check reg number withinn [0,31]   
      if ( $reg_list[1] =~ /^[-+]?\d+$/ ) {   #match dexcimal like -abc, abc and check if it is beyond limition.  
         $reg_list[1]  &= 0xFFFF ;            
      } elsif ( $reg_list[1] =~ /^0x[0-9a-f]{1,4}$/i ) {  # match hexcimal like 0xA, 0xAB, 0xABC or 0xABCD 
         $reg_list[1]   =  hex($reg_list[1]) ; 
      } else {
         report_error() ;  
      }
      printf TEPF  LUI_FORM , $opcode, $reg_list[0], $reg_list[1] ; 
      printf TEPF  "    //$_" ; 
   
   } elsif  ( /^\s*(j|jal)\s+(\w+)\s*$/i ) {   # j/jal lable 
      my $opcode   = $opcode{uc($1)} ;  
      printf TEPF J_FORM , $opcode, uc($2)  ; 
      printf TEPF  "    //$_" ; 
   
   } elsif ( /^\s*(mfc0|mtc0)\s+r(\d+)\s*,\s*C0_(CAUSE|STATUS|EPC)\s*$/i ) {    # mfc0  rxx, C0_CAUSE/C0_STATUS/EPC 
      report_error() if $2 > 31 ;   # check reg number withinn [0,31]  
      my $func = $func{uc($1)} ;
      printf TEPF MFC0_FORM , $func, $2, $c0_reg{uc($3)} ; 
      printf TEPF  "    //$_" ; 
   } elsif ( /^\s*eret\s*$/i ) {   # eret 
      printf TEPF CODE_ERET ; 
      printf TEPF  "    //$_" ; 
   } elsif ( /^\s*syscall\s*$/i ) {   # syscall 
      printf TEPF CODE_SYSCALL ; 
      printf TEPF  "    //$_" ; 
   } elsif ( /^\s*(div) \s*(.*)/i ) {   #  div rs, rt 
      my $func   = $func{uc($1)} ;  
      my @reg_list = ( $2 =~ /^r(\d+)\s*,\s*r(\d+)\s*$/i  ) ; 
      report_error() if scalar @reg_list != 2 ;  # check if 3 registers options 
      report_error() if ( $reg_list[0] > 31 ) or  ( $reg_list[1] > 31 ) ; # check reg number withinn [0,31]   
      printf TEPF DIV_FORM , $reg_list[0], $reg_list[1], $func ; 
      printf TEPF  "    //$_" ; 
   
   } else {
      report_error() ;  

   }  

   if ( $cur_label ne '' ) {
      $labels{$cur_label} =  $addr ; 
      $cur_label  =  '' ; 
   }   
   
   $addr += 4 ; 
}    

close ASMF ; 
close TEPF ; 


print "labels tables created is\n" ; 
while ( my ( $key, $value ) = each %labels ) {
   print "   $key => $value\n" ; 
}

print "The first scan of assembler is done !!!\n" ; 

open ( TEPF, "<", "$tempfile" ) or die " Can't oepn $tempfile: $!\n"; 
open ( MIFF, ">", "$miffile" ) or die " Can't creat $miffile: $!\n"; 


while ( <TEPF> ) {

   if ( /<(.+)>/ ) {
      if ( $1 =~ /(\d+),(\w+)/ ) {
         my $offset = sprintf("%016b", ( ($labels{$2}-$1-4 ) >> 2 )  & 0xFFFF ) ; 
         s/<(.+)>/$offset/  ; 
      
      } elsif ( $1 =~ /(\w+)/ ) {
         my $offset = sprintf("%026b",$labels{$1} >> 2 ) ; 
         s/<(.+)>/$offset/ ;      
      
      } else {
         report_error() ;  
      }    
   }

   /^(\d+) / ; 
   my $hex8 =  unpack("H*", pack("B*", $1 ) ) ;  
   printf MIFF  "$hex8\n", 
}   

close TEPF ; 
close MIFF ; 

print "The second scan of assembler is done !!!\n" ; 
print "----- Build Pass -----\n" ;

exit;

sub   report_error { 
   print "Syntax error at Line $. of $asmfile\n"; 
   exit 1 ;
}   
