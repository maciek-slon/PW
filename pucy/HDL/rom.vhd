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
	port map (	address => R_ADDR(4 downto 0), q => R_DATA, memenab=> (not R_RD) and R_ADDR(5) and (not R_MREQ));

end architecture pamiec_ROM;
