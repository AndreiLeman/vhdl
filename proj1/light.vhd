library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity light is
	port (LEDR: out std_logic_vector(17 downto 0);
			SW: in std_logic_vector(17 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of light is
begin
	LEDR <= SW;
end;

