library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.ejxGenerator;
entity freqdetector is
	generic(inwidth: integer := 8;
			-- cutoff freq is inversely proportional to SAMPLERATE/2^order
			lpf_cutoff_order: integer := 10
			);
	port(clk,en: in std_logic;
			datain: in signed(inwidth-1 downto 0);
			freq: in unsigned(27 downto 0);
			dataout_i: out signed(inwidth+9-1 downto 0);
			dataout_q: out signed(inwidth+9-1 downto 0));
	constant iqwidth: integer := inwidth+9;
end entity;
architecture a of freqdetector is
	signal osc_re,osc_im: signed(8 downto 0);
	signal i,q,i1,q1: signed(iqwidth-1 downto 0);
	signal i_divided,q_divided,i1_divided,q1_divided: signed(iqwidth-1 downto 0);
	
	signal en1,en2,en3: std_logic;
begin
	--avoid metastability
	en1 <= en when rising_edge(clk);
	en2 <= en1 when rising_edge(clk);
	en3 <= en2 when rising_edge(clk);

	osc: ejxGenerator port map(clk,freq,osc_re,osc_im);
	i <= datain*osc_re when rising_edge(clk);
	q <= datain*osc_im when rising_edge(clk);
	
	i_divided <= (lpf_cutoff_order-1 downto 0=>i(iqwidth-1)) & i(iqwidth-1 downto lpf_cutoff_order);
	q_divided <= (lpf_cutoff_order-1 downto 0=>q(iqwidth-1)) & q(iqwidth-1 downto lpf_cutoff_order);
	i1_divided <= (lpf_cutoff_order-1 downto 0=>i1(iqwidth-1)) & i1(iqwidth-1 downto lpf_cutoff_order);
	q1_divided <= (lpf_cutoff_order-1 downto 0=>q1(iqwidth-1)) & q1(iqwidth-1 downto lpf_cutoff_order);
	
	i1 <= i1-i1_divided+i_divided when en3='1' and rising_edge(clk);
	q1 <= q1-q1_divided+q_divided when en3='1' and rising_edge(clk);
	dataout_i <= i1;
	dataout_q <= q1;
end architecture;
