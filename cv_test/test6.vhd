
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.simple_altera_pll;
entity test6 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic);
end entity;

architecture a of test6 is
	signal dacClk,outbit: std_logic;
	signal analogOut: unsigned(7 downto 0);
begin
	pll: simple_altera_pll generic map("50 MHz","50 MHz") port map(CLOCK_50,dacClk);
	outbit <= not outbit when rising_edge(dacClk);
	analogOut <= (others=>outbit);
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= '1';
	VGA_R <= analogOut;
	VGA_G <= analogOut;
	VGA_B <= analogOut;
	VGA_CLK <= dacClk;
end architecture;
