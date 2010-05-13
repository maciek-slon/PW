-------------------------------------
-- MNOZARKA
-------------------------------------
-- Ÿród³o:
--   http://en.wikipedia.org/wiki/Booth's_multiplication_algorithm
-------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity booth_multiply is
generic (n : positive := 8);
port ( M, R: in std_logic_vector (n - 1 downto 0); --liczby do pomnozenia
		WYN: out std_logic_vector (2*n - 1 downto 0); --wynik mnozenia
		MUL_WT : out std_ulogic; -- sygna³ trwania przetwarzania
		MUL_GEN: in std_ulogic;-- sygna³ zegarowy
		MUL_CR : in std_ulogic; -- sygna³ reset  
		MUL : in std_ulogic);
end entity booth_multiply;

architecture booth_multiply_arch of booth_multiply is 
shared variable A, S, P : std_logic_vector(2*n downto 0); -- d³ugoœæ 2n+1
shared variable Z1 : std_logic_vector(n downto 0);
shared variable Z2 : std_logic_vector(n-1 downto 0);
shared variable MM : std_logic_vector(n-1 downto 0);
shared variable CNT : integer range 0 to 31;
type stany is (ST0, ST1, ST2, ST3, ST4);

shared variable STAN : stany;

begin
	p0 : process (MUL_GEN, MUL_CR, M, R, MUL) is
		begin
		
		if(MUL_CR = '0') then
			STAN := ST0;
			MUL_WT <= '0';
			WYN <= (others => '0');
			Z1 := (others => '0');
			Z2 := (others => '0');
		else 
			if rising_edge(MUL_GEN) then
				case (STAN) is
					when ST0 =>
						WYN <= (others => '0');
						if (MUL = '1') then
							MUL_WT <= '1';
							STAN := ST1;
							MM := not M;
							MM := UNSIGNED(MM) + 1;
							A := (M & Z1);
							S := (MM & Z1);
							P := (Z2 & R & '0');
							CNT := 0;
						else 
							MUL_WT <= '0';
							STAN := ST0;
						end if;
					when ST1 => 
						MUL_WT <= '1';
						if (P(1 downto 0) = "01") then
							P := UNSIGNED(P) + UNSIGNED(A);
						elsif (P(1 downto 0) = "10") then
							P := UNSIGNED(P) + UNSIGNED(S);
						end if;
						STAN := ST2;
					when ST2 => 
						MUL_WT <= '1';
						if (CNT < n) then
							STAN := ST1;
							P := (P(2*n) & P(2*n downto 1));
							CNT := CNT + 1;
						else
							STAN := ST3;
							CNT := 0;
						end if;
					when ST3 => 
						MUL_WT <= '0';
						if (MUL = '1') then
							WYN <= P(2*n downto 1);
							STAN := ST3;
						else
							WYN <= (others => '0');
							STAN := ST0;
						end if;
					when others => 
						MUL_WT <= '0';
				end case;
			end if;					
		end if;		
				
	end process p0;

end architecture booth_multiply_arch;



-------------------------------------
-- ROM
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library lpm;
use lpm.lpm_components.lpm_rom;

entity rom is
port (	R_GEN : in std_logic;
		R_DATA : inout std_logic_vector (7 downto 0);
		R_ADDR : in std_logic_vector (15 downto 0);
		R_MREQ : in std_logic;
		R_RD : in std_logic);
end entity rom;

architecture pamiec_ROM of rom is
shared variable DOUT : std_logic_vector (7 downto 0);
shared variable ADR : std_logic_vector (4 downto 0);

begin

e0: lpm_rom
	generic map(LPM_WIDTH => 8, LPM_WIDTHAD => 5, LPM_NUMWORDS => 32,
				LPM_FILE=>"none.mif",
				LPM_OUTDATA => "UNREGISTERED",
				LPM_ADDRESS_CONTROL => "UNREGISTERED", LPM_HINT=>"UNUSED")
	port map (	address => R_ADDR(4 downto 0), q => R_DATA, memenab=> (not R_RD) and R_ADDR(5));

end architecture pamiec_ROM;

-------------------------------------
-- RAM
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library lpm;
use lpm.lpm_components.lpm_ram_dp;

entity ram is
port (	RAM_GEN : in std_logic;
		RAM_DATA : inout std_logic_vector (7 downto 0);
		RAM_ADDR : in std_logic_vector (15 downto 0);
		RAM_MREQ : in std_logic;
		RAM_WR : in std_logic;
		RAM_RD : in std_logic);
end entity ram;

architecture pamiec_RAM of ram is
shared variable DIN : std_logic_vector (7 downto 0);
shared variable DOUT : std_logic_vector (7 downto 0);
shared variable ADR : std_logic_vector (4 downto 0);

begin
--e0: lpm_ram_dq
--	generic map(LPM_WIDTH => 8, LPM_WIDTHAD => 5, LPM_NUMWORDS => 32,
--				LPM_INDATA => "UNREGISTERED", LPM_OUTDATA => "UNREGISTERED",
--				LPM_ADDRESS_CONTROL => "UNREGISTERED")
--	port map (	data => DIN, address => ADR, we => not RAM_WR, q => DOUT);
	
f0: lpm_ram_dp
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 5, LPM_NUMWORDS => 32,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "UNREGISTERED",
				LPM_RDADDRESS_CONTROL => "UNREGISTERED",
				LPM_WRADDRESS_CONTROL => "REGISTERED")
		port map (	rdaddress => ADR, q => DOUT,
					wraddress => ADR, data => DIN, wren => not RAM_WR, wrclken => '1', wrclock => RAM_GEN);	

p0:	process (RAM_GEN, RAM_MREQ, RAM_ADDR) is
	begin
		if rising_edge(RAM_GEN) and RAM_MREQ = '0' and RAM_ADDR(15 downto 5) = "00000000000" then --za³o¿enie, ¿e RAM jest pod adresami od 0 do 1F
			ADR := RAM_ADDR(4 downto 0);
			if RAM_RD = '0' then 
				RAM_DATA <= DOUT; 
			elsif RAM_WR = '0' then 
				DIN := RAM_DATA;
			else
				RAM_DATA <= (others => 'Z');
			end if;
		end if;
	end process p0;
end architecture pamiec_RAM;
	

-------------------------------------
-- CPU module
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library lpm;
use lpm.lpm_components.lpm_ram_dp;

entity cpu is
port (	CR : in std_logic;
		GEN : in std_logic;
		DATA : inout std_logic_vector (7 downto 0);
		ADDR : buffer std_logic_vector (15 downto 0);
		MREQ : buffer std_logic;
		IOREQ : buffer std_logic;
		RD : buffer std_logic;
		WR : buffer std_logic;
		WT : in std_logic;
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
end entity cpu;

architecture cpu of cpu is

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

COMPONENT booth_multiply is
	GENERIC ( n : INTEGER := 8 );
	PORT
	(
		M		:	 IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		R		:	 IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		WYN		:	 OUT STD_LOGIC_VECTOR(2*n-1 DOWNTO 0);
		MUL_WT	:	 OUT STD_ULOGIC;
		MUL_GEN	:	 IN STD_ULOGIC;
		MUL_CR	:	 IN STD_ULOGIC;
		MUL		:	 IN STD_ULOGIC
	);
END COMPONENT booth_multiply;

COMPONENT output_lpt is
	PORT
	(
		LPT_GEN			:	 IN STD_LOGIC;
		LPT_CR			:	 IN STD_LOGIC;

		LPT_ADDR		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_DATA		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_IOREQ		:	 IN STD_LOGIC;
		LPT_RD			:	 IN STD_LOGIC;
		LPT_WR			:	 IN STD_LOGIC;
		LPT_WT			:	 OUT STD_LOGIC;

		LPT_OUT_DATA	:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		LPT_BUSY		:	 IN STD_LOGIC;
		LPT_ACK			:	 IN STD_LOGIC;
		LPT_STROBE		:	 OUT STD_LOGIC;
		LPT_SELECTLN	:	 OUT STD_LOGIC;
		LPT_SEL			:	 IN STD_LOGIC;
		LPT_INIT		:	 OUT STD_LOGIC;
		LPT_AUTOFD		:	 OUT STD_LOGIC
	);
END COMPONENT output_lpt;

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

type stany is (ST0, ST1, ST2, ST3, ST4, ST5, ST6, ST7, ST_WAIT);
shared variable STAN : stany;

-- sterowanie pamiêci¹ rejestrów
shared variable REG_A : std_logic_vector (2 downto 0);
shared variable REG_D : std_logic_vector (2 downto 0);
shared variable D_A : std_logic_vector (7 downto 0);
shared variable R_D : std_logic_vector (7 downto 0);
shared variable WR_ENA : std_logic;

-- instruction cache
shared variable IC1 : std_logic_vector (7 downto 0);
shared variable IC2 : std_logic_vector (7 downto 0);
shared variable IC3 : std_logic_vector (7 downto 0);

-- register cachce
shared variable TMP0 : std_logic_vector (7 downto 0);
shared variable TMP1 : std_logic_vector (7 downto 0);
shared variable TMP2 : std_logic_vector (7 downto 0);

shared variable TMP : std_logic;

-- OUT_LPT
shared variable OUT_WT: std_logic;

-- IN_PS2
shared variable IN_WT: std_logic;

-- mnozarka
shared variable B_M : std_logic;
shared variable M_WT : std_logic;
shared variable M_WY : std_logic_vector (7 downto 0);

-- flaga ustawiana po instrukcji STOP, zawiesza dzia³anie procesora
shared variable STOP : std_logic;

-- program counter
shared variable PC : integer range 0 to 63;

-- pomocnicze liczniki
shared variable CNT : std_logic_vector(1 downto 0);
--shared variable DELAY : integer := 0;
shared variable DELAY : std_logic_vector(2 downto 0) := "000";

------------------------
-- funkcje pomocnicze
------------------------
function READ_REG(ADR : in std_logic_vector) return std_logic_vector is
begin
	REG_A := ADR;
	return (D_A);
end function READ_REG;

function WRITE_REG(ADR : in std_logic_vector; D : in std_logic_vector) return std_logic is
begin
	R_D := D;
	REG_D := ADR;
	WR_ENA := '1';
	return('1');
end function WRITE_REG;

function READ_RAM(ADR : in std_logic_vector) return std_logic is
begin
	ADDR <= ADR; 
	RD <= '0';
	WR <= '1';
	MREQ <= '0';
	IOREQ <= '1';
	return('1');
end function READ_RAM;

function WRITE_RAM(ADR : in std_logic_vector) return std_logic is
begin
	ADDR <= ADR; 
	RD <= '1';
	WR <= '0';
	MREQ <= '0';
	IOREQ <= '1';
	return('1');
end function WRITE_RAM;

function WRITE_OUT(ADR : in std_logic_vector) return std_logic is
begin
	ADDR <= (x"00" & ADR); 
	RD <= '1';
	WR <= '0';
	MREQ <= '1';
	IOREQ <= '0';
	return('1');
end function WRITE_OUT;

function READ_IN(ADR : in std_logic_vector) return std_logic is
begin
	ADDR <= (x"00" & ADR); 
	RD <= '0';
	WR <= '1';
	MREQ <= '1';
	IOREQ <= '0';
	return('1');
end function READ_IN;

begin
rom0: rom port map (R_GEN => GEN,   R_DATA => DATA,   R_ADDR => ADDR,   R_MREQ => MREQ,                 R_RD => RD);

ram0: ram port map (RAM_GEN => GEN, RAM_DATA => DATA, RAM_ADDR => ADDR, RAM_MREQ => MREQ, RAM_WR => WR, RAM_RD => RD);

mul0: booth_multiply port map (	M => TMP1, R => TMP2, WYN(7 downto 0) => M_WY, MUL_WT => M_WT, MUL_GEN => GEN, MUL_CR => CR, MUL => B_M);

lpt0: output_lpt port map (LPT_ADDR => ADDR(7 downto 0), LPT_DATA => DATA, LPT_IOREQ => IOREQ, LPT_RD => RD, LPT_WR => WR,
						    LPT_GEN => GEN, LPT_CR => CR, LPT_OUT_DATA => OUT_DATA,  LPT_BUSY => BUSY,
							LPT_ACK => ACK, LPT_STROBE => STROBE, LPT_SELECTLN => SELECTLN,  LPT_SEL => SEL, 
							LPT_INIT => INIT, LPT_AUTOFD => AUTOFD, LPT_WT => OUT_WT);

ps20: input_ps2 port map (	PS2_DATA => DATA, PS2_GEN => GEN, PS2_CR => CR, PS2_ADDR => ADDR(7 downto 0),
							PS2_IOREQ => IOREQ, PS2_RD => RD, PS2_WR => WR, PS2_WT => IN_WT, PS2_IN_DATA => IN_DATA, PS2_IN_CLK => IN_CLK);
							

regA: lpm_ram_dp
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 3, LPM_NUMWORDS => 8,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "UNREGISTERED",
				LPM_RDADDRESS_CONTROL => "UNREGISTERED",
				LPM_WRADDRESS_CONTROL => "REGISTERED")
		port map (	rdaddress => REG_A, q => D_A,
					wraddress => REG_D, data => R_D, wren => WR_ENA, wrclken => '1', wrclock => GEN);


p0:	process (GEN, CR) is
	begin
		if(CR = '0') then
			PC := 32; -- pocz¹tek adresów pamiêci ROM
			CNT := "00";
			DATA <= (others => 'Z');
			RD <= '1';
			WR <= '1';
			MREQ <= '1';
			IOREQ <= '1';
			STAN := ST0;
			STOP := '0';
		elsif (rising_edge(GEN)) then
			
			case STAN is
			
				when ST0 => --jeœli PC < od 32 (max pamieci), odczyt instrukcji z ROM
					IF (STOP = '1') THEN
						STAN := ST0;
					ELSE
						STAN := ST1;
						ADDR <= conv_std_logic_vector(PC, 16); 
						RD <= '0';
						WR <= '1';
						MREQ <= '0';
						IOREQ <= '1';
						DATA <= (others => 'Z');
						WR_ENA := '0';
						B_M := '0';
					END IF;
					
				when ST1 => --oczekiwanie na odczyt z pamieci
					if (UNSIGNED(DELAY) < 3) THEN
						DELAY := UNSIGNED(DELAY) + 1;
						STAN := ST1;
					ELSE
						STAN := ST2;
						DELAY := "000";
					END IF;
					
				when ST2 => -- wstêpne pobranie instrukcji i operandów
					case CNT is
						when "00" => 
							IC1 := DATA; 
							STAN := ST0; 
							CNT := "01"; 
							PC := PC + 1;
						when "01" => 
							IC2 := DATA; 
							STAN := ST0; 
							CNT := "10"; 
							PC := PC + 1;
							TMP0 := READ_REG(IC1(2 downto 0));
						when "10" => 
							TMP0 := D_A;
							IC3 := DATA;
							STAN := ST1; 
							CNT := "11"; 
							PC := PC - 2;
							TMP1 := READ_REG(IC2(6 downto 4));
						when "11" =>
							TMP1 := D_A;
							TMP2 := READ_REG(IC2(2 downto 0));
							STAN := ST3;
							CNT := "00";
					end case;
					RD <= '1';
					WR <= '1';
					MREQ <= '1';
					IOREQ <= '1';
					
				when ST_WAIT =>
					if (UNSIGNED(DELAY) < 1) THEN
						DELAY := UNSIGNED(DELAY) + 1;
						STAN := ST_WAIT;
					ELSE
						STAN := ST0;
						DELAY := "000";
					END IF;
					
				when ST3 =>
					TMP2 := D_A;
								
					case IC1(7 downto 3) is
						when "00000" => -- OK STOP
							STOP := '1';
							STAN := ST0;
							
						when "00001" => --    JMP 0
							PC := 32;
							STAN := ST0;
							
						when "00010" => --    JMP A
							PC := CONV_INTEGER(UNSIGNED(IC2));
							STAN := ST0;
							
						when "00011" => --    JZ Rd, A
							IF (TMP0 = x"00") THEN
								PC := CONV_INTEGER(UNSIGNED(IC2));
							END IF;
							STAN := ST0;
							
						when "00100" => -- OK Rd <= Ra + Rb
							TMP := WRITE_REG(IC1(2 downto 0), UNSIGNED(TMP1) + UNSIGNED(TMP2));
							PC := PC + 2;
							STAN := ST0;
							
						when "00101" => -- OK Rd <= Ra - Rb
							TMP := WRITE_REG(IC1(2 downto 0), UNSIGNED(TMP1) - UNSIGNED(TMP2));
							PC := PC + 2;
							STAN := ST0;
							
						when "00110" => -- OK Rd <= RAM(RaRb)
							if (DELAY = "000") then 
								TMP := READ_RAM( (TMP1 & TMP2) );
								DELAY := UNSIGNED(DELAY) + 1;
							elsif(UNSIGNED(DELAY) < 3) then
								DELAY := UNSIGNED(DELAY) + 1;
							else
								RD <= '1';
								TMP := WRITE_REG(IC1(2 downto 0), DATA);
								DELAY := "000";
								PC := PC + 2;
								STAN := ST0;
							end if;
						
						when "01000" => -- OK Rd <= Ra # Rb					
							TMP := WRITE_REG(IC1(2 downto 0), TMP1 or TMP2);
							PC := PC + 2;
							STAN := ST0;
							
						when "01001" => -- OK Rd <= Ra & Rb
							TMP := WRITE_REG(IC1(2 downto 0), TMP1 and TMP2);
							PC := PC + 2;
							STAN := ST0;
							
						when "01010" => -- OK Rd <= DIN
							TMP := WRITE_REG(IC1(2 downto 0), IC2);

							PC := PC + 2;
							STAN := ST0;
						
						when "01110" => -- OK Rd => RAM(A)
							DATA <= TMP0;
							TMP := WRITE_RAM((IC2 & IC3));
							
							PC := PC + 3;
							STAN := ST_WAIT;
						
						when "10100" => -- OK Rd <= Ra * Rb
							TMP := M_WT;
							if(UNSIGNED(DELAY) < 3) then
								B_M := '1';
								--M_WT := '1';
								DELAY := UNSIGNED(DELAY) + 1;
							else
								
								if (M_WT = '1') then
									STAN := ST3;
									TMP0 := M_WY;
								else			
									B_M := '0';	
									TMP := WRITE_REG(IC1(2 downto 0), M_WY);
									
									PC := PC + 2;
									STAN := ST0;
									DELAY := "000";
								end if;
							end if;
						
						when "01100" => --    Rd => OUT(A)
							if(UNSIGNED(DELAY) < 3) then
								DATA <= TMP0;
								TMP := WRITE_OUT(IC2);
								DELAY := UNSIGNED(DELAY) + 1;
							else
								if(OUT_WT = '1') then
									STAN := ST3;
								else
									PC := PC + 2;
									STAN := ST0;				
									DELAY := "000";
								end if;
							end if;
						
						when "01011" =>
							if(UNSIGNED(DELAY) < 3) then
								TMP := READ_IN(IC2);
								DELAY := UNSIGNED(DELAY) + 1;
							else
								if(IN_WT = '1') then
									STAN := ST3;
									
								else
									TMP := WRITE_REG(IC1(2 downto 0), DATA);
									PC := PC + 2;
									STAN := ST0;				
									DELAY := "000";
								end if;
							end if;
						
						when others =>
							STOP := '1';
							STAN := ST0;
					end case; -- IC1
				
				when others =>
					STOP := '1';
					STAN := ST0;
				
			end case;
			
		end if;
		
	end process p0;
	
end architecture cpu;
	

	