library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.ulpi_serial;
use work.clk_wiz_v3_6;
use work.slow_clock;
use work.deltaSigmaModulator;
use work.deltaSigmaModulator3;
use work.usbgpio;

entity top2 is
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
		--usb ulpi
		USB_DIR: in std_logic;
		USB_NXT: in std_logic;
		USB_DATA: inout std_logic_vector(7 downto 0);
		USB_RESET_B: out std_logic;
		USB_STP: out std_logic;
		USB_REFCLK: out std_logic
		);
end top2;

architecture a of top2 is
	--clocks
	signal CLOCK_60,CLOCK_150,CLOCK_200,CLOCK_300: std_logic;
	signal usbclk,dacClk: std_logic;
	
	--usb_serial data interface
	signal rxval,rxrdy,realrxval,txval,txrdy: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal tmp: unsigned(7 downto 0);
	
	--usb serial audio interface
	signal rxdat_indicator: std_logic; --MSB of rxdat
	signal rxdat_lower: signed(6 downto 0); --rest of rxdat
	signal rxphase,rxphaseNext: unsigned(2 downto 0);
	signal adataLatch,adataLatchNext: std_logic;
	signal adata,adataNext,adataResampled,adataResampled1,adataResampled2: signed(47 downto 0);
	
	signal do_rx: std_logic;
	
	signal audio_ds0,audio_ds1: std_logic;
	
	signal gpioout: std_logic_vector(48 downto 0);
	signal gpioin: std_logic_vector(13 downto 0);
begin
	ANALOG <= "000";
	--AUDIO <= "00";
	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_60,
		CLK_OUT2=>CLOCK_300,
		CLK_OUT3=>CLOCK_200,
		CLK_OUT4=>CLOCK_150,
		LOCKED=>open);
	usbclk <= CLOCK_60;
	
	-- usb serial port device
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, rxval,rxrdy,txval,txrdy, rxdat,txdat,
		LED=>LED(0));
	USB_RESET_B <= '1';
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>CLOCK_60, C1=>not CLOCK_60,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);

	
	-- usb_serial data
	-- loopback
--	rxrdy <= '1';
--	txval <= rxval when rising_edge(usbclk);
--	tmp <= unsigned(rxdat);
--	txdat <= std_logic_vector(tmp+1) when rising_edge(usbclk);
	LED(1) <= rxval;
	
	--audio
	--txval <= '0';
	audio_rxen: entity slow_clock generic map(1360,1) port map(usbclk,do_rx);
--	realrxval <= rxrdy and rxval;
--	
--	rxphaseNext <= "000" when rxdat_indicator='0' else
--		rxphase+1;
--	rxphase <= rxphaseNext when realrxval='1' and rising_edge(usbclk);
--	rxdat_indicator <= rxdat(7);
--	rxdat_lower <= signed(rxdat(6 downto 0));
--	adataNext(6 downto 0) <= rxdat_lower when rxphase=0 and realrxval='1' and rising_edge(usbclk);
--	adataNext(13 downto 7) <= rxdat_lower when rxphase=1 and realrxval='1' and rising_edge(usbclk);
--	adataNext(20 downto 14) <= rxdat_lower when rxphase=2 and realrxval='1' and rising_edge(usbclk);
--	adataNext(27 downto 21) <= rxdat_lower when rxphase=3 and realrxval='1' and rising_edge(usbclk);
--	adataNext(34 downto 28) <= rxdat_lower when rxphase=4 and realrxval='1' and rising_edge(usbclk);
--	adataNext(41 downto 35) <= rxdat_lower when rxphase=5 and realrxval='1' and rising_edge(usbclk);
--	adataNext(48 downto 42) <= rxdat_lower when rxphase=6 and realrxval='1' and rising_edge(usbclk);
--	-- no-op during 7th phase
--	adataLatchNext <= '1' when rxphase=6 and realrxval='1' else '0';
--	adataLatch <= adataLatchNext when rising_edge(usbclk);
--	adata <= adataNext when adataLatch='1' and rising_edge(usbclk);
	
	usbg: entity usbgpio generic map(7,2) port map(usbclk,rxval,rxrdy,rxdat,txval,txdat,
		gpioout,gpioin,do_rx,do_rx);
	
	gpioin <= gpioout(13 downto 0);
	
	
	dacClk <= CLOCK_300;
	adataResampled1 <= signed(gpioout(47 downto 0)) when rising_edge(dacClk);
	adataResampled2 <= adataResampled1 when rising_edge(dacClk);
	adataResampled <= adataResampled2 when adataResampled1=adataResampled2 and rising_edge(dacClk);
	
	dsm0: entity deltaSigmaModulator3 port map(dacClk,adataResampled(23 downto 0)&X"00",audio_ds0);
	dsm1: entity deltaSigmaModulator3 port map(dacClk,adataResampled(47 downto 24)&X"00",audio_ds1);
	--dsm: entity deltaSigmaModulator generic map(11) port map(CLOCK_60,unsigned(aout)&X"00",audio_ds);
	GPIOB(0) <= audio_ds0;
	GPIOB(2) <= not audio_ds0;
	AUDIO(0) <= audio_ds0;
	AUDIO(1) <= audio_ds1;
end a;

