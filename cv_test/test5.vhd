library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.simple_altera_pll;
use work.AudioSubSystemStereo;
use work.deltaSigmaModulator;
use work.deltaSigmaModulator3;
use work.deltaSigmaModulator4;
use work.volumeControl;
use work.signedClipper;
use work.osc;
use work.base10_display;
use work.hexdisplay;
use work.slow_clock;
entity test5 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic);
end entity;

architecture a of test5 is
	signal CLOCK_300,CLOCK_200,dacClk,led_out,tmpclk,tmpclk0,aclk,ain_m,ain_m4: std_logic;
	signal ainL,ainR,aoutL,aoutR,ain_scaled,ain_scaled_1: signed(15 downto 0);
	signal ain: signed(16 downto 0);
	signal ain_scaled1: signed(19 downto 0);
	signal ain_u: unsigned(16 downto 0);
	signal osc_speed_sw: unsigned(2 downto 0);
	signal samples_per_px,samples_per_px1: unsigned(19 downto 0);
	signal countedClk,div1,CLOCK_5Hz: std_logic;
	signal cnt,a1,a2,b1,b2,freq: unsigned(25 downto 0);
	signal display: unsigned(31 downto 0);
begin
	--pll: simple_altera_pll generic map("50 MHz","200 MHz") port map(CLOCK_50,CLOCK_200);
	pll2: simple_altera_pll generic map("50 MHz","200 MHz") port map(CLOCK_50,dacClk);
	--pll3: simple_altera_pll generic map("50 MHz","300 MHz") port map(CLOCK_50,CLOCK_300);
	sclk1: slow_clock generic map(10000000,5000000) port map(CLOCK_50,CLOCK_5Hz);
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	ain <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	vc: volumeControl port map(ain(16 downto 1),ain_scaled1,SW(2 downto 0));
	sc: signedClipper generic map(20,16) port map(ain_scaled1,ain_scaled);
	--ain_u <= unsigned(ain)+"10000000000000000" when rising_edge(aclk);
	--dsm: deltaSigmaModulator port map(dacClk,ain_u&(14 downto 0=>'0'),ain_m);
	ain_scaled_1 <= ain_scaled when rising_edge(aclk);
	dsm: deltaSigmaModulator3 port map(dacClk,ain_scaled_1&(15 downto 0=>'0'),ain_m);
	dsm4: deltaSigmaModulator4 port map(dacClk,ain_scaled_1&(15 downto 0=>'0'),ain_m4,signed("0000"&SW(5 downto 3)&"1"&(23 downto 0=>'0')));
	GPIO_1(0) <= ain_m;
	GPIO_1(1) <= not ain_m;
	GPIO_1(2) <= ain_m;
	GPIO_1(3) <= not ain_m;
	GPIO_1(4) <= SW(0);
	GPIO_1(5) <= SW(1);
	GPIO_1(34) <= ain_m4;
	GPIO_1(35) <= not ain_m4;
	
	--frequency counter
	countedClk <= ain_m4 when KEY(3)='1' else ain_m;
	div1 <= not div1 when rising_edge(countedClk);
	cnt <= cnt+1 when rising_edge(div1);
	a1 <= cnt when rising_edge(CLOCK_5Hz);
	a2 <= a1 when rising_edge(CLOCK_5Hz);
	freq <= a1-a2;
	disp: base10_display generic map(26,8) port map(freq,display);
	hd0: hexdisplay port map(display(11 downto 8),HEX0);
	hd1: hexdisplay port map(display(15 downto 12),HEX1);
	hd2: hexdisplay port map(display(19 downto 16),HEX2);
	hd3: hexdisplay port map(display(23 downto 20),HEX3);
	hd4: hexdisplay port map(display(27 downto 24),HEX4);
	hd5: hexdisplay port map(display(31 downto 28),HEX5);
	
	
gen1:
	for I in 0 to 15 generate
		samples_per_px1(I) <= '1' when unsigned(SW(9 downto 6))=to_unsigned(I,4) else '0';
	end generate;
	samples_per_px <= samples_per_px1 when KEY(3)='1' else (others=>'0');
	o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,ain_scaled,
		samples_per_px,CLOCK_50,aclk);
end architecture;
