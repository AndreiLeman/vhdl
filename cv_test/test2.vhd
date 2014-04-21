library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
entity test2 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0));
end entity;

architecture a of test2 is
	signal cnt: unsigned(23 downto 0);
begin
	LEDR <= SW;
	
	--GPIO_0 <= (others=>SW(0));
	--LEDR <= GPIO_1(9 downto 0);
	cnt <= cnt+1 when rising_edge(GPIO_1(0));
	hd0: hexdisplay port map(cnt(3 downto 0),HEX0);
	hd1: hexdisplay port map(cnt(7 downto 4),HEX1);
	hd2: hexdisplay port map(cnt(11 downto 8),HEX2);
	hd3: hexdisplay port map(cnt(15 downto 12),HEX3);
	hd4: hexdisplay port map(cnt(19 downto 16),HEX4);
	hd5: hexdisplay port map(cnt(23 downto 20),HEX5);
end architecture;
