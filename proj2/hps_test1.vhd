library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemStereo;
use work.osc;
use work.de1_hexdisplay;
use work.vga_out;
use work.generic_oscilloscope;
use work.graphics_types.all;
use work.signedClipper;
entity hps_test1 is
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
			
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			
			DRAM_ADDR                            : out   std_logic_vector(12 downto 0);                    -- addr
			DRAM_BA                              : out   std_logic_vector(1 downto 0);                     -- ba
			DRAM_CAS_N                           : out   std_logic;                                        -- cas_n
			DRAM_CKE                             : out   std_logic;                                        -- cke
			DRAM_CS_N                            : out   std_logic;                                        -- cs_n
			DRAM_DQ                              : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			DRAM_LDQM,DRAM_UDQM                  : out   std_logic;
			DRAM_RAS_N                           : out   std_logic;                                        -- ras_n
			DRAM_WE_N                            : out   std_logic;                                        -- we_n
			DRAM_CLK                         : out   std_logic                                         -- clk
		);
end entity;
architecture a of hps_test1 is
    component hps1 is
        port (
            clk_clk                               : in    std_logic                      := 'X';             -- clk
            reset_reset_n                         : in    std_logic                      := 'X';             -- reset_n
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
            hps_0_h2f_reset_reset_n               : out   std_logic;                                         -- reset_n
            pio_0_export                          : out   std_logic_vector(31 downto 0);                     -- export
            audio_mem1_address                    : in    std_logic_vector(12 downto 0)  := (others => 'X'); -- address
            audio_mem1_chipselect                 : in    std_logic                      := 'X';             -- chipselect
            audio_mem1_clken                      : in    std_logic                      := 'X';             -- clken
            audio_mem1_write                      : in    std_logic                      := 'X';             -- write
            audio_mem1_readdata                   : out   std_logic_vector(63 downto 0);                     -- readdata
            audio_mem1_writedata                  : in    std_logic_vector(63 downto 0)  := (others => 'X'); -- writedata
            audio_mem1_byteenable                 : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- byteenable
            irq0_irq                              : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- irq
            audio_mem1c_clk                       : in    std_logic                      := 'X';             -- clk
            audio_regs_export                     : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- export
            audio_pll_clk                         : out   std_logic;                                         -- clk
            fb_vga_export                         : out   std_logic_vector(59 downto 0);                     -- export
            vga_fb_conf_export                    : in    std_logic_vector(127 downto 0) := (others => 'X'); -- export
            vga_fb_reg_conf_export                : out   std_logic_vector(127 downto 0)                     -- export
        );
    end component hps1;
	 
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
	signal dram_dqm: std_logic_vector(1 downto 0);
	
	constant W: integer := 1280;
	constant H: integer := 1024;
	
--	signal vclk: std_logic;
--	signal x,y: unsigned(11 downto 0);
--	signal memread_q: std_logic_vector(31 downto 0);
--	signal memread_q1: unsigned(31 downto 0);
--	signal memread_rst,memread_rd_en: std_logic;

	signal fb_conf: std_logic_vector(127 downto 0);
	signal fb_vga_out: std_logic_vector(59 downto 0);
	signal fb_vga_out1,osc_vga_out: unsigned(27 downto 0);
	signal vga_out,vga_out_1,vga_out_2,vga_out_3: unsigned(27 downto 0);
	signal fb_pos: position;
	signal osc_c: color;
	signal vga_out_c,vga_out_c1: color;
	signal vga_conf: std_logic_vector(127 downto 0);
begin
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, --AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	AUD_XCK <= audio_pll_clk;
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
	irq(3 downto 1) <= not KEY(3 downto 1);
	irq(31 downto 4) <= (others=>'0');
	
	cl: signedClipper generic map(17,14) port map((aoutL(15)&aoutL)+(aoutR(15)&aoutR),osc_in);
	o: generic_oscilloscope port map(aclk,fb_vga_out1(27),
		(11 downto 0=>'0')&((unsigned(SW(8 downto 5))*unsigned(SW(8 downto 5)))),
		osc_in(13 downto 0)&"00",unsigned(vga_conf(43 downto 32)),unsigned(vga_conf(59 downto 48)),
		fb_pos,osc_c);
	
	fb_vga_out1 <= unsigned(fb_vga_out(59 downto 32));
	fb_pos <= (unsigned(fb_vga_out(11 downto 0)),unsigned(fb_vga_out(27 downto 16)));
	vclk <= fb_vga_out1(27);
	vga_out_1 <= fb_vga_out1 when rising_edge(vclk);
	vga_out_2 <= vga_out_1 when rising_edge(vclk);
	vga_out_3 <= vga_out_2 when rising_edge(vclk);
	vga_out <= vga_out_3 when rising_edge(vclk);
	
	VGA_CLK <= vclk;
	vga_out_c <= (vga_out_3(7 downto 0),vga_out_3(15 downto 8),vga_out_3(23 downto 16))
		when SW(9)='0' else osc_c;
	vga_out_c1 <= vga_out_c when rising_edge(vclk);
	VGA_R <= vga_out_c1(0) when falling_edge(vclk);
	VGA_G <= vga_out_c1(1) when falling_edge(vclk);
	VGA_B <= vga_out_c1(2) when falling_edge(vclk);
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= not vga_out(24);
	VGA_HS <= not vga_out(25);
	VGA_VS <= not vga_out(26);
	
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
	
	hps: component hps1 port map(
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
		audio_pll_clk=>audio_pll_clk,
		
		--fb_conf_export=>fb_conf,
		fb_vga_export=>fb_vga_out,
		vga_fb_conf_export=>vga_conf,
		vga_fb_reg_conf_export=>vga_conf
		
--		sdram_addr=>DRAM_ADDR,
--		sdram_ba=>DRAM_BA,
--		sdram_cas_n=>DRAM_CAS_N,
--		sdram_cke=>DRAM_CKE,
--		sdram_cs_n=>DRAM_CS_N,
--		sdram_dq=>DRAM_DQ,
--		sdram_dqm=>dram_dqm,
--		sdram_ras_n=>DRAM_RAS_N,
--		sdram_we_n=>DRAM_WE_N,
--		sdram_clk_clk=>DRAM_CLK         

--		memread1_export=>(SW(9 downto 0)&(21 downto 0=>'0')),
--		memread2_export=>memread_q,
--		memread_rd_en_export=>memread_rd_en,
--		memread_rdclk_clk=>vclk,
--		memread_rst_export=>memread_rst

		
	);
--	DRAM_LDQM <= dram_dqm(0);
--	DRAM_UDQM <= dram_dqm(1);
	--LEDR <= pio0data(9 downto 0);
	--hd: de1_hexdisplay generic map(b=>8) 
	--	port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
	--		data=>("00"&SW(9 downto 0)&(19 downto 0=>'0')),button1=>not KEY(3),button2=>not KEY(2));
end architecture;
