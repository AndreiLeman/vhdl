library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
package mypackage is
	type sha_state is array(0 to 7) of unsigned(31 downto 0);
	type u32_array is array(integer range <>) of unsigned(31 downto 0);
	type byte_array is array(integer range <>) of unsigned(7 downto 0);
end package;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.mypackage.all; 
entity simple_sha256 is
	port(inp: in std_logic_vector(0 to 511);
			s_in: in sha_state;
			s_out: out sha_state;
			disp_out: out unsigned(31 downto 0));
end entity;
architecture a of simple_sha256 is
	type w_t is array(0 to 63) of unsigned(31 downto 0);
	type state_chain is array(64 downto 0) of unsigned(31 downto 0);
	type tmp1_t is array(63 downto 0) of unsigned(31 downto 0);
	signal w,k: w_t;
	signal a,b,c,d,e,f,g,h: state_chain;
	signal temp1,temp2: tmp1_t;
begin
	disp_out<=s_in(0)+a(64);
	k <= (X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5", X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
		X"d807aa98", X"12835b01", X"243185be", X"550c7dc3", X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
		X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc", X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
		X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7", X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
		X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13", X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
		X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3", X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
		X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5", X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
		X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208", X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2");
gen_fill_w:
	for I in 0 to 15 generate
		w(I) <= unsigned(inp(I*32 to (I+1)*32-1));
	end generate;
gen_calc_w:
	for I in 16 to 63 generate
		w(I) <= w(I-16) +
			--(w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
			(rotate_right(w(I-15),7) xor rotate_right(w(I-15),18) xor shift_right(w(I-15),3)) +
			w(I-7) +
			--(w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
			(rotate_right(w(I-2),17) xor rotate_right(w(I-2),19) xor shift_right(w(I-2),10));
	end generate;
	a(0)<=s_in(0); b(0)<=s_in(1); c(0)<=s_in(2); d(0)<=s_in(3);
	e(0)<=s_in(4); f(0)<=s_in(5); g(0)<=s_in(6); h(0)<=s_in(7);
gen_state_chain:
	for I in 0 to 63 generate
		--0a, 1b, 2c, 3d, 4e, 5f, 6g, 7h
		temp1(I) <= h(I) + 
			(rotate_right(e(I), 6) xor rotate_right(e(I), 11) xor rotate_right(e(I), 25)) +
			((e(I) and f(I)) xor ((not e(I)) and g(I))) +
			k(I) + w(I);
		temp2(I) <= (rotate_right(a(I), 2) xor rotate_right(a(I), 13) xor rotate_right(a(I), 22)) +
			((a(I) and b(I)) xor (a(I) and c(I)) xor (b(I) and c(I)));
		h(I+1)<=g(I); g(I+1)<=f(I); f(I+1)<=e(I);
		e(I+1)<=d(I)+temp1(I);
		d(I+1)<=c(I); c(I+1)<=b(I); b(I+1)<=a(I);
		a(I+1)<=temp1(I)+temp2(I);
	end generate;
	s_out(0)<=s_in(0)+a(64); s_out(1)<=s_in(1)+b(64); s_out(2)<=s_in(2)+c(64); s_out(3)<=s_in(3)+d(64);
	s_out(4)<=s_in(4)+e(64); s_out(5)<=s_in(5)+f(64); s_out(6)<=s_in(6)+g(64); s_out(7)<=s_in(7)+h(64);
end architecture;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.mypackage.all;
use work.simple_sha256;
use work.de1_hexdisplay;
entity de1_sha256_test is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0));
end entity;
architecture a of de1_sha256_test is
	signal sha_data: std_logic_vector(0 to 511);
	signal st,st_o: sha_state;
	signal x: unsigned(7 downto 0);
	signal disp: unsigned(31 downto 0);
begin
	st <= (X"6a09e667",X"bb67ae85",X"3c6ef372",X"a54ff53a",X"510e527f",X"9b05688c",X"1f83d9ab",X"5be0cd19");
	sha_data <= SW(7 downto 0)&"1"&(438 downto 0=>'0')&std_logic_vector(to_unsigned(8,64));
	sha: simple_sha256 port map(inp=>sha_data, s_in=>st, s_out=>st_o,disp_out=>disp);
	
	hd: de1_hexdisplay generic map(b=>8) 
		port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
			data=>std_logic_vector(disp),button1=>not KEY(1),button2=>not KEY(0));
end architecture;

