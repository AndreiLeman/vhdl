library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity test1 is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		HPS_SD_CLK,HPS_SD_CMD: out std_logic;
		HPS_SD_DATA: inout std_logic_vector(3 downto 0);
		CLOCK_50: in std_logic);
end entity;
architecture a of test1 is
begin
	LEDR(3 downto 0) <= HPS_SD_DATA;
end architecture;
