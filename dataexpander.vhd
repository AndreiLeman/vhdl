library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;

entity dataExpander is
	generic(inWidth: integer;
			outWidth: integer);
	port(inData: in std_logic_vector(inWidth-1 downto 0);
			inClk: in std_logic;
			outData: out std_logic_vector(outWidth-1 downto 0);
			outClk: out std_logic);
end entity;
architecture a of dataExpander is
	constant EXPANSION_FACTOR: integer := outWidth/inWidth;
	constant EXPANSION_ORDER: integer := integer(ceil(log2(real(EXPANSION_FACTOR))));
	type expanderSR_t is array(0 to EXPANSION_FACTOR-1)
			of std_logic_vector(inWidth-1 downto 0);
	signal expanderSR: expanderSR_t;
	signal expanderOut: std_logic_vector(outWidth-1 downto 0);
	signal expanderClkDiv: std_logic_vector(EXPANSION_ORDER downto 0);
	signal expanderOutClk: std_logic;
begin
	--clock divider
	expanderClkDiv(EXPANSION_ORDER) <= inClk;
gen_expander_div:
	for I in 0 to EXPANSION_ORDER-1 generate
		expanderClkDiv(I) <= not expanderClkDiv(I) when falling_edge(expanderClkDiv(I+1));
	end generate;
	expanderOutClk <= expanderClkDiv(0);
	
	--shift register
	expanderSR(EXPANSION_FACTOR-1) <= inData when rising_edge(inClk);
gen_expander_sr:
	for I in 0 to EXPANSION_FACTOR-2 generate
		expanderSR(I) <= expanderSR(I+1) when rising_edge(inClk);
	end generate;
	
	--sampling register
gen_expander_sampler:
	for I in 0 to EXPANSION_FACTOR-1 generate
		expanderOut((I+1)*inWidth-1 downto I*inWidth) <= expanderSR(I)
			when rising_edge(expanderOutClk);
	end generate;
	
	outData <= expanderOut;
	outClk <= expanderOutClk;
end architecture;
