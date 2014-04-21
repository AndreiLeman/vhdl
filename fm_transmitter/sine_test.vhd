library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sineGenerator;
entity sine_test is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in unsigned(9 downto 0);
			GPIO_0,GPIO_1: inout std_logic_vector(0 to 35));
end entity;
architecture a of sine_test is
	signal sine: signed(8 downto 0);
begin
	sg: sineGenerator port map(CLOCK_50,"0"&SW&(16 downto 0=>'0'),sine);
	GPIO_1(2 to 10) <= std_logic_vector(sine);
end architecture;
