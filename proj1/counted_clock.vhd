library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity counted_clock is
	generic(N: integer);
	port(inp: in std_logic;
			outp: out std_logic);
end entity;

architecture a of counted_clock is
	constant delay: integer := 1000000;
	signal cnt,nextcnt: unsigned(31 downto 0) := to_unsigned(0,32);
	signal clk_en,clk_en1: std_logic := '0';
begin
	cnt <= nextcnt when falling_edge(inp);
	nextcnt <= cnt when cnt>delay+N else cnt+1;
	clk_en <= '1' when cnt>=delay and cnt<delay+N else '0';
	clk_en1 <= clk_en when falling_edge(inp);
	outp <= inp and clk_en1;
end architecture;
