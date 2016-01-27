library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity simple_altera_pll is
	generic(infreq: string; outfreq: string; fractional: string := "true");
	port(inclk: in std_logic; outclk: out std_logic);
end entity;
architecture a of simple_altera_pll is
	component altera_pll generic(fractional_vco_multiplier,reference_clock_frequency,operation_mode,
		output_clock_frequency0,phase_shift0: string; number_of_clocks,duty_cycle0: integer);
		port(refclk: in std_logic;outclk: out std_logic);
	end component;
begin
	pll: component altera_pll generic map(fractional_vco_multiplier=>fractional,reference_clock_frequency=>infreq,
		operation_mode=>"direct",number_of_clocks=>1,output_clock_frequency0=>outfreq,
		phase_shift0=>"0 ps",duty_cycle0=>50)
		port map(refclk=>inclk,outclk=>outclk);
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity simple_altera_pll2 is
	generic(infreq: string; outfreq1,outfreq2: string; fractional: string := "false");
	port(inclk: in std_logic; outclk1,outclk2: out std_logic);
end entity;
architecture a of simple_altera_pll2 is
	component altera_pll generic(
		fractional_vco_multiplier,reference_clock_frequency,operation_mode: string;
		output_clock_frequency0,phase_shift0: string;
		output_clock_frequency1,phase_shift1: string;
		number_of_clocks,duty_cycle0,duty_cycle1: integer);
		port(refclk: in std_logic;outclk: out std_logic_vector(1 downto 0));
	end component;
	signal outclk: std_logic_vector(1 downto 0);
begin
	pll: component altera_pll generic map(fractional_vco_multiplier=>fractional,reference_clock_frequency=>infreq,
		operation_mode=>"direct",number_of_clocks=>2,
		output_clock_frequency0=>outfreq1, phase_shift0=>"0 ps",duty_cycle0=>50,
		output_clock_frequency1=>outfreq2, phase_shift1=>"0 ps",duty_cycle1=>50)
		port map(refclk=>inclk,outclk=>outclk);
	outclk1 <= outclk(0);
	outclk2 <= outclk(1);
end architecture;
