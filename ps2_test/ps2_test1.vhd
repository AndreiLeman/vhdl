library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
entity ps2_test1 is
	port(HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2: inout std_logic;
		CLOCK_50: in std_logic);
end entity;
architecture a of ps2_test1 is
	signal state,ns: unsigned(3 downto 0) := "0000";
	signal sr,last_data,last_data1,last_data2: unsigned(8 downto 0);
	signal should_sample: std_logic;
begin
	--open drain port
	PS2_CLK <= 'Z';
	PS2_DAT <= 'Z';
	
	state <= ns when falling_edge(PS2_CLK);
	ns <= "0001" when state="0000" and PS2_DAT='0' else
			"0000" when state="0000" else
			"0000" when state="1010" else
			state+1;
	should_sample <= '1' when state="1010" else '0';
	
	--deserializer shift register
	sr <= PS2_DAT & sr(8 downto 1) when falling_edge(PS2_CLK);
	last_data <= sr when should_sample='1' and falling_edge(PS2_CLK);
	last_data1 <= last_data when should_sample='1' and falling_edge(PS2_CLK);
	last_data2 <= last_data1 when should_sample='1' and falling_edge(PS2_CLK);
	
	hd0: hexdisplay port map(last_data(3 downto 0),HEX0);
	hd1: hexdisplay port map(last_data(7 downto 4),HEX1);
	hd2: hexdisplay port map(last_data1(3 downto 0),HEX2);
	hd3: hexdisplay port map(last_data1(7 downto 4),HEX3);
	hd4: hexdisplay port map(last_data2(3 downto 0),HEX4);
	hd5: hexdisplay port map(last_data2(7 downto 4),HEX5);
end architecture;
