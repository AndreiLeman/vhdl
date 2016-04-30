library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- de-bounces button input
entity debugtool_buttonCleanup is
generic(N: integer := 2; --# of buttons
	stages: integer := 5);
port(clk: in std_logic;
	inp: in std_logic_vector(N-1 downto 0);
	outp: out std_logic_vector(N-1 downto 0)
);
end entity;

architecture a of debugtool_buttonCleanup is
	type a is array(0 to stages-1) of std_logic_vector(N-1 downto 0);
	type b is array(N-1 downto 0) of std_logic_vector(0 to stages-1);
	signal a1: a;
	signal b1: b;
	signal result,resultNext: std_logic_vector(N-1 downto 0);
begin
--shift register stages
	a1(0) <= inp when rising_edge(clk);
g: for I in 1 to stages-1 generate
		a1(I) <= a1(I-1) when rising_edge(clk);
	end generate;
--transpose
g2:for I in 0 to stages-1 generate
	g3:for J in 0 to N-1 generate
			b1(J)(I) <= a1(I)(J);
		end generate;
	end generate;
--combine data from stages
g4:for I in 0 to N-1 generate
		resultNext(I) <= '1' when b1(I)="11111" else
			'0' when b1(I)="00000" else
			result(I);
	end generate;
	result <= resultNext when rising_edge(clk);
	outp <= result;
end architecture;
