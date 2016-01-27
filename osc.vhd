library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
use work.osc_ram;
use work.counter_d;
use work.graphics_types.all;
use work.generic_oscilloscope;
use work.simple_altera_pll;
entity osc is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			datain: in signed(15 downto 0);
			samples_per_px: in unsigned(19 downto 0);
			CLOCK_50,aclk: in std_logic;
			stop: in std_logic := '0');
end entity;
architecture a of osc is
	component pll_65 is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component pll_65;
	constant W: integer := 1024;
	constant H: integer := 768;
	signal clk: std_logic;
	signal x,y: unsigned(11 downto 0);
	type pixel is array(0 to 2) of unsigned(7 downto 0);
	signal p: color;
begin
	--pll: component pll_65 port map(refclk=>CLOCK_50,outclk_0=>clk);
	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"64.102564 MHz")
		port map(inclk=>CLOCK_50,outclk=>clk);
	vga_timer: vga_out generic map(W=>W,H=>H,syncdelay=>4)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	VGA_CLK <= clk;
	VGA_R <= p(0) when falling_edge(clk);
	VGA_G <= p(1) when falling_edge(clk);
	VGA_B <= p(2) when falling_edge(clk);
	
	main: generic_oscilloscope port map(aclk,clk,samples_per_px,datain,
		to_unsigned(W,12),to_unsigned(H,12),(x,y),p,stop);
end architecture;



