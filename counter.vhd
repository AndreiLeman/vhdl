library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity counter is
	--counts from 0 (inclusive) to max (exclusive)
	generic(N: integer; max: integer);
	port(clk: in std_logic;
			outp: out unsigned(N-1 downto 0));
end entity;
architecture a of counter is
	signal cv: unsigned(N-1 downto 0) := to_unsigned(0,N);
	signal adder1: unsigned(N-1 downto 0) := to_unsigned(1,N);
	signal nv,adder: unsigned(N-1 downto 0);
	signal comp,comp1: std_logic := '0';
	signal adder2,adder3: unsigned(N-1 downto 0);
begin
	cv <= nv when rising_edge(clk);
	adder <= cv+2;
	adder2 <= cv-to_unsigned(max-2,N);
	comp <= '1' when cv>=max-2 else '0';
	adder1 <= adder when rising_edge(clk);
	adder3 <= adder2 when rising_edge(clk);
	comp1 <= comp when rising_edge(clk);
	nv <= adder3 when comp1='1' else adder1;
	outp <= cv;
end architecture;
