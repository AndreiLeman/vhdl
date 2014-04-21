library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity volumeControl is
	port(inp: in signed(15 downto 0);
			outp: out signed(19 downto 0);
			vol: in std_logic_vector(2 downto 0));
end entity;
architecture a of volumeControl is
	signal scale: unsigned(8 downto 0);
	signal vol1: unsigned(2 downto 0);
	signal tmp: signed(25 downto 0);
begin
	vol1 <= unsigned(vol);
	scale <= vol1*vol1*vol1;
	tmp <= inp*("0"&signed(scale));
	outp <= tmp(25 downto 6);
end architecture;
