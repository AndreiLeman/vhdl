library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity triangleGenerator is
	port(clk: in std_logic;
		freq: in unsigned(31 downto 0); --periods per sample; purely fractional
		outp: out unsigned(30 downto 0));
end entity;
architecture a of triangleGenerator is
	signal counter,tmp: unsigned(31 downto 0);
begin
	counter <= counter+freq when rising_edge(clk);
	tmp <= counter when counter<to_unsigned(2**31,32) else not counter;
	outp <= tmp(30 downto 0) when rising_edge(clk);
end architecture;
