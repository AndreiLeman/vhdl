library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity modulus1 is
	port(inp: in unsigned(31 downto 0);
			outp: out unsigned(3 downto 0));
end entity;

architecture a of modulus1 is
	signal tmp: unsigned(63 downto 0);
	signal tmp1: unsigned(63 downto 0);
	signal tmp2: unsigned(63 downto 0);
	signal tmp3: unsigned(31 downto 0);
begin
	tmp1 <= inp * 429496729;
	tmp2 <= tmp1(63 downto 32)*10;
	tmp3 <= inp-tmp2(31 downto 0);
	outp <= tmp3(3 downto 0);
end architecture;
