-------------------------------------
-- MNOZARKA
-------------------------------------
-- zrodlo:
--   http://en.wikipedia.org/wiki/Booth's_multiplication_algorithm
-------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity booth_multiply is
generic (n : positive := 8);
port ( M, R: in std_logic_vector (n - 1 downto 0); --liczby do pomnozenia
		WYN: out std_logic_vector (2*n - 1 downto 0); --wynik mnozenia
		MUL_WT : out std_ulogic; -- sygnal trwania przetwarzania
		MUL_GEN: in std_ulogic;-- sygnal zegarowy
		MUL_CR : in std_ulogic; -- sygnal reset  
		MUL : in std_ulogic);
end entity booth_multiply;

architecture booth_multiply_arch of booth_multiply is 
shared variable A, S, P : std_logic_vector(2*n downto 0); -- dlugosc 2n+1
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
