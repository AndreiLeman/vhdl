
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
--use work.VGA;
use work.sprite1;
use work.graphics_types.all;
use work.bounce_sprite;
entity vga_test2 is
	port(VGA_R,VGA_G,VGA_B: out std_logic_vector(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(17 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of vga_test2 is
	constant W: integer := 640;
	constant H: integer := 480;
	constant spriteW,spriteH: integer := 16;
	signal clk,pclk: std_logic;
	signal x,y: unsigned(11 downto 0);
	signal p,p1,p2,p3: position;
	signal sprite_p,sprite_rp,tmp_sprite_p: position;
	signal px,px1,sprite_px: color;
	signal sprite_transparent,sprite_en,sprite_en1,sprite_en2,sprite_en3: std_logic;
	signal dx,dy: signed(12 downto 0);
	signal xs,ys: signed(25 downto 0);
	signal bounce_en: std_logic;
	signal bg: color;
begin


	clk <= not clk when rising_edge(CLOCK_50);
	vga_timer: vga_out generic map(syncdelay=>3)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	pclk <= '1' when y=H and rising_edge(clk) else '0' when rising_edge(clk);
	p <= (x,y);
	p1 <= p when rising_edge(clk);
	p2 <= p1 when rising_edge(clk);
	p3 <= p2 when rising_edge(clk);
	VGA_CLK <= clk;
	VGA_R <= px1(29 downto 22) when falling_edge(clk);
	VGA_G <= px1(19 downto 12) when falling_edge(clk);
	VGA_B <= px1(9 downto 2) when falling_edge(clk);
	
	px1 <= px when rising_edge(clk);
	px <= sprite_px when sprite_en3='1' and sprite_transparent='0' else bg;

	bg <= (SW(9 downto 7)&"0000000"&SW(6 downto 4)&"0000000"&
		SW(3 downto 1)&"0000000");
	
	
	sprite_en <= '1' when p(0)>sprite_p(0) and p(1)>sprite_p(1)
		and p(0)<sprite_p(0)+spriteW and p(1)<sprite_p(1)+spriteH else '0';
	sprite_en1 <= sprite_en when rising_edge(clk);
	sprite_en2 <= sprite_en1 when rising_edge(clk);
	sprite_en3 <= sprite_en2 when rising_edge(clk);
	
--	--sprite_p <= ("00"&unsigned(SW(9 downto 5))&"00000","00"&unsigned(SW(4 downto 0))&"00000");
	sprite_rp <= (p(0)-sprite_p(0),p(1)-sprite_p(1)) when rising_edge(clk);
sp: sprite1 port map(x=>sprite_rp(0)(7 downto 0),y=>sprite_rp(1)(7 downto 0),
	clk=>clk,color_o=>sprite_px,transparent=>sprite_transparent);

--sprite_p <= ("000"&tmp_sprite_p(0)(11 downto 3),"000"&tmp_sprite_p(1)(11 downto 3));
	sprite_p <= tmp_sprite_p;
	bounce_en <= SW(0) when falling_edge(pclk);
	asdf: bounce_sprite generic map(W,H,spriteW,spriteH) 
		port map(clk=>pclk and bounce_en,sprite_p=>tmp_sprite_p,
		initvX=>"00000000000"&unsigned(SW(17 downto 14)),
		initvY=>"00000000000"&unsigned(SW(13 downto 10)));
end architecture;
