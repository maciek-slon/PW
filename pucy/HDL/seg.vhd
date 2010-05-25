library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity seg is
port (	SEG_CR : in std_logic;
		SEG_GEN : in std_logic;
		SEG_DATA : in std_logic_vector (7 downto 0);
		SEG_ADDR : in std_logic_vector (15 downto 0);
		SEG_MREQ : in std_logic;
		SEG_WR : in std_logic;
		SEG_RD : in std_logic;
		SEG_OUT : out std_logic_vector(7 downto 0));
end entity seg;

architecture seg of seg is
shared variable D_OUT : std_logic_vector(7 downto 0);

begin

p0: process (SEG_GEN, SEG_CR, SEG_DATA)is
	begin
		if(SEG_CR = '0') then
			D_OUT := (others => '1');
		else 
			if rising_edge(SEG_GEN) then
				if (SEG_ADDR(7 downto 0) = "00001111") then
					D_OUT := SEG_DATA;
				end if;
				SEG_OUT <= D_OUT;
			end if;
		end if;

	end process p0;

end architecture seg;