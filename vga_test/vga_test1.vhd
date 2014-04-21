
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
entity vga_test1 is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of vga_test1 is
	constant W: integer := 1280;
	constant H: integer := 1024;
	signal clk: std_logic;
	signal x,y: unsigned(11 downto 0);
	type pixel is array(0 to 2) of unsigned(7 downto 0);
	signal p,p1: pixel;
begin
	--pll: component pll_65 port map(refclk=>CLOCK_50,outclk_0=>clk);
	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"135.000000 MHz")
		port map(inclk=>CLOCK_50,outclk=>clk);
	
	vga_timer: vga_out generic map(syncdelay=>2)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	VGA_CLK <= clk;
	VGA_R <= p1(0) when falling_edge(clk);
	VGA_G <= p1(1) when falling_edge(clk);
	VGA_B <= p1(2) when falling_edge(clk);
	p1 <= p when rising_edge(clk);
	p(0) <= X"ff" when (x=0 or y=0 or x=W-1 or y=H-1) else x(9 downto 2);
	p(1) <= X"ff" when (x=0 or y=0 or x=W-1 or y=H-1) else y(9 downto 2);
	p(2) <= X"ff" when (x=0 or y=0 or x=W-1 or y=H-1) else unsigned(SW(7 downto 0));
end architecture;
