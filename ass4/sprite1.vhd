library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.graphics_types.all;
use work.VGA.all;
--64x64
--delay is 2 clock cycles
entity sprite1 is
	port(x,y: in unsigned(7 downto 0);
			clk: in std_logic;
			color_o: out color;
			transparent: out std_logic);
end entity;
architecture a of sprite1 is
	--type rom1 is array(1023 downto 0) of unsigned(1 downto 0);
	constant spriteW,spriteH: integer := 16;
	signal t: std_logic;
	signal dx,dy: signed(8 downto 0);
	signal xs,ys: signed(17 downto 0);
	signal cc: unsigned(2 downto 0);
	signal ind: unsigned(7 downto 0);
	signal c: color;
begin
	--color <= redmix;
	
	--dx <= ("0"&signed(x))-spriteW/2 when rising_edge(clk);
	--dy <= ("0"&signed(y))-spriteH/2 when rising_edge(clk);
	--xs <= dx*dx when rising_edge(clk);
	--ys <= dy*dy when rising_edge(clk);
	
	ind <= y(3 downto 0)&x(3 downto 0);
	cc <= to_unsigned(MarioSpriteROM(to_integer(ind)),3) when rising_edge(clk);
	c <= MarioColourTable(to_integer(cc));
	color_o <= c when rising_edge(clk);
	--t <= '1' when c=BlackMix else '0';
	-- y*16+x
	
	--t <= '0' when (xs+ys)<(spriteW/2)**2 else '1';
	--transparent <= t when rising_edge(clk);
	transparent <= '0';
end architecture;
