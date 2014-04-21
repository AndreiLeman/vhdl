library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;

entity de1_hexdisplay is
	generic(b: integer);
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			data: std_logic_vector(b*4-1 downto 0);
			button1,button2: in std_logic);
end entity;
architecture a of de1_hexdisplay is
	type data1_t is array(b-1 downto 0) of unsigned(3 downto 0);
	signal data1: data1_t;
	signal i,i2: unsigned(15 downto 0);
	signal c,last_button: std_logic;
begin
gen1:
	for I in 0 to b-1 generate
		data1(I) <= unsigned(data((I+1)*4-1 downto I*4));
	end generate;
	h0: hexdisplay port map(inp=>data1(to_integer(i+5)),outp=>HEX5);
	h1: hexdisplay port map(inp=>data1(to_integer(i+4)),outp=>HEX4);
	h2: hexdisplay port map(inp=>data1(to_integer(i+3)),outp=>HEX3);
	h3: hexdisplay port map(inp=>data1(to_integer(i+2)),outp=>HEX2);
	h4: hexdisplay port map(inp=>data1(to_integer(i+1)),outp=>HEX1);
	h5: hexdisplay port map(inp=>data1(to_integer(i)),outp=>HEX0);
	last_button <= '0' when button1='1' else '1' when button2='1'
		else '0' when button1='1' and button2='1';
	i2 <= i+1 when last_button='0' and i<b-6 else
			i-1 when last_button='1' and i>0 else i;
	c<=button1 or button2;
	i <= i2 when falling_edge(c);
end architecture;
