library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
use work.graphics_types.all;
use work.simple_altera_pll;
use work.spectrum2;
use work.generic_bar_display;
use work.spectrum2_ram;
use work.generic_oscilloscope;

entity spectrum2_wrapper is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			datain: in signed(7 downto 0);
			CLOCK_50,dataclk: in std_logic;
			samples_per_px: in unsigned(19 downto 0);
			sel: in std_logic;	-- 0: oscilloscope; 1: spectrum analyzer
			stop: in std_logic := '0');
end entity;
architecture a of spectrum2_wrapper is
	constant W: integer := 1024;
	constant H: integer := 768;
	signal clk: std_logic;
	signal x,y: unsigned(11 downto 0);
	type pixel is array(0 to 2) of unsigned(7 downto 0);
	signal c,c_osc,c_spectrum: color;
	
	signal ram_wclk,ram_rclk: std_logic;
	signal ram_raddr,ram_raddr1,ram_waddr,ram_waddr1: unsigned(9 downto 0);
	signal ram_wdata,ram_wdata1: unsigned(15 downto 0);
	signal ram_rdata: std_logic_vector(15 downto 0);
	
	signal raddr: unsigned(11 downto 0);
begin
	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"64.102564 MHz")
		port map(inclk=>CLOCK_50,outclk=>clk);
	vga_timer: vga_out generic map(W=>W,H=>H,syncdelay=>4)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	VGA_CLK <= clk;
	VGA_R <= c(0) when falling_edge(clk);
	VGA_G <= c(1) when falling_edge(clk);
	VGA_B <= c(2) when falling_edge(clk);
	
	main: spectrum2 port map(dataclk,datain,to_unsigned(natural(real(0.0005*16777216)),24),ram_wclk,ram_waddr,ram_wdata);
	disp: generic_bar_display port map(clk,
		to_unsigned(W,12),to_unsigned(H,12),(x,y),c_spectrum,raddr,unsigned(ram_rdata(15 downto 4)));
	ram_rclk <= clk;
	ram_raddr <= raddr(9 downto 0);
	
	--ram
	ram: spectrum2_ram port map(std_logic_vector(ram_wdata),std_logic_vector(ram_raddr),
		ram_rclk,std_logic_vector(ram_waddr),ram_wclk,'1',ram_rdata);
	
	
	osc: generic_oscilloscope port map(dataclk,clk,samples_per_px,datain&"00000000",
		to_unsigned(W,12),to_unsigned(H,12),(x,y),c_osc,stop);
		
	c <= c_spectrum when sel='1' else c_osc;
end architecture;



