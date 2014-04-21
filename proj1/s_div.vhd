library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity s_div is
	generic(A: integer := 8);
	port(d: in unsigned(A-1 downto 0);
			clk,inp: in std_logic;
			outp: out std_logic;
			outp_r: out unsigned(A-1 downto 0));
end entity;
architecture a of s_div is
	signal cur_rem,next_rem: unsigned(A-1 downto 0);
	signal tmp1,tmp3: unsigned(A downto 0);
	signal tmp2: std_logic;
begin
	cur_rem <= next_rem when rising_edge(clk);
	outp_r <= cur_rem;
	tmp1(A downto 1) <= cur_rem;
	tmp1(0) <= inp;
	tmp2 <= '1' when tmp1>=d else '0';
	tmp3 <= tmp1-d when tmp2='1' else tmp1;
	next_rem <= tmp3(A-1 downto 0);
	outp <= tmp2;
end architecture;

