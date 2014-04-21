library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity toneGenerator is
	port(freq: in unsigned(23 downto 0); --periods per sample; purely fractional
			audioOut: out signed(15 downto 0); --unregistered
			aclk: in std_logic);
end entity;
architecture a of toneGenerator is
	signal counter: unsigned(23 downto 0);
begin
	counter <= counter+freq when rising_edge(aclk);
	--eliminate dc offset
	audioOut <= to_signed(0,16) when freq=0 else
		signed(unsigned(counter(23 downto 8)+"1000000000000000"));
end architecture;
