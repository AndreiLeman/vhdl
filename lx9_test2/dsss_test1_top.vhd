library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.slow_clock;
use work.sineGenerator;
use work.dsssDecoder;
use work.graphics_types.all;
use work.ili9341Out;
use work.generic_oscilloscope;
use work.cic_lpf_2_nd;
use work.cic_lpf_2_d;
use work.dsssDecoder2;
use work.dsssDecoder3;
use work.dsssCode1;
use work.dcram;
use work.generic_bar_display;
entity dsssTest1Top is
	port(coreclk,lcdclk,oscDataClk,adcFClk: in std_logic;
		oscDataIn: in signed(15 downto 0);
		adcFiltered2Truncated: in signed(9 downto 0);
		lcd_scl,lcd_sdi,lcd_cs,lcd_dc,lcd_rst: out std_logic;
		SW: in std_logic_vector(1 downto 0);
		ebuttons: in std_logic_vector(2 downto 0)
		);
end entity;
architecture a of dsssTest1Top is
	--dsss decoder 2
	signal dsssDataClk: std_logic;
	
	
	--lcd display
	constant lcdW: integer := 320;
	constant lcdH: integer := 240;
	signal lcdPos: position;
	signal lcdPixel: color;
	
	--oscilloscope
	signal oscSampleAddr: std_logic;
	signal oscPos: position;
	signal oscPixel: color;
	signal samples_per_px: unsigned(19 downto 0);
	
	--dsss2 + display
	signal codeAddr: unsigned(9 downto 0);
	signal code: std_logic;
	
	signal dsssPhase: unsigned(7 downto 0); --not the code phase, but the divclk phase
	signal dsssOutValid: std_logic;
	signal dsssOutAddr: unsigned(8 downto 0);
	signal dsssOutData: signed(16 downto 0);
	signal dsss2ramAddr: unsigned(8 downto 0);
	signal dsss2ramData: signed(11 downto 0);
	signal dsss2ramWren: std_logic;
	signal dsss2Pixel: color;
	signal dsss2DisplayAddr: unsigned(11 downto 0);
	signal dsss2DisplayData: std_logic_vector(11 downto 0);
begin
	--lcd display
	
	lcdcntrl: entity ili9341Out port map(clk=>lcdclk,
		p=>lcdPos,pixel=>lcdPixel,
		lcd_scl=>lcd_scl,lcd_sdi=>lcd_sdi,
		lcd_cs=>lcd_cs,lcd_dc=>lcd_dc,lcd_rst=>lcd_rst);
	lcdPixel <= oscPixel when SW(0)='0' else dsss2Pixel;
	
	--oscilloscope
	osc: entity generic_oscilloscope generic map(external_sample_pulse=>true)
		port map(dataclk=>oscDataClk,
			videoclk=>lcdclk,samples_per_px=>samples_per_px,
			datain=>oscDataIn,W=>to_unsigned(320,12),H=>to_unsigned(240,12),
			p=>oscPos,outp=>oscPixel,stop=>ebuttons(0),
			do_sample_addr=>oscSampleAddr);
	
	oscPos <= (319-lcdPos(1), 239-lcdPos(0)) when rising_edge(lcdclk);
	oscSampleAddr <= '1' when lcdPos(0)=0 and lcdPos(1)=319 else '0';
	samples_per_px <= to_unsigned(0,20) when SW(0)='1'
		else to_unsigned(1,20);
	
	
	--dsss decoder
	sc_dsss2: entity slow_clock generic map(225,100) port map(clk=>coreclk,o=>dsssDataClk,phase=>dsssPhase);
	dsss2: entity dsssDecoder3 generic map(clkdiv=>225, clkdivOrder=>8, inbits=>8, outbits=>17, combSeparationOrder=>1)
		port map(coreclk=>coreclk,divclk=>dsssDataClk,din=>adcFiltered2Truncated(9 downto 2),
			divclkPhase=>dsssPhase,
			codeAddr=>codeAddr,code=>code,
			outValid=>dsssOutValid,outAddr=>dsssOutAddr,outData=>dsssOutData);
	cg: entity dsssCode1 port map(coreclk,codeAddr,code);	--code is synchronized to accPhase2
	
	--correlator output display
	dsss2ram: entity dcram generic map(width=>12,depthOrder=>9,outputRegistered=>false)
		port map(rdclk=>lcdClk,wrclk=>dsssDataClk,
			rden=>'1',rdaddr=>dsss2DisplayAddr(8 downto 0),
			rddata=>dsss2DisplayData,
			wren=>dsss2ramWren,wraddr=>dsss2ramAddr,
			wrdata=>std_logic_vector(dsss2ramData));
	dsss2ramData <= dsssOutData(16 downto 5)+120; -- when rising_edge(CLOCK_1);
	dsss2ramAddr <= dsssOutAddr; -- when rising_edge(CLOCK_1);
	dsss2ramWren <= dsssOutValid; -- when rising_edge(CLOCK_1);

	bardisp: entity generic_bar_display port map(clk=>lcdClk,
		W=>to_unsigned(lcdW,12), H=>to_unsigned(lcdH,12), p=>oscPos,
		outp=>dsss2Pixel,ram_addr=>dsss2DisplayAddr,
		ram_data=>unsigned(dsss2DisplayData));
end a;
