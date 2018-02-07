----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:54:24 05/07/2016 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

use work.ulpi_serial;
use work.slow_clock;
use work.dsssCode2Combined;
use work.clkgen_i2c;
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

architecture Behavioral of top is
	--usb_serial data interface
	signal rxval,rxrdy,realrxval,txval,txrdy: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal txroom: unsigned(13 downto 0);
	signal tmp: unsigned(7 downto 0);
	--clocks
	signal CLOCK_60,rfClk,CLOCK_300,CLOCK_225,internalclk: std_logic;
	signal usbclk,dacClk: std_logic;
	--usb gpios
	signal gpioout: std_logic_vector(6 downto 0);
	signal gpioin: std_logic_vector(7 downto 0);
	signal gpiore: std_logic;	--determines whether to sample gpioin and send it
	
	--leds
	signal led_dim,led_usbserial: std_logic;
	
	--i2c
	signal i2c_do_tx,i2cclk: std_logic;
	signal outscl,outsda: std_logic;
	
	-- **temporary add-on: dsss transmitter (code 2)**
	signal dsssClk: std_logic;
	signal dsssAddr: unsigned(13 downto 0);
	signal dsssStream,dsssStream1,dsssModOut: std_logic;
	
	signal rfOut: std_logic;
begin
	--unused pins
	DAC_R <= (others=>'0');
	DAC_G <= (others=>'0');
	DAC_B <= (others=>'0');
	DAC_PSAVE_N <= '0';
	DAC_BLANK_N <= '0';
	DAC_SYNC_N <= '0';
	ANALOG <= "000";
	AUDIO <= "00";
	
	--misc
	CLKGEN_MOSFET <= '0';
	ADC_STBY <= '1';
	
	--internal clock
	INST_STARTUP: STARTUP_SPARTAN6 port map(
		CFGCLK => open,
		CFGMCLK => internalclk,
		CLK => '0',
		EOS => open,
		GSR => '0',
		GTS => '0',
		KEYCLEARB => '0');
	
	--clocks
	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_60,
		CLK_OUT2=>CLOCK_300,
		CLK_OUT3=>CLOCK_225,
		LOCKED=>open);
	pll2: entity clk_wiz_v3_6_2 port map(
		CLK_IN1=>CLOCK_300,
		CLK_OUT1=>rfClk);
	usbclk <= CLOCK_60;
	
	-- 250kHz state machine clock => 62.5kHz i2c clock
	i2cc: entity slow_clock generic map(200,100) port map(internalclk,i2cclk);
	
	--clockgen i2c
	i2c1: entity clkgen_i2c port map(i2cclk,outscl,outsda,open,i2c_do_tx);
	i2c_do_tx <= SW(1);
	CLKGEN_SCL <= '0' when outscl='0' else 'Z';
	CLKGEN_SDA <= '0' when outsda='0' else 'Z';
	
	-- usb serial port device
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, rxval,rxrdy,txval,txrdy, rxdat,txdat,
		LED=>led_usbserial, txroom=>txroom);
	USB_RESET_B <= '1';
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>CLOCK_60, C1=>not CLOCK_60,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);
	
	-- usb gpio
	rxen: entity slow_clock generic map(12,1) port map(usbclk,rxrdy); -- 5MHz rx rate
	realrxval <= rxval and rxrdy;
	gpioout <= rxdat(6 downto 0) when realrxval='1' and rising_edge(usbclk);
	gpiore <= rxdat(7) and realrxval when rising_edge(usbclk);
	txdat <= gpioin;
	txval <= gpiore;
	
	--gpio pins
	gpioin <= "000"&GPIOB(4 downto 0);
	GPIOB(2 downto 0) <= gpioout(2 downto 0);
	
	--leds
	ledc: entity slow_clock generic map(5000,900) port map(internalclk,led_dim);
	LED(0) <= led_usbserial and led_dim;
	LED(1) <= not txrdy;
	
	
	-- **temporary add-on: dsss transmitter (code 2)**
	dsssc: entity slow_clock generic map(256,128) port map(CLOCK_225,dsssClk);	--0.87890625MHz
	dsssAddr <= dsssAddr+1 when rising_edge(dsssClk);
	dsssRom: entity dsssCode2Combined port map(dsssClk,dsssAddr,dsssStream);
	dsssStream1 <= dsssStream when rising_edge(dsssClk);
	dsssModOut <= rfClk and (dsssStream1 xor SW(1));
	rfOut <= dsssModOut when SW(0)='1' else '0';
	
	GPIOR <= (
		0=>rfOut,
		1=>rfOut,
		2=>rfOut,
		4=>not rfOut,
		3=>not rfOut,
		5=>not rfOut,
		others=>'0'
	);
	
end Behavioral;

