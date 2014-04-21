library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity add64 is
	port (inp1,inp2: in unsigned(31 downto 0);
			clk: in std_logic;
			outp: out unsigned(31 downto 0));
end entity;
architecture a of add64 is
	signal tmp: unsigned(31 downto 0);
begin
	tmp <= inp1+inp2;
	outp <= tmp when falling_edge(clk);
end architecture;
