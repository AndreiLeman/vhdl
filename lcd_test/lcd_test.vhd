library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.slow_clock;
use work.graphics_types.all;
use work.ili9327Out;
use work.bounce_sprite;

entity lcd_test is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2: inout std_logic;
			LEDR: out std_logic_vector(9 downto 0)
			);
end entity;
architecture a of lcd_test is
	--i/o pins
	signal lcd_cs_n,lcd_rs,lcd_wr_n,lcd_rd_n,lcd_rst_n,lcd_led: std_logic;
	signal lcd_data: unsigned(15 downto 0);
	
	--lcd user side interface signals
	signal lcdClk: std_logic;
	signal curPos: position;
	signal offscreen: std_logic;
	signal pixel,pixelOut: color;
	
	--sprite position control
	signal spritePos: position;
	
	constant W: integer := 320;
	constant H: integer := 240;
	constant spriteW,spriteH: integer := 50;

begin
	--3.125MHz
	sc: entity slow_clock generic map(16,8) port map(CLOCK_50,lcdClk);

	--lcd controller
	lcdOut: entity ili9327Out generic map(2) port map(clk=>lcdClk,p=>curPos,offscreen=>offscreen,
		pixel=>pixelOut, lcd_rs=>lcd_rs,lcd_wr_n=>lcd_wr_n,lcd_data=>lcd_data);

	--draw the rectangle
	pixel <= (X"ff",X"00",X"00") when curPos(0)>spritePos(0) and curPos(0)<spritePos(0)+spriteW
			and curPos(1)>spritePos(1) and curPos(1)<spritePos(1)+spriteH
		else (X"ff",X"ff",X"00") when curPos(0)=0 or curPos(1)=0 or curPos(0)=W-1 or curPos(1)=H-1
		else (X"00",X"00",X"00");
	pixelOut <= pixel when rising_edge(lcdClk);
	
	--calculate the position of the rectangle
	bounce: entity bounce_sprite generic map(W,H,spriteW,spriteH)
		port map(offscreen,spritePos,to_unsigned(40,15),to_unsigned(40,15));

	
	--output signals
	lcd_cs_n <= '0';
	lcd_rst_n <= '1';
	lcd_led <= '1';
	lcd_rd_n <= '1';

	GPIO_0 <= (others=>'0');
	GPIO_1 <= (2=>lcd_led,
					6=>lcd_rst_n,
					0=>lcd_cs_n,
					10=>lcd_data(15),
					11=>'Z',				--T_IRQ
					12=>lcd_data(14),
					13=>'Z',				--T_DO
					14=>lcd_data(13),
					16=>lcd_data(12),
					18=>lcd_data(11),
					20=>lcd_data(10),
					22=>lcd_data(9),
					23=>lcd_data(7),
					24=>lcd_data(8),
					25=>lcd_data(6),
					32=>lcd_rd_n,
					34=>lcd_data(5),
					26=>lcd_wr_n,
					27=>lcd_data(4),
					28=>lcd_rs,
					29=>lcd_data(3),
					31=>lcd_data(2),
					33=>lcd_data(1),
					35=>lcd_data(0),
					others=>'1'
					);
	
end a;
