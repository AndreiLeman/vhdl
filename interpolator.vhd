library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sinc_rom;
-- x256 interpolator
-- depth is 11 samples; delay is 5 samples
entity interpolator256 is
	port(clk,wr_en: in std_logic;
			datain: in signed(23 downto 0);
			dataout: out signed(24 downto 0));
end entity;
architecture a of interpolator256 is
	constant L: integer := 5;
	type sr_t is array(L*2 downto 0) of signed(23 downto 0);
	type arr is array(0 to L) of signed(23 downto 0);
	type arr2 is array(L*2 downto 0) of signed(47 downto 0);
	signal sr: sr_t;
	signal datain1: signed(23 downto 0);
	signal counter: unsigned(7 downto 0);
	signal q1,q2: signed((L+1)*24-1 downto 0);
	signal a1,a2: arr;
	signal en1,en2,en3: std_logic;
	signal tmp_out: arr2;
	signal s1a,s1b,s1c,s1d,s2a,s2b,s3: signed(47 downto 0);
begin
	datain1 <= datain when wr_en='1' and rising_edge(clk);
	counter <= (others=>'0') when wr_en='1' and rising_edge(clk) else
		counter+1 when rising_edge(clk);
	en1 <= wr_en when rising_edge(clk);
	en2 <= en1 when rising_edge(clk);
	en3 <= en2 when rising_edge(clk);

	rom: sinc_rom port map(counter,not counter,clk,clk,q1,q2);
gen1:
	for I in 0 to 5 generate
		a1(I) <= q1((L+1-I)*24-1 downto (L-I)*24) when rising_edge(clk);
		a2(I) <= q2((L+1-I)*24-1 downto (L-I)*24) when rising_edge(clk);
	end generate;
	sr <= sr(9 downto 0)&datain1 when rising_edge(en3);
gen_mult1:
	for I in 0 to L generate
		tmp_out(L+I) <= sr(L+I)*a1(I) when rising_edge(clk);
	end generate;
gen_mult2:
	for I in 0 to L-1 generate
		tmp_out(L-1-I) <= sr(L-1-I)*a2(I) when rising_edge(clk);
	end generate;
	s1a <= tmp_out(0)+tmp_out(1)+tmp_out(2) when rising_edge(clk);
	s1b <= tmp_out(3)+tmp_out(4)+tmp_out(5) when rising_edge(clk);
	s1c <= tmp_out(6)+tmp_out(7)+tmp_out(8) when rising_edge(clk);
	s1d <= tmp_out(9)+tmp_out(10) when rising_edge(clk);
	s2a <= s1a+s1b when rising_edge(clk);
	s2b <= s1c+s1d when rising_edge(clk);
	s3 <= s2a+s2b when rising_edge(clk);
	dataout <= s3(47 downto 23);
end architecture;
