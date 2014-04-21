library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.counter;
entity vga_out is
	generic(W: integer := 1280;
		H: integer := 1024;
		hsync_predelay: integer := 16;
		hsync_postdelay: integer := 248;
		hsync_duration: integer := 144;
		vsync_predelay: integer := 1;
		vsync_postdelay: integer := 38;
		vsync_duration: integer := 3;
		syncdelay: integer := 0);
	port(VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			clk: in std_logic;
			cx,cy: out unsigned(11 downto 0));
end entity;

architecture a of vga_out is
	constant realdelay: integer := syncdelay+2;
	signal c2c,nc2c: std_logic;
	signal x,y,c1v,c2v: unsigned(11 downto 0);
	type syncsignal_a is array(realdelay downto 0) of std_logic_vector(2 downto 0);
	signal syncsignals: syncsignal_a;
begin
	cx <= x-hsync_duration-hsync_postdelay when rising_edge(clk);
	cy <= y when rising_edge(clk);
	
	cnt1: counter generic map(N=>12,max=>W+hsync_predelay+hsync_duration+hsync_postdelay)
		port map(clk=>clk,outp=>c1v);
	cnt2: counter generic map(N=>12,max=>H+vsync_predelay+vsync_duration+vsync_postdelay)
		port map(clk=>c2c,outp=>c2v);
	nc2c <= '1' when c1v=W+hsync_predelay+hsync_duration+hsync_postdelay-1 else '0';
	c2c <= nc2c when rising_edge(clk);
	x <= c1v;
	y <= c2v;
	
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= not syncsignals(syncdelay)(0) when falling_edge(clk);
	VGA_HS <= not syncsignals(syncdelay)(1) when falling_edge(clk);
	VGA_VS <= not syncsignals(syncdelay)(2) when falling_edge(clk);

	syncsignals(0)(0) <= '1' when x<(hsync_duration+hsync_postdelay)
		or x>=(hsync_duration+hsync_postdelay+W) or y>=H else '0';
	syncsignals(0)(1) <= '1' when x<hsync_duration else '0';
	syncsignals(0)(2) <= '1' when y>=H+vsync_predelay and y<H+vsync_predelay+vsync_duration else '0';
	
gen_delays:
	for I in 0 to realdelay-1 generate
		syncsignals(I+1) <= syncsignals(I) when rising_edge(clk);
	end generate;
end architecture;

