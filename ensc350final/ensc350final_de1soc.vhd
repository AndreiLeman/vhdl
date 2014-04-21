library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.ensc350final;
entity ensc350final_de1soc is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2: inout std_logic;
			
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0));
end entity;
architecture a of ensc350final_de1soc is
begin
	main: ensc350final port map(CLOCK_50,LEDR,KEY,SW,
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,
			AUD_XCK,FPGA_I2C_SCLK,FPGA_I2C_SDAT,AUD_BCLK,
			AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT,AUD_DACDAT,
			PS2_CLK,PS2_DAT,PS2_CLK2,PS2_DAT2,
			VGA_R,VGA_G,VGA_B,
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
			GPIO_1);
end architecture;
