library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity debugtool_switchAsButton is
port(sw,clk: in std_logic;
		-- evt is asserted for 1 clock cycle whenever sw
		-- is flipped (either from 0 to 1 or vice versa)
		evt: out std_logic);
end entity;

architecture a of debugtool_switchAsButton is
	signal sw1,sw2: std_logic;
begin
	sw1 <= sw when rising_edge(clk);
	sw2 <= sw1 when rising_edge(clk);
	evt <= sw1 xor sw2 when rising_edge(clk);
end architecture;

