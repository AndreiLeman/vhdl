
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
use work.sprite1;
use work.trollface_sprite;
use work.graphics_types.all;
use work.bounce_sprite;
entity vga_test2 is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of vga_test2 is
	constant W: integer := 1920;
	constant H: integer := 1080;
	constant hsync_predelay: integer := 120;
	constant hsync_postdelay: integer := 328;
	constant hsync_duration: integer := 208;
	constant vsync_predelay: integer := 1;
	constant vsync_postdelay: integer := 34;
	constant vsync_duration: integer := 3;
	constant spriteW,spriteH: integer := 128;
	signal clk,pclk: std_logic;
	signal x,y: unsigned(11 downto 0);
	signal p,p1,p2,p3: position;
	signal sprite_p,sprite_rp,tmp_sprite_p: position;
	signal px,px1,sprite_px: color;
	signal sprite_transparent,sprite_en,sprite_en1,sprite_en2,sprite_en3: std_logic;
	signal dx,dy: signed(12 downto 0);
	signal xs,ys: signed(25 downto 0);
	
	signal pclk2,invert: std_logic;
	signal invert1: unsigned(7 downto 0);
	signal bg: color;
	
	component altpll_135m
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component;
begin
	--pll: component pll_65 port map(refclk=>CLOCK_50,outclk_0=>clk);
	pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"173.000000 MHz")
		port map(inclk=>CLOCK_50,outclk=>clk);
	--pll: component altpll_135m port map(inclk0=>CLOCK_50,c0=>clk);
	
	vga_timer: vga_out generic map(W,H,hsync_predelay,hsync_postdelay,hsync_duration,
		vsync_predelay,vsync_postdelay,vsync_duration,syncdelay=>2)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	pclk <= '1' when y=H and rising_edge(clk) else '0' when rising_edge(clk);
	p <= (x,y);
	p1 <= p when rising_edge(clk);
	p2 <= p1 when rising_edge(clk);
	p3 <= p2 when rising_edge(clk);
	VGA_CLK <= clk;
	VGA_R <= px1(0) when falling_edge(clk);
	VGA_G <= px1(1) when falling_edge(clk);
	VGA_B <= px1(2) when falling_edge(clk);
	invert1 <= (others => invert);
	px1 <= px when rising_edge(clk);
	px <= sprite_px when sprite_en3='1' and sprite_transparent='0' else bg;
	pclk2 <= not pclk2 when rising_edge(pclk);
	invert <= not invert when rising_edge(pclk2);
	bg <= (unsigned(SW(9 downto 7))&"00000",unsigned(SW(6 downto 4))&"00000",
		unsigned(SW(3 downto 1))&"00000");
	
	
	sprite_en <= '1' when p(0)>sprite_p(0) and p(1)>sprite_p(1)
		and p(0)<sprite_p(0)+spriteW and p(1)<sprite_p(1)+spriteH else '0';
	sprite_en1 <= sprite_en when rising_edge(clk);
	sprite_en2 <= sprite_en1 when rising_edge(clk);
	sprite_en3 <= sprite_en2 when rising_edge(clk);
	
	--sprite_p <= ("00"&unsigned(SW(9 downto 5))&"00000","00"&unsigned(SW(4 downto 0))&"00000");
	sprite_rp <= (p(0)-sprite_p(0),p(1)-sprite_p(1)) when rising_edge(clk);
	--sp: sprite1 port map(x=>sprite_rp(0)(7 downto 0),y=>sprite_rp(1)(7 downto 0),
	--	clk=>clk,color=>sprite_px,transparent=>sprite_transparent);
	sp: trollface_sprite port map(x=>sprite_rp(0)(6 downto 0),y=>sprite_rp(1)(6 downto 0),
		clk=>clk,color=>sprite_px,transparent=>sprite_transparent);
	
	--sprite_p <= ("000"&tmp_sprite_p(0)(11 downto 3),"000"&tmp_sprite_p(1)(11 downto 3));
	sprite_p <= tmp_sprite_p;
	asdf: bounce_sprite generic map(W,H,spriteW,spriteH) port map(clk=>pclk and SW(0),sprite_p=>tmp_sprite_p);
end architecture;
