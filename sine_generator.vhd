library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sin_rom;
entity sineGenerator is
	port(clk: in std_logic;
			freq: in unsigned(27 downto 0); -- fraction only; cycles per clk rising edge
			outp: out signed(8 downto 0));
end entity;
architecture a of sineGenerator is
	constant lutAddrBits: integer := 9;
	signal x: unsigned(27 downto 0);
	signal t: unsigned(lutAddrBits+1 downto 0);
	signal lut_addr: unsigned(lutAddrBits-1 downto 0);
	signal lut_q,lut_q1: unsigned(7 downto 0);
	signal out_tmp,lut_q2,lut_q2i: signed(8 downto 0);
	signal invert1,invert2,invert3: std_logic;
begin
	x <= x+freq when rising_edge(clk);
	t <= x(27 downto 27-lutAddrBits-1);
	lut_addr <= t(lutAddrBits-1 downto 0) when t(lutAddrBits)='0'
		else not t(lutAddrBits-1 downto 0);
	rom: sin_rom port map(lut_addr,clk,lut_q);
	lut_q1 <= lut_q when rising_edge(clk);
	invert1 <= t(lutAddrBits+1) when rising_edge(clk);
	invert2 <= invert1 when rising_edge(clk);
	invert3 <= invert2 when rising_edge(clk);
	
	lut_q2 <= "0"&signed(lut_q1) when rising_edge(clk);
	lut_q2i <= ("1"&signed(not lut_q1))+1 when rising_edge(clk);
	
	out_tmp <= lut_q2 when invert3='0' else lut_q2i;
	outp <= out_tmp when rising_edge(clk);
end architecture;
