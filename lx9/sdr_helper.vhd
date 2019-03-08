library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

use work.slow_clock;
use work.clk_wiz_v3_6;
use work.hexdisplay_custom;
use work.serial7seg2;
use work.debugtool_buttoncleanup;
use work.clkgen_i2c;
use work.ulpi_serial;
use work.ledpreprocess;
use work.autoSampler;
use work.cic_lpf_2_d;
use work.dcfifo;
use work.spidatatx;

entity sdr_helper is
	port(
		-- physical ports
		LED: out std_logic_vector(1 downto 0);
		SW: in std_logic_vector(1 downto 0);
		CLKGEN_SCL,CLKGEN_SDA: inout std_logic;
		CLKGEN_MOSFET: out std_logic;
		ADC: in std_logic_vector(9 downto 0);
		ADC_STBY: out std_logic;
		USB_DIR: in std_logic;
		USB_NXT: in std_logic;
		USB_DATA: inout std_logic_vector(7 downto 0);
		USB_RESET_B: out std_logic;
		USB_STP: out std_logic;
		USB_REFCLK: out std_logic;
		GPIOB: inout std_logic_vector(4 downto 0);
		GPIOR: inout std_logic_vector(8 downto 0);
		
		-- required inputs
		CLOCK_300,CLOCK_60: in std_logic;
		
		-- ######## optional ports ########
		internalclk: buffer std_logic;
		
		-- usb serial interface, synchronous to CLOCK_60
		usbtxval: in std_logic;
		usbtxrdy: buffer std_logic;
		usbtxdat: in std_logic_vector(7 downto 0);
		
		usbrxval: out std_logic;
		usbrxrdy: in std_logic;
		usbrxdat: out std_logic_vector(7 downto 0);
		
		-- adc data
		adcClk: out std_logic;	-- 75MHz
		adcIn: out signed(9 downto 0);  -- raw adc data, synchronous to adcClk
		adcFClk: out std_logic;	-- 25MHz
		adcFiltered: out signed(17 downto 0);	-- downsampled adc data, synchrounous to adcFClk
		adcFilteredReduced: out signed(7 downto 0);
		
		-- ui
		ssegclk: buffer std_logic := 'X';
		displayInt: in unsigned(15 downto 0) := (others=>'0');
		displayDots: in std_logic_vector(3 downto 0) := (others=>'0');
		SW_clean: out std_logic_vector(1 downto 0) := "XX";
		ebuttons,ebuttonsPrev: buffer std_logic_vector(2 downto 0) := "XX"
	);
end entity;

architecture a of sdr_helper is

	--reset
	signal clkgen_en: std_logic := '0';
	signal usbclk: std_logic;
	signal reset: std_logic;

	--ui
	signal led_usbserial: std_logic;
	signal led_dim1,led_dim2: std_logic; -- a low duty cycle clock
	
	--adc
	signal adcSclk,adcClk0: std_logic;
	signal do_tx_adc,adc_valid0,adc_valid1,adc_valid,adc_shifted_valid: std_logic;
	signal adc_sampled: std_logic_vector(9 downto 0);
	signal adc_shifted,adc_shifted_resynced: signed(9 downto 0);
	signal adc_failcnt: unsigned(15 downto 0);
	signal adc_checksum: std_logic;
	--cic filter (lowpass)
	signal adcFClk0: std_logic;
	signal adcFiltered0: signed(17 downto 0);
	
	--7seg display
	signal sseg: std_logic_vector(31 downto 0);
	signal hex_scl,hex_cs,hex_sdi: std_logic;
	
	--usb_serial data interface
	
	signal txroom: unsigned(13 downto 0);
	signal tmp: unsigned(7 downto 0);
	
	signal fifo1empty,fifo1full: std_logic;
	
	--i2c
	signal i2c_do_tx,i2cclk: std_logic;
	signal outscl,outsda,outctrl,outscl2,outsda2: std_logic;
	signal realsda1,realscl1,realsda2,realscl2: std_logic;
	
	--spi
	signal pll2_R: std_logic_vector(9 downto 0);
	signal pll2_mod: std_logic_vector(11 downto 0);
	signal pll2_N: std_logic_vector(15 downto 0);
	signal pll2_O: std_logic_vector(2 downto 0);
	signal adf4350_clk,adf4350_le,adf4350_data: std_logic;
begin
	
	
	ADC_STBY <= '0';



	--############# CLOCKS ##############
	
	INST_STARTUP: STARTUP_SPARTAN6
        port map(
         CFGCLK => open,
         CFGMCLK => internalclk,
         CLK => '0',
         EOS => open,
         GSR => '0',
         GTS => '0',
         KEYCLEARB => '0');
	-- 250kHz state machine clock => 62.5kHz i2c clock
	i2cc: entity slow_clock generic map(200,100) port map(internalclk,i2cclk);
	-- 50kHz 7-segment spi clock
	ssc: entity slow_clock generic map(1000,500) port map(internalclk,ssegclk);
	usbclk <= CLOCK_60;

	-- reset
	CLKGEN_MOSFET <= not clkgen_en;
	clkgen_en <= '1' when reset='1' and rising_edge(internalclk);
	
	
	
	
	
	--############# usb serial port device ##############
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, usbrxval,usbrxrdy,usbtxval,usbtxrdy, usbrxdat,usbtxdat,
		LED=>led_usbserial, txroom=>txroom);
	USB_RESET_B <= '1';
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>usbclk, C1=>not usbclk,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);
		
	-- adc data
	adcSclk <= CLOCK_300;
	adc_sampler: entity autoSampler generic map(clkdiv=>4, width=>10)
		port map(clk=>adcSclk,datain=>ADC,dataout=>adc_sampled,dataoutvalid=>adc_valid,
			failcnt=>adc_failcnt);

	adc_shifted <= signed(adc_sampled)+"1000000000" when rising_edge(adcSclk);
	adc_shifted_valid <= adc_valid when rising_edge(adcSclk);
	
	--resynchronize adc data to adcClk
	adc_sc: entity slow_clock generic map(4,2) port map(adcSclk,adcClk0,adc_shifted_valid);
	adcClk <= adcClk0;
	adc_shifted_resynced <= adc_shifted when rising_edge(adcClk0);
	adcIn <= adc_shifted_resynced;
	
	--filter adc data
	adc_sc_f: entity slow_clock generic map(12,6) port map(adcSclk,adcFClk0);
	adcFClk <= adcFClk0;
	filt: entity cic_lpf_2_d generic map(inbits=>10,outbits=>18,decimation=>3,stages=>5,bw_div=>1)
		port map(adcClk0,adcFClk0,adc_shifted_resynced,adcFiltered0);
	adcFiltered <= adcFiltered0;
	
	adcFilteredReduced <= adcFiltered0(16 downto 9) when rising_edge(adcFClk0);
	
	--############# UI ##############
	reset <= ebuttons(0);
	
g:	for I in 0 to 3 generate
		hd: entity hexdisplay_custom port map(displayInt((I+1)*4-1 downto I*4),
			sseg((I+1)*8-1 downto I*8), displayDots(I));
	end generate;
	s7seg: entity serial7seg2 port map(ssegclk,sseg,ebuttons,
		GPIOB(0),GPIOB(1),GPIOB(2));
	ebuttonsPrev <= ebuttons when rising_edge(ssegclk);
	bc: entity debugtool_buttonCleanup generic map(2) port map(i2cclk,SW,SW_clean);
	
	--leds
	ledc1: entity slow_clock generic map(5000,500) port map(internalclk,led_dim1);
	ledc2: entity slow_clock generic map(5000,300) port map(internalclk,led_dim2);
	ledp1: entity ledPreprocess port map(led_dim1,not usbtxrdy,LED(1));
	ledp0: entity ledPreprocess port map(led_dim2,led_usbserial,LED(0));
	
	
	
	--i2c
	i2c1: entity clkgen_i2c port map(i2cclk,outscl,outsda,outctrl,reset);
	realscl1 <= outscl;-- when gpioout(1)(0)='0' else gpioout(0)(0);
	realsda1 <= outsda;-- when gpioout(1)(1)='0' else gpioout(0)(1);
	CLKGEN_SCL <= '0' when realscl1='0' else 'Z';
	CLKGEN_SDA <= '0' when realsda1='0' else 'Z';
	
	--spi
	pll2_R <= std_logic_vector(to_unsigned(1,10));
	pll2_mod <= std_logic_vector(to_unsigned(32,12));
	pll2_N <= std_logic_vector(to_unsigned(134,16));
	pll2_O <= "010"; -- output divide by 4
	spi1: entity spiDataTx generic map(words=>6,wordsize=>32) port map(
	--	 XXXXXXXXLLXXXXXXXXXXXXXXXXXXX101
		"00000000010000000000000000000101" &
	--	 XXXXXXXXF              BBBBBBBBVMAAAAROO100
		"000000001" & pll2_O & "11111111000110110100" &
		"00000000000000000000000000000011" &
		"01100100" & pll2_R & "01111101000010" &
		"00001000000000001" & pll2_mod & "001" &
		"0" & pll2_N & "000000000000000",
		i2cclk, reset, adf4350_clk, adf4350_le, adf4350_data);
	--external spi pll (adf4350)
	GPIOR(2) <= adf4350_clk;
	GPIOR(5) <= adf4350_le;
	GPIOR(6) <= adf4350_data;
end architecture;
