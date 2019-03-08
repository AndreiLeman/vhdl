----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:43:49 06/24/2016 
-- Design Name: 
-- Module Name:    top - a 
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
	--usb device
	signal rxval,rxrdy,realrxval,txval,txrdy,txclk: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal usbclk,usbtxval,usbtxrdy,usbrxval,usbrxrdy: std_logic;
	signal usbtxdat,usbrxdat: std_logic_vector(7 downto 0);
	signal led_usbserial: std_logic;

	--data interface logic
	signal devreg, devregNext: std_logic_vector(6 downto 0);
begin
	-- usb serial port device
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, usbrxval,usbrxrdy,usbtxval,usbtxrdy, usbrxdat,usbtxdat,
		LED=>led_usbserial, txroom=>txroom);
	USB_RESET_B <= '1';
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>usbclk, C1=>not usbclk,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);

	fifo1: entity dcfifo generic map(8,14) port map(usbclk,txclk,
		usbtxval,usbtxrdy,usbtxdat,open,
		txval,txrdy,txdat,open);
	fifo2: entity dcfifo generic map(8,14) port map(rxclk,usbclk,
		txval,txrdy,txdat,open,
		rxval,rxrdy,rxdat,open);

	--LEDs
	LED(0) <= led_usbserial;
end a;

