library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.toneGenerator;
entity multiToneGenerator is
	port(ctrlclk,aclk,ctrlclk_en: in std_logic;
			audioOut: out signed(15 downto 0); --unregistered
			--control bus: set freq, and then assert either enable or disable
			--for one clock cycle to enable/disable that frequency
			freq: in unsigned(23 downto 0);
			enable,disable: in std_logic;
			clear: std_logic := '0');
end entity;
architecture a of multiToneGenerator is
	constant n: integer := 8; --max number of simultaneous tones
	type freq_array_t is array(0 to n-1) of unsigned(23 downto 0);
	type audio_array_t is array(0 to n-1) of signed(15 downto 0);
	signal freq_array: freq_array_t;
	signal freq_wr_en,wrselect_chain,indicator,indicator_chain: std_logic_vector(0 to n-1);
	signal audio_array: audio_array_t;
	signal atmp1,atmp2: signed(20 downto 0);
	signal atmp3: signed(29 downto 0);
	constant multiplier: real := (1.0/real(n));
	signal multiplier1: signed(8 downto 0) := 
		"0"&signed(to_unsigned(integer(floor(multiplier*real(integer(2)**8))),8));
	signal enable1: std_logic;
begin
	enable1 <= (not indicator_chain(n-1)) and enable;
gen1:
	for I in 0 to n-1 generate
		indicator(I) <= '1' when freq_array(I)=freq and (not (freq=0)) else '0';
		freq_array(I) <= to_unsigned(0,24) when (clear='1' or (indicator(I)='1'
			and disable='1')) and ctrlclk_en='1' and rising_edge(ctrlclk) else
			freq when freq_wr_en(I)='1' and enable1='1' and ctrlclk_en='1' and rising_edge(ctrlclk);
	end generate;
gen_indicator:
	for I in 1 to n-1 generate
		indicator_chain(I) <= indicator_chain(I-1) or indicator(I);
	end generate;
	indicator_chain(0) <= indicator(0);
gen2: -- OR gate chain
	for I in 1 to n-1 generate
		wrselect_chain(I) <= '1' when wrselect_chain(I-1)='1' or freq_array(I)=0 else '0';
		freq_wr_en(I) <= (not wrselect_chain(I-1)) and wrselect_chain(I);
	end generate;
	wrselect_chain(0) <= '1' when freq_array(0)=0 else '0';
	freq_wr_en(0) <= wrselect_chain(0);
gen3: -- tone generators
	for I in 0 to n-1 generate
		tg: toneGenerator port map(freq_array(I),audio_array(I),aclk);
	end generate;
	
	atmp1 <= ((4 downto 0=>audio_array(0)(15))&audio_array(0))
		+((4 downto 0=>audio_array(1)(15))&audio_array(1)) when rising_edge(aclk);
	atmp2 <= ((4 downto 0=>audio_array(2)(15))&audio_array(2))
		+((4 downto 0=>audio_array(3)(15))&audio_array(3))
		+((4 downto 0=>audio_array(4)(15))&audio_array(4))	when rising_edge(aclk);
	atmp3 <= (atmp1+atmp2)*multiplier1;
	audioOut <= atmp3(24 downto 9);
end architecture;
