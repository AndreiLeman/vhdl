library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemStereo;
use work.generic_oscilloscope;
use work.graphics_types.all;
use work.signedClipper;
use work.deltaSigmaModulator;
use work.deltaSigmaModulator2;
use work.interpolator256;
use work.mainHPSInterface;
use work.simple_altera_pll;
entity main2 is
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
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0)
			);
end entity;
architecture a of main2 is
	 
	-- # of samples; each sample is 32 bits (16 for left, 16 for right)
	constant audio_bufsize: integer := 65536/4;
	constant audio_bufsize_words: integer := audio_bufsize/2;
	signal mem_raddr: unsigned(12 downto 0);
	signal mem_q: std_logic_vector(63 downto 0);
	signal vclk,aclk,audio_mem_clk: std_logic := '0';
	signal ainL,ainR,aoutL,aoutR,aoutL0,aoutR0,dataL,dataR: signed(15 downto 0);
	signal tmpL,tmpR: signed(26 downto 0);
	signal aout: std_logic_vector(31 downto 0);
	signal irq: std_logic_vector(31 downto 0);
	signal aoutL_abs,aoutR_abs,aout_abs: unsigned(15 downto 0);
	signal cnt1: unsigned(12 downto 0);
	signal audio_regs: std_logic_vector(31 downto 0);
	signal audio_irq,audio_irq1: std_logic;
	signal audio_gain: signed(10 downto 0);
	signal audio_gain1: unsigned(4 downto 0);
	signal osc_in: signed(13 downto 0);
	signal aoutMono0: signed(16 downto 0);
	signal aoutMono: signed(15 downto 0);
	signal dacIn: unsigned(23 downto 0);
	signal audioCClk,dacClk,dacOut: std_logic;
	signal dacOut2: unsigned(3 downto 0);
	signal dram_dqm: std_logic_vector(1 downto 0);
	
	signal aclk1,interp_clk,interp_wr_en: std_logic;
	signal interp_out: signed(24 downto 0);
	signal interp_out1: signed(23 downto 0);
	signal interp_div: unsigned(2 downto 0);

	signal fb_conf: std_logic_vector(127 downto 0);
	signal fb_vga_out: std_logic_vector(59 downto 0);
	signal fb_vga_out1,osc_vga_out: unsigned(27 downto 0);
	signal vga_out,vga_out_1,vga_out_2,vga_out_3: unsigned(27 downto 0);
	signal fb_pos: position;
	signal osc_c: color;
	signal vga_out_c,vga_out_c1: color;
	signal vga_conf: std_logic_vector(128 downto 0);
	
	--gpio
	signal pio0data: std_logic_vector(31 downto 0);
	signal pio2data: std_logic_vector(31 downto 0);
	--jtag
	signal jtag_tdi,jtag_tdo,jtag_tms,jtag_tck: std_logic;
begin
	pll1: simple_altera_pll generic map("50 MHz", "33.868799 MHz") port map(CLOCK_50,dacClk);
	audioCClk <= not audioCClk when rising_edge(dacClk);
	AUD_XCK <= audioCClk;
	
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, --AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	
	tmpL <= dataL*audio_gain when rising_edge(aclk);
	tmpR <= dataR*audio_gain when rising_edge(aclk);
	--aoutL <= signed((2 downto 0=>aout(15))&aout(15 downto 3));
	--aoutR <= signed((2 downto 0=>aout(31))&aout(31 downto 19));
	clL: signedClipper generic map(21,16) port map(tmpL(26 downto 6),aoutL0);
	clR: signedClipper generic map(21,16) port map(tmpR(26 downto 6),aoutR0);
	aoutL <= aoutL0 when rising_edge(aclk);
	aoutR <= aoutR0 when rising_edge(aclk);
	audio_gain1 <= unsigned(SW(4 downto 0));
	audio_gain <= "0"&signed(audio_gain1*audio_gain1);
	--audio_gain <= "00001";

	
	aoutMono0 <= (aoutL(15)&aoutL)+(aoutR(15)&aoutR);
	aoutMono <= aoutMono0(16 downto 1) when rising_edge(aclk);
	
	
	--interpolator
	interp_div <= "000" when interp_div="010" and rising_edge(dacClk) else
		interp_div+1 when rising_edge(dacClk);
	interp_clk <= '1' when interp_div="000" and rising_edge(dacClk) else
		'0' when rising_edge(dacClk);
	aclk1 <= aclk when rising_edge(interp_clk);
	interp_wr_en <= (aclk1 xor aclk) and aclk when rising_edge(interp_clk);
	interp: interpolator256 port map(interp_clk,interp_wr_en,aoutMono&X"00",interp_out);
	
	--DAC
	dacCl: signedClipper generic map(25,24) port map(interp_out,interp_out1);
	dacIn <= unsigned(interp_out1)+"100000000000000000000000" when rising_edge(dacClk);
	dsm: deltaSigmaModulator generic map(11) port map(dacClk,dacIn&X"00",dacOut);
	dsm2: deltaSigmaModulator2 generic map(12) port map(dacClk,dacIn&X"00",dacOut2);
	GPIO_0(2) <= dacOut2(3);
	GPIO_0(3) <= dacOut2(2);
	GPIO_0(4) <= dacOut2(1);
	GPIO_0(5) <= dacOut2(0);
	GPIO_0(1) <= dacOut;
	GPIO_0(7) <= not dacOut;
	GPIO_0(0) <= not dacOut;
	
	
	--volume indicator
	cnt1 <= cnt1+32 when rising_edge(CLOCK_50);
	aoutL_abs <= unsigned(aoutL) when aoutL>0 else unsigned(-aoutL);
	aoutR_abs <= unsigned(aoutR) when aoutR>0 else unsigned(-aoutR);
	aout_abs <= aoutL_abs when aoutL_abs>aoutR_abs and rising_edge(aclk)
		else aoutR_abs when rising_edge(aclk);
	LEDR(0) <= '1' when aout_abs>("000"&cnt1) and rising_edge(CLOCK_50)
		else '0' when rising_edge(CLOCK_50);
	--LEDR <= std_logic_vector(aoutL(15 downto 6)) when aoutL>0 else std_logic_vector(-aoutL(15 downto 6));
	
	cl: signedClipper generic map(17,14) port map((aoutL(15)&aoutL)+(aoutR(15)&aoutR),osc_in);
	o: generic_oscilloscope port map(aclk,fb_vga_out1(27),
		(11 downto 0=>'0')&((unsigned(SW(8 downto 5))*unsigned(SW(8 downto 5)))),
		osc_in(13 downto 0)&"00",unsigned(vga_conf(43 downto 32)),unsigned(vga_conf(59 downto 48)),
		fb_pos,osc_c);
	
	fb_vga_out1 <= unsigned(fb_vga_out(59 downto 32));
	fb_pos <= (unsigned(fb_vga_out(11 downto 0)),unsigned(fb_vga_out(27 downto 16)));
	vclk <= fb_vga_out1(27);
	vga_out_1 <= fb_vga_out1 when rising_edge(vclk);
	vga_out_2 <= vga_out_1 when rising_edge(vclk);
	vga_out_3 <= vga_out_2 when rising_edge(vclk);
	vga_out <= vga_out_3 when rising_edge(vclk);
	
	vga_conf(128) <= '1' when SW(9)='0' else '0';
	
	VGA_CLK <= vclk;
	vga_out_c <= (vga_out_3(7 downto 0),vga_out_3(15 downto 8),vga_out_3(23 downto 16))
		when SW(9)='0' else osc_c;
	vga_out_c1 <= vga_out_c when rising_edge(vclk);
	VGA_R <= vga_out_c1(0) when falling_edge(vclk);
	VGA_G <= vga_out_c1(1) when falling_edge(vclk);
	VGA_B <= vga_out_c1(2) when falling_edge(vclk);
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= not vga_out(24);
	VGA_HS <= not vga_out(25);
	VGA_VS <= not vga_out(26);
	
	--jtag
	jtag_tck <= pio0data(0);
	jtag_tms <= pio0data(1);
	jtag_tdi <= pio0data(2);
	pio2data(0) <= jtag_tdo;
	pio2data(31 downto 1) <= (others=>'0');
	
	GPIO_0(18) <= jtag_tck;
	GPIO_0(19) <= jtag_tms;
	GPIO_0(20) <= jtag_tdi;
	jtag_tdo <= GPIO_0(21);
	
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
			pio0data,pio2data,
			fb_vga_out, vga_conf, vga_conf(127 downto 0),(31 downto 1=>'0'),
			aclk,dataL,dataR,
			std_logic_vector(ainL&ainR&X"00000000"),
			aclk);
end architecture;
