library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity PUCY_MP_02 is
port (	CR : in std_logic;
		GEN : in std_logic;
		
		
		DATA 	: inout std_logic_vector (7 downto 0);
		ADDR 	: inout std_logic_vector (15 downto 0);
		MREQ 	: inout std_logic;
		IOREQ 	: inout std_logic;
		RD 		: inout std_logic;
		WR 		: inout std_logic;
		WT 		: inout std_logic;		
		
		OUT_DATA : out std_logic_vector(7 downto 0);
		BUSY : iN STD_LOGIC;
		ACK	: IN STD_LOGIC;
		STROBE : OUT STD_LOGIC;
		SELECTLN : OUT STD_LOGIC;
		SEL	: IN STD_LOGIC;
		INIT : OUT STD_LOGIC;
		AUTOFD : OUT STD_LOGIC;
		
		IN_DATA : in std_logic;
		IN_CLK: in std_logic);		
end entity PUCY_MP_02;

architecture PUCY_MP_02 of PUCY_MP_02 is

COMPONENT input_ps2 is
	PORT
	(
		PS2_DATA	:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PS2_GEN		:	 IN STD_LOGIC;
		PS2_CR		:	 IN STD_LOGIC;
		PS2_ADDR	:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		PS2_IOREQ	:	 IN STD_LOGIC;
		PS2_RD		:	 IN STD_LOGIC;
		PS2_WR		:	 IN STD_LOGIC;
		PS2_WT		:	 OUT STD_LOGIC;
		PS2_IN_DATA	:	 IN STD_LOGIC;
		PS2_IN_CLK	:	 IN STD_LOGIC
	);
END COMPONENT input_ps2;

COMPONENT output_lpt is
	PORT
	(
		LPT_GEN		:	 IN STD_LOGIC;
		LPT_CR		:	 IN STD_LOGIC;
		LPT_DATA	:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_ADDR	:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_IOREQ	:	 IN STD_LOGIC;
		LPT_RD		:	 IN STD_LOGIC;
		LPT_WR		:	 IN STD_LOGIC;
		LPT_WT		:	 OUT STD_LOGIC;
		LPT_OUT_DATA:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_BUSY	:	 IN STD_LOGIC;
		LPT_ACK		:	 IN STD_LOGIC;
		LPT_STROBE	:	 OUT STD_LOGIC;
		LPT_SELECTLN:	 OUT STD_LOGIC;
		LPT_SEL		:	 IN STD_LOGIC;
		LPT_INIT	:	 OUT STD_LOGIC;
		LPT_AUTOFD	:	 OUT STD_LOGIC
	);
END COMPONENT output_lpt;

COMPONENT rom is
	PORT
	(
		R_GEN		:	 IN STD_LOGIC;
		R_DATA		:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		R_ADDR		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		R_MREQ		:	 IN STD_LOGIC;
		R_RD		:	 IN STD_LOGIC
	);
END COMPONENT rom;

COMPONENT ram is
	PORT
	(
		RAM_GEN		:	 IN STD_LOGIC;
		RAM_DATA	:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		RAM_ADDR	:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		RAM_MREQ	:	 IN STD_LOGIC;
		RAM_WR		:	 IN STD_LOGIC;
		RAM_RD		:	 IN STD_LOGIC
	);
END COMPONENT ram;

COMPONENT cpu is
	PORT
	(
		CPU_CR		:	 IN STD_LOGIC;
		CPU_GEN		:	 IN STD_LOGIC;
		CPU_DATA		:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		CPU_ADDR		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		CPU_MREQ		:	 OUT STD_LOGIC;
		CPU_IOREQ		:	 OUT STD_LOGIC;
		CPU_RD		:	 OUT STD_LOGIC;
		CPU_WR		:	 OUT STD_LOGIC;
		CPU_WT		:	 IN STD_LOGIC
	);
END COMPONENT cpu;

--signal DATA 	: std_logic_vector (7 downto 0);
--signal ADDR 	: std_logic_vector (15 downto 0);
--signal MREQ 	: std_logic;
--signal IOREQ 	: std_logic;
--signal RD 		: std_logic;
--signal WR 		: std_logic;
--signal WT 		: std_logic;

shared variable OUT_WT : std_logic;
shared variable IN_WT : std_logic;


begin
rom0: rom port map (R_GEN => GEN,   R_DATA => DATA,   R_ADDR => ADDR,   R_MREQ => MREQ,                 R_RD => RD);
ram0: ram port map (RAM_GEN => GEN, RAM_DATA => DATA, RAM_ADDR => ADDR, RAM_MREQ => MREQ, RAM_WR => WR, RAM_RD => RD);
lpt0: output_lpt port map (LPT_ADDR => ADDR(7 downto 0), LPT_DATA => DATA, LPT_IOREQ => IOREQ, LPT_RD => RD, LPT_WR => WR,
						    LPT_GEN => GEN, LPT_CR => CR, LPT_OUT_DATA => OUT_DATA,  LPT_BUSY => BUSY,
							LPT_ACK => ACK, LPT_STROBE => STROBE, LPT_SELECTLN => SELECTLN,  LPT_SEL => SEL, 
							LPT_INIT => INIT, LPT_AUTOFD => AUTOFD, LPT_WT => OUT_WT);
ps20: input_ps2 port map (	PS2_DATA => DATA, PS2_GEN => GEN, PS2_CR => CR, PS2_ADDR => ADDR(7 downto 0),
							PS2_IOREQ => IOREQ, PS2_RD => RD, PS2_WR => WR, PS2_WT => IN_WT, PS2_IN_DATA => IN_DATA, PS2_IN_CLK => IN_CLK);
cpu0: cpu port map(	CPU_CR => CR, CPU_GEN => GEN, CPU_DATA => DATA, CPU_ADDR => ADDR, CPU_MREQ => MREQ, CPU_IOREQ => IOREQ,
					CPU_RD => RD, CPU_WR => WR, CPU_WT => OUT_WT or IN_WT);

end architecture PUCY_MP_02;