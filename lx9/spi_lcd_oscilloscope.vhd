library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ili9341Out;
use work.graphics_types.all;
use work.generic_oscilloscope;

entity spiLCDOscilloscope is
	port(lcdclk: in std_logic;				--spi clock for lcd display & controller
		lcd_scl,lcd_sdi,lcd_cs,
			lcd_dc,lcd_rst: out std_logic;	--lcd panel signals
		dataclk: in std_logic;
		datain: in signed(15 downto 0);
		samples_per_px: in unsigned(19 downto 0) := (0=>'1', others=>'0');
		stop: in std_logic := '0');
end entity;

architecture a of spiLCDOscilloscope is
	--lcd display
	constant lcdW: integer := 320;
	constant lcdH: integer := 240;
	signal lcdPos: position;
	signal lcdPixel: color;
	
	--oscilloscope
	signal oscSampleAddr: std_logic;
	signal oscPos: position;
	signal oscPixel: color;
begin
	--lcd display
	
	lcdcntrl: entity ili9341Out port map(clk=>lcdclk,
		p=>lcdPos,pixel=>lcdPixel,
		lcd_scl=>lcd_scl,lcd_sdi=>lcd_sdi,
		lcd_cs=>lcd_cs,lcd_dc=>lcd_dc,lcd_rst=>lcd_rst);
	lcdPixel <= oscPixel;
	
	--oscilloscope
	osc: entity generic_oscilloscope generic map(external_sample_pulse=>true)
		port map(dataclk=>dataclk,
			videoclk=>lcdclk,samples_per_px=>samples_per_px,
			datain=>datain,W=>to_unsigned(320,12),H=>to_unsigned(240,12),
			p=>oscPos,outp=>oscPixel,stop=>stop,
			do_sample_addr=>oscSampleAddr);
	
	oscPos <= (319-lcdPos(1), 239-lcdPos(0)) when rising_edge(lcdclk);
	oscSampleAddr <= '1' when lcdPos(0)=0 and lcdPos(1)=319 else '0';
end a;

