library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
entity main is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			GPIO_0: inout std_logic_vector(35 downto 0));
end entity;
architecture a of main is
	signal asdfg: unsigned(23 downto 0);
begin
	h0: hexdisplay port map(inp=>asdfg(3 downto 0),outp=>HEX0);
	h1: hexdisplay port map(inp=>asdfg(7 downto 4),outp=>HEX1);
	h2: hexdisplay port map(inp=>asdfg(11 downto 8),outp=>HEX2);
	h3: hexdisplay port map(inp=>asdfg(15 downto 12),outp=>HEX3);
	h4: hexdisplay port map(inp=>asdfg(19 downto 16),outp=>HEX4);
	h5: hexdisplay port map(inp=>asdfg(23 downto 20),outp=>HEX5);
	
	asdfg <= asdfg+1 when rising_edge(GPIO_0(9));
end architecture;
