library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity synchronizer is
	generic(N: integer);
	port(sclk,dclk: in std_logic;
			src: in std_logic_vector(N-1 downto 0);
			dst: out std_logic_vector(N-1 downto 0);

			--accessed from dst domain
			readreq: in std_logic := '1');
end entity;
architecture a of synchronizer is
	signal ff1,ff2: std_logic_vector(N-1 downto 0);
	signal rdreq,rdreq1,rdreq2,ready,ready1,ready2: std_logic;
	signal clk_ff1,clk_ff2: std_logic;
begin
	rdreq1 <= rdreq when rising_edge(sclk);
	rdreq2 <= rdreq1 when rising_edge(sclk);
	ready <= rdreq1 and rdreq2 when rising_edge(sclk);
	ready1 <= ready when rising_edge(dclk);
	ready2 <= ready1 when rising_edge(dclk);
	clk_ff2 <= ready1 and ready2 when rising_edge(dclk);
	clk_ff1 <= rdreq1;
	rdreq <= readreq and not clk_ff2;
	
	ff1 <= src when rising_edge(clk_ff1);
	ff2 <= ff1 when rising_edge(clk_ff2);
	dst <= ff2;
end architecture;
