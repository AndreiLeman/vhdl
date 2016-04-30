----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:23:57 03/18/2016 
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
end top;

architecture a of top is
	signal SW_clean: std_logic_vector(1 downto 0);
	signal lvdsclk_true,lvdsclk_comp,lvdsin,serdesclk1,serdesclk2,
		bufio_divclk,divclk,serdesstrobe: std_logic;
	signal lvdsin_parallel: unsigned(3 downto 0);
	signal usbclk,internalclk,clock_1hz,clock_1hz_internal: std_logic;
	
	--ui
	signal uiclk,button0,hex_scl,hex_cs,hex_sdi: std_logic;
	signal usb_datavalid: std_logic;
	signal cnt1: unsigned(7 downto 0);
	
	--clocks
	signal CLOCK_60,CLOCK_150,CLOCK_200,CLOCK_300: std_logic;
	
	--utmi adaptor intermediate signals
	signal 	PHY_DATABUS16_8 : std_logic;
	signal PHY_RESET :       std_logic;
	signal PHY_XCVRSELECT :  std_logic;
	signal PHY_TERMSELECT :  std_logic;
	signal PHY_OPMODE :      std_logic_vector(1 downto 0);
	signal PHY_LINESTATE :    std_logic_vector(1 downto 0);
	signal PHY_CLKOUT :       std_logic;
	signal PHY_TXVALID :     std_logic;
	signal PHY_TXREADY : std_logic;
	signal PHY_RXVALID :       std_logic;
	signal PHY_RXACTIVE :      std_logic;
	signal PHY_RXERROR :     std_logic;
	signal PHY_DATAIN :        std_logic_vector(7 downto 0);
	signal PHY_DATAOUT :     std_logic_vector(7 downto 0);
	signal a_ulpi_data_in,a_ulpi_data_out,a_ulpi_data_out1: std_logic_vector(7 downto 0);
	signal a_ulpi_dir,a_ulpi_nxt,a_ulpi_stp,
		a_ulpi_reset,a_ulpi_clk60: std_logic;
	signal ulpi_dir1: std_logic;
begin
	ANALOG <= "000";
	AUDIO <= "00";
--	buf1: IBUFGDS_DIFF_OUT port map(I=>lvdsclk_p, IB=>lvdsclk_n,
--		O=>lvdsclk_true,OB=>lvdsclk_comp);
--	buf2: IBUFDS port map(I=>lvdsin_p, IB=>lvdsin_n, O=>lvdsin);
--	
--	bufio_1: BUFIO2_2CLK generic map(DIVIDE=>4) port map(I=>lvdsclk_true,IB=>lvdsclk_comp,IOCLK=>serdesclk1,
--		DIVCLK=>bufio_divclk,SERDESSTROBE=>serdesstrobe);
--	bufio_2: BUFIO2 generic map(I_INVERT=>true) port map(I=>lvdsclk_true,IOCLK=>serdesclk2);
--	bufg_1: BUFG port map(I=>bufio_divclk,O=>divclk);
--	
--	
--	serdes: ISERDES2 generic map
--		(DATA_RATE=>"DDR", DATA_WIDTH=>4, BITSLIP_ENABLE=>false)
--		port map(CLK0=>serdesclk1,CLK1=>serdesclk2,CLKDIV=>divclk,CE0=>'1',
--		D=>lvdsin,IOCE=>serdesstrobe,SHIFTIN=>'0',Q1=>lvdsin_parallel(0),
--		Q2=>lvdsin_parallel(1),Q3=>lvdsin_parallel(2),Q4=>lvdsin_parallel(3));
--	--outclk <= bufio_divclk;
--	outdata <= lvdsin_parallel;
	
	--outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
	--	port map(C0=>divclk, C1=>not divclk,CE=>'1',D0=>'1',D1=>'0',Q=>outclk);
		
		
		
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
	LED(1) <= USB_DIR;
	
	
	pll: entity clk_wiz_v3_6 port map(
		CLK_IN1=>CLOCK_25,
		CLK_OUT1=>CLOCK_60,
		CLK_OUT2=>CLOCK_300,
		CLK_OUT3=>CLOCK_200,
		CLK_OUT4=>CLOCK_150,
		LOCKED=>open);
	
	usbt: entity usbtest port map(LED(0),
			PHY_DATABUS16_8, PHY_RESET, PHY_XCVRSELECT, PHY_TERMSELECT,
			PHY_OPMODE, PHY_LINESTATE, PHY_CLKOUT, PHY_TXVALID, PHY_TXREADY,
			PHY_RXVALID, PHY_RXACTIVE, PHY_RXERROR, PHY_DATAIN, PHY_DATAOUT);
	adaptor: entity ulpi_port port map(a_ulpi_data_in,a_ulpi_data_out,a_ulpi_dir,
		a_ulpi_nxt,a_ulpi_stp,a_ulpi_reset,a_ulpi_clk60,
		
		PHY_RESET,PHY_XCVRSELECT,PHY_TERMSELECT,PHY_OPMODE,PHY_LINESTATE,PHY_CLKOUT,
		PHY_TXVALID, PHY_TXREADY,PHY_RXVALID, PHY_RXACTIVE, PHY_RXERROR,'0','0',
		PHY_DATAIN,PHY_DATAOUT);
		
	--PHY_TERMSELECT <= SW_clean(0);
	--PHY_OPMODE <= "01" when SW_clean(0)='0' else "00";
	a_ulpi_data_out1 <= a_ulpi_data_out; -- when falling_edge(usbclk);
	
	usbclk <= CLOCK_60;
	ulpi_dir1 <= USB_DIR when rising_edge(CLOCK_60);
	a_ulpi_data_in <= USB_DATA when USB_DIR='1' else "00000000";
	USB_DATA <= a_ulpi_data_out1 when USB_DIR='0' else "ZZZZZZZZ";
	a_ulpi_dir <= USB_DIR;
	a_ulpi_nxt <= USB_NXT;
	USB_STP <= a_ulpi_stp;
	USB_RESET_B <= SW(0);
	a_ulpi_clk60 <= CLOCK_60;
	--USB_REFCLK <= CLOCK_60;
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>CLOCK_60, C1=>not CLOCK_60,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);
		
		
	--debug
	cnt1 <= cnt1+1 when rising_edge(usbclk);
	bc: entity debugtool_buttonCleanup generic map(2) port map(uiclk,SW,SW_clean);
	button1: entity debugtool_switchAsButton port map(SW_clean(1), usbclk, button0);
	bd: entity debugtool_bytedisplay port map(hex_scl,hex_cs,hex_sdi,uiclk,
		button0,usbclk,'1',unsigned(USB_DATA), USB_DIR, USB_NXT);
	usb_datavalid <= '0' when USB_DATA="00000000" else '1';
	GPIOB(0) <= hex_scl;
	GPIOB(1) <= hex_cs;
	GPIOB(2) <= hex_sdi;
	GPIOB(3) <= '1';
	GPIOB(4) <= '1';
end a;

