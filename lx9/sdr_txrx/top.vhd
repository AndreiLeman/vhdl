----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:41:20 05/14/2016 
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

use work.slow_clock;
use work.clk_wiz_v3_6;
use work.dcfifo;
use work.spidatatx;
use work.ejxGenerator;
use work.sdr_helper;
use work.cic_lpf_2_nd;
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
	--clocks
	signal CLOCK_25b: std_logic;
	signal CLOCK_300,CLOCK_100,CLOCK_60,CLOCK_25_1: std_logic;
	signal usbclk: std_logic;
	
	
	--adc data
	signal adcClk,adcFClk: std_logic;
	signal adcIn: signed(9 downto 0);
	signal adcFilteredReduced: signed(7 downto 0);
	
	--dac data
	signal txBBClk,dacClk,txBBPhase: std_logic;
	signal bbDatI,bbDatQ,bbDatQ0: signed(7 downto 0);
	signal bbDatF1I,bbDatF1Q,bbDatF2I,bbDatF2Q,dacDatI,dacDatQ: signed(12 downto 0);
	signal dacDatUnsignedI,dacDatUnsignedQ: unsigned(9 downto 0);
	
	--usb serial data
	signal rxval,rxrdy,realrxval,rxclk,txval,txrdy,txclk: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal usbtxval,usbtxrdy,usbrxval,usbrxrdy: std_logic;
	signal usbtxdat,usbrxdat: std_logic_vector(7 downto 0);
	
	--usb gpio
	type gpios_t is array(0 to 15) of std_logic_vector(3 downto 0);
	signal gpioout: gpios_t;
	signal usbgpio_do_rx: std_logic;
	
	signal gpior1: std_logic_vector(8 downto 0);
	
	--vna tx data
	signal vna_txdat: std_logic_vector(7 downto 0);
	signal vna_txval: std_logic;
	
	--ui
	signal ssegclk: std_logic;
	signal SW_clean: std_logic_vector(1 downto 0);
	signal ebuttons,ebuttonsPrev: std_logic_vector(2 downto 0);
	
	
	
	--signal generator bias
	signal bias1,bias2: signed(3 downto 0);
	signal iq_amplitude,iq_amplitudeNext: unsigned(6 downto 0) := "1000000";
	
	
begin
	--############# CONSTANT OUTPUTS ##############
	DAC_PSAVE_N <= '1';
	DAC_BLANK_N <= '1';
	DAC_SYNC_N <= '0';
	ANALOG <= "000";
	AUDIO <= "00";
	
	
	--############# CLOCKS ##############

	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_25_1,
		CLK_OUT2=>CLOCK_300,
		CLK_OUT3=>CLOCK_100,
		CLK_OUT4=>CLOCK_60,
		LOCKED=>open);
	usbclk <= CLOCK_60;
	
	
	-- fifos
	fifo1: entity dcfifo generic map(8,13) port map(usbclk,txclk,
		usbtxval,usbtxrdy,usbtxdat,open,
		txval,txrdy,txdat,open);
	fifo2: entity dcfifo generic map(8,13) port map(rxclk,usbclk,
		rxval,rxrdy,rxdat,open,
		usbrxval,usbrxrdy,usbrxdat,open);
	
	-- usb tx data
	txclk <= adcFClk;
	txval <= '1';
	txdat <= std_logic_vector(adcFilteredReduced);


	-- usb gpio
	--rxclk <= usbclk;
	--rxrdy <= usbgpio_do_rx;
--g2:	for I in 0 to 2 generate
		--gpioout(I) <= rxdat(3 downto 0) when rxrdy='1' and rxval='1' and unsigned(rxdat(7 downto 4))=I and rising_edge(usbclk);
	--end generate;
	--rxen: entity slow_clock generic map(30,1) port map(usbclk,usbgpio_do_rx);


	-- usb -> dac data
	sc_bb: entity slow_clock generic map(50,25) port map(CLOCK_300,txBBClk);
	rxclk <= txBBClk;
	rxrdy <= '1';
	
	txBBPhase <= not txBBPhase when rising_edge(txBBClk);
	bbDatI <= signed(rxdat) when txBBPhase='1' and rising_edge(txBBClk);
	bbDatQ0 <= signed(rxdat) when txBBPhase='0' and rising_edge(txBBClk);
	bbDatQ <= bbDatQ0 when txBBPhase='1' and rising_edge(txBBClk);	-- re-align i and q together

	dacClk <= adcClk;

	txfiltI1: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatI,bbDatF1I);
	txfiltI2: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatF1I(12 downto 5),bbDatF2I);
	txfiltI3: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatF2I(12 downto 5),dacDatI);
	txfiltQ1: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatQ,bbDatF1Q);
	txfiltQ2: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatF1Q(12 downto 5),bbDatF2Q);
	txfiltQ3: entity cic_lpf_2_nd generic map(inbits=>8,outbits=>13,stages=>1,bw_div=>25)
		port map(dacClk,bbDatF2Q(12 downto 5),dacDatQ);
	
	
	dacDatUnsignedI <= unsigned(dacDatI(11 downto 2))+"1000000000" when rising_edge(dacClk);
	dacDatUnsignedQ <= unsigned(dacDatQ(11 downto 2))+"1000000000" when rising_edge(dacClk);
	
	
	DAC_R <= dacDatUnsignedI when rising_edge(dacClk);
	DAC_G <= dacDatUnsignedQ when rising_edge(dacClk);
	DAC_B <= (others=>'0'); --fm2&"0";
	
	sdrh: entity sdr_helper port map(
		LED,SW,CLKGEN_SCL,CLKGEN_SDA,CLKGEN_MOSFET,ADC,ADC_STBY,USB_DIR,USB_NXT,USB_DATA,
		USB_RESET_B,USB_STP,USB_REFCLK,GPIOB,gpior1,CLOCK_300,CLOCK_60, open,
		usbtxval,usbtxrdy,usbtxdat,
		usbrxval,usbrxrdy,usbrxdat,

		--adc data
		adcClk,adcIn,
		adcFClk,open,adcFilteredReduced,
		
		--hexdisplay
		ssegclk,
		X"0000",
		"0000",
		SW_clean,
		ebuttons,ebuttonsPrev
	);
	
	GPIOR(2) <= gpioout(2)(0) when gpioout(2)(3)='1' else gpior1(2);
	GPIOR(5) <= gpioout(2)(1) when gpioout(2)(3)='1' else gpior1(5);
	GPIOR(6) <= gpioout(2)(2) when gpioout(2)(3)='1' else gpior1(6);
end a;

