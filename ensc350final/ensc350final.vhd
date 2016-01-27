library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemStereo;
use work.simple_oscilloscope;
use work.fm_modulator;
use work.deltaSigmaModulator;
use work.signedClipper;
use work.multiToneGenerator;
use work.ps2Piano;
use work.hexdisplay;
use work.volumeControl;
use work.ps2Receiver;
use work.interpolator256;
entity ensc350final is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2: inout std_logic;
			
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			GPIO: inout std_logic_vector(35 downto 0);
			SMA_CLKOUT: out std_logic);
end entity;
architecture a of ensc350final is
	component pll_100 is
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component pll_100;
	component pll_300 is
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component pll_300;
	signal interp_div: unsigned(2 downto 0);
	signal aclk,aclk1,vclk,interp_clk,CLOCK_135,CLOCK_300: std_logic;
	signal aoutL,aoutR,ainL,ainR,oscIn: signed(15 downto 0);
	signal ainMono: signed(16 downto 0);
	signal ainMonoScaled: signed(19 downto 0);
	signal vga: unsigned(27 downto 0);
	signal fm_intermediate,fm_out,CLOCK_100,CLOCK_100_1: std_logic;
	signal interp_wr_en: std_logic;
	signal interp_out: signed(23 downto 0);
	signal dacIn,dacIn2: unsigned(23 downto 0);
	signal dacClk,dacOut: std_logic;
	signal mainAudio,mainAudio0: signed(15 downto 0);
	
	signal osc_speed_sw: unsigned(2 downto 0);
	
	signal disp_data: unsigned(23 downto 0);
	
	--piano
	signal ps2_state,ps2_ns: unsigned(3 downto 0) := "0000";
	signal ps2_sr: unsigned(8 downto 0);
	signal last_key,ps2_last_byte,ps2_last_data,ps2_last_data1,ps2_last_data2: unsigned(7 downto 0);
	signal ps2_should_sample: std_logic;
	signal piano_freq: unsigned(23 downto 0);
	signal iskeydown,iskeyup,piano_reset: std_logic;
	signal pianoAin,pianoAin1: signed(15 downto 0);
	signal pianoAinScaled: signed(19 downto 0);
	signal ps2_new_clk: std_logic;
	signal piano_octave,next_piano_octave: unsigned(1 downto 0) := "00";
	signal piano_shift,next_piano_shift: unsigned(3 downto 0) := "0000";
	signal disp_piano_shift: std_logic := '0';
begin
	ass: AudioSubSystemStereo port map(CLOCK_50,AUD_XCK,not KEY(0),I2C_SCLK,I2C_SDAT,
		AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT, AUD_DACDAT,
		aoutL,aoutR,ainL,ainR,aclk);
	osc_speed_sw <= unsigned(SW(9 downto 7));
	o: simple_oscilloscope port map(CLOCK_50,aclk,vga,oscIn,
		(10 downto 0=>'0')&(osc_speed_sw*osc_speed_sw*osc_speed_sw));
	
	--audio mixing and volume controls
	ainMono <= (ainL(15)&ainL)+(ainR(15)&ainR);
	vc1: volumeControl port map(ainMono(16 downto 1),ainMonoScaled,SW(3 downto 1));
	vc2: volumeControl port map(pianoAin1,pianoAinScaled,SW(6 downto 4));
	sc: signedClipper generic map(21,16)
		port map(pianoAinScaled
			+(ainMonoScaled(19)&ainMonoScaled),mainAudio0);
	mainAudio <= mainAudio0 when rising_edge(aclk);
	oscIn <= mainAudio;
	aoutL <= mainAudio;
	aoutR <= mainAudio;
	
	--fm radio
	pll: pll_100 port map(CLOCK_50,CLOCK_100);
	pll2: pll_300 port map(CLOCK_50,CLOCK_300);
	fm: fm_modulator port map(CLOCK_300,(2 downto 0=>mainAudio(15))&mainAudio(15 downto 9),fm_intermediate);
	CLOCK_100_1 <= CLOCK_100 and SW(0);
	fm_out <= (fm_intermediate xor CLOCK_100_1) and SW(0);
	SMA_CLKOUT <= fm_out;
	GPIO(35 downto 26) <= (others=>fm_out);
	GPIO(24) <= fm_out;
	GPIO(25) <= not fm_out;
	
	--interpolator
	interp_div <= interp_div+1 when rising_edge(CLOCK_50);
	interp_clk <= interp_div(2);
	aclk1 <= aclk when rising_edge(interp_clk);
	interp_wr_en <= (aclk1 xor aclk) and aclk when rising_edge(interp_clk);
	interp: interpolator256 port map(interp_clk,interp_wr_en,mainAudio&X"00",interp_out);
	
	--DAC
	dacIn <= unsigned(interp_out)+"100000000000000000000000" when rising_edge(aclk);
	dacIn2 <= dacIn when rising_edge(dacClk);
	dacClk <= CLOCK_100;
	dsm: deltaSigmaModulator generic map(11) port map(dacClk,dacIn2&X"00",dacOut);
	GPIO(0) <= dacOut;
	GPIO(1) <= not dacOut;
	GPIO(7) <= dacOut;
	GPIO(3) <= dacOut;
	
	--vga output
	vclk <= vga(27);
	VGA_CLK <= vclk;
	VGA_R <= vga(7 downto 0) when falling_edge(vclk);
	VGA_G <= vga(15 downto 8) when falling_edge(vclk);
	VGA_B <= vga(23 downto 16) when falling_edge(vclk);
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= not vga(24);
	VGA_HS <= not vga(25);
	VGA_VS <= not vga(26);
	
	--keyboard piano
	
	--open drain port for ps/2 keyboard
	PS2_CLK <= 'Z';
	PS2_DAT <= 'Z';
	
	ps2_new_clk <= PS2_CLK when rising_edge(CLOCK_50);
	ps2_state <= ps2_ns when falling_edge(ps2_new_clk);
	ps2_ns <= "0001" when ps2_state="0000" and PS2_DAT='0' else
			"0000" when ps2_state="0000" else
			"0000" when ps2_state="1010" else
			ps2_state+1;
	ps2_should_sample <= '1' when ps2_state="1010" else '0';
	ps2_sr <= PS2_DAT & ps2_sr(8 downto 1) when falling_edge(ps2_new_clk);
	ps2_last_byte <= ps2_sr(7 downto 0);
	ps2_rcv: ps2Receiver port map(not ps2_new_clk,ps2_should_sample,ps2_last_byte,last_key,iskeydown,iskeyup);
	
	p: ps2Piano port map(last_key,"00"&((piano_octave*to_unsigned(12,4))+piano_shift),piano_freq);
	tg: multiToneGenerator port map(not ps2_new_clk,aclk,ps2_should_sample,pianoAin,piano_freq,iskeydown,iskeyup,piano_reset);
	pianoAin1 <= pianoAin when rising_edge(aclk);
	
	--piano config
	piano_shift <= next_piano_shift when ps2_should_sample='1' and iskeydown='1' and falling_edge(ps2_new_clk);
	piano_octave <= next_piano_octave when ps2_should_sample='1' and iskeydown='1' and falling_edge(ps2_new_clk);
	next_piano_shift <= 
		piano_shift+1 when last_key=X"74" and (not (piano_shift=11)) else
		piano_shift-1 when last_key=X"6b" and (not (piano_shift=0)) else
		piano_shift;
	next_piano_octave <=
		piano_octave+1 when last_key=X"75" and (not (piano_octave="11")) else
		piano_octave-1 when last_key=X"72" and (not (piano_octave="00")) else
		piano_octave;
	piano_reset <= '1' when (last_key=X"74" or last_key=X"6b" or last_key=X"75" or last_key=X"72")
		and iskeydown='1' else '0';
	disp_piano_shift <= '1' when piano_reset='1' and ps2_should_sample='1' and falling_edge(ps2_new_clk) else
		'0' when iskeydown='1' and ps2_should_sample='1' and falling_edge(ps2_new_clk);
	
	ps2_last_data <= ps2_last_byte when ps2_should_sample='1' and falling_edge(ps2_new_clk);
	ps2_last_data1 <= ps2_last_data when ps2_should_sample='1' and falling_edge(ps2_new_clk);
	ps2_last_data2 <= ps2_last_data1 when ps2_should_sample='1' and falling_edge(ps2_new_clk);
	
	disp_data(7 downto 0) <= ps2_last_data when disp_piano_shift='0' else (piano_shift / 10)&(piano_shift mod 10);
	disp_data(15 downto 8) <= ps2_last_data1 when disp_piano_shift='0' else "000000"&piano_octave;
	disp_data(23 downto 16) <= ps2_last_data2;
	hd0: hexdisplay port map(disp_data(3 downto 0),HEX0);
	hd1: hexdisplay port map(disp_data(7 downto 4),HEX1);
	hd2: hexdisplay port map(disp_data(11 downto 8),HEX2);
	hd3: hexdisplay port map(disp_data(15 downto 12),HEX3);
	hd4: hexdisplay port map(disp_data(19 downto 16),HEX4,disp_piano_shift);
	hd5: hexdisplay port map(disp_data(23 downto 20),HEX5,disp_piano_shift);
end architecture;
