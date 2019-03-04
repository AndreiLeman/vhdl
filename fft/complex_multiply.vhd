library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- read delay is 6 cycles
entity complexMultiply is
	generic(in1Bits,in2Bits,outBits: integer := 8);
	port(clk: in std_logic;
			in1,in2: in complex;
			out1: out complex
			);
end entity;
architecture a of complexMultiply is
	constant internalBits: integer := in1Bits + in2Bits;
	signal a,b,a2,b2,a3,b3: signed(in1Bits-1 downto 0);
	signal c,d,c2,d2,c3,d3: signed(in2Bits-1 downto 0);
	
	signal ac,bd,ad,bc,ac2,bd2,ad2,bc2,ac3,bd3,ad3,bc3: signed(internalBits-1 downto 0);
	signal res_re,res_im: signed(internalBits-1 downto 0);
	signal rnd_re,rnd_im: signed(outBits-1 downto 0);
	signal halfLSB: signed(internalBits-outBits-1 downto 0);
	
	signal out0: complex;
begin
	a <= complex_re(in1, in1Bits) when rising_edge(clk);
	b <= complex_im(in1, in1Bits) when rising_edge(clk);
	c <= complex_re(in2, in2Bits) when rising_edge(clk);
	d <= complex_im(in2, in2Bits) when rising_edge(clk);
	
	a2 <= a when rising_edge(clk);
	b2 <= b when rising_edge(clk);
	c2 <= c when rising_edge(clk);
	d2 <= d when rising_edge(clk);
	a3 <= a2 when rising_edge(clk);
	b3 <= b2 when rising_edge(clk);
	c3 <= c2 when rising_edge(clk);
	d3 <= d2 when rising_edge(clk);
	
	
	-- multiply
	ac <= a*c when rising_edge(clk);
	--bd <= b*d when rising_edge(clk);
	ad <= a*d when rising_edge(clk);
	--bc <= b*c when rising_edge(clk);
	
	ac2 <= ac when rising_edge(clk);
	--bd2 <= bd when rising_edge(clk);
	ad2 <= ad when rising_edge(clk);
	--bc2 <= bc when rising_edge(clk);
	
	ac3 <= ac2 when rising_edge(clk);
	bd3 <= b3*d3 when rising_edge(clk);
	ad3 <= ad2 when rising_edge(clk);
	bc3 <= b3*c3 when rising_edge(clk);
	
	-- add
	halfLSB <= "01" & (halfLSB'left-2 downto 0=>'0');
	res_re <= ac3-bd3 when rising_edge(clk);--+resize(halfLSB,internalBits);
	res_im <= ad3+bc3 when rising_edge(clk);--+resize(halfLSB,internalBits);
	
	-- round & cast
	rnd_re <= res_re(res_re'left-1 downto res_re'left-outBits) when rising_edge(clk);
	rnd_im <= res_im(res_im'left-1 downto res_im'left-outBits) when rising_edge(clk);
	
	--out1.re <= to_integer(rnd_re) when rising_edge(clk);
	--out1.im <= to_integer(rnd_im) when rising_edge(clk);
	out1 <= to_complex(rnd_re, rnd_im);
	--out1 <= out0 when rising_edge(clk);
end a;
