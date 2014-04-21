library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hexdisplay is
	port(inp: in unsigned(3 downto 0);
			outp: out std_logic_vector(6 downto 0);
			disable: in std_logic := '0');
end entity;
architecture a of hexdisplay is
	signal tmp: std_logic_vector(6 downto 0);
begin
	tmp <= "1111110" when inp=0 else
				"0110000" when inp=1 else
				"1101101" when inp=2 else
				"1111001" when inp=3 else
				"0110011" when inp=4 else
				"1011011" when inp=5 else
				"1011111" when inp=6 else
				"1110000" when inp=7 else
				"1111111" when inp=8 else
				"1111011" when inp=9 else
				"1110111" when inp=10 else	-- A
				"0011111" when inp=11 else -- B
				"1001110" when inp=12 else -- C
				"0111101" when inp=13 else -- D
				"1001111" when inp=14 else -- E
				"1000111";		-- F
gen_outp:
	for I in 0 to 6 generate
		outp(I) <= not tmp(6-I) when disable='0' else '1';
	end generate;
end architecture;

