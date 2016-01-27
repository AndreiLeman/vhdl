library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.vjtag1;

entity test2 is
	port(USB_B2_CLK: in std_logic;
		USB_B2_DATA: in std_logic_vector(7 downto 0);
		HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		LEDR: out std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0));
end entity;
architecture a of test2 is
	signal tmp: unsigned(7 downto 0);
	signal cnt: unsigned(23 downto 0);
	signal ir_out,ir_in: STD_LOGIC_VECTOR (0 DOWNTO 0);
	signal tdi,tdo,tck: std_logic;
begin
	tmp <= unsigned(USB_B2_DATA) when KEY(0)='1' and falling_edge(USB_B2_CLK);
	LEDR(0) <= USB_B2_CLK;
	LEDR(9 downto 1) <= (others=>'0');
	hd0: hexdisplay port map(tmp(3 downto 0),HEX0);
	hd1: hexdisplay port map(tmp(7 downto 4),HEX1);
	hd2: hexdisplay port map(cnt(19 downto 16),HEX2);
	hd3: hexdisplay port map(cnt(23 downto 20),HEX3);
	cnt <= cnt+1 when KEY(0)='1' and rising_edge(USB_B2_CLK);
	
	vj: vjtag1 port map(ir_out,tdo,ir_in,tck,tdi);
	tdo <= '0';
end architecture;
