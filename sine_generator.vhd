library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sin_rom;
entity sineGenerator is
	port(clk: in std_logic;
			freq: in unsigned(27 downto 0);
			outp: out signed(8 downto 0));
end entity;
architecture a of sineGenerator is
	signal x: unsigned(27 downto 0);
	signal t: unsigned(10 downto 0);
	signal lut_addr: unsigned(8 downto 0);
	signal lut_q,lut_q1: unsigned(7 downto 0);
	signal out_tmp: signed(8 downto 0);
	signal invert1,invert2: std_logic;
begin
	x <= x+freq when rising_edge(clk);
	t <= x(27 downto 17);
	lut_addr <= t(8 downto 0) when t(9)='0' else not t(8 downto 0);
	rom: sin_rom port map(lut_addr,clk,lut_q);
	lut_q1 <= lut_q when rising_edge(clk);
	invert1 <= t(10) when rising_edge(clk);
	invert2 <= invert1 when rising_edge(clk);
	
	out_tmp <= "0"&signed(lut_q1) when invert2='0' else
		("1"&signed(not lut_q1))+1;
	outp <= out_tmp when rising_edge(clk);
end architecture;
