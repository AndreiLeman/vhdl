library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 

--calculates w in 4 clock cycles
entity sha256_compute_w is
	port(clk,firstround: in std_logic;
			inp: in std_logic_vector(0 to 511);
			outp_w: out u32_array(0 to 15));
end entity;
architecture a of sha256_compute_w is
	signal next_w,inp_w: u32_array(0 to 15);
	signal w: u32_array(0 to 31);
begin
gen_ff:
	for I in 0 to 15 generate
		w(I) <= next_w(I) when rising_edge(clk);
	end generate;
	next_w <= inp_w when firstround='1' else w(16 to 31);
gen_fill_w:
	for I in 0 to 15 generate
		inp_w(I) <= unsigned(inp(I*32 to (I+1)*32-1));
	end generate;
gen_calc_w:
	for I in 16 to 31 generate
		w(I) <= w(I-16) + (rotate_right(w(I-15),7) xor rotate_right(w(I-15),18) xor shift_right(w(I-15),3)) +
			w(I-7) + (rotate_right(w(I-2),17) xor rotate_right(w(I-2),19) xor shift_right(w(I-2),10));
	end generate;
	outp_w <= w(0 to 15);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
entity sha256_compute_main is
	generic(R: integer);
	port(inp_state: in sha_state;
			w,k: in u32_array(0 to R-1);
			outp_state: out sha_state);
end entity;
architecture a of sha256_compute_main is
	signal a,b,c,d,e,f,g,h: u32_array(0 to R);
	signal temp1,temp2: u32_array(0 to R-1);
begin
	a(0)<=inp_state(0); b(0)<=inp_state(1); c(0)<=inp_state(2); d(0)<=inp_state(3);
	e(0)<=inp_state(4); f(0)<=inp_state(5); g(0)<=inp_state(6); h(0)<=inp_state(7);
gen_state_chain:
	for I in 0 to R-1 generate
		--0a, 1b, 2c, 3d, 4e, 5f, 6g, 7h
		temp1(I) <= h(I) + 
			(rotate_right(e(I), 6) xor rotate_right(e(I), 11) xor rotate_right(e(I), 25)) +
			((e(I) and f(I)) xor ((not e(I)) and g(I))) + k(I) + w(I);
		temp2(I) <= (rotate_right(a(I), 2) xor rotate_right(a(I), 13) xor rotate_right(a(I), 22)) +
			((a(I) and b(I)) xor (a(I) and c(I)) xor (b(I) and c(I)));
		h(I+1)<=g(I); g(I+1)<=f(I); f(I+1)<=e(I);
		e(I+1)<=d(I)+temp1(I);
		d(I+1)<=c(I); c(I+1)<=b(I); b(I+1)<=a(I);
		a(I+1)<=temp1(I)+temp2(I);
	end generate;
	outp_state(0)<=a(R); outp_state(1)<=b(R);
	outp_state(2)<=c(R); outp_state(3)<=d(R);
	outp_state(4)<=e(R); outp_state(5)<=f(R);
	outp_state(6)<=g(R); outp_state(7)<=h(R);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all;
use work.sha256_compute_w;
use work.sha256_compute_main;
--rst must be asserted once per computation cycle right before the first rising edge of clk
--and must be de-asserted before the next rising edge of the clock
entity sha256_2 is
	port(inp: in std_logic_vector(0 to 511);
			inp_state: in sha_state;
			clk: in std_logic;
			clk_out: out std_logic;
			outp: inout sha_state;
			disp: out unsigned(63 downto 0));
end entity;
architecture a of sha256_2 is
	signal state_ff,tmpstate,curstate: sha_state;
	signal w,k: u32_array(0 to 15);
	signal rst,rst1,srst,oclk: std_logic;
	signal ind,next_ind: unsigned(1 downto 0);
	signal k_arr: u32_array(0 to 63);
	type k1_t is array(0 to 3) of u32_array(0 to 15);
	signal k1: k1_t;
begin
	main: sha256_compute_main generic map(R=>16)
		port map(inp_state=>curstate,w=>w,k=>k,outp_state=>tmpstate);
	curstate <= inp_state when srst='1' else state_ff;
	state_ff <= tmpstate when rising_edge(clk);
	srst <= rst when rising_edge(clk);
	rst1 <= '1' when ind="10" else '0';
	rst <= rst1 when rising_edge(clk);
	oclk <= '1' when ind="00" or ind="01" else '0';
	clk_out <= oclk when rising_edge(clk);
	compute_w: sha256_compute_w port map(clk=>clk, firstround=>rst,inp=>inp,outp_w=>w);
gen_outp:
	for I in 0 to 7 generate
		outp(I) <= state_ff(I)+inp_state(I);
	end generate;
	disp <= w(0) & w(1);--outp(0) & outp(1);
	
	ind <= next_ind when rising_edge(clk);
	next_ind <= to_unsigned(0,2) when rst='1' else ind+1;
	k_arr <= (X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5", X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
		X"d807aa98", X"12835b01", X"243185be", X"550c7dc3", X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
		X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc", X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
		X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7", X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
		X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13", X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
		X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3", X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
		X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5", X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
		X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208", X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2");
gen_fill_k:
	for I in 0 to 3 generate
		k1(I) <= k_arr(I*16 to (I+1)*16-1);
	end generate;
	k <= k1(to_integer(ind));
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all;
use work.simple_sha256;
use work.de1_hexdisplay;
use work.sha256_2;
entity de1_sha256_test2 is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0));
end entity;
architecture a of de1_sha256_test2 is
	signal sha_data: std_logic_vector(0 to 511);
	signal state: sha_state;
	signal disp: unsigned(63 downto 0);
	signal sha_clock: std_logic;
begin
	sha_data <= SW(7 downto 0)&"1"&(438 downto 0=>'0')&std_logic_vector(to_unsigned(8,64));
	sha: sha256_2 port map(clk=>not KEY(3),inp=>sha_data,outp=>state,disp=>disp,clk_out=>sha_clock,
		inp_state=>(X"6a09e667",X"bb67ae85",X"3c6ef372",X"a54ff53a",X"510e527f",X"9b05688c",X"1f83d9ab",X"5be0cd19"));
	--disp <= state(0);
	LEDR(0) <= sha_clock;
	hd: de1_hexdisplay generic map(b=>16) 
		port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
			data=>std_logic_vector(disp),button1=>not KEY(1),button2=>not KEY(0));
end architecture;

