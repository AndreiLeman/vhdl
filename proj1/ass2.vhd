library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
entity base10_extract is
	generic(i,b: integer);
	port(inp: in unsigned(b-1 downto 0);
			subtr: in unsigned(31 downto 0);
			outp: out unsigned(3 downto 0));
end entity;
architecture a of base10_extract is
	constant multiplier: integer := 5**i;
	constant extraspace: integer := integer(ceil(log2(real(multiplier))));
	signal tmp: unsigned(b+extraspace-1 downto 0);
	signal tmp1,tmp2: unsigned(extraspace+i-1 downto 0);
begin
	tmp <= inp*to_unsigned(5**i,extraspace);
	tmp1 <= tmp(b+extraspace-1 downto b-i);
	tmp2 <= tmp1-subtr(extraspace+i-1 downto 0);
	outp <= tmp2(3 downto 0);
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.base10_extract;
entity ass2 is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(17 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(17 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0));
end entity;

architecture a of ass2 is
	signal clk: std_logic;
	signal number: unsigned(17 downto 0);
	type bcdt is array(7 downto 0) of unsigned(3 downto 0);
	signal bcd: bcdt;
	type tmp_t is array(7 downto 0) of unsigned(31 downto 0);
	signal tmp: tmp_t;
	--signal tmp1,tmp2,tmp3,tmp4,tmp5: unsigned(35 downto 0);
begin
	number <= unsigned(SW);
gen_ext:
	for I in 0 to 7 generate
		ext: base10_extract generic map (i => I+1, b => 18)
			port map (inp => number, subtr => tmp(I), outp => bcd(I));
	end generate;
gen_tmp:
	for I in 1 to 7 generate
		tmp(I) <= tmp(I-1)(27 downto 0)*to_unsigned(10,4)+bcd(I-1)*10;
	end generate;
	tmp(0) <= to_unsigned(0,32);

	h0: hexdisplay port map(inp=>bcd(7),outp=>HEX0);
	h1: hexdisplay port map(inp=>bcd(6),outp=>HEX1);
	h2: hexdisplay port map(inp=>bcd(5),outp=>HEX2);
	h3: hexdisplay port map(inp=>bcd(4),outp=>HEX3);
	h4: hexdisplay port map(inp=>bcd(3),outp=>HEX4);
	h5: hexdisplay port map(inp=>bcd(2),outp=>HEX5);
	h6: hexdisplay port map(inp=>bcd(1),outp=>HEX6);
	h7: hexdisplay port map(inp=>bcd(0),outp=>HEX7);
end architecture;
