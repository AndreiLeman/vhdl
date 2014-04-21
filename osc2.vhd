
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out3;
use work.osc_ram;
use work.counter_d;
use work.graphics_types.all;
use work.generic_oscilloscope;
--for pinout of vga_out, see vga_fb.vhd
entity osc2 is
	port(	vclk,aclk: in std_logic;
			vga_conf: in unsigned(91 downto 0);
			vga_out: out unsigned(27 downto 0);
			datain: in signed(15 downto 0);
			samples_per_px: in unsigned(19 downto 0);
			stop: in std_logic := '0');
end entity;
architecture a of osc2 is
	signal p: position;
	signal c: color;
begin
	vga_out(27) <= vclk;
	vga_timer: vga_out3 generic map(syncdelay=>4)
		port map(vga_out(24),vga_out(26),vga_out(25),vclk,p,vga_conf);
	vga_out(23 downto 0) <= c(2)&c(1)&c(0); --BGR pixel order
	main: generic_oscilloscope port map(aclk,vclk,samples_per_px,datain,
		vga_conf(11 downto 0),vga_conf(27 downto 16),p,c,stop);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc2;
use work.simple_altera_pll;
entity simple_oscilloscope is
	port(CLOCK_50,aclk: in std_logic;
			vga_out: out unsigned(27 downto 0);
			datain: in signed(15 downto 0);
			samples_per_px: in unsigned(19 downto 0) := to_unsigned(1,20);
			stop: in std_logic := '0');
end entity;
architecture a of simple_oscilloscope is
	signal vclk: std_logic;
	signal vga_conf: unsigned(91 downto 0);
begin
	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"135 MHz")
		port map(inclk=>CLOCK_50,outclk=>vclk);
--	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"172.857142 MHz")
--		port map(inclk=>CLOCK_50,outclk=>vclk);
	o: osc2 port map(vclk,aclk,vga_conf,vga_out,datain,samples_per_px,stop);
	
	vga_conf <= 
		to_unsigned(3,10) &
		to_unsigned(38,10) &
		to_unsigned(1,10) &
		to_unsigned(144,10) &
		to_unsigned(248,10) &
		to_unsigned(16,10) &
		to_unsigned(1024,16) &
		to_unsigned(1280,16);

--	vga_conf <= 
--		to_unsigned(3,10) &
--		to_unsigned(34,10) &
--		to_unsigned(1,10) &
--		to_unsigned(208,10) &
--		to_unsigned(328,10) &
--		to_unsigned(120,10) &
--		to_unsigned(1080,16) &
--		to_unsigned(1920,16);
end architecture;
