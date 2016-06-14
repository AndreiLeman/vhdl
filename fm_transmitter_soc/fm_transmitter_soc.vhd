library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.simple_altera_pll;
use work.AudioSubSystemStereo;
use work.volumeControl2;
use work.sineGenerator;
use work.mainHPSInterface;
use work.hexdisplay;
use work.slow_clock;
use work.dsssCode1;

entity fm_transmitter_soc is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HPS_CONV_USB_N,HPS_ENET_INT_N,HPS_ENET_MDIO,
			HPS_GSENSOR_INT, HPS_I2C1_SCLK, HPS_I2C1_SDAT,
			HPS_I2C2_SCLK, HPS_I2C2_SDAT, HPS_I2C_CONTROL,
			HPS_KEY, HPS_LED,HPS_SD_CMD,
			HPS_SPIM_SS: inout std_logic;
			HPS_DDR3_CAS_N,HPS_DDR3_CKE,HPS_DDR3_CK_N,
			HPS_DDR3_CK_P, HPS_DDR3_CS_N, HPS_DDR3_ODT,
			HPS_DDR3_RAS_N, HPS_DDR3_RESET_N, HPS_DDR3_WE_N,
			HPS_ENET_GTX_CLK, HPS_ENET_MDC, HPS_ENET_TX_EN,
			HPS_FLASH_DCLK, HPS_FLASH_NCSO, HPS_SD_CLK,
			HPS_SPIM_CLK, HPS_SPIM_MOSI, HPS_UART_TX,
			HPS_USB_STP: out std_logic;
			HPS_DDR3_RZQ,HPS_ENET_RX_CLK,HPS_ENET_RX_DV,
			HPS_SPIM_MISO,HPS_UART_RX,HPS_USB_CLKOUT,
			HPS_USB_DIR,HPS_USB_NXT: in std_logic;
			HPS_DDR3_DM,HPS_ENET_TX_DATA: out std_logic_vector(3 downto 0);
			HPS_DDR3_DQS_N,HPS_DDR3_DQS_P,HPS_SD_DATA,
			HPS_FLASH_DATA: inout std_logic_vector(3 downto 0);
			HPS_ENET_RX_DATA: in std_logic_vector(3 downto 0);
			HPS_DDR3_ADDR: out std_logic_vector(14 downto 0);
			HPS_DDR3_BA: out std_logic_vector(2 downto 0);
			HPS_DDR3_DQ: inout std_logic_vector(31 downto 0);
			HPS_GPIO: inout std_logic_vector(1 downto 0);
			HPS_USB_DATA: inout std_logic_vector(7 downto 0);
			
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0));
end entity;
architecture a of fm_transmitter_soc is
	signal aclk,audioCClk,dacClk: std_logic;
	signal vga_conf: std_logic_vector(127 downto 0);
	signal fb_vga_out: std_logic_vector(59 downto 0);
	signal hpsAudioL,hpsAudioR: signed(15 downto 0);
	signal useAudioIn: std_logic := '0';	--whether to use the analog audio in instead of the HPS digital audio input
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	
	--unused
	signal pio0data: std_logic_vector(31 downto 0);
	
	--mono
	signal ainSummed,hpsAudioSummed: signed(16 downto 0);
	signal fmAudio: signed(16 downto 0);
	signal fmAudioScaled: signed(23 downto 0);
	
	--fm modulator
	signal fm_enable: std_logic;
	signal CLOCK_300: std_logic;
	signal freq_int,freq_int_d0,freq_int_d1,freq_int_d2: unsigned(6 downto 0);
	signal freq_f: unsigned(3 downto 0);
	signal freq_int1,freq_f1,freq_sum: unsigned(31 downto 0);
	signal base_freq: unsigned(27 downto 0);
	signal fm_freq: unsigned(27 downto 0);
	signal fm1,fm1Next,fm1_src: signed(8 downto 0);
	signal fm2,fm2i: unsigned(8 downto 0);
	signal enc_clk: std_logic;
	
	--dsss (testing; experimental)
	signal dsssClk: std_logic;
	signal dsssAddr: unsigned(9 downto 0);
	signal dsssStream,dsssStream1: std_logic;
	
	--UI
	signal uiClk: std_logic;
	signal lastk3,lastk2,k3,k2: std_logic;
begin
	audiopll: simple_altera_pll generic map("50 MHz", "33.868799 MHz", fractional=>"true") port map(CLOCK_50,dacClk);
	audioCClk <= not audioCClk when rising_edge(dacClk);
	AUD_XCK <= audioCClk;
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, --AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	
	--UI
	uiClk <= not uiClk when rising_edge(CLOCK_50);
	useAudioIn <= not useAudioIn when falling_edge(KEY(1));
	LEDR(0) <= useAudioIn;
	freq_int <= unsigned(SW(9 downto 3));
	lastk3 <= KEY(3) when rising_edge(uiClk);
	lastk2 <= KEY(2) when rising_edge(uiClk);
	k3 <=  (not KEY(3)) and lastk3 when rising_edge(uiClk);
	k2 <= (not KEY(2)) and lastk2 when rising_edge(uiClk);
	freq_f <= freq_f-1 when k3='1' and (not (freq_f=0)) and rising_edge(uiClk) else
		freq_f+1 when k2='1' and (not (freq_f=9)) and rising_edge(uiClk);
	
	freq_int_d2 <= freq_int/100;
	freq_int_d1 <= (freq_int/10) mod 10;
	freq_int_d0 <= freq_int mod 10;
	hd0: hexdisplay port map(freq_f,HEX0);
	hd1: hexdisplay port map(freq_int_d0(3 downto 0),HEX1);
	hd2: hexdisplay port map(freq_int_d1(3 downto 0),HEX2);
	hd3: hexdisplay port map(freq_int_d2(3 downto 0),HEX3);
	HEX4 <= (others=>'1');
	HEX5 <= (others=>'1');
	
	aoutL <= fmAudioScaled(23 downto 8);
	aoutR <= fmAudioScaled(23 downto 8);
	
	--mono
	ainSummed <= (ainL(15)&ainL)+ainR when rising_edge(aclk);
	hpsAudioSummed <= (hpsAudioL(15)&hpsAudioL)+(hpsAudioR(15)&hpsAudioR) when rising_edge(aclk);
	fmAudio <= ainSummed when useAudioIn='1' else hpsAudioSummed;
	vc: volumeControl2 generic map(17,24) port map(aclk,fmAudio,fmAudioScaled,SW(2 downto 0));
	
	--fm modulator
	enc_clk <= aclk;
	pll300: simple_altera_pll generic map("50 MHz","300 MHz", fractional=>"false") port map(CLOCK_50,CLOCK_300);
	freq_int1 <= freq_int*to_unsigned(14316558,25);
	freq_f1 <= freq_f*to_unsigned(1431655,28);
	freq_sum <= freq_int1+freq_f1;
	base_freq <= freq_sum(31 downto 4);
	fm_freq <= base_freq+((5 downto 0=>fmAudioScaled(23))&unsigned(fmAudioScaled(23 downto 2)))
		when rising_edge(enc_clk);
	sg: sineGenerator port map(CLOCK_300,fm_freq,fm1_src);
	
	fm1Next <= fm1_src when fm_enable='1' else "000000000";
	fm1 <= fm1Next when rising_edge(CLOCK_300);
	fm2 <= unsigned(fm1)+"100000000" when rising_edge(CLOCK_300);
	fm2i <= unsigned(-fm1)+"100000000" when rising_edge(CLOCK_300);
	
	--dsss modulator
	dsssc: entity slow_clock generic map(300,150) port map(CLOCK_300,dsssClk);	--1MHz
	dsssAddr <= dsssAddr+1 when rising_edge(dsssClk);
	dsssRom: entity dsssCode1 port map(dsssClk,dsssAddr,dsssStream);
	dsssStream1 <= dsssStream when rising_edge(CLOCK_300);
	
	--signal outputs
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= '1';
	VGA_R <= fm2(8 downto 1) when rising_edge(CLOCK_300);
	--VGA_G <= "00000000";
	VGA_G <= fm2(8 downto 1) when rising_edge(CLOCK_300);
	VGA_B <= fm2(8 downto 1) when rising_edge(CLOCK_300);
	VGA_CLK <= CLOCK_300;
	
	hps: mainHPSInterface port map(CLOCK_50, HPS_CONV_USB_N,HPS_ENET_INT_N,HPS_ENET_MDIO,
			HPS_GSENSOR_INT, HPS_I2C1_SCLK, HPS_I2C1_SDAT, HPS_I2C2_SCLK, HPS_I2C2_SDAT, 
			HPS_I2C_CONTROL, HPS_KEY, HPS_LED,HPS_SD_CMD, HPS_SPIM_SS, HPS_DDR3_CAS_N,
			HPS_DDR3_CKE,HPS_DDR3_CK_N, HPS_DDR3_CK_P, HPS_DDR3_CS_N, HPS_DDR3_ODT,
			HPS_DDR3_RAS_N, HPS_DDR3_RESET_N, HPS_DDR3_WE_N, HPS_ENET_GTX_CLK, HPS_ENET_MDC,
			HPS_ENET_TX_EN, HPS_FLASH_DCLK, HPS_FLASH_NCSO, HPS_SD_CLK, HPS_SPIM_CLK,
			HPS_SPIM_MOSI, HPS_UART_TX, HPS_USB_STP, HPS_DDR3_RZQ,HPS_ENET_RX_CLK,
			HPS_ENET_RX_DV, HPS_SPIM_MISO,HPS_UART_RX,HPS_USB_CLKOUT, HPS_USB_DIR,
			HPS_USB_NXT, HPS_DDR3_DM,HPS_ENET_TX_DATA,HPS_DDR3_DQS_N,HPS_DDR3_DQS_P,
			HPS_SD_DATA, HPS_FLASH_DATA, HPS_ENET_RX_DATA, HPS_DDR3_ADDR, HPS_DDR3_BA,
			HPS_DDR3_DQ, HPS_GPIO, HPS_USB_DATA,
			pio0data,pio0data,
			fb_vga_out, "0"&vga_conf, vga_conf,(31 downto 1=>'0'),
			aclk,hpsAudioL,hpsAudioR,(others=>'0'),'0');
	--hps I/Os
	fm_enable <= dsssStream1 and not useAudioIn;
	GPIO_0(31 downto 0) <= pio0data;
end;
