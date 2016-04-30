----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:16:35 04/29/2016 
-- Design Name: 
-- Module Name:    usbgpio - a 
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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
entity usbgpio is
	generic(outwords,inwords: integer := 1	-- # of 7 bit words
		);
	Port ( clk : in  STD_LOGIC;
		  rxval : in  STD_LOGIC;
		  rxrdy : out std_logic;
		  rxdat : in  STD_LOGIC_VECTOR (7 downto 0);
		  txval : out  STD_LOGIC;
		  txdat : out  STD_LOGIC_VECTOR (7 downto 0);
		  gpioout : out  STD_LOGIC_VECTOR (outwords*7-1 downto 0);
		  gpioin : in  STD_LOGIC_VECTOR (inwords*7-1 downto 0);
		  
		  -- on the rising edge of clk, if do_send_input is 1, 
		  -- the pipeline will start sending words from gpioin
		  do_send_input: in std_logic;
		  -- whenever a complete bitset is received, if do_advance_output=0,
		  -- the pipeline will be paused and rxrdy deasserted until do_advance_output=1
		  do_advance_output: in std_logic := '1');
end usbgpio;

architecture a of usbgpio is
	constant inb: integer := integer(ceil(log2(real(inwords))));
	constant outb: integer := integer(ceil(log2(real(outwords))));
	
	-- gpio output (usb rx)
	signal should_do_rx,do_rx: std_logic;
	signal rxphase,rxphaseNext: unsigned(outb-1 downto 0);
	signal rxdat_indicator: std_logic; --MSB of rxdat
	signal rxdat_lower: std_logic_vector(6 downto 0); --rest of rxdat
	signal dataout,dataoutNext: std_logic_vector(outwords*7-1 downto 0);
	signal dataoutLatch,dataoutLatchNext: std_logic;
	
	-- gpio input (usb tx)
	signal txphase,txphaseNext: unsigned(inb-1 downto 0);
	signal datain: std_logic_vector(inwords*7-1 downto 0);
	type datain_grouped_t is array(inwords-1 downto 0) of std_logic_vector(6 downto 0);
	signal datain_grouped: datain_grouped_t;
	signal txvalNext: std_logic;
	signal txdatNext: std_logic_vector(7 downto 0);
begin
	rxphaseNext <= to_unsigned(1,outb) when rxdat_indicator='0' else
		to_unsigned(0,outb) when rxphase=(outwords-1) else
		rxphase+1;
	rxphase <= rxphaseNext when do_rx='1' and rising_edge(clk);
	
	should_do_rx <= '1' when do_advance_output='1' or rxphase/=0 else '0';
	rxrdy <= should_do_rx;
	do_rx <= should_do_rx and rxval;
	
	rxdat_indicator <= rxdat(7);
	rxdat_lower <= rxdat(6 downto 0);
gen:
	for I in 0 to outwords-1 generate
		dataoutNext((I+1)*7-1 downto I*7) <= rxdat_lower when rxphase=I and do_rx='1' and rising_edge(clk);
	end generate;
	dataout <= dataoutNext when rxphase=0 and do_advance_output='1' and rising_edge(clk);
	gpioout <= dataout;
	
	
	txphaseNext <= to_unsigned(0,inb) when txphase=0 and do_send_input='0'
		else to_unsigned(0,inb) when txphase=(inwords-1)
		else txphase+1;
	txphase <= txphaseNext when rising_edge(clk);
	datain <= gpioin;
gen2:
	for I in 0 to inwords-1 generate
		datain_grouped(I) <= datain((I+1)*7-1 downto I*7);
	end generate;
	txdatNext(6 downto 0) <= datain_grouped(to_integer(txphase));
	txdatNext(7) <= '0' when txphase=0 else '1';
	txdat <= txdatNext when rising_edge(clk);
	txvalNext <= '1' when do_send_input='1' or txphase/=0 else '0';
	txval <= txvalNext when rising_edge(clk);
	
end a;

