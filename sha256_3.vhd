library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
--shift register
entity u32_shifter is
	generic(N: integer);
	port(inp: in unsigned(31 downto 0);
			clk: in std_logic;
			outp: out unsigned(31 downto 0));
end entity;
architecture a of u32_shifter is
	type tmpt is array(N downto 0) of unsigned(31 downto 0);
	signal tmp: tmpt;
begin
gen:
	for I in 0 to N-1 generate
		tmp(I) <= tmp(I+1) when rising_edge(clk);
	end generate;
	tmp(N) <= inp;
	outp <= tmp(0);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
--function for calculating one round of w
entity sha256_3_w_comb is
	port(clk: in std_logic;
			inp: in u32_array(15 downto 0);
			outp: out u32_array(15 downto 0));
end entity;
architecture a of sha256_3_w_comb is
	signal tmp111,tmp112,tmp113,tmp121,tmp122,tmp123: unsigned(31 downto 0);
	signal tmp211,tmp212,tmp221,tmp222: unsigned(31 downto 0);
	signal r,r1,r2: u32_array(15 downto 0);
	signal out1,out2: unsigned(31 downto 0);
begin
	r <= inp when rising_edge(clk);
	r1 <= r when rising_edge(clk);
	r2 <= r1 when rising_edge(clk);
	tmp111 <= (rotate_right(r(14),7) xor rotate_right(r(14),18) xor shift_right(r(14),3)) when rising_edge(clk);
	tmp112 <= (rotate_right(r(1),17) xor rotate_right(r(1),19) xor shift_right(r(1),10)) when rising_edge(clk);
	tmp113 <= r(15)+r(6) when rising_edge(clk);
	
	tmp211 <= tmp111+tmp112 when rising_edge(clk);
	tmp212 <= tmp113 when rising_edge(clk);
	out1 <= tmp211+tmp212 when rising_edge(clk);
	
	tmp121 <= (rotate_right(r(13),7) xor rotate_right(r(13),18) xor shift_right(r(13),3)) when rising_edge(clk);
	tmp122 <= (rotate_right(r(0),17) xor rotate_right(r(0),19) xor shift_right(r(0),10)) when rising_edge(clk);
	tmp123 <= r(14)+r(5) when rising_edge(clk);
	tmp221 <= tmp121+tmp122 when rising_edge(clk);
	tmp222 <= tmp123 when rising_edge(clk);
	out2 <= tmp221+tmp222 when rising_edge(clk);
	outp(1) <= out1;
	outp(0) <= out2;
	outp(15 downto 2) <= r2(13 downto 0) when rising_edge(clk);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
use work.u32_shifter;
use work.sha256_3_w_comb;
entity sha256_3_w is
	port(clk: in std_logic;
			inp: in std_logic_vector(0 to 511);
			outp_w: out u32_array(0 to 63));
end entity;
architecture a of sha256_3_w is
	--type pipeline_internal is array(17 downto 0) of unsigned(31 downto 0);
	type pipeline_internal1 is array(0 to 24) of u32_array(15 downto 0);
	type pipeline_internal2 is array(0 to 22) of u32_array(13 downto 0);
	signal internal: pipeline_internal1;
	signal internal_delay: pipeline_internal1;
begin
gen_fill_w:
	for I in 0 to 15 generate
		internal(0)(15-I) <= unsigned(inp(I*32 to (I+1)*32-1));
	end generate;
gen_main:
	for I in 0 to 23 generate
		--internal(I)(0) <= internal(I)(16) +
		--	(rotate_right(internal(I)(15),7) xor rotate_right(internal(I)(15),18) xor shift_right(internal(I)(15),3)) +
		--	internal(I)(7) + (rotate_right(internal(I)(2),17) xor rotate_right(internal(I)(2),19) xor shift_right(internal(I)(2),10));
		--internal(I)(1) <= internal(I)(17) +
		--	(rotate_right(internal(I)(16),7) xor rotate_right(internal(I)(16),18) xor shift_right(internal(I)(16),3)) +
		--	internal(I)(8) + (rotate_right(internal(I)(3),17) xor rotate_right(internal(I)(3),19) xor shift_right(internal(I)(3),10));
		comb: sha256_3_w_comb port map(clk=>clk,inp=>internal(I),outp=>internal(I+1));
	end generate;
gen_ff:
	for I in 0 to 22 generate
		--internal_delay(I) <= internal(I)(15 downto 2) when rising_edge(clk);
		--internal(I+1)(17 downto 4) <= internal_delay(I) when rising_edge(clk);
		--internal(I+1)(3 downto 2) <= internal(I)(1 downto 0) when rising_edge(clk);
	end generate;
gen_delay:
	for I in 0 to 23 generate
		outp_w(I*2) <= internal(I)(15);
		--outp_w(I*2+1) <= internal(I)(14) when rising_edge(clk);
		s: u32_shifter generic map(N=>2) port map(clk=>clk,inp=>internal(I)(14),outp=>outp_w(I*2+1));
		--s1: u32_shifter generic map(N=>(24-I)*2) port map(clk=>clk,inp=>internal(I)(15),outp=>outp_w(I*2));
		--s2: u32_shifter generic map(N=>(24-I)*2) port map(clk=>clk,inp=>internal(I)(14),outp=>outp_w(I*2+1));
	end generate;
gen_delay1:
	for I in 0 to 15 generate
		del: u32_shifter generic map(N=>I*2) port map(clk=>clk,inp=>internal(24)(15-I),outp=>outp_w(I+48));
	end generate;
	--outp_w(48 to 63) <= u32_array(internal(24)(15 downto 0));
end architecture;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all;
entity sha256_3_main_comb is
	port(inp_state: in sha_state;
			w,k: in unsigned(31 downto 0);
			clk: in std_logic;
			outp_state: out sha_state);
end entity;
architecture a of sha256_3_main_comb is
	signal a,b,c,d,e,f,g,h: u32_array(0 to 1);
	signal tmp111,tmp112,tmp121,tmp122,tmp131,tmp132: unsigned(31 downto 0);
	signal temp1,temp2,temp3: unsigned(31 downto 0);
	signal s,s1,s2,o: sha_state;
	signal w1: unsigned(31 downto 0);
begin
	s <= inp_state when rising_edge(clk);
	s1 <= s when rising_edge(clk);
	s2 <= s1 when rising_edge(clk);
	w1 <= w when rising_edge(clk);
	a(0)<=s(0); b(0)<=s(1); c(0)<=s(2); d(0)<=s(3);
	e(0)<=s(4); f(0)<=s(5); g(0)<=s(6); h(0)<=s(7);
	--0a, 1b, 2c, 3d, 4e, 5f, 6g, 7h
	
	tmp111 <= (rotate_right(e(0), 6) xor rotate_right(e(0), 11) xor rotate_right(e(0), 25)) when rising_edge(clk);
	tmp112 <= ((e(0) and f(0)) xor ((not e(0)) and g(0))) when rising_edge(clk);
	temp1 <= tmp111+tmp112 when rising_edge(clk);
	--temp1 <= (rotate_right(e(0), 6) xor rotate_right(e(0), 11) xor rotate_right(e(0), 25)) +
	--	((e(0) and f(0)) xor ((not e(0)) and g(0))) when rising_edge(clk);
	
	tmp121 <= (rotate_right(a(0), 2) xor rotate_right(a(0), 13) xor rotate_right(a(0), 22)) when rising_edge(clk);
	tmp122 <= ((a(0) and b(0)) xor (a(0) and c(0)) xor (b(0) and c(0))) when rising_edge(clk);
	temp2 <= tmp121+tmp122 when rising_edge(clk);
	--temp2 <= (rotate_right(a(0), 2) xor rotate_right(a(0), 13) xor rotate_right(a(0), 22)) +
	--	((a(0) and b(0)) xor (a(0) and c(0)) xor (b(0) and c(0))) when rising_edge(clk);
	
	tmp131 <= h(0)+w1 when rising_edge(clk);
	tmp132 <= k; --assume that k is constant
	temp3 <= tmp131+tmp132 when rising_edge(clk);
	--temp3 <= h(0)+k+w1 when rising_edge(clk);
	
	o(0)<=temp1+temp3+temp2;
	o(1)<=s2(0);
	o(2)<=s2(1);
	o(3)<=s2(2);
	o(4)<=s2(3)+temp1+temp3;
	o(5)<=s2(4);
	o(6)<=s2(5);
	o(7)<=s2(6);
	outp_state <= o;
end architecture;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
use work.u32_shifter;
use work.sha256_3_main_comb;
entity sha256_3_main is
	port(w,k: in u32_array(0 to 63);
			clk: in std_logic;
			inp: in sha_state;
			outp: out sha_state);
end entity;
architecture a of sha256_3_main is
	type pipeline_internal1 is array(0 to 64) of sha_state;
	signal tmp: pipeline_internal1;
	signal w1: u32_array(0 to 63);
begin
	tmp(0) <= inp;
gen:
	for I in 0 to 63 generate
		del: u32_shifter generic map(N=>I) port map(clk=>clk,inp=>w(I),outp=>w1(I));
		comb: sha256_3_main_comb port map(inp_state=>tmp(I),w=>w1(I),k=>k(I),clk=>clk,outp_state=>tmp(I+1));
	end generate;
gen1:
	for I in 0 to 7 generate
		outp(I) <= tmp(64)(I)+inp(I) when rising_edge(clk);
	end generate;
end architecture;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
use work.sha256_3_w;
use work.sha256_3_main;
entity sha256_3 is
	port(inp: in std_logic_vector(0 to 511);
			inp_state: in sha_state;
			clk: in std_logic;
			outp: out sha_state;
			w: out u32_array(0 to 63));
end entity;
architecture a of sha256_3 is
	signal w1,k: u32_array(0 to 63);
begin
	k <= (X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5", X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
		X"d807aa98", X"12835b01", X"243185be", X"550c7dc3", X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
		X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc", X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
		X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7", X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
		X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13", X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
		X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3", X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
		X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5", X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
		X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208", X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2");
	gen_w: sha256_3_w port map(clk=>clk,inp=>inp,outp_w=>w1);
	w <= w1;
	main: sha256_3_main port map(w=>w1,k=>k,clk=>clk,inp=>inp_state,outp=>outp);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all;
use work.de1_hexdisplay;
use work.sha256_3_w;
use work.sha256_3;
use work.sha256_3_main_comb;
use work.slow_clock;
entity de1_sha256_test3 is
	port(CLOCK_50: in std_logic;
		HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0));
end entity;
architecture a of de1_sha256_test3 is
	signal data1: std_logic_vector(0 to 511);
	signal state1,s1,s2,s3,s4,s5: sha_state;
	signal disp,disp1,disp2,d1: unsigned(63 downto 0);
	signal sha_clock: std_logic;
	signal w: u32_array(0 to 63);
	component pll1 is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic         -- clk
		);
	end component pll1;
	signal userdata,userdata1: std_logic_vector(0 to 7);
	signal b,b2: std_logic := '0';
begin
	userdata <= SW(7 downto 0) when b='1' else "01010101";
	userdata1 <= userdata when rising_edge(sha_clock);
	b <= not b when rising_edge(sha_clock);
	data1 <= userdata1&"1"&(438 downto 0=>'0')&std_logic_vector(to_unsigned(8,64));
	LEDR(0) <= sha_clock;
	--sc: slow_clock generic map(divide=>10000000,dutycycle=>5000000) port map(clk=>CLOCK_50,o=>sha_clock);
	pll: component pll1 port map(refclk=>CLOCK_50,outclk_0=>sha_clock);
	--sha: sha256_3_w port map(clk=>sha_clock,inp=>data1,outp_w=>w);
	sha_1: sha256_3 port map(clk=>sha_clock,inp=>data1,outp=>state1,w=>w,
		inp_state=>(X"6a09e667",X"bb67ae85",X"3c6ef372",X"a54ff53a",X"510e527f",X"9b05688c",X"1f83d9ab",X"5be0cd19"));
	--sha1: sha256_3_main_comb port map(inp_state=>(X"6a09e667",X"bb67ae85",X"3c6ef372",X"a54ff53a",X"510e527f",X"9b05688c",X"1f83d9ab",X"5be0cd19"),
	--	w=>w(55),k=>X"428a2f98",clk=>sha_clock,outp_state=>s1);
	--sha2: sha256_3_main_comb port map(inp_state=>s1,
	--	w=>w(56),k=>X"71374491",clk=>sha_clock,outp_state=>s2);
	--sha3: sha256_3_main_comb port map(inp_state=>s2,
	--	w=>w(57),k=>X"b5c0fbcf",clk=>sha_clock,outp_state=>s3);
	--sha4: sha256_3_main_comb port map(inp_state=>s3,
	--	w=>w(58),k=>X"e9b5dba5",clk=>sha_clock,outp_state=>s4);
	--sha5: sha256_3_main_comb port map(inp_state=>s4,
	--	w=>w(59),k=>X"3956c25b",clk=>sha_clock,outp_state=>s5);
	--sha6: sha256_3_main_comb port map(inp_state=>s5,
	--	w=>w(60),k=>X"59f111f1",clk=>sha_clock,outp_state=>state1);
	--d1 <= state1(0)&state1(1) when rising_edge(sha_clock);
	d1 <= state1(0)&state1(1);
	disp <= d1 when rising_edge(sha_clock);
	disp1 <= disp;-- when rising_edge(sha_clock) and b='1';
	b2 <= not b2 when falling_edge(sha_clock);
	disp2 <= disp1 when falling_edge(b);
	
	hd: de1_hexdisplay generic map(b=>16) 
		port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
			data=>std_logic_vector(disp2),button1=>not KEY(1),button2=>not KEY(0));
end architecture;
