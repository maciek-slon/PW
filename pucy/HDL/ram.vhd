-------------------------------------
-- RAM
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
shared variable DIN : std_logic_vector (7 downto 0);
shared variable DOUT : std_logic_vector (7 downto 0);
shared variable ADR : std_logic_vector (4 downto 0);

begin
--f0: lpm_ram_dp
--		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 5, LPM_NUMWORDS => 32,
--				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "REGISTERED",
--				LPM_RDADDRESS_CONTROL => "REGISTERED",
--				LPM_WRADDRESS_CONTROL => "REGISTERED")
--		port map (	rdaddress => ADR, q => DOUT, rden => (not RAM_RD) and (not RAM_MREQ) and (not RAM_ADDR(5)) , rdclock => RAM_GEN, rdclken => '1',
--					wraddress => ADR, data => RAM_DATA, wren => not RAM_WR, wrclken => '1', wrclock => RAM_GEN);	
--(not RAM_WR) and (not RAM_MREQ) and (not RAM_ADDR(5))

f0: lpm_ram_dq 
		generic map (LPM_WIDTH => 8, LPM_WIDTHAD => 5, LPM_NUMWORDS => 32,
				LPM_INDATA => "REGISTERED", LPM_OUTDATA => "REGISTERED",
				LPM_ADDRESS_CONTROL => "REGISTERED")
		port map (	address => RAM_ADDR(4 downto 0), q => DOUT, 
					data => RAM_DATA, we => (not RAM_WR) and (not RAM_MREQ) and (not RAM_ADDR(5)), inclock => RAM_GEN, outclock => RAM_GEN);	

	
	RAM_DATA <= DOUT when ((not RAM_RD) and (not RAM_MREQ) and (not RAM_ADDR(5))) = '1'
				else (others => 'Z');

--p0:	process (RAM_GEN, RAM_MREQ, RAM_ADDR) is
--	begin
--		if rising_edge(RAM_GEN) and RAM_MREQ = '0' and RAM_ADDR(15 downto 5) = "00000000000" then --za³o¿enie, ¿e RAM jest pod adresami od 0 do 1F
--			ADR := RAM_ADDR(4 downto 0);
--			if RAM_RD = '0' then 
--				RAM_DATA <= DOUT; 
--			elsif RAM_WR = '0' then 
--				DIN := RAM_DATA;
--			else
--				RAM_DATA <= (others => 'Z');
--			end if;
--		end if;
--	end process p0;
end architecture pamiec_RAM;
