LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dcram;
ENTITY osc_ram IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
	);
END osc_ram;


ARCHITECTURE a OF osc_ram IS
	signal q1: STD_LOGIC_VECTOR (23 DOWNTO 0);
BEGIN
	ram: entity dcram generic map(width=>24, depthOrder=>13)
		port map(rdclk=>rdclock,wrclk=>wrclock,							--clocks
			rden=>'1',rdaddr=>unsigned(rdaddress),rddata=>q1,			--read side
			wren=>wren,wraddr=>unsigned(wraddress),wrdata=>data);		--write side
	q <= q1 when rising_edge(rdclock);
END a;
