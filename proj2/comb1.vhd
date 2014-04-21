library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.adc_test;
use work.hps_test2;
entity comb1 is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HPS_CONV_USB_N,HPS_ENET_INT_N,HPS_ENET_MDIO,
			HPS_GSENSOR_INT, HPS_I2C1_SCLK, HPS_I2C1_SDAT,
			HPS_I2C2_SCLK, HPS_I2C2_SDAT, HPS_I2C_CONTROL,
			HPS_KEY, HPS_LED,HPS_SD_CMD,
			HPS_SPIM_SS: inout std_logic;
			HPS_DDR3_CAS_N,HPS_DDR3_CKE,HPS_DDR3_CK_N,
			HPS_DDR3_CK_P, HPS_DDR3_CS_N, HPS_DDR3_ODT,
			HPS_DDR3_RAS_N, HPS_DDR3_RESET_N, HPS_DDR3_WE_N,
			HPS_ENET_GTX_CLK, HPS_ENET_MDC, HPS_ENET_TX_EN,
			HPS_FLASH_DCLK, HPS_FLASH_NCSO, HPS_SD_CLK,
			HPS_SPIM_CLK, HPS_SPIM_MOSI, HPS_UART_TX,
			HPS_USB_STP: out std_logic;
			HPS_DDR3_RZQ,HPS_ENET_RX_CLK,HPS_ENET_RX_DV,
			HPS_SPIM_MISO,HPS_UART_RX,HPS_USB_CLKOUT,
			HPS_USB_DIR,HPS_USB_NXT: in std_logic;
			HPS_DDR3_DM,HPS_ENET_TX_DATA: out std_logic_vector(3 downto 0);
			HPS_DDR3_DQS_N,HPS_DDR3_DQS_P,HPS_SD_DATA,
			HPS_FLASH_DATA: inout std_logic_vector(3 downto 0);
			HPS_ENET_RX_DATA: in std_logic_vector(3 downto 0);
			HPS_DDR3_ADDR: out std_logic_vector(14 downto 0);
			HPS_DDR3_BA: out std_logic_vector(2 downto 0);
			HPS_DDR3_DQ: inout std_logic_vector(31 downto 0);
			HPS_GPIO: inout std_logic_vector(1 downto 0);
			HPS_USB_DATA: inout std_logic_vector(7 downto 0);
			GPIO_0,GPIO_1: inout std_logic_vector(5 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			KEY: in std_logic_vector(3 downto 0);
			ADC_SCLK,ADC_DIN,ADC_CS_N: out std_logic;
			ADC_DOUT: in std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT,AUD_XCK: out std_logic);
end entity;
architecture a of comb1 is
begin
	a1: hps_test2 port map(CLOCK_50,
			LEDR(1 downto 0),
			SW(4 downto 0),
			HPS_CONV_USB_N,HPS_ENET_INT_N,HPS_ENET_MDIO,
			HPS_GSENSOR_INT, HPS_I2C1_SCLK, HPS_I2C1_SDAT,
			HPS_I2C2_SCLK, HPS_I2C2_SDAT, HPS_I2C_CONTROL,
			HPS_KEY, HPS_LED,HPS_SD_CMD,
			HPS_SPIM_SS,
			HPS_DDR3_CAS_N,HPS_DDR3_CKE,HPS_DDR3_CK_N,
			HPS_DDR3_CK_P, HPS_DDR3_CS_N, HPS_DDR3_ODT,
			HPS_DDR3_RAS_N, HPS_DDR3_RESET_N, HPS_DDR3_WE_N,
			HPS_ENET_GTX_CLK, HPS_ENET_MDC, HPS_ENET_TX_EN,
			HPS_FLASH_DCLK, HPS_FLASH_NCSO, HPS_SD_CLK,
			HPS_SPIM_CLK, HPS_SPIM_MOSI, HPS_UART_TX,
			HPS_USB_STP,
			HPS_DDR3_RZQ,HPS_ENET_RX_CLK,HPS_ENET_RX_DV,
			HPS_SPIM_MISO,HPS_UART_RX,HPS_USB_CLKOUT,
			HPS_USB_DIR,HPS_USB_NXT,
			HPS_DDR3_DM,HPS_ENET_TX_DATA,
			HPS_DDR3_DQS_N,HPS_DDR3_DQS_P,HPS_SD_DATA,
			HPS_FLASH_DATA,
			HPS_ENET_RX_DATA,
			HPS_DDR3_ADDR,
			HPS_DDR3_BA,
			HPS_DDR3_DQ,
			HPS_GPIO,
			HPS_USB_DATA,
			GPIO_0(5 downto 0),GPIO_1(5 downto 0));
	a2: adc_test port map(VGA_R,VGA_G,VGA_B,
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
			SW(7 downto 5),
			KEY(0 downto 0),
			ADC_SCLK,ADC_DIN,ADC_CS_N,
			ADC_DOUT,
			FPGA_I2C_SCLK,
			FPGA_I2C_SDAT,
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT,
			AUD_DACDAT,AUD_XCK,
			
			GPIO_0,GPIO_1,
			CLOCK_50);
end architecture;
