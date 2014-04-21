library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity simple_counter is
	--counts from 0 (inclusive) to max (exclusive)
	generic(N: integer);
	port(clk: in std_logic;
			max: in unsigned(N-1 downto 0);
			outp: out unsigned(N-1 downto 0));
end entity;
architecture a of simple_counter is
	signal cv,nv: unsigned(N-1 downto 0);
begin
	cv <= nv when rising_edge(clk);
	nv <= cv+1 when cv<max-1 else to_unsigned(0,N);
	outp <= cv;
end architecture;
