library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity random is
	generic(b: integer := 8);
	port(clk: in std_logic;
			outp: out std_logic_vector(b-1 downto 0));
end entity;
architecture a of random is
	signal tmp,tmp1,tmp2,tmp3: std_logic_vector(b-1 downto 0);
begin
	tmp<=not tmp when rising_edge(clk);
	tmp1<=tmp when rising_edge(clk);
	tmp2<=tmp when rising_edge(clk);
	tmp3<=tmp1 xor tmp2;
gen:
	for I in 0 to b-1 generate
		outp(I) <= clk when tmp3(I)='1';
	end generate;
end architecture;
