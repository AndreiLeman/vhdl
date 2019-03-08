library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

use work.all;
entity top is
    port(
		LED: out std_logic_vector(1 downto 0);
		SW: in std_logic_vector(1 downto 0);
		LVDSCLK_P,LVDSCLK_N: inout std_logic;
		LVDS_P, LVDS_N: inout std_logic_vector(2 downto 0);
		GPIOB: inout std_logic_vector(4 downto 0);
		GPIOR: inout std_logic_vector(8 downto 0);
		ANALOG: out std_logic_vector(2 downto 0);
		AUDIO: out std_logic_vector(1 downto 0);
		CLOCK_25: in std_logic;
		
		CLKGEN_SCL,CLKGEN_SDA: inout std_logic;
		CLKGEN_MOSFET: out std_logic;
		
		ADC: in std_logic_vector(9 downto 0);
		ADC_STBY: out std_logic;
		DAC_R,DAC_G,DAC_B: out unsigned(9 downto 0);
		DAC_PSAVE_N,DAC_BLANK_N,DAC_SYNC_N: out std_logic;
		--usb ulpi
		USB_DIR: in std_logic;
		USB_NXT: in std_logic;
		USB_DATA: inout std_logic_vector(7 downto 0);
		USB_RESET_B: out std_logic;
		USB_STP: out std_logic;
		USB_REFCLK: out std_logic
		);
end top;

architecture a of top is
	--global shared clocks
	signal internalclk,CLOCK_300,CLOCK_60: std_logic;
	
	--global control signals
	signal clkgen_en: std_logic := '0';
	signal reset: std_logic;
	
	--ui
	signal SW_clean: std_logic_vector(1 downto 0);
	signal led_usbserial: std_logic;
	signal led_dim1,led_dim2: std_logic; -- a low duty cycle clock
	signal ebuttons,ebuttonsPrev: std_logic_vector(2 downto 0);
	
	--oscilloscope
	signal lcdclk: std_logic;
	signal lcd_scl,lcd_sdi,lcd_cs,lcd_dc,lcd_rst: std_logic;
	
	--tx buffer space display
	signal bufspc_reset, displayDots: std_logic;
	signal txroom1,bufspc_min,bufspc_minNext: unsigned(15 downto 0);
	
	--7seg display
	signal sseg: std_logic_vector(31 downto 0);
	signal displayInt: unsigned(15 downto 0);
	signal ssegclk,hex_scl,hex_cs,hex_sdi: std_logic;
	
	--usb_serial data interface
	signal usbclk,usbtxval,usbtxrdy: std_logic;
	signal usbtxdat: std_logic_vector(7 downto 0);
	signal usbtxroom: unsigned(13 downto 0);
	signal tmp: unsigned(7 downto 0);
	
	--usb data fifo
	signal rxval,rxrdy,realrxval,txval,txrdy,txclk: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal fifo1empty,fifo1full: std_logic;
	
	--usb GPIO
	signal usbgpio_do_rx: std_logic;
	type gpios_t is array(0 to 15) of std_logic_vector(3 downto 0);
	signal gpioout: gpios_t;
	
	--adc
	signal adcSclk,adcClk,adcFClk: std_logic;
	signal adcRaw: signed(9 downto 0);
	signal adcFiltered: signed(17 downto 0);
	signal adcFailcnt: unsigned(15 downto 0);
	signal adcReduced: signed(7 downto 0);
	
	--i2c
	signal i2c_do_tx,i2cclk: std_logic;
	signal outscl,outsda,outctrl,outscl2,outsda2: std_logic;
	signal realsda1,realscl1,realsda2,realscl2: std_logic;
	
	--spi
	signal adf4350_clk,adf4350_le,adf4350_data: std_logic;
begin
	--=========static outputs=========
	DAC_PSAVE_N <= '1';
	DAC_BLANK_N <= '1';
	DAC_SYNC_N <= '1';
	ANALOG <= "000";
	USB_RESET_B <= '1';
	ADC_STBY <= '0';
	DAC_R <= (others=>'0');
	DAC_G <= (others=>'0');
	DAC_B <= (others=>'0');
	AUDIO <= "00";

	--=============clocks============
	INST_STARTUP: STARTUP_SPARTAN6 port map(
		CFGCLK => open,
		CFGMCLK => internalclk,
		CLK => '0',
		EOS => open,
		GSR => '0',
		GTS => '0',
		KEYCLEARB => '0');
	
	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_300,
		CLK_OUT2=>CLOCK_60);

    -- 250kHz state machine clock => 62.5kHz i2c clock
	i2cc: entity slow_clock generic map(200,100) port map(internalclk,i2cclk);
	-- 50kHz 7-segment spi clock
	ssc: entity slow_clock generic map(1000,500) port map(internalclk,ssegclk);
	
	
	--==============UI==============
	
	--leds
	ledc1: entity slow_clock generic map(5000,500) port map(internalclk,led_dim1);
	ledc2: entity slow_clock generic map(5000,300) port map(internalclk,led_dim2);
	ledp1: entity ledPreprocess port map(led_dim1,not txrdy,LED(1));
	ledp0: entity ledPreprocess port map(led_dim2,led_usbserial,LED(0));
	
	--hex display
	displayDots <= '0';
g:	for I in 0 to 3 generate
		hd: entity hexdisplay_custom port map(displayInt((I+1)*4-1 downto I*4),
			sseg((I+1)*8-1 downto I*8), displayDots);
	end generate;
	s7seg: entity serial7seg2 port map(ssegclk,sseg,ebuttons,
		GPIOB(0),GPIOB(1),GPIOB(2));
	
	displayInt <= adcFailcnt;
	
	--buttons & switches
	ebuttonsPrev <= ebuttons when rising_edge(ssegclk);
	bc: entity debugtool_buttonCleanup generic map(2) port map(i2cclk,SW,SW_clean);
	reset <= ebuttons(0);
	
	clkgen_en <= '1' when reset='1' and rising_edge(internalclk);
	CLKGEN_MOSFET <= not clkgen_en;
	
	--oscilloscope
	-- 18.75MHz lcd clock
	lcdc: entity slow_clock generic map(16,8) port map(CLOCK_300,lcdclk);
	osc: entity spiLCDOscilloscope port map(lcdclk,lcd_scl,lcd_sdi,lcd_cs,
		lcd_dc,lcd_rst, adcClk, adcRaw&"000000",
		stop=>ebuttons(0));

	GPIOR(0) <= lcd_sdi when falling_edge(lcdclk);
	GPIOR(1) <= lcd_dc when falling_edge(lcdclk);
	GPIOR(4) <= lcd_scl;
	GPIOR(3) <= lcd_cs when falling_edge(lcdclk);
	
	
	
	--==========peripherals==========
	
	-- usb serial port device
	usbclk <= CLOCK_60;
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, rxval,rxrdy,usbtxval,usbtxrdy, rxdat,usbtxdat,
		LED=>led_usbserial, txroom=>usbtxroom);
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>usbclk, C1=>not usbclk,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);
	fifo1: entity dcfifo generic map(8,13) port map(usbclk,txclk,
		usbtxval,usbtxrdy,usbtxdat,open,
		txval,txrdy,txdat,open);
	
	bufspc_rstc: entity slow_clock generic map(10000000,1) port map(internalclk,bufspc_reset);
	txroom1 <= resize(usbtxroom,16) when rising_edge(usbclk);
	bufspc_minNext <= X"ffff" when bufspc_reset='1' else
		txroom1 when txroom1<bufspc_min else
		bufspc_min;
	bufspc_min <= bufspc_minNext when rising_edge(usbclk);
	
	-- usb GPIO
	rxrdy <= usbgpio_do_rx;
g2:	for I in 0 to 2 generate
		gpioout(I) <= rxdat(3 downto 0) when rxrdy='1' and rxval='1' and unsigned(rxdat(7 downto 4))=I and rising_edge(usbclk);
	end generate;
	rxen: entity slow_clock generic map(30,1) port map(usbclk,usbgpio_do_rx);
	
	-- adc data
	adcSClk <= CLOCK_300;
	adcP: entity adcPreprocess port map(adcSClk,ADC,adcClk,adcFClk,adcRaw,adcFiltered,adcFailcnt);
	
	adcReduced <= adcFiltered(13 downto 6) when SW_clean(1)='0'
		else adcFiltered(16 downto 9);

	txclk <= adcFClk;
	txval <= '1'; --adc_shifted_valid when rising_edge(adcSclk);
	txdat <= std_logic_vector(adcReduced(7 downto 0)) when rising_edge(adcClk);
	
	
	
	--===========configuration===========
	
	--i2c
	i2c1: entity clkgen_i2c port map(i2cclk,outscl,outsda,outctrl,reset);
	i2c2: entity clkgen_external_i2c port map(i2cclk,outscl2,outsda2,open,reset);
	realscl1 <= outscl when gpioout(1)(0)='0' else gpioout(0)(0);
	realsda1 <= outsda when gpioout(1)(1)='0' else gpioout(0)(1);
	realscl2 <= outscl2 when gpioout(1)(2)='0' else gpioout(0)(2);
	realsda2 <= outsda2 when gpioout(1)(3)='0' else gpioout(0)(3);
	CLKGEN_SCL <= '0' when realscl1='0' else 'Z';
	CLKGEN_SDA <= '0' when realsda1='0' else 'Z';
	GPIOR(7) <= '0' when realscl2='0' else 'Z';
	GPIOR(8) <= '0' when realsda2='0' else 'Z';
	
	
	--external spi pll (adf4350)
	adf4350_clk <= gpioout(2)(0);
	adf4350_le <= gpioout(2)(1);
	adf4350_data <= gpioout(2)(2);
	GPIOR(2) <= adf4350_clk;
	GPIOR(5) <= adf4350_le;
	GPIOR(6) <= adf4350_data;

end architecture;

