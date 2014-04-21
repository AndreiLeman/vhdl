library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity ps2Receiver is
	port(keyclk,keyclk_en: in std_logic;
			bytein: in unsigned(7 downto 0);
			keyout: out unsigned(7 downto 0);
			iskeydown,iskeyup: out std_logic);
end entity;
architecture a of ps2Receiver is
	type state_t is (normal,keyup);
	signal state,nState: state_t;
begin
	state <= nState when keyclk_en='1' and rising_edge(keyclk);
	nState <= keyup when state=normal and bytein=X"F0" else
				normal;
	iskeydown <= '1' when state=normal and (not (bytein=X"F0")) and (not (bytein=X"E0")) else '0';
	iskeyup <= '1' when state=keyup else '0';
	keyout <= bytein;
end architecture;
