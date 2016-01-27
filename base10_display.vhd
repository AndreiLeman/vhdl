library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.base10_extract;
entity base10_display is
	generic(bits: integer; digits: integer);
	port(x: in unsigned(bits-1 downto 0);
			data: out unsigned(4*digits-1 downto 0));
end entity;
architecture a of base10_display is
begin
gen:
	for I in 0 to digits-1 generate
		ex: base10_extract generic map(bits,I) port map(x,data((I+1)*4-1 downto I*4));
	end generate;
end architecture;
