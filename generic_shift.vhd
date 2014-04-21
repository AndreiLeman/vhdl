library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity generic_shift is
	generic(N: integer := 32);
	port(data: in unsigned(N-1 downto 0));
end entity;
architecture a of generic_shift is
begin
	
end architecture;
