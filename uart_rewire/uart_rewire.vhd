library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity uart_rewire is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
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
			HPS_SPIM_CLK, HPS_SPIM_MOSI, HPS_USB_STP: out std_logic;
			HPS_DDR3_RZQ,HPS_ENET_RX_CLK,HPS_ENET_RX_DV,
			HPS_SPIM_MISO,HPS_USB_CLKOUT,
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
			
			-- tx is out, rx is in
			HPS_UART_TX, HPS_UART_RX: inout std_logic;
			
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0));
end entity;
architecture a of uart_rewire is
		component hps_rewire_uart is
        port (
            clk_clk                                : in    std_logic                     := 'X';             -- clk
            clk_mainbus_clk                        : in    std_logic                     := 'X';             -- clk
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK  : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0    : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1    : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2    : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3    : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0    : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO    : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC     : out   std_logic;                                        -- hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL  : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL  : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK  : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1    : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2    : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3    : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
            hps_0_hps_io_hps_io_qspi_inst_IO0      : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO0
            hps_0_hps_io_hps_io_qspi_inst_IO1      : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO1
            hps_0_hps_io_hps_io_qspi_inst_IO2      : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO2
            hps_0_hps_io_hps_io_qspi_inst_IO3      : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO3
            hps_0_hps_io_hps_io_qspi_inst_SS0      : out   std_logic;                                        -- hps_io_qspi_inst_SS0
            hps_0_hps_io_hps_io_qspi_inst_CLK      : out   std_logic;                                        -- hps_io_qspi_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_CMD      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0       : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1       : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK      : out   std_logic;                                        -- hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2       : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3       : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D0       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7       : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK      : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP      : out   std_logic;                                        -- hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR      : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT      : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
            hps_0_hps_io_hps_io_spim1_inst_CLK     : out   std_logic;                                        -- hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI    : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO    : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0     : out   std_logic;                                        -- hps_io_spim1_inst_SS0
            hps_0_hps_io_hps_io_i2c0_inst_SDA      : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SDA
            hps_0_hps_io_hps_io_i2c0_inst_SCL      : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SCL
            hps_0_hps_io_hps_io_i2c1_inst_SDA      : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SDA
            hps_0_hps_io_hps_io_i2c1_inst_SCL      : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SCL
            hps_0_hps_io_hps_io_gpio_inst_GPIO09   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO09
            hps_0_hps_io_hps_io_gpio_inst_GPIO35   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO35
            hps_0_hps_io_hps_io_gpio_inst_GPIO40   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO40
            hps_0_hps_io_hps_io_gpio_inst_GPIO41   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO41
            hps_0_hps_io_hps_io_gpio_inst_GPIO48   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO48
            hps_0_hps_io_hps_io_gpio_inst_GPIO53   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO53
            hps_0_hps_io_hps_io_gpio_inst_GPIO54   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO54
            hps_0_hps_io_hps_io_gpio_inst_GPIO61   : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO61
            hps_0_hps_io_hps_io_gpio_inst_LOANIO49 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_LOANIO49
            hps_0_hps_io_hps_io_gpio_inst_LOANIO50 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_LOANIO50
            irq0_irq                               : in    std_logic_vector(31 downto 0) := (others => 'X'); -- irq
            memory_mem_a                           : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                          : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                          : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                        : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                         : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                        : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                       : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                       : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                        : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n                     : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                          : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                         : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                       : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                         : out   std_logic;                                        -- mem_odt
            memory_mem_dm                          : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                       : in    std_logic                     := 'X';             -- oct_rzqin
            reset_reset_n                          : in    std_logic                     := 'X';             -- reset_n
            loan_io_in                             : out   std_logic_vector(66 downto 0);                    -- in
            loan_io_out                            : in    std_logic_vector(66 downto 0) := (others => 'X'); -- out
            loan_io_oe                             : in    std_logic_vector(66 downto 0) := (others => 'X')  -- oe
        );
    end component hps_rewire_uart;
	 signal loan_io_in,loan_io_out,loan_io_oe: std_logic_vector(66 downto 0);
	 
	 signal uart_rxd,uart_txd: std_logic;
begin
	 u0 : component hps_rewire_uart port map(
		clk_clk                               => CLOCK_50,			--clk.clk
		clk_mainbus_clk							  => CLOCK_50,
		reset_reset_n                         => '1',				--reset.reset_n
		memory_mem_a                          => HPS_DDR3_ADDR,    	--memory.mem_a
		memory_mem_ba                         => HPS_DDR3_BA,   	--mem_ba
		memory_mem_ck                         => HPS_DDR3_CK_P,   	--mem_ck
		memory_mem_ck_n                       => HPS_DDR3_CK_N, 	--mem_ck_n
		memory_mem_cke                        => HPS_DDR3_CKE,  	--mem_cke
		memory_mem_cs_n                       => HPS_DDR3_CS_N, 	--mem_cs_n
		memory_mem_ras_n                      => HPS_DDR3_RAS_N,	--mem_ras_n
		memory_mem_cas_n                      => HPS_DDR3_CAS_N,	--mem_cas_n
		memory_mem_we_n                       => HPS_DDR3_WE_N, 	--mem_we_n
		memory_mem_reset_n                    => HPS_DDR3_RESET_N,	--mem_reset_n
		memory_mem_dq                         => HPS_DDR3_DQ,   	--mem_dq
		memory_mem_dqs                        => HPS_DDR3_DQS_P,  	--mem_dqs
		memory_mem_dqs_n                      => HPS_DDR3_DQS_N,	--mem_dqs_n
		memory_mem_odt                        => HPS_DDR3_ODT,  	--mem_odt
		memory_mem_dm                         => HPS_DDR3_DM,   	--mem_dm
		memory_oct_rzqin                      => HPS_DDR3_RZQ,	--oct_rzqin
		hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK, --hps_0_hps_io.hps_io_emac1_inst_TX_CLK
		hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0) ,   --hps_io_emac1_inst_TXD0
		hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1) ,   --hps_io_emac1_inst_TXD1
		hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2) ,   --hps_io_emac1_inst_TXD2
		hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3) ,   --hps_io_emac1_inst_TXD3
		hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0) ,   --hps_io_emac1_inst_RXD0
		hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO ,   --hps_io_emac1_inst_MDIO
		hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC  ,    --hps_io_emac1_inst_MDC
		hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV, --hps_io_emac1_inst_RX_CTL
		hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN, --hps_io_emac1_inst_TX_CTL
		hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK, --hps_io_emac1_inst_RX_CLK
		hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1) ,   --hps_io_emac1_inst_RXD1
		hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2) ,   --hps_io_emac1_inst_RXD2
		hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3) ,   --hps_io_emac1_inst_RXD3
				  
				  
		hps_0_hps_io_hps_io_qspi_inst_IO0     => HPS_FLASH_DATA(0)    ,     --hps_io_qspi_inst_IO0
		hps_0_hps_io_hps_io_qspi_inst_IO1     => HPS_FLASH_DATA(1)    ,     --hps_io_qspi_inst_IO1
		hps_0_hps_io_hps_io_qspi_inst_IO2     => HPS_FLASH_DATA(2)    ,     --hps_io_qspi_inst_IO2
		hps_0_hps_io_hps_io_qspi_inst_IO3     => HPS_FLASH_DATA(3)    ,     --hps_io_qspi_inst_IO3
		hps_0_hps_io_hps_io_qspi_inst_SS0     => HPS_FLASH_NCSO    ,     --hps_io_qspi_inst_SS0
		hps_0_hps_io_hps_io_qspi_inst_CLK     => HPS_FLASH_DCLK    ,     --hps_io_qspi_inst_CLK
				  
		hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD    ,     --hps_io_sdio_inst_CMD
		hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0)     ,      --hps_io_sdio_inst_D0
		hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1)     ,      --hps_io_sdio_inst_D1
		hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK   ,     --hps_io_sdio_inst_CLK
		hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2)     ,      --hps_io_sdio_inst_D2
		hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3)     ,      --hps_io_sdio_inst_D3
						  
		hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0)    ,      --hps_io_usb1_inst_D0
		hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1)    ,      --hps_io_usb1_inst_D1
		hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2)    ,      --hps_io_usb1_inst_D2
		hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3)    ,      --hps_io_usb1_inst_D3
		hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4)    ,      --hps_io_usb1_inst_D4
		hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5)    ,      --hps_io_usb1_inst_D5
		hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6)    ,      --hps_io_usb1_inst_D6
		hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7)    ,      --hps_io_usb1_inst_D7
		hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT    ,     --hps_io_usb1_inst_CLK
		hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP    ,     --hps_io_usb1_inst_STP
		hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR    ,     --hps_io_usb1_inst_DIR
		hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT    ,     --hps_io_usb1_inst_NXT
						  
		hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK  ,    --hps_io_spim1_inst_CLK
		hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI ,   --hps_io_spim1_inst_MOSI
		hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO ,   --hps_io_spim1_inst_MISO
		hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS ,    --hps_io_spim1_inst_SS0
		
		--  !!!!!!!!UART PINS ON HPS REWIRED AS LOANED GPIO!!!!!!!!
		hps_0_hps_io_hps_io_gpio_inst_LOANIO49     => HPS_UART_RX    ,     --hps_io_uart0_inst_RX
		hps_0_hps_io_hps_io_gpio_inst_LOANIO50     => HPS_UART_TX    ,     --hps_io_uart0_inst_TX
				
		hps_0_hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C1_SDAT    ,     --hps_io_i2c0_inst_SDA
		hps_0_hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C1_SCLK    ,     --hps_io_i2c0_inst_SCL
				
		hps_0_hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C2_SDAT    ,     --hps_io_i2c1_inst_SDA
		hps_0_hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C2_SCLK    ,     --hps_io_i2c1_inst_SCL
				  
		hps_0_hps_io_hps_io_gpio_inst_GPIO09  => HPS_CONV_USB_N,  --hps_io_gpio_inst_GPIO09
		hps_0_hps_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,  --hps_io_gpio_inst_GPIO35
		hps_0_hps_io_hps_io_gpio_inst_GPIO40  => HPS_GPIO(0),  --hps_io_gpio_inst_GPIO40
		hps_0_hps_io_hps_io_gpio_inst_GPIO41  => HPS_GPIO(1),  --hps_io_gpio_inst_GPIO41
		hps_0_hps_io_hps_io_gpio_inst_GPIO48  => HPS_I2C_CONTROL,  --hps_io_gpio_inst_GPIO48
		hps_0_hps_io_hps_io_gpio_inst_GPIO53  => HPS_LED,  --hps_io_gpio_inst_GPIO53
		hps_0_hps_io_hps_io_gpio_inst_GPIO54  => HPS_KEY,  --hps_io_gpio_inst_GPIO54
		hps_0_hps_io_hps_io_gpio_inst_GPIO61  => HPS_GSENSOR_INT,  --hps_io_gpio_inst_GPIO61
		
		loan_io_in=>loan_io_in,
		loan_io_out=>loan_io_out,
		loan_io_oe=>loan_io_oe
	);
	loan_io_oe <= (50=>'1', others=>'0');
	loan_io_out <= (others=>uart_txd);
	uart_rxd <= loan_io_in(49);
	
	--fpga gpios
	GPIO_0(26) <= uart_rxd;
	uart_txd <= GPIO_0(27);
	
	--leds
	LEDR(1) <= not uart_rxd;
	LEDR(0) <= not uart_txd;
end architecture;


