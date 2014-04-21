library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemStereo;
use work.osc;
use work.de1_hexdisplay;
use work.vga_out;
use work.signedClipper;
use work.deltaSigmaModulator;
use work.deltaSigmaModulator2;
entity hps_test2 is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(1 downto 0);
			SW: in std_logic_vector(4 downto 0);
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
			
			GPIO_0,GPIO_1: inout std_logic_vector(5 downto 0)
		);
end entity;
architecture a of hps_test2 is
    component hps2 is
        port (
            clk_clk                               : in    std_logic                     := 'X';             -- clk
            reset_reset_n                         : in    std_logic                     := 'X';             -- reset_n
            memory_mem_a                          : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                         : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                         : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                       : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                        : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                       : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                      : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                      : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                       : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n                    : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                         : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                        : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                      : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                        : out   std_logic;                                        -- mem_odt
            memory_mem_dm                         : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                      : in    std_logic                     := 'X';             -- oct_rzqin
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    : out   std_logic;                                        -- hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
            hps_0_hps_io_hps_io_qspi_inst_IO0     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO0
            hps_0_hps_io_hps_io_qspi_inst_IO1     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO1
            hps_0_hps_io_hps_io_qspi_inst_IO2     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO2
            hps_0_hps_io_hps_io_qspi_inst_IO3     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO3
            hps_0_hps_io_hps_io_qspi_inst_SS0     : out   std_logic;                                        -- hps_io_qspi_inst_SS0
            hps_0_hps_io_hps_io_qspi_inst_CLK     : out   std_logic;                                        -- hps_io_qspi_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_CMD     : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     : out   std_logic;                                        -- hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D0      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     : out   std_logic;                                        -- hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
            hps_0_hps_io_hps_io_spim1_inst_CLK    : out   std_logic;                                        -- hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    : out   std_logic;                                        -- hps_io_spim1_inst_SS0
            hps_0_hps_io_hps_io_uart0_inst_RX     : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     : out   std_logic;                                        -- hps_io_uart0_inst_TX
            hps_0_hps_io_hps_io_i2c0_inst_SDA     : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SDA
            hps_0_hps_io_hps_io_i2c0_inst_SCL     : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SCL
            hps_0_hps_io_hps_io_i2c1_inst_SDA     : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SDA
            hps_0_hps_io_hps_io_i2c1_inst_SCL     : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SCL
            hps_0_hps_io_hps_io_gpio_inst_GPIO09  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO09
            hps_0_hps_io_hps_io_gpio_inst_GPIO35  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO35
            hps_0_hps_io_hps_io_gpio_inst_GPIO40  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO40
            hps_0_hps_io_hps_io_gpio_inst_GPIO41  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO41
            hps_0_hps_io_hps_io_gpio_inst_GPIO48  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO48
            hps_0_hps_io_hps_io_gpio_inst_GPIO53  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO53
            hps_0_hps_io_hps_io_gpio_inst_GPIO54  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO54
            hps_0_hps_io_hps_io_gpio_inst_GPIO61  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO61
            hps_0_h2f_reset_reset_n               : out   std_logic;                                        -- reset_n
            pio_0_export                          : out   std_logic_vector(31 downto 0);                    -- export
            audio_mem1_address                    : in    std_logic_vector(12 downto 0) := (others => 'X'); -- address
            audio_mem1_chipselect                 : in    std_logic                     := 'X';             -- chipselect
            audio_mem1_clken                      : in    std_logic                     := 'X';             -- clken
            audio_mem1_write                      : in    std_logic                     := 'X';             -- write
            audio_mem1_readdata                   : out   std_logic_vector(63 downto 0);                    -- readdata
            audio_mem1_writedata                  : in    std_logic_vector(63 downto 0) := (others => 'X'); -- writedata
            audio_mem1_byteenable                 : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- byteenable
            irq0_irq                              : in    std_logic_vector(31 downto 0) := (others => 'X'); -- irq
            audio_mem1c_clk                       : in    std_logic                     := 'X';             -- clk
            audio_regs_export                     : in    std_logic_vector(31 downto 0) := (others => 'X') -- export
        );
    end component hps2;
	 
	-- # of samples; each sample is 32 bits (16 for left, 16 for right)
	constant audio_bufsize: integer := 65536/4;
	constant audio_bufsize_words: integer := audio_bufsize/2;
	signal pio0data: std_logic_vector(31 downto 0);
	signal mem_raddr: unsigned(12 downto 0);
	signal mem_q: std_logic_vector(63 downto 0);
	signal vclk,aclk,audio_mem_clk: std_logic := '0';
	signal ainL,ainR,aoutL,aoutR,aoutL0,aoutR0,dataL,dataR: signed(15 downto 0);
	signal tmpL,tmpR: signed(26 downto 0);
	signal aout: std_logic_vector(31 downto 0);
	signal irq: std_logic_vector(31 downto 0);
	signal aoutL_abs,aoutR_abs,aout_abs: unsigned(15 downto 0);
	signal cnt1: unsigned(12 downto 0);
	signal audio_regs: std_logic_vector(31 downto 0);
	signal audio_irq,audio_irq1: std_logic;
	signal audio_gain: signed(10 downto 0);
	signal audio_gain1: unsigned(4 downto 0);
	signal osc_in: signed(13 downto 0);
	signal audio_pll_clk: std_logic;
	
	signal aoutMono0: signed(16 downto 0);
	signal aoutMono: signed(15 downto 0);
	signal dacIn,prevDacIn,modIn: unsigned(15 downto 0);
	signal tmp1,tmp2: unsigned(26 downto 0);
	signal aCounter: unsigned(12 downto 0);
	constant aCounterPeriod: integer := 1000;
	signal aclk0: std_logic;
	signal dacClk,dacOut: std_logic;
	signal dacOut2: unsigned(3 downto 0);
begin
--	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, --AudMclk=>AUD_XCK,
--			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
--			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
--			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
--	AUD_XCK <= audio_pll_clk;
	audio_mem_clk <= not audio_mem_clk when falling_edge(aclk);
	mem_raddr <= mem_raddr+1 when rising_edge(audio_mem_clk);
	aout <= mem_q(31 downto 0) when audio_mem_clk='1' and rising_edge(aclk) 
		else mem_q(63 downto 32) when rising_edge(aclk);
	dataL <= signed(aout(15 downto 0));
	dataR <= signed(aout(31 downto 16));
	tmpL <= dataL*audio_gain when rising_edge(aclk);
	tmpR <= dataR*audio_gain when rising_edge(aclk);
	--aoutL <= signed((2 downto 0=>aout(15))&aout(15 downto 3));
	--aoutR <= signed((2 downto 0=>aout(31))&aout(31 downto 19));
	clL: signedClipper generic map(21,16) port map(tmpL(26 downto 6),aoutL0);
	clR: signedClipper generic map(21,16) port map(tmpR(26 downto 6),aoutR0);
	aoutL <= aoutL0 when rising_edge(aclk);
	aoutR <= aoutR0 when rising_edge(aclk);
	audio_gain1 <= unsigned(SW(4 downto 0));
	audio_gain <= "0"&signed(audio_gain1*audio_gain1);
	
	
	
	aoutMono0 <= (aoutL(15)&aoutL)+(aoutR(15)&aoutR);
	aoutMono <= aoutMono0(16 downto 1) when rising_edge(aclk);
	dacIn <= unsigned(aoutMono)+"1000000000000000" when rising_edge(dacClk);
	--prevDacIn <= dacIn when rising_edge(aclk);
	--tmp1 <= prevDacIn*(not aCounter) when rising_edge(dacClk);
	--tmp2 <= dacIn*aCounter when rising_edge(dacClk);
	--modIn <= tmp1(26 downto 11)+tmp2(26 downto 11) when rising_edge(dacClk);
	
	
	dac_pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"44.099378 MHz")
		port map(inclk=>CLOCK_50,outclk=>dacClk);
	aCounter <= to_unsigned(0,13) when aCounter>=aCounterPeriod and rising_edge(dacClk) else
		aCounter+1 when rising_edge(dacClk);
	aclk0 <= '1' when aCounter<aCounterPeriod/2 else '0';
	aclk <= aclk0 when rising_edge(dacClk);
	dsm: deltaSigmaModulator generic map(12) port map(dacClk,dacIn,dacOut);
	dsm2: deltaSigmaModulator2 generic map(12) port map(dacClk,dacIn,dacOut2);
	LEDR(1) <= dacOut;
	GPIO_0(1) <= dacOut;
	GPIO_0(3) <= dacOut;
	GPIO_0(5) <= dacOut;
	GPIO_0(0) <= not dacOut;
	GPIO_0(2) <= not dacOut;
	GPIO_0(4) <= not dacOut;
	
	GPIO_1(1 downto 0) <= (others=>'Z');
	GPIO_1(2) <= dacOut2(3);
	GPIO_1(3) <= dacOut2(2);
	GPIO_1(4) <= dacOut2(1);
	GPIO_1(5) <= dacOut2(0);

--	GPIO_1(2) <= dacIn(15);
--	GPIO_1(3) <= dacIn(14);
--	GPIO_1(4) <= dacIn(13);
--	GPIO_1(5) <= dacIn(12);
--	GPIO_1(6) <= dacIn(11);
--	GPIO_1(7) <= dacIn(10);
--	GPIO_1(8) <= dacIn(9);
--	GPIO_1(9) <= dacIn(8);
--	GPIO_1(10) <= dacIn(7);


	--audio_gain <= "00001";
	
	--o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,osc_in,
	--	to_unsigned(32,20),CLOCK_50,aclk);
	--o: simple_oscilloscope port map(CLOCK_50,aclk,osc_vga_out,osc_in(16 downto 1),
	--	(11 downto 0=>'0')&((unsigned(SW(8 downto 5))*unsigned(SW(8 downto 5)))));
--	osc_in <= aoutL when SW(5 downto 4)="00" else
--					aoutR when SW(5 downto 4)="01" else
--					dataL when SW(5 downto 4)="10" else
--					dataR;
	
	
	audio_regs(0) <= '1' when mem_raddr>=audio_bufsize_words/2 and rising_edge(aclk)
		else '0' when rising_edge(aclk);
	audio_irq <= '1' when (mem_raddr<audio_bufsize_words/4 or
		(mem_raddr>=audio_bufsize_words/2 and mem_raddr<(audio_bufsize_words/2+audio_bufsize_words/4)))
		and rising_edge(aclk) else '0' when rising_edge(aclk);
	
	--volume indicator
	cnt1 <= cnt1+32 when rising_edge(CLOCK_50);
	aoutL_abs <= unsigned(aoutL) when aoutL>0 else unsigned(-aoutL);
	aoutR_abs <= unsigned(aoutR) when aoutR>0 else unsigned(-aoutR);
	aout_abs <= aoutL_abs when aoutL_abs>aoutR_abs and rising_edge(aclk)
		else aoutR_abs when rising_edge(aclk);
	LEDR(0) <= '1' when aout_abs>("000"&cnt1) and rising_edge(CLOCK_50)
		else '0' when rising_edge(CLOCK_50);
	--LEDR <= std_logic_vector(aoutL(15 downto 6)) when aoutL>0 else std_logic_vector(-aoutL(15 downto 6));
	
	--irqs
	audio_irq1 <= audio_irq when rising_edge(aclk);
	irq(0) <= audio_irq1 when rising_edge(aclk);
	irq(31 downto 1) <= (others=>'0');
	
--	fb_conf <= "000"&"1" &
--		std_logic_vector(to_unsigned(3,10)) &
--		std_logic_vector(to_unsigned(38,10)) &
--		std_logic_vector(to_unsigned(1,10)) &
--		std_logic_vector(to_unsigned(144,10)) &
--		std_logic_vector(to_unsigned(248,10)) &
--		std_logic_vector(to_unsigned(16,10)) &
--		std_logic_vector(to_unsigned(1024,16)) &
--		std_logic_vector(to_unsigned(1280,16)) &
--		"00"&SW(9 downto 0)&(19 downto 0=>'0');
--	vga_pll: work.simple_altera_pll generic map(infreq=>"50.0 MHz",outfreq=>"135.000000 MHz")
--		port map(inclk=>CLOCK_50,outclk=>vclk);
--	vga_timer: vga_out generic map(W=>W,H=>H,syncdelay=>3)
--		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
--		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>vclk,cx=>x,cy=>y);
--	memread_rst <= '1' when y=H and rising_edge(vclk) else
--		'0' when rising_edge(vclk);
--	memread_rd_en <= '1' when y<H and x<W else '0';
--	memread_q1 <= unsigned(memread_q) when rising_edge(vclk);
--	VGA_R <= memread_q1(7 downto 0);
--	VGA_G <= memread_q1(15 downto 8);
--	VGA_B <= memread_q1(23 downto 16);
--	VGA_CLK <= vclk;
	
	hps: component hps2 port map(
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
		audio_regs_export=>audio_regs
	);
end architecture;
