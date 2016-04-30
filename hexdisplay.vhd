library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
package HEXdisplaypkg is
	type HEXarray is array(5 downto 0) of std_logic_vector(6 downto 0);
end package;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- for de1-soc board
entity hexdisplay is
	port(inp: in unsigned(3 downto 0);
			outp: out std_logic_vector(6 downto 0);
			disable: in std_logic := '0');
end entity;
architecture a of hexdisplay is
	signal tmp: std_logic_vector(0 to 6);
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
		outp(I) <= not tmp(I) when disable='0' else '1';
	end generate;
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- for custom hex array board
entity hexdisplay_custom is
	port(inp: in unsigned(3 downto 0);
			outp: out std_logic_vector(7 downto 0);
			dot: in std_logic := '0';
			disable: in std_logic := '0');
end entity;
architecture a of hexdisplay_custom is
	signal tmp,tmp1: std_logic_vector(7 downto 0);
begin
	tmp <=   "10110111" when inp=0 else
				"00000110" when inp=1 else
				"01110011" when inp=2 else
				"01010111" when inp=3 else
				"11000110" when inp=4 else
				"11010101" when inp=5 else
				"11110101" when inp=6 else
				"00000111" when inp=7 else
				"11110111" when inp=8 else
				"11010111" when inp=9 else
				"11100111" when inp=10 else	-- A
				"11110100" when inp=11 else -- B
				"10110001" when inp=12 else -- C
				"01110110" when inp=13 else -- D
				"11110001" when inp=14 else -- E
				"11100001";		-- F
gen_outp:
	tmp1(7 downto 4) <= tmp(7 downto 4);
	tmp1(3) <= dot;
	tmp1(2 downto 0) <= tmp(2 downto 0);
	outp <= tmp1 when disable='0' else "00000000";
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.HEXdisplaypkg.all;
use work.hexdisplay;
entity hexarraydisplay is
	port(inp: in unsigned(23 downto 0);
		outp: out HEXarray;
		disable: in std_logic_vector(5 downto 0) := "000000");
end entity;
architecture a of hexarraydisplay is
begin
gen:
	for I in 0 to 5 generate
		hd: entity hexdisplay port map(inp(I*4+3 downto I*4),outp(I),disable(I));
	end generate;
end architecture;


