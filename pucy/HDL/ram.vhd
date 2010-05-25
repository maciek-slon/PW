-------------------------------------
-- RAM
-- pamiec dostepna pod adresami 0x100 - 0x1FF
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library lpm;
use lpm.lpm_components.lpm_ram_dp;
use lpm.lpm_components.lpm_ram_dq;

entity ram is
port (	RAM_GEN : in std_logic;
		RAM_DATA : inout std_logic_vector (7 downto 0);
		RAM_ADDR : in std_logic_vector (15 downto 0);
		RAM_MREQ : in std_logic;
		RAM_WR : in std_logic;
		RAM_RD : in std_logic);
end entity ram;

architecture pamiec_RAM of ram is
shared variable DOUT : std_logic_vector (7 downto 0);
signal ENAB : std_logic;

begin
f0: lpm_ram_dq 
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 8, LPM_NUMWORDS => 256,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "REGISTERED",
				LPM_ADDRESS_CONTROL => "REGISTERED")
		port map (	address => RAM_ADDR(7 downto 0), q => DOUT, 
					data => RAM_DATA, we => (not RAM_WR) and (not RAM_MREQ) and ENAB , inclock => RAM_GEN, outclock => RAM_GEN);	

	--Ustawianie szyny danych w stan wysokiej impedancji, gdy nie jest uzywana
	RAM_DATA <= DOUT when ((not RAM_RD) and (not RAM_MREQ) and ENAB) = '1'
				else (others => 'Z');
				
	ENAB <= '1' when (RAM_ADDR(15 downto 8) = x"01")
			else '0';

end architecture pamiec_RAM;
