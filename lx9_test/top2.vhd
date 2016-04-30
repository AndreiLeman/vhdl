
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.slow_clock;
use work.usbtest;
use work.ulpi_port;
use work.clk_wiz_v3_6;
use work.debugtool_bytedisplay;
use work.debugtool_switchAsButton;
use work.debugtool_buttonCleanup;
use work.ep1_loopback;
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
--		
--		lvdsclk_p,lvdsclk_n: in std_logic;
--		lvdsin_p,lvdsin_n: in std_logic;
--		outclk: out std_logic;
--		outdata: out unsigned(3 downto 0)
		);
end top2;

architecture a of top2 is
	signal SW_clean: std_logic_vector(1 downto 0);
	signal usbclk,internalclk,clock_1hz,clock_1hz_internal: std_logic;
	signal usbrst: std_logic;
	
	--ui
	signal uiclk,button0,hex_scl,hex_cs,hex_sdi: std_logic;
	signal usb_datavalid: std_logic;
	signal cnt1: unsigned(7 downto 0);
	
	--clocks
	signal CLOCK_60,CLOCK_150,CLOCK_200,CLOCK_300: std_logic;
begin
	ANALOG <= "000";
	AUDIO <= "00";
		
	INST_STARTUP: STARTUP_SPARTAN6
        port map(
         CFGCLK => open,
         CFGMCLK => internalclk,
         CLK => '0',
         EOS => open,
         GSR => '0',
         GTS => '0',
         KEYCLEARB => '0');
	sc1: entity slow_clock generic map(50000000,25000000) port map(internalclk,clock_1hz_internal);
	sc2: entity slow_clock generic map(60000000,30000000) port map(CLOCK_60,clock_1hz);
	-- 1kHz
	sc3: entity slow_clock generic map(60000,30000) port map(CLOCK_60,uiclk);
	--LED(0) <= clock_1hz_internal;
	--LED(1) <= clock_1hz;
	--LED(0) <= USB_DIR;
	--LED(1) <= a_ulpi_data_out(0) or a_ulpi_data_out(1) or a_ulpi_data_out(2) or a_ulpi_data_out(3)
	--	or a_ulpi_data_out(4) or a_ulpi_data_out(5) or a_ulpi_data_out(6) or a_ulpi_data_out(7);
	--LED <= PHY_LINESTATE;
	--LED(1) <= USB_DIR;
	
	
	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_60,
		CLK_OUT2=>CLOCK_300,
		CLK_OUT3=>CLOCK_200,
		CLK_OUT4=>CLOCK_150,
		LOCKED=>open);
	
	usbclk <= CLOCK_60;
	
	test: entity ep1_loopback port map(LED(0),USB_DATA,USB_DIR,USB_NXT,
		USB_STP,usbrst,usbclk,usbclk);
	USB_RESET_B <= SW(0);
	
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>CLOCK_60, C1=>not CLOCK_60,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);
		
		
	--debug
	cnt1 <= cnt1+1 when rising_edge(usbclk);
	bc: entity debugtool_buttonCleanup generic map(2) port map(uiclk,SW,SW_clean);
	button1: entity debugtool_switchAsButton port map(SW_clean(1), usbclk, button0);
	bd: entity debugtool_bytedisplay port map(hex_scl,hex_cs,hex_sdi,uiclk,
		button0,usbclk,'1',unsigned(USB_DATA), USB_DIR, USB_NXT, isWriting=>LED(1));
	usb_datavalid <= '0' when USB_DATA="00000000" else '1';
	GPIOB(0) <= hex_scl;
	GPIOB(1) <= hex_cs;
	GPIOB(2) <= hex_sdi;
	GPIOB(3) <= '1';
	GPIOB(4) <= '1';
end a;

