library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.signedClipper;
entity volumeControl2 is
	generic(bitsIn: integer := 16;
				bitsOut: integer := 16);
	port(	clk: in std_logic;
			inp: in signed(bitsIn-1 downto 0);
			outp: out signed(bitsOut-1 downto 0);
			vol: in std_logic_vector(2 downto 0));
end entity;
architecture a of volumeControl2 is
	signal inp1: signed(bitsIn-1 downto 0);
	signal scale: unsigned(8 downto 0);
	signal vol1: unsigned(2 downto 0);
	signal tmp: signed(bitsIn+9 downto 0);
	signal tmp2: signed(bitsOut-1 downto 0);
begin
	inp1 <= inp when rising_edge(clk);
	vol1 <= unsigned(vol);
	scale <= vol1*vol1*vol1;
	tmp <= inp1*("0"&signed(scale)) when rising_edge(clk);
	sc: signedClipper generic map(bitsIn+10,bitsOut) port map(tmp,tmp2);
	outp <= tmp2 when rising_edge(clk);
end architecture;
