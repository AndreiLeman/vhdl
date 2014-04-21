library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity test1 is
	port(a,b,c,d,e,f,g,h,i,j,clk1,clk2: in std_logic;
			x2,y2,x1,y1: out std_logic);
end entity;

architecture a of test1 is
	signal x,y: std_logic;
begin
	x <= a xor b xor c xor d xor e;
	y <= f xor g xor h xor i xor j;
	x1 <= x when rising_edge(clk1);
	x2 <= '0' when clk2='1' else x when rising_edge(clk1);
	y1 <= y when rising_edge(clk1);
	y2 <= '0' when clk2='1' else y when rising_edge(clk1);
end architecture;
