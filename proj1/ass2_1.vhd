library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;

entity ass2_1 is
	port(SW: in std_logic_vector(17 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0));
end entity;
architecture a of ass2_1 is
	type bcdt is array(7 downto 0) of unsigned(3 downto 0);
	type tmpt is array(7 downto 0) of unsigned(21 downto 0);
	signal number: unsigned(17 downto 0);
	signal bcd: bcdt;
	signal tmp: tmpt;
begin
	number <= unsigned(SW);
gen1:
	for I in 1 to 7 generate
		tmp(I) <= tmp(I-1)(17 downto 0)*to_unsigned(10,4);
	end generate;
	tmp(0) <= number*to_unsigned(10,4);
gen2:
	for I in 0 to 7 generate
		bcd(I) <= tmp(I)(21 downto 18);
	end generate;
	h0: hexdisplay port map(inp=>bcd(7),outp=>HEX0);
	h1: hexdisplay port map(inp=>bcd(6),outp=>HEX1);
	h2: hexdisplay port map(inp=>bcd(5),outp=>HEX2);
	h3: hexdisplay port map(inp=>bcd(4),outp=>HEX3);
	h4: hexdisplay port map(inp=>bcd(3),outp=>HEX4);
	h5: hexdisplay port map(inp=>bcd(2),outp=>HEX5);
	h6: hexdisplay port map(inp=>bcd(1),outp=>HEX6);
	h7: hexdisplay port map(inp=>bcd(0),outp=>HEX7);
end architecture;




library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;

entity de1_ass2_1 is
	port(SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0));
end entity;
architecture a of de1_ass2_1 is
	type bcdt is array(7 downto 0) of unsigned(3 downto 0);
	type tmpt is array(7 downto 0) of unsigned(13 downto 0);
	signal number: unsigned(9 downto 0);
	signal bcd: bcdt;
	signal tmp: tmpt;
begin
	number <= unsigned(SW);
gen1:
	for I in 1 to 5 generate
		tmp(I) <= tmp(I-1)(9 downto 0)*to_unsigned(10,4);
	end generate;
	tmp(0) <= number*to_unsigned(10,4);
gen2:
	for I in 0 to 7 generate
		bcd(I) <= tmp(I)(13 downto 10);
	end generate;
	h0: hexdisplay port map(inp=>bcd(5),outp=>HEX0);
	h1: hexdisplay port map(inp=>bcd(4),outp=>HEX1);
	h2: hexdisplay port map(inp=>bcd(3),outp=>HEX2);
	h3: hexdisplay port map(inp=>bcd(2),outp=>HEX3);
	h4: hexdisplay port map(inp=>bcd(1),outp=>HEX4);
	h5: hexdisplay port map(inp=>bcd(0),outp=>HEX5);
end architecture;

