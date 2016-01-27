library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity mainHPSInterface is
	port(CLOCK_50: in std_logic;
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
			
			pio0data: out std_logic_vector(31 downto 0);
			pio2data: in std_logic_vector(31 downto 0);
			
			 fb_vga_out: out std_logic_vector(59 downto 0);
			 vga_conf: in std_logic_vector(128 downto 0);
			 vga_reg_conf: out std_logic_vector(127 downto 0);
			 user_irq: in std_logic_vector(31 downto 1);
			 aclk: in std_logic;
			 adataL,adataR: out signed(15 downto 0);
			 --stream2hps
			 stream2hps_datain: in std_logic_vector(63 downto 0);
			 stream2hps_clk: in std_logic
			);
end entity;
architecture a of mainHPSInterface is
        component main_hps is
        port (
            audio_mem1_address                    : in    std_logic_vector(12 downto 0)  := (others => 'X'); -- address
            audio_mem1_chipselect                 : in    std_logic                      := 'X';             -- chipselect
            audio_mem1_clken                      : in    std_logic                      := 'X';             -- clken
            audio_mem1_write                      : in    std_logic                      := 'X';             -- write
            audio_mem1_readdata                   : out   std_logic_vector(63 downto 0);                     -- readdata
            audio_mem1_writedata                  : in    std_logic_vector(63 downto 0)  := (others => 'X'); -- writedata
            audio_mem1_byteenable                 : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- byteenable
            audio_mem1c_clk                       : in    std_logic                      := 'X';             -- clk
            audio_regs_export                     : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- export
            clk_clk                               : in    std_logic                      := 'X';             -- clk
            fb_vga_export                         : out   std_logic_vector(59 downto 0);                     -- export
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                         -- hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                         -- hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                         -- hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                         -- hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                         -- hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   : inout std_logic                      := 'X';             -- hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    : out   std_logic;                                         -- hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                         -- hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD3
            hps_0_hps_io_hps_io_qspi_inst_IO0     : inout std_logic                      := 'X';             -- hps_io_qspi_inst_IO0
            hps_0_hps_io_hps_io_qspi_inst_IO1     : inout std_logic                      := 'X';             -- hps_io_qspi_inst_IO1
            hps_0_hps_io_hps_io_qspi_inst_IO2     : inout std_logic                      := 'X';             -- hps_io_qspi_inst_IO2
            hps_0_hps_io_hps_io_qspi_inst_IO3     : inout std_logic                      := 'X';             -- hps_io_qspi_inst_IO3
            hps_0_hps_io_hps_io_qspi_inst_SS0     : out   std_logic;                                         -- hps_io_qspi_inst_SS0
            hps_0_hps_io_hps_io_qspi_inst_CLK     : out   std_logic;                                         -- hps_io_qspi_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_CMD     : inout std_logic                      := 'X';             -- hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     : out   std_logic;                                         -- hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D0      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     : out   std_logic;                                         -- hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_NXT
            hps_0_hps_io_hps_io_spim1_inst_CLK    : out   std_logic;                                         -- hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;                                         -- hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   : in    std_logic                      := 'X';             -- hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    : out   std_logic;                                         -- hps_io_spim1_inst_SS0
            hps_0_hps_io_hps_io_uart0_inst_RX     : in    std_logic                      := 'X';             -- hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     : out   std_logic;                                         -- hps_io_uart0_inst_TX
            hps_0_hps_io_hps_io_i2c0_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SDA
            hps_0_hps_io_hps_io_i2c0_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SCL
            hps_0_hps_io_hps_io_i2c1_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SDA
            hps_0_hps_io_hps_io_i2c1_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SCL
            hps_0_hps_io_hps_io_gpio_inst_GPIO09  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO09
            hps_0_hps_io_hps_io_gpio_inst_GPIO35  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO35
            hps_0_hps_io_hps_io_gpio_inst_GPIO40  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO40
            hps_0_hps_io_hps_io_gpio_inst_GPIO41  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO41
            hps_0_hps_io_hps_io_gpio_inst_GPIO48  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO48
            hps_0_hps_io_hps_io_gpio_inst_GPIO53  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO53
            hps_0_hps_io_hps_io_gpio_inst_GPIO54  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO54
            hps_0_hps_io_hps_io_gpio_inst_GPIO61  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO61
            irq0_irq                              : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- irq
            memory_mem_a                          : out   std_logic_vector(14 downto 0);                     -- mem_a
            memory_mem_ba                         : out   std_logic_vector(2 downto 0);                      -- mem_ba
            memory_mem_ck                         : out   std_logic;                                         -- mem_ck
            memory_mem_ck_n                       : out   std_logic;                                         -- mem_ck_n
            memory_mem_cke                        : out   std_logic;                                         -- mem_cke
            memory_mem_cs_n                       : out   std_logic;                                         -- mem_cs_n
            memory_mem_ras_n                      : out   std_logic;                                         -- mem_ras_n
            memory_mem_cas_n                      : out   std_logic;                                         -- mem_cas_n
            memory_mem_we_n                       : out   std_logic;                                         -- mem_we_n
            memory_mem_reset_n                    : out   std_logic;                                         -- mem_reset_n
            memory_mem_dq                         : inout std_logic_vector(31 downto 0)  := (others => 'X'); -- mem_dq
            memory_mem_dqs                        : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                      : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                        : out   std_logic;                                         -- mem_odt
            memory_mem_dm                         : out   std_logic_vector(3 downto 0);                      -- mem_dm
            memory_oct_rzqin                      : in    std_logic                      := 'X';             -- oct_rzqin
            pio_0_export                          : out   std_logic_vector(31 downto 0);                     -- export
            reset_reset_n                         : in    std_logic                      := 'X';             -- reset_n
            stream2hps_0_dataclk_clk              : in    std_logic                      := 'X';             -- clk
            stream2hps_0_datain_export            : in    std_logic_vector(63 downto 0)  := (others => 'X'); -- export
            stream2hps_0_irq_irq                  : out   std_logic;                                         -- irq
            vga_fb_conf_export                    : in    std_logic_vector(128 downto 0) := (others => 'X'); -- export
            vga_fb_reg_conf_export                : out   std_logic_vector(127 downto 0);                    -- export
            pio_2_export                          : in    std_logic_vector(31 downto 0)  := (others => 'X')  -- export
        );
    end component main_hps;
	 
	-- # of samples; each sample is 32 bits (16 for left, 16 for right)
	constant audio_bufsize: integer := 65536/4;
	constant audio_bufsize_words: integer := audio_bufsize/2;
	--signal pio0data: std_logic_vector(31 downto 0);
	signal mem_raddr: unsigned(12 downto 0);
	signal mem_q: std_logic_vector(63 downto 0);
	signal vclk,audio_mem_clk: std_logic := '0';
	signal irq: std_logic_vector(31 downto 0);
	signal cnt1: unsigned(12 downto 0);
	signal audio_regs: std_logic_vector(31 downto 0);
	signal audio_irq,audio_irq1,stream2hps_irq: std_logic;
	signal aclk1: std_logic;
	signal memdata: std_logic_vector(31 downto 0);
begin
	audio_mem_clk <= not audio_mem_clk when falling_edge(aclk);
	mem_raddr <= mem_raddr+1 when rising_edge(audio_mem_clk);
	memdata <= mem_q(31 downto 0) when audio_mem_clk='1' and rising_edge(aclk) 
		else mem_q(63 downto 32) when rising_edge(aclk);
	adataL <= signed(memdata(15 downto 0));
	adataR <= signed(memdata(31 downto 16));
	
	audio_regs(0) <= '1' when mem_raddr>=audio_bufsize_words/2 and rising_edge(aclk)
		else '0' when rising_edge(aclk);
	audio_irq <= '1' when (mem_raddr<audio_bufsize_words/4 or
		(mem_raddr>=audio_bufsize_words/2 and mem_raddr<(audio_bufsize_words/2+audio_bufsize_words/4)))
		and rising_edge(aclk) else '0' when rising_edge(aclk);
	--irqs
	audio_irq1 <= audio_irq when rising_edge(aclk);
	irq(0) <= audio_irq1 when rising_edge(aclk);
	irq(1) <= stream2hps_irq;
	irq(31 downto 2) <= user_irq(31 downto 2);
	
	
	
	hps: component main_hps port map(
		clk_clk                               => CLOCK_50,			--clk.clk
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
						
		hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX    ,     --hps_io_uart0_inst_RX
		hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX    ,     --hps_io_uart0_inst_TX
				
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
		pio_0_export    =>pio0data,
		audio_mem1_address=>std_logic_vector(mem_raddr),
		audio_mem1_chipselect=>'1',
		audio_mem1_clken=>'1',
		audio_mem1_write=>'0',
		audio_mem1_readdata=>mem_q,
		audio_mem1_byteenable=>"11111111",
		audio_mem1c_clk=>audio_mem_clk,
		
		irq0_irq=>irq,
		audio_regs_export=>audio_regs,
		--audio_pll_clk=>dacClk,
		
		--fb_conf_export=>fb_conf,
		fb_vga_export=>fb_vga_out,
		vga_fb_conf_export=>vga_conf,
		vga_fb_reg_conf_export=>vga_reg_conf,
		
		stream2hps_0_dataclk_clk=>stream2hps_clk,
		stream2hps_0_datain_export=>stream2hps_datain,
		stream2hps_0_irq_irq=>stream2hps_irq,
		pio_2_export=>pio2data
	);
end architecture;
