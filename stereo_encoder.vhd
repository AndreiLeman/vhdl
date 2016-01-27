library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sineGenerator;
entity stereoEncoder is
	port(clk: in std_logic;
			pilot_freq: in unsigned(27 downto 0); -- fraction only; cycles per clk rising edge
			inL,inR: in signed(23 downto 0);
			outp: out signed(23 downto 0));
end entity;
architecture a of stereoEncoder is
	signal diff,sum,sum1: signed(24 downto 0);
	signal diff_encoded: signed(33 downto 0);
	signal pilot_tone,carrier,p1,p2,p3: signed(8 downto 0);
	signal tmp1: signed(17 downto 0);
	--signal carrier: signed(16 downto 0);
	signal tmp: signed(33 downto 0);
begin
	diff <= (inL(23)&inL)-(inR(23)&inR) when rising_edge(clk);
	sum <= (inL(23)&inL)+(inR(23)&inR) when rising_edge(clk);
	sg: sineGenerator port map(clk,pilot_freq,pilot_tone);
	sg2: sineGenerator port map(clk,pilot_freq(26 downto 0)&"0",carrier);
	--tmp1 <= pilot_tone*pilot_tone when rising_edge(clk);
	--carrier <= tmp1(16 downto 0)-to_signed(2**15,17) when rising_edge(clk);
	diff_encoded <= diff*carrier when rising_edge(clk);
	p1 <= pilot_tone when rising_edge(clk);
	p2 <= p1 when rising_edge(clk);
	p3 <= p2 when rising_edge(clk);
	sum1 <= sum when rising_edge(clk);
	tmp <= diff_encoded(32 downto 0)&"0" +(sum1&"000000000")
		+(p1&(17 downto 0=>'0')) when rising_edge(clk);
	outp <= tmp(33 downto 10);
end architecture;
