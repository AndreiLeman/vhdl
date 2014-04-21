library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.simple_counter;
use work.graphics_types.all;
entity vga_out2 is
	generic(syncdelay: integer := 0);
	port(VGA_BLANK,VGA_VS,VGA_HS: out std_logic;
			clk: in std_logic;
			p: out position;
			W,H: in unsigned(11 downto 0);
			hsync_predelay,hsync_postdelay,hsync_duration,
			vsync_predelay,vsync_postdelay,vsync_duration:
				in unsigned(9 downto 0));
end entity;

architecture a of vga_out2 is
	constant realdelay: integer := syncdelay+2;
	signal c2c,nc2c: std_logic;
	signal x,y,c1v,c2v: unsigned(11 downto 0);
	type syncsignal_a is array(realdelay downto 0) of std_logic_vector(2 downto 0);
	signal syncsignals: syncsignal_a;
begin
	p(0) <= x-hsync_duration-hsync_postdelay when rising_edge(clk);
	p(1) <= y when rising_edge(clk);
	
	cnt1: simple_counter generic map(N=>12)
		port map(clk=>clk,max=>W+hsync_predelay+hsync_duration+hsync_postdelay,outp=>c1v);
	cnt2: simple_counter generic map(N=>12)
		port map(clk=>c2c,max=>H+vsync_predelay+vsync_duration+vsync_postdelay,outp=>c2v);
	nc2c <= '1' when c1v=W+hsync_predelay+hsync_duration+hsync_postdelay-1 else '0';
	c2c <= nc2c when rising_edge(clk);
	x <= c1v;
	y <= c2v;

	VGA_BLANK <= syncsignals(syncdelay)(0) when falling_edge(clk);
	VGA_HS <= syncsignals(syncdelay)(1) when falling_edge(clk);
	VGA_VS <= syncsignals(syncdelay)(2) when falling_edge(clk);

	syncsignals(0)(0) <= '1' when x<(hsync_duration+hsync_postdelay)
		or x>=(hsync_duration+hsync_postdelay+W) or y>=H else '0';
	syncsignals(0)(1) <= '1' when x<hsync_duration else '0';
	syncsignals(0)(2) <= '1' when y>=H+vsync_predelay and y<H+vsync_predelay+vsync_duration else '0';
	
gen_delays:
	for I in 0 to realdelay-1 generate
		syncsignals(I+1) <= syncsignals(I) when rising_edge(clk);
	end generate;
end architecture;

--conf pinout:
--[15..0]	width
--[31..16]	height
--[91..32]	misc:
--		[9..0]	h_predelay (pixels)
--		[19..10]	h_postdelay
--		[29..20]	h_duration
--		[39..30]	v_predelay (lines)
--		[49..40]	v_postdelay
--		[59..50]	v_duration
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out2;
use work.graphics_types.all;
entity vga_out3 is
	generic(syncdelay: integer := 0);
	port(VGA_BLANK,VGA_VS,VGA_HS: out std_logic;
			clk: in std_logic;
			p: out position;
			conf: in unsigned(91 downto 0));
end entity;
architecture a of vga_out3 is
	signal conf_misc: unsigned(59 downto 0);
begin
	conf_misc <= conf(91 downto 32);
	vga: vga_out2 generic map(syncdelay) port map(VGA_BLANK,VGA_VS,VGA_HS,clk,p,
		conf(11 downto 0),conf(27 downto 16),
		conf_misc(9 downto 0),conf_misc(19 downto 10),conf_misc(29 downto 20),
		conf_misc(39 downto 30),conf_misc(49 downto 40),conf_misc(59 downto 50));
end architecture;
