library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity simple_altera_pll is
	generic(infreq: string; outfreq: string);
	port(inclk: in std_logic; outclk: out std_logic);
end entity;
architecture a of simple_altera_pll is
	component altera_pll generic(fractional_vco_multiplier,reference_clock_frequency,operation_mode,
		output_clock_frequency0,phase_shift0: string; number_of_clocks,duty_cycle0: integer);
		port(refclk: in std_logic;outclk: out std_logic);
	end component;
begin
	pll: component altera_pll generic map(fractional_vco_multiplier=>"false",reference_clock_frequency=>infreq,
		operation_mode=>"direct",number_of_clocks=>1,output_clock_frequency0=>outfreq,
		phase_shift0=>"0 ps",duty_cycle0=>50)
		port map(refclk=>inclk,outclk=>outclk);
end architecture;
