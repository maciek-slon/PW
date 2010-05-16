<<<<<<< HEAD
-------------------------------------
-- CPU module
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library lpm;
use lpm.lpm_components.lpm_ram_dp;

entity cpu is
port (	CPU_CR : in std_logic;
		CPU_GEN : in std_logic;
		CPU_DATA : inout std_logic_vector (7 downto 0);
		CPU_ADDR : buffer std_logic_vector (15 downto 0);
		CPU_MREQ : buffer std_logic;
		CPU_IOREQ : buffer std_logic;
		CPU_RD : buffer std_logic;
		CPU_WR : buffer std_logic;
		CPU_WT : in std_logic);
end entity cpu;

architecture cpu of cpu is
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

type stany is (ST0, ST1, ST2, ST3, ST4, ST5, ST6, ST7, ST_WAIT);
shared variable STAN : stany;

-- sterowanie pami?ci? rejestr?w
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

-- flaga ustawiana po instrukcji STOP, zawiesza dzia?anie procesora
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
	CPU_ADDR <= ADR; 
	CPU_RD <= '0';
	CPU_WR <= '1';
	CPU_MREQ <= '0';
	CPU_IOREQ <= '1';
	return('1');
end function READ_RAM;

function WRITE_RAM(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= ADR; 
	CPU_RD <= '1';
	CPU_WR <= '0';
	CPU_MREQ <= '0';
	CPU_IOREQ <= '1';
	return('1');
end function WRITE_RAM;

function WRITE_OUT(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= (x"00" & ADR); 
	CPU_RD <= '1';
	CPU_WR <= '0';
	CPU_MREQ <= '1';
	CPU_IOREQ <= '0';
	return('1');
end function WRITE_OUT;

function READ_IN(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= (x"00" & ADR); 
	CPU_RD <= '0';
	CPU_WR <= '1';
	CPU_MREQ <= '1';
	CPU_IOREQ <= '0';
	return('1');
end function READ_IN;

begin
mul0: booth_multiply port map (	M => TMP1, R => TMP2, WYN(7 downto 0) => M_WY, MUL_WT => M_WT, MUL_GEN => CPU_GEN, MUL_CR => CPU_CR, MUL => B_M);

regA: lpm_ram_dp
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 3, LPM_NUMWORDS => 8,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "UNREGISTERED",
				LPM_RDADDRESS_CONTROL => "UNREGISTERED",
				LPM_WRADDRESS_CONTROL => "REGISTERED")
		port map (	rdaddress => REG_A, q => D_A,
					wraddress => REG_D, data => R_D, wren => WR_ENA, wrclken => '1', wrclock => CPU_GEN);


p0:	process (CPU_GEN, CPU_CR) is
	begin
		if(CPU_CR = '0') then
			PC := 32; -- pocz?tek adres?w pami?ci ROM
			CNT := "00";
			CPU_DATA <= (others => 'Z');
			CPU_RD <= '1';
			CPU_WR <= '1';
			CPU_MREQ <= '1';
			CPU_IOREQ <= '1';
			STAN := ST0;
			STOP := '0';
		elsif (rising_edge(CPU_GEN)) then
			
			case STAN is
			
				when ST0 => --je?li PC < od 32 (max pamieci), odczyt instrukcji z ROM
					IF (STOP = '1') THEN
						STAN := ST0;
					ELSE
						STAN := ST1;
						CPU_ADDR <= conv_std_logic_vector(PC, 16); 
						CPU_RD <= '0';
						CPU_WR <= '1';
						CPU_MREQ <= '0';
						CPU_IOREQ <= '1';
						CPU_DATA <= (others => 'Z');
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
					
				when ST2 => -- wst?pne pobranie instrukcji i operand?w
					case CNT is
						when "00" => 
							IC1 := CPU_DATA; 
							STAN := ST0; 
							CNT := "01"; 
							PC := PC + 1;
						when "01" => 
							IC2 := CPU_DATA; 
							STAN := ST0; 
							CNT := "10"; 
							PC := PC + 1;
							TMP0 := READ_REG(IC1(2 downto 0));
						when "10" => 
							TMP0 := D_A;
							IC3 := CPU_DATA;
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
					CPU_RD <= '1';
					CPU_WR <= '1';
					CPU_MREQ <= '1';
					CPU_IOREQ <= '1';
					
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
								CPU_RD <= '1';
								TMP := WRITE_REG(IC1(2 downto 0), CPU_DATA);
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
							CPU_DATA <= TMP0;
							TMP := WRITE_RAM((IC2 & IC3));
							
							PC := PC + 3;
							STAN := ST_WAIT;
						
						when "10100" => --    Rd <= Ra * Rb
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
						
						when "01100" => -- Rd => OUT(A)
							if(UNSIGNED(DELAY) < 3) then
								CPU_DATA <= TMP0;
								TMP := WRITE_OUT(IC2);
								DELAY := UNSIGNED(DELAY) + 1;
							else
								if(CPU_WT = '1') then
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
								if(CPU_WT = '1') then
									STAN := ST3;
									
								else
									TMP := WRITE_REG(IC1(2 downto 0), CPU_DATA);
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
=======
-------------------------------------
-- CPU module
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library lpm;
use lpm.lpm_components.lpm_ram_dp;

entity cpu is
port (	CPU_CR : in std_logic;
		CPU_GEN : in std_logic;
		CPU_DATA : inout std_logic_vector (7 downto 0);
		CPU_ADDR : buffer std_logic_vector (15 downto 0);
		CPU_MREQ : buffer std_logic;
		CPU_IOREQ : buffer std_logic;
		CPU_RD : buffer std_logic;
		CPU_WR : buffer std_logic;
		CPU_WT : in std_logic);
end entity cpu;

architecture cpu of cpu is
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
	CPU_ADDR <= ADR; 
	CPU_RD <= '0';
	CPU_WR <= '1';
	CPU_MREQ <= '0';
	CPU_IOREQ <= '1';
	return('1');
end function READ_RAM;

function WRITE_RAM(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= ADR; 
	CPU_RD <= '1';
	CPU_WR <= '0';
	CPU_MREQ <= '0';
	CPU_IOREQ <= '1';
	return('1');
end function WRITE_RAM;

function WRITE_OUT(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= (x"00" & ADR); 
	CPU_RD <= '1';
	CPU_WR <= '0';
	CPU_MREQ <= '1';
	CPU_IOREQ <= '0';
	return('1');
end function WRITE_OUT;

function READ_IN(ADR : in std_logic_vector) return std_logic is
begin
	CPU_ADDR <= (x"00" & ADR); 
	CPU_RD <= '0';
	CPU_WR <= '1';
	CPU_MREQ <= '1';
	CPU_IOREQ <= '0';
	return('1');
end function READ_IN;

begin
mul0: booth_multiply port map (	M => TMP1, R => TMP2, WYN(7 downto 0) => M_WY, MUL_WT => M_WT, MUL_GEN => CPU_GEN, MUL_CR => CPU_CR, MUL => B_M);

regA: lpm_ram_dp
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 3, LPM_NUMWORDS => 8,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "UNREGISTERED",
				LPM_RDADDRESS_CONTROL => "UNREGISTERED",
				LPM_WRADDRESS_CONTROL => "REGISTERED")
		port map (	rdaddress => REG_A, q => D_A,
					wraddress => REG_D, data => R_D, wren => WR_ENA, wrclken => '1', wrclock => CPU_GEN);


p0:	process (CPU_GEN, CPU_CR) is
	begin
		if(CPU_CR = '0') then
			PC := 32; -- pocz¹tek adresów pamiêci ROM
			CNT := "00";
			CPU_DATA <= (others => 'Z');
			CPU_RD <= '1';
			CPU_WR <= '1';
			CPU_MREQ <= '1';
			CPU_IOREQ <= '1';
			STAN := ST0;
			STOP := '0';
		elsif (rising_edge(CPU_GEN)) then
			
			case STAN is
			
				when ST0 => --jeœli PC < od 32 (max pamieci), odczyt instrukcji z ROM
					IF (STOP = '1') THEN
						STAN := ST0;
					ELSE
						STAN := ST1;
						CPU_ADDR <= conv_std_logic_vector(PC, 16); 
						CPU_RD <= '0';
						CPU_WR <= '1';
						CPU_MREQ <= '0';
						CPU_IOREQ <= '1';
						CPU_DATA <= (others => 'Z');
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
							IC1 := CPU_DATA; 
							STAN := ST0; 
							CNT := "01"; 
							PC := PC + 1;
						when "01" => 
							IC2 := CPU_DATA; 
							STAN := ST0; 
							CNT := "10"; 
							PC := PC + 1;
							TMP0 := READ_REG(IC1(2 downto 0));
						when "10" => 
							TMP0 := D_A;
							IC3 := CPU_DATA;
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
					CPU_RD <= '1';
					CPU_WR <= '1';
					CPU_MREQ <= '1';
					CPU_IOREQ <= '1';
					
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
								CPU_RD <= '1';
								TMP := WRITE_REG(IC1(2 downto 0), CPU_DATA);
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
							CPU_DATA <= TMP0;
							TMP := WRITE_RAM((IC2 & IC3));
							
							PC := PC + 3;
							STAN := ST_WAIT;
						
						when "10100" => --    Rd <= Ra * Rb
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
						
						when "01100" => -- Rd => OUT(A)
							if(UNSIGNED(DELAY) < 3) then
								CPU_DATA <= TMP0;
								TMP := WRITE_OUT(IC2);
								DELAY := UNSIGNED(DELAY) + 1;
							else
								if(CPU_WT = '1') then
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
								if(CPU_WT = '1') then
									STAN := ST3;
									
								else
									TMP := WRITE_REG(IC1(2 downto 0), CPU_DATA);
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
>>>>>>> ce569fcde12890d044167b1accd1ccecb566f56f
