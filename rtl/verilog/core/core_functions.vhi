-- FUNCTIONS --
macro getALUFunc(instr: Instr_t) : ALUFunc_t := 
	if (((instr = INSTR_ADD) or (instr = INSTR_ADDI))) then (ALUF_ADD)
	elsif ((instr = INSTR_SUB)) then (ALUF_SUB)
	elsif (((instr = INSTR_SLL) or (instr = INSTR_SLLI))) then (ALUF_SLL)
	elsif (((instr = INSTR_SLT) or (instr = INSTR_SLTI))) then (ALUF_SLT)
	elsif (((instr = INSTR_SLTU) or (instr = INSTR_SLTIU))) then (ALUF_SLTU)
	elsif (((instr = INSTR_XOR) or (instr = INSTR_XORI))) then (ALUF_XOR)
	elsif (((instr = INSTR_SRL) or (instr = INSTR_SRLI))) then (ALUF_SRL)
	elsif (((instr = INSTR_SRA) or (instr = INSTR_SRAI))) then (ALUF_SRA)
	elsif (((instr = INSTR_OR) or (instr = INSTR_ORI))) then (ALUF_OR)
	elsif (((instr = INSTR_AND) or (instr = INSTR_ANDI))) then (ALUF_AND)
	elsif ((((((instr = INSTR_LB) or (instr = INSTR_LH)) or (instr = INSTR_LW)) or (instr = INSTR_LBU)) or (instr = INSTR_LHU))) then (ALUF_ADD)
	elsif (((instr = INSTR_JALR) or (instr = INSTR_JAL))) then (ALUF_X)
	elsif (((instr = INSTR_BEQ) or (instr = INSTR_BNE))) then (ALUF_SUB)
	elsif (((instr = INSTR_BLT) or (instr = INSTR_BGE))) then (ALUF_SLT)
	elsif (((instr = INSTR_BLTU) or (instr = INSTR_BGEU))) then (ALUF_SLTU)
	elsif ((((instr = INSTR_SB) or (instr = INSTR_SH)) or (instr = INSTR_SW))) then (ALUF_ADD)
	elsif ((instr = INSTR_AUIPC)) then (ALUF_ADD)
	elsif ((instr = INSTR_LUI)) then (ALUF_COPY1)
	else (ALUF_X);
end if;
end macro; 

macro getALUResult(func: ALUFunc_t;op1: unsigned;op2: unsigned) : unsigned := 
	if ((func = ALUF_ADD)) then unsigned((op1 + op2)(31 downto 0))
	elsif ((func = ALUF_SUB)) then unsigned((op1 - op2)(31 downto 0))
	elsif ((func = ALUF_AND)) then unsigned((op1 and op2))
	elsif ((func = ALUF_OR)) then unsigned((op1 or op2))
	elsif ((func = ALUF_XOR)) then unsigned((op1 xor op2))
	elsif ((func = ALUF_SLT) and (signed(op1) < signed(op2))) then unsigned(resize(1,32))
	elsif ((func = ALUF_SLT)) then unsigned(resize(0,32))
	elsif ((func = ALUF_SLTU) and (op1 < op2)) then unsigned(resize(1,32))
	elsif ((func = ALUF_SLTU)) then unsigned(resize(0,32))
	elsif ((func = ALUF_SLL)) then unsigned((shift_left(op1,(op2 and resize(31,32)))))
	elsif ((func = ALUF_SRA)) then unsigned(unsigned((shift_right(signed(op1),signed((op2 and resize(31,32)))))))
	elsif ((func = ALUF_SRL)) then unsigned((shift_right(op1,(op2 and resize(31,32)))))
	elsif ((func = ALUF_COPY1)) then unsigned(op1)
	else unsigned(resize(0,32));
end if;
end macro; 

macro getBranchResult(ALUResult: unsigned;PCReg: unsigned;encodedInstr: unsigned) : unsigned := 
	if (((getInstr(encodedInstr) = INSTR_BEQ) and (ALUResult = resize(0,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	elsif (((getInstr(encodedInstr) = INSTR_BNE) and (ALUResult /= resize(0,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	elsif (((getInstr(encodedInstr) = INSTR_BLT) and (ALUResult = resize(1,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	elsif (((getInstr(encodedInstr) = INSTR_BGE) and (ALUResult = resize(0,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	elsif (((getInstr(encodedInstr) = INSTR_BLTU) and (ALUResult = resize(1,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	elsif (((getInstr(encodedInstr) = INSTR_BGEU) and (ALUResult = resize(0,32)))) then unsigned((PCReg + getImmediate(encodedInstr))(31 downto 0))
	else unsigned((PCReg + resize(4,32))(31 downto 0));
end if;
end macro; 

macro getFunct3(encodedInstr: unsigned) : unsigned := 
	unsigned(((shift_right(encodedInstr,resize(12,32))) and resize(7,32)));
end macro; 

macro getFunct7(encodedInstr: unsigned) : unsigned := 
	unsigned(((shift_right(encodedInstr,resize(25,32))) and resize(127,32)));
end macro; 

macro getImmediate(encodedInstr: unsigned) : unsigned := 
	if (((((encodedInstr and resize(127,32)) = resize(19,32)) or ((encodedInstr and resize(127,32)) = resize(3,32))) or ((encodedInstr and resize(127,32)) = resize(103,32))) and (getInstr(encodedInstr) = INSTR_SRAI)) then unsigned(((shift_right(encodedInstr,resize(20,32))) and resize(31,32)))
	elsif (((((encodedInstr and resize(127,32)) = resize(19,32)) or ((encodedInstr and resize(127,32)) = resize(3,32))) or ((encodedInstr and resize(127,32)) = resize(103,32))) and (((shift_right(encodedInstr,resize(31,32))) and resize(1,32)) = resize(0,32))) then unsigned((shift_right(encodedInstr,resize(20,32))))
	elsif (((((encodedInstr and resize(127,32)) = resize(19,32)) or ((encodedInstr and resize(127,32)) = resize(3,32))) or ((encodedInstr and resize(127,32)) = resize(103,32)))) then unsigned((resize(4294963200,32) or (shift_right(encodedInstr,resize(20,32)))))
	elsif (((encodedInstr and resize(127,32)) = resize(35,32)) and (((shift_right(encodedInstr,resize(31,32))) and resize(1,32)) = resize(0,32))) then unsigned((((shift_right(encodedInstr,resize(20,32))) and resize(4064,32)) or ((shift_right(encodedInstr,resize(7,32))) and resize(31,32))))
	elsif (((encodedInstr and resize(127,32)) = resize(35,32))) then unsigned((resize(4294963200,32) or (((shift_right(encodedInstr,resize(20,32))) and resize(4064,32)) or ((shift_right(encodedInstr,resize(7,32))) and resize(31,32)))))
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(31,32))) and resize(1,32)) = resize(0,32))) then unsigned(((((shift_left(encodedInstr,resize(4,32))) and resize(2048,32)) or ((shift_right(encodedInstr,resize(20,32))) and resize(2016,32))) or ((shift_right(encodedInstr,resize(7,32))) and resize(30,32))))
	elsif (((encodedInstr and resize(127,32)) = resize(99,32))) then unsigned((resize(4294963200,32) or ((((shift_left(encodedInstr,resize(4,32))) and resize(2048,32)) or ((shift_right(encodedInstr,resize(20,32))) and resize(2016,32))) or ((shift_right(encodedInstr,resize(7,32))) and resize(30,32)))))
	elsif ((((encodedInstr and resize(127,32)) = resize(55,32)) or ((encodedInstr and resize(127,32)) = resize(23,32)))) then unsigned((encodedInstr and resize(4294963200,32)))
	elsif (((encodedInstr and resize(127,32)) = resize(111,32)) and (((shift_right(encodedInstr,resize(31,32))) and resize(1,32)) = resize(0,32))) then unsigned((((encodedInstr and resize(1044480,32)) or ((shift_right(encodedInstr,resize(9,32))) and resize(2048,32))) or ((shift_right(encodedInstr,resize(20,32))) and resize(2046,32))))
	elsif (((encodedInstr and resize(127,32)) = resize(111,32))) then unsigned((resize(4293918720,32) or (((encodedInstr and resize(1044480,32)) or ((shift_right(encodedInstr,resize(9,32))) and resize(2048,32))) or ((shift_right(encodedInstr,resize(20,32))) and resize(2046,32)))))
	else unsigned(resize(0,32));
end if;
end macro; 

macro getInstr(encodedInstr: unsigned) : Instr_t := 
	if (((encodedInstr and resize(127,32)) = resize(55,32))) then (INSTR_LUI)
	elsif (((encodedInstr and resize(127,32)) = resize(23,32))) then (INSTR_AUIPC)
	elsif (((encodedInstr and resize(127,32)) = resize(111,32))) then (INSTR_JAL)
	elsif (((encodedInstr and resize(127,32)) = resize(103,32))) then (INSTR_JALR)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32))) then (INSTR_BEQ)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_BNE)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(4,32))) then (INSTR_BLT)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32))) then (INSTR_BGE)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(6,32))) then (INSTR_BLTU)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(7,32))) then (INSTR_BGEU)
	elsif (((encodedInstr and resize(127,32)) = resize(99,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32))) then (INSTR_LB)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_LH)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(2,32))) then (INSTR_LW)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(4,32))) then (INSTR_LBU)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32))) then (INSTR_LHU)
	elsif (((encodedInstr and resize(127,32)) = resize(3,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(35,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32))) then (INSTR_SB)
	elsif (((encodedInstr and resize(127,32)) = resize(35,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_SH)
	elsif (((encodedInstr and resize(127,32)) = resize(35,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(2,32))) then (INSTR_SW)
	elsif (((encodedInstr and resize(127,32)) = resize(35,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32))) then (INSTR_ADDI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_SLLI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(2,32))) then (INSTR_SLTI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(3,32))) then (INSTR_SLTIU)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(4,32))) then (INSTR_XORI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) then (INSTR_SRLI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(32,32))) then (INSTR_SRAI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(6,32))) then (INSTR_ORI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(7,32))) then (INSTR_ANDI)
	elsif (((encodedInstr and resize(127,32)) = resize(19,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) then (INSTR_ADD)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(32,32))) then (INSTR_SUB)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_SLL)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(2,32))) then (INSTR_SLT)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(3,32))) then (INSTR_SLTU)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(4,32))) then (INSTR_XOR)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) then (INSTR_SRL)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(32,32))) then (INSTR_SRA)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(6,32))) then (INSTR_OR)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(7,32))) then (INSTR_AND)
	elsif (((encodedInstr and resize(127,32)) = resize(51,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(15,32)) and ((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and ((encodedInstr and unsigned(resize(-267415680,32))) = resize(0,32)))) then (INSTR_FENCE)
	elsif (((encodedInstr and resize(127,32)) = resize(15,32)) and ((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32)) and ((encodedInstr and unsigned(resize(-28800,32))) = resize(0,32)))) then (INSTR_FENCEI)
	elsif (((encodedInstr and resize(127,32)) = resize(15,32))) then (INSTR_UNKNOWN)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_ECALL)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(1,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_EBREAK)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(1,32))) then (INSTR_CSRRW)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(2,32))) then (INSTR_CSRRS)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(3,32))) then (INSTR_CSRRC)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(5,32))) then (INSTR_CSRRWI)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(6,32))) then (INSTR_CSRRSI)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(7,32))) then (INSTR_CSRRCI)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(2,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_URET)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(8,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(2,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_SRET)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(24,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(2,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_MRET)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(8,32))) and (((shift_right(encodedInstr,resize(20,32))) and resize(31,32)) = resize(5,32))) and (((shift_right(encodedInstr,resize(15,32))) and resize(31,32)) = resize(0,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_WFI)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32)) and (((((shift_right(encodedInstr,resize(12,32))) and resize(7,32)) = resize(0,32)) and (((shift_right(encodedInstr,resize(25,32))) and resize(127,32)) = resize(9,32))) and (((shift_right(encodedInstr,resize(7,32))) and resize(31,32)) = resize(0,32)))) then (INSTR_SFENCEVMA)
	elsif (((encodedInstr and resize(127,32)) = resize(115,32))) then (INSTR_UNKNOWN)
	else (INSTR_UNKNOWN);
end if;
end macro; 

macro getMemoryMask(instr: Instr_t) : ME_MaskType := 
	if (((instr = INSTR_LW) or (instr = INSTR_SW))) then (MT_W)
	elsif (((instr = INSTR_LH) or (instr = INSTR_SH))) then (MT_H)
	elsif (((instr = INSTR_LB) or (instr = INSTR_SB))) then (MT_B)
	elsif ((instr = INSTR_LHU)) then (MT_HU)
	elsif ((instr = INSTR_LBU)) then (MT_BU)
	else (MT_X);
end if;
end macro; 

macro getOpcode(encodedInstr: unsigned) : unsigned := 
	unsigned((encodedInstr and resize(127,32)));
end macro; 

macro getRDAddr(encodedInstr: unsigned) : unsigned := 
	unsigned(((shift_right(encodedInstr,resize(7,32))) and resize(31,32)));
end macro; 

macro getRS(RSAddr: unsigned;reg_01: unsigned;reg_02: unsigned;reg_03: unsigned) : unsigned := 
	if (((RSAddr and resize(3,32)) = resize(1,32))) then unsigned(reg_01)
	elsif (((RSAddr and resize(3,32)) = resize(2,32))) then unsigned(reg_02)
	elsif (((RSAddr and resize(3,32)) = resize(3,32))) then unsigned(reg_03)
	else unsigned(resize(0,32));
end if;
end macro; 

macro getRS1Addr(encodedInstr: unsigned) : unsigned := 
	unsigned(((shift_right(encodedInstr,resize(15,32))) and resize(31,32)));
end macro; 

macro getRS2Addr(encodedInstr: unsigned) : unsigned := 
	unsigned(((shift_right(encodedInstr,resize(20,32))) and resize(31,32)));
end macro; 

macro getReg1Val(RDAddr: unsigned;newVal: unsigned;reg_01: unsigned) : unsigned := 
	if (((RDAddr and resize(3,32)) = resize(1,32))) then unsigned(newVal)
	else unsigned(reg_01);
end if;
end macro; 

macro getReg2Val(RDAddr: unsigned;newVal: unsigned;reg_02: unsigned) : unsigned := 
	if (((RDAddr and resize(3,32)) = resize(2,32))) then unsigned(newVal)
	else unsigned(reg_02);
end if;
end macro; 

macro getReg3Val(RDAddr: unsigned;newVal: unsigned;reg_03: unsigned) : unsigned := 
	if (((RDAddr and resize(3,32)) = resize(3,32))) then unsigned(newVal)
	else unsigned(reg_03);
end if;
end macro; 

