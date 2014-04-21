library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
--shift register
entity bit_shifter is
	generic(N: integer; delay: integer);
	port(inp: in std_logic_vector(N-1 downto 0);
			clk: in std_logic;
			outp: out std_logic_vector(N-1 downto 0));
end entity;
architecture a of bit_shifter is
	type tmpt is array(delay downto 0) of std_logic_vector(N-1 downto 0);
	signal tmp: tmpt;
begin
gen:
	for I in 0 to delay-1 generate
		tmp(I) <= tmp(I+1) when rising_edge(clk);
	end generate;
	tmp(delay) <= inp;
	outp <= tmp(0);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.mypackage.all;
use work.simple_sha256;
use work.de1_hexdisplay;
use work.sha256_3;
use work.bit_shifter;

entity de1_sha256_brute is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		CLOCK_50: in std_logic);
end entity;

architecture a of de1_sha256_brute is
	component pll1 is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic         -- clk
		);
	end component pll1;
	constant len: integer := 8;
	--constant tmpsize: integer := integer(ceil(log2(real(26**len))));
	signal sclk,sha_clk,mainclk: std_logic;
	signal cur_c,next_c: byte_array(0 to len-1);
	signal c: std_logic_vector(1 to len);
	signal cur_data,cur_data1,delay_out,out_data,disp_data: std_logic_vector(0 to len*8-1);
	--type tmpt is array(0 to len-1) of unsigned(tmpsize+5-1 downto 0);
	--signal tmp: tmpt;
	signal clk_en,clk_en1,clk_en2: std_logic := '1';
	signal sha_out,sha_result: sha_state;
	signal sha_data: std_logic_vector(0 to 511);
	signal disp: std_logic_vector(63 downto 0);
	signal matched,matched1,latched: std_logic := '0';
begin
	mainclk <= CLOCK_50;
	pll: component pll1 port map(refclk=>CLOCK_50,outclk_0=>sha_clk);
	--sha_clk <= mainclk;
	
	--clk <= (CLOCK_50 and SW(8)) or (not KEY(3));
	--sc: slow_clock generic map(divide=>2000000,dutycycle=>1000000)
	--	port map(clk=>CLOCK_50,o=>sclk);
	
	delay1: bit_shifter generic map(N=>len*8,delay=>195) port map(clk=>sha_clk,inp=>cur_data,outp=>delay_out);
gen_data:
	for I in 0 to len-1 generate
		cur_data(I*8 to (I+1)*8-1) <= std_logic_vector(unsigned(cur_c(I)+to_unsigned(97,8)));
	end generate;
	
	next_c(0) <= X"00" when cur_c(0)=to_unsigned(25,8)
					else cur_c(0)+X"01";
	c(1) <= '1' when cur_c(0)=to_unsigned(25,8) else '0';
gen_add:
	for I in 1 to len-1 generate
		next_c(I) <= cur_c(I) when c(I)='0' else
						X"00" when cur_c(I)=to_unsigned(25,8) else
						cur_c(I)+X"01";
		c(I+1) <= '1' when c(I)='1' and cur_c(I)=to_unsigned(25,8) else '0';
	end generate;
	cur_c <= next_c when rising_edge(sha_clk);

	sha_data <= cur_data&"1"&(447-1-len*8 downto 0=>'0')&std_logic_vector(to_unsigned(len*8,64));
	sha: sha256_3 port map(clk=>sha_clk,inp=>sha_data,outp=>sha_out,
		inp_state=>(X"6a09e667",X"bb67ae85",X"3c6ef372",X"a54ff53a",X"510e527f",X"9b05688c",X"1f83d9ab",X"5be0cd19"));
	
	sha_result <= sha_out when rising_edge(sha_clk);
	matched <= '1' when (sha_result(0)&sha_result(1))=X"491e90127a6df148" else '0';
	matched1 <= matched when rising_edge(sha_clk);
	latched <= (latched or matched1) and KEY(3) when rising_edge(sha_clk);
	out_data <= delay_out when falling_edge(sha_clk);
	disp_data <= out_data when rising_edge(latched);
	
	LEDR(1) <= latched;

	hd: de1_hexdisplay generic map(b=>16) 
		port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
			data=>disp,button1=>not KEY(1),button2=>not KEY(0));
	disp <= std_logic_vector(std_logic_vector(disp_data)) when SW(9)='1'
		else std_logic_vector(std_logic_vector(out_data));--std_logic_vector(sha_result(0))&std_logic_vector(sha_result(1));
end architecture;
