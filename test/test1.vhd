library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
entity test1 is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
		CLOCK_50: in std_logic);
end entity;
architecture a of test1 is
	signal clock_25,clock_12: std_logic;
	signal adc_in: unsigned(7 downto 0);
begin
	clock_25 <= not clock_25 when rising_edge(CLOCK_50);
	clock_12 <= not clock_12 when rising_edge(clock_25);
	GPIO_1(27) <= clock_12;
	GPIO_1(26) <= '0';
	hd0: hexdisplay port map(adc_in(3 downto 0),HEX0);
	hd1: hexdisplay port map(adc_in(7 downto 4),HEX1);
	adc_in <= unsigned(GPIO_1(35 downto 28));
end architecture;
