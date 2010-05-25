-------------------------------------
-- ROM
-- pamiec dostepna pod adresami 0x000 - 0x0FF
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
signal ENAB : std_logic;

begin

e0: lpm_rom
	generic map(LPM_WIDTH => 8, LPM_WIDTHAD => 8, LPM_NUMWORDS => 256,
				LPM_FILE=>"none.mif",
				LPM_OUTDATA => "UNREGISTERED",
				LPM_ADDRESS_CONTROL => "UNREGISTERED", LPM_HINT=>"UNUSED")
	port map (	address => R_ADDR(7 downto 0), q => R_DATA, memenab=> (not R_RD) and ENAB and (not R_MREQ));

	ENAB <= '1' when (R_ADDR(15 downto 8) = x"00")
			else '0';

end architecture pamiec_ROM;
