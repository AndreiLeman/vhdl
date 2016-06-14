library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--dims an led using pwm, and makes sure pulses aren't missed
entity ledPreprocess is
	port (clk: in std_logic;	--clock used for led dimming
			i: in std_logic;
			o: out std_logic);
end;

architecture a of ledPreprocess is
	signal ff1,ff2: std_logic;
begin
	ff1 <= '1' when i='1' else
		'0' when rising_edge(clk);
	ff2 <= ff1 when rising_edge(clk);
	o <= ff2 and clk;
end architecture;
