

parameter   OP_R_TYPE   =  6'b00_0000; 
parameter   OP_ADDI     =  6'b00_1000;  
parameter   OP_ANDI     =  6'b00_1100;
parameter   OP_ORI      =  6'b00_1101;
parameter   OP_XORI     =  6'b00_1110;
parameter   OP_LW       =  6'b10_0011;
parameter   OP_SW       =  6'b10_1011;
parameter   OP_BEQ      =  6'b00_0100;
parameter   OP_BNE      =  6'b00_0101;
parameter   OP_LUI      =  6'b00_1111;
parameter   OP_J        =  6'b00_0010;
parameter   OP_JAL      =  6'b00_0011;
parameter   OP_C0       =  6'b01_0000;

parameter   OP_RS_MFC0  =  5'b0_0000;
parameter   OP_RS_MTC0  =  5'b0_0100;
parameter   OP_RS_ERET  =  5'b1_0000;

parameter   OP_FUNC_ADD = 6'b10_0000;
parameter   OP_FUNC_SUB = 6'b10_0010;
parameter   OP_FUNC_AND = 6'b10_0100;
parameter   OP_FUNC_OR  = 6'b10_0101;
parameter   OP_FUNC_XOR = 6'b10_0110;
parameter   OP_FUNC_SLL = 6'b00_0000;
parameter   OP_FUNC_SRL = 6'b00_0010;
parameter   OP_FUNC_SRA = 6'b00_0011;
parameter   OP_FUNC_JR  = 6'b00_1000;  
parameter   OP_FUNC_SYSCALL = 6'b00_1100;  
parameter   OP_FUNC_ERET = 6'b01_1000;  


parameter   ALU_CTRL_ADD   =  4'b0000;
parameter   ALU_CTRL_SUB   =  4'b0100;
parameter   ALU_CTRL_AND   =  4'b0001;
parameter   ALU_CTRL_OR    =  4'b0101;
parameter   ALU_CTRL_XOR   =  4'b0010;
parameter   ALU_CTRL_SLL   =  4'b0011;
parameter   ALU_CTRL_SRL   =  4'b0111;
parameter   ALU_CTRL_SRA   =  4'b1111; 
parameter   ALU_CTRL_LUI   =  4'b0110; 

parameter   REG_STATUS_ADDR    =  5'd12 ; 
parameter   REG_CAUSE_ADDR     =  5'd13 ; 
parameter   REG_EPC_ADDR       =  5'd14 ; 
