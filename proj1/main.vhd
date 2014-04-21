library ieee;
library slow_clock;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use slow_clock.all;

entity asdf is
	port (a,clk: in std_logic;
			b: out std_logic);
end entity asdf;

architecture aaa of asdf is
	type states is (idle,a0,a1,a2);
	signal cs,ns: states;
	signal clk2: std_logic;
begin
	sc: entity slow_clock.slow_clock
		port map 
		(
			clk => clk,
			o => clk2
		);
	cs <= ns when rising_edge(clk2);
	ns <= idle when (cs=idle and a='0') or cs=a2 else
			a0 when cs=idle and a='1' else
			a1 when cs=a0 else
			a2; -- when cs=a1;
	b <= '0' when cs=idle else '1';
end architecture aaa;
