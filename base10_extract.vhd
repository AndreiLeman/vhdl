library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity base10_extract is
	generic(bits: integer; n: integer);
	port(x: in unsigned(bits-1 downto 0);
			digit: out unsigned(3 downto 0));
end entity;
architecture a of base10_extract is
	signal tmp1,tmp2: unsigned(bits-1 downto 0);
begin
	tmp1 <= x/(10**n);
	tmp2 <= tmp1 mod 10;
	digit <= tmp2(3 downto 0);
end architecture;
