library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity signedClipper is
	generic(bitsIn: integer;
				bitsOut: integer);
	port(inp: in signed(bitsIn-1 downto 0);
			outp: out signed(bitsOut-1 downto 0));
end entity;
architecture a of signedClipper is
	constant max: integer := 2**(bitsOut-1)-1;
	constant min: integer := -(2**(bitsOut-1));
begin
	outp <= to_signed(max,bitsOut) when inp>max else
				to_signed(min,bitsOut) when inp<min else
				inp(bitsOut-1 downto 0);
end architecture;

