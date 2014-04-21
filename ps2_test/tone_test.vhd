library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.multiToneGenerator;
use work.deltaSigmaModulator2;
entity tone_test is
	port(CLOCK_50: in std_logic;
		SW: in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(3 downto 0);
		GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0));
end entity;
architecture a of tone_test is
	signal aclk,dacClk: std_logic;
	signal aout,aout1: signed(15 downto 0);
	signal aCounter: unsigned(12 downto 0);
	constant aCounterPeriod: integer := 2000;
	signal dacOut2: unsigned(3 downto 0);
begin
	--clocks
	dac_pll: work.simple_altera_pll generic map("50.0 MHz","88.194444 MHz")
		port map(inclk=>CLOCK_50,outclk=>dacClk);
	aCounter <= to_unsigned(0,13) when aCounter>=aCounterPeriod and rising_edge(dacClk) else
		aCounter+1 when rising_edge(dacClk);
	aclk <= '1' when aCounter<aCounterPeriod/2 and rising_edge(dacClk)
		else '0' when rising_edge(dacClk);
	
	tg: multiToneGenerator port map(not KEY(0),aclk,'1',aout,
		"00"&unsigned(SW(9 downto 1))&"0000000000000",SW(0),not SW(0));
		
	aout1 <= (3 downto 0=>aout(15))&aout(15 downto 4) when rising_edge(aclk);
	--DAC	
	dsm2: deltaSigmaModulator2 generic map(11) port map(dacClk,
		unsigned(aout1)+"1000000000000000",dacOut2);
	GPIO_1(2) <= dacOut2(3);
	GPIO_1(3) <= dacOut2(2);
	GPIO_1(4) <= dacOut2(1);
	GPIO_1(5) <= dacOut2(0);
end architecture;
