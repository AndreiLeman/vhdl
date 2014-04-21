library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.multiToneGenerator;
use work.deltaSigmaModulator2;
use work.ps2Piano;
use work.hexdisplay;
entity piano_test is
	port(CLOCK_50: in std_logic;
		HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2: inout std_logic;
		GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0));
end entity;
architecture a of piano_test is
	component key_fifo IS
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdempty		: OUT STD_LOGIC ;
			wrfull		: OUT STD_LOGIC 
		);
	END component;
	signal aclk,dacClk,keyclk2: std_logic;
	signal aout: signed(15 downto 0);
	signal aout1: unsigned(15 downto 0);
	signal aCounter: unsigned(12 downto 0);
	constant aCounterPeriod: integer := 2000;
	signal dacOut2: unsigned(3 downto 0);
	
	signal state,ns: unsigned(3 downto 0) := "0000";
	signal last_key0: std_logic_vector(7 downto 0);
	signal sr,last_data,last_data1,last_data2: unsigned(8 downto 0);
	signal last_key: unsigned(7 downto 0);
	signal should_sample: std_logic;
	signal freq: unsigned(23 downto 0);
	signal en,dis,fifo_empty1,fifo_empty: std_logic;
begin
	--clocks
	dac_pll: work.simple_altera_pll generic map("50.0 MHz","88.194444 MHz")
		port map(inclk=>CLOCK_50,outclk=>dacClk);
	key_pll: work.simple_altera_pll generic map("50.0 MHz","1 MHz")
		port map(inclk=>CLOCK_50,outclk=>keyclk2);
	aCounter <= to_unsigned(0,13) when aCounter>=aCounterPeriod and rising_edge(dacClk) else
		aCounter+1 when rising_edge(dacClk);
	aclk <= '1' when aCounter<aCounterPeriod/2 and rising_edge(dacClk)
		else '0' when rising_edge(dacClk);
		
	--open drain port
	PS2_CLK <= 'Z';
	PS2_DAT <= 'Z';
	state <= ns when falling_edge(PS2_CLK);
	ns <= "0001" when state="0000" and PS2_DAT='0' else
			"0000" when state="0000" else
			"0000" when state="1010" else
			state+1;
	should_sample <= '1' when state="1010" else '0';
	
	--deserializer shift register
	sr <= PS2_DAT & sr(8 downto 1) when falling_edge(PS2_CLK);
	
	--fifo: key_fifo port map(std_logic_vector(sr(7 downto 0)),
	--	keyclk2,'1',not PS2_CLK,should_sample,last_key0,fifo_empty);
	--fifo_empty1 <= fifo_empty when rising_edge(keyclk2);
	last_key <= sr(7 downto 0);
	
	p: ps2Piano port map(not PS2_CLK,should_sample,last_key,freq,en,dis);
	tg: multiToneGenerator port map(not PS2_CLK,aclk,should_sample,aout,freq,en,dis);

	aout1 <= unsigned((1 downto 0=>aout(15))&aout(15 downto 2))+"1000000000000000"
		when rising_edge(aclk);
	--DAC	
	dsm2: deltaSigmaModulator2 generic map(11) port map(dacClk,
		unsigned(aout1),dacOut2);
	GPIO_1(2) <= dacOut2(3);
	GPIO_1(3) <= dacOut2(2);
	GPIO_1(4) <= dacOut2(1);
	GPIO_1(5) <= dacOut2(0);
	
	
	last_data <= sr when should_sample='1' and falling_edge(PS2_CLK);
	last_data1 <= last_data when should_sample='1' and falling_edge(PS2_CLK);
	last_data2 <= last_data1 when should_sample='1' and falling_edge(PS2_CLK);
	hd0: hexdisplay port map(last_data(3 downto 0),HEX0);
	hd1: hexdisplay port map(last_data(7 downto 4),HEX1);
	hd2: hexdisplay port map(last_data1(3 downto 0),HEX2);
	hd3: hexdisplay port map(last_data1(7 downto 4),HEX3);
	hd4: hexdisplay port map(last_data2(3 downto 0),HEX4);
	hd5: hexdisplay port map(last_data2(7 downto 4),HEX5);
end architecture;
