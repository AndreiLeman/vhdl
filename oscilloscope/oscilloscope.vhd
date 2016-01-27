library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc;
use work.AudioSubSystemStereo;
use work.deltaSigmaModulator;
use work.spiRomTx;
use work.spectrum2_wrapper;
use work.hexdisplay;
use work.hexarraydisplay;
use work.HEXdisplaypkg.all;
use work.reducedHPSInterface;
use work.dataExpander;
use work.slow_clock;
entity oscilloscope is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			
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
			HPS_USB_DATA: inout std_logic_vector(7 downto 0)
			);
end entity;
architecture a of oscilloscope is
	component adcpll is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic         -- clk
		);
	end component adcpll;
	signal osc_data: signed(16 downto 0);
	signal samples_per_px,samples_per_px1: unsigned(19 downto 0);
	signal adcclk,aclk: std_logic;
	signal clock_25,clock_12,clock_6,clock_4,clock_3,
		clock_1_5,clock_800k,clock_10,busClk: std_logic;
	signal CLOCK_1,CLOCK_500k,CLOCK_250k,CLOCK_125k,CLOCK_62k: std_logic;
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal adc_data: std_logic_vector(7 downto 0);
	signal adc_in: unsigned(7 downto 0);
	signal adc_in_s: signed(7 downto 0);
	signal biasPulses: std_logic;
	signal bias: unsigned(3 downto 0);
	signal gainPulses: std_logic;
	signal gain: unsigned(3 downto 0);
	signal N: unsigned(7 downto 0);
	signal div3,k01,k11: std_logic;
	signal freq_int_3: unsigned(7 downto 0);
	signal freq_int: unsigned(6 downto 0) := to_unsigned(90,7);
	signal freq_int_d0,freq_int_d1,freq_int_d2: unsigned(6 downto 0);
	
	signal spi_data: unsigned(87 downto 0);
	signal spi_romAddr: unsigned(7 downto 0);
	signal spi_romAddr1: unsigned(6 downto 0);
	signal spi_romData,spi_clk,spi_cs,spi_clken: std_logic;
	signal spi_doTx,spi_doTx1: std_logic;
	signal offset: unsigned(23 downto 0);
	
	--ui
	signal HEX_freq1,HEX_freq2,pll2_hex,HEXout: HEXarray;
	signal clockdiv: unsigned(16 downto 0);
	signal uiclock: std_logic;
	signal sw_pll,sw_spec,sw_pll2: std_logic;
	
	-- pll control
	constant i2ccycles: integer := 56;
	signal io_sdain,io_sdaout,io_scl,io_cmpin: std_logic;
	signal MD,MD_next,MD_next1: unsigned(17 downto 0);
	signal i2c_do_tx,i2c_do_tx1,i2c_do_tx2,i2c_do_tx3,i2c_do_tx4,
		i2cclk1,i2cclk2,i2cclken,i2cclken1,i2cclkout: std_logic;
	signal i2csr,i2csrnext,i2cdata: unsigned(i2ccycles downto 0);
	signal i2ccnt,i2ccntnext: unsigned(15 downto 0);
	
	-- pll2 control
	constant pll2_sendInterval: integer := 255;
	signal pll2_clk,pll2_le,pll2_leNext,pll2_doSend: std_logic;
	type pll2_states is (stop,load,send,done);
	signal pll2_state,pll2_stateNext: pll2_states;
	signal pll2_addr,pll2_addrNext: unsigned(1 downto 0);
	signal pll2_cnt,pll2_cntNext: unsigned(7 downto 0);
	signal pll2_sr,pll2_srNext: unsigned(23 downto 0);
	signal pll2_data: unsigned(23 downto 0);
	signal pll2_B: unsigned(12 downto 0);
	signal pll2_A: unsigned(5 downto 0);
	signal pll2_clken,pll2_clkenNext: std_logic;
	
	signal pll2_outClk,pll2_outData,pll2_outLe: std_logic;
	
	signal pll2_X,pll2_XNext: unsigned(5 downto 0);
	signal pll2_N: unsigned(9 downto 0);
	signal pll2_k01,pll2_k11: std_logic;
	
	--stream2hps
	signal s2hData: std_logic_vector(63 downto 0);
	signal s2hClk: std_logic;
begin
gen:
	for I in 0 to 15 generate
		samples_per_px1(I) <= '1' when unsigned(SW(3 downto 0))=to_unsigned(I,4) else '0';
	end generate;
	samples_per_px <= samples_per_px1 when SW(9)='0' else (others=>'0');
	--samples_per_px <= unsigned(SW)*unsigned(SW) when rising_edge(CLOCK_50);
	
	
	--o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
	--	osc_data(16 downto 1),samples_per_px,CLOCK_50,aclk);
	spd: spectrum2_wrapper port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
		adc_in_s,CLOCK_50,aclk,samples_per_px,SW(8));
		
	
	
	--audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
	--		I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
	--		DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
	--		AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	--osc_data <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	--aoutL <= ainL;
	--aoutR <= ainR;
	
	clock_25 <= not clock_25 when rising_edge(CLOCK_50);
	clock_12 <= not clock_12 when rising_edge(clock_25);
	clock_6 <= not clock_6 when rising_edge(clock_12);
	clock_3 <= not clock_3 when rising_edge(clock_6);
	clock_1_5 <= not clock_1_5 when rising_edge(clock_3);
	clock_800k <= not clock_800k when rising_edge(clock_1_5);
	
	CLOCK_500k <= not CLOCK_500k when rising_edge(CLOCK_1);
	CLOCK_250k <= not CLOCK_250k when rising_edge(CLOCK_500k);
	CLOCK_125k <= not CLOCK_125k when rising_edge(CLOCK_250k);
	CLOCK_62k <= not CLOCK_62k when rising_edge(CLOCK_125k);
	clockdiv <= clockdiv+1 when rising_edge(clock_1);
	uiclock <= clockdiv(16);
	
	sc10: slow_clock generic map(5,2) port map(CLOCK_50,clock_10);
	sc1: slow_clock generic map(10,5) port map(CLOCK_10,clock_1);
	sc4: slow_clock generic map(50,25) port map(busClk,clock_4);
	--pll4: work.simple_altera_pll generic map("50.0 MHz","4 MHz","false") port map(CLOCK_50,clock_4);
	pll200: work.simple_altera_pll generic map("50.0 MHz","200 MHz","false") port map(CLOCK_50,busClk);
	--	port map(inclk=>CLOCK_50,outclk=>aclk);
	pll: adcpll port map(CLOCK_50,'0',adcclk,aclk);
	--aclk <= CLOCK_50;
	--GPIO_0(0) <= clock_12;
	--GPIO_0(1) <= clock_12;
	GPIO_1(9) <= adcclk;
	GPIO_1(8) <= '0';
	
	
	adc_data(0) <= GPIO_1(7);
	adc_data(1) <= GPIO_1(6);
	adc_data(2) <= GPIO_1(5);
	adc_data(3) <= GPIO_1(4);
	adc_data(4) <= GPIO_1(3);
	adc_data(5) <= GPIO_1(2);
	adc_data(6) <= GPIO_1(1);
	adc_data(7) <= GPIO_1(0);
	adc_in <= unsigned(adc_data) when rising_edge(aclk);
	adc_in_s <= signed(adc_in)+"10000000" when rising_edge(aclk);
	osc_data <= adc_in_s&"000000000" when rising_edge(aclk);
	
	
	-- bias control
	dsm: deltaSigmaModulator port map(clock_1_5,bias&(27 downto 0=>'0'),biasPulses);
	bias <= bias+1 when falling_edge(KEY(3)) and sw_spec='1';
	GPIO_1(20) <= biasPulses;
	GPIO_1(21) <= biasPulses;
	-- gain control
	dsm2: deltaSigmaModulator port map(clock_800k,"0"&gain&(26 downto 0=>'0'),gainPulses);
	gain <= gain+1 when falling_edge(KEY(2)) and sw_spec='1';
	GPIO_1(31) <= gainPulses;

	div3 <= '1' when freq_int<60 else '0';
	k01 <= (not KEY(0)) and sw_spec when rising_edge(spi_clk);
	k11 <= (not KEY(1)) and sw_spec when rising_edge(spi_clk);
	freq_int <= freq_int+1 when (KEY(0)='0' and k01='0' and sw_spec='1') and rising_edge(spi_clk) else
			freq_int-1 when (KEY(1)='0' and k11='0' and sw_spec='1') and rising_edge(spi_clk);
	
	freq_int_d2 <= freq_int/100;
	freq_int_d1 <= (freq_int/10) mod 10;
	freq_int_d0 <= freq_int mod 10;
	hd1: hexarraydisplay port map(X"00"&freq_int_d2(3 downto 0)
		&freq_int_d1(3 downto 0)&freq_int_d0(3 downto 0)
		&"0000",HEX_freq1,"110000");
	
	freq_int_3 <= (freq_int&"0") + freq_int;
	N <= freq_int&"0" when div3='0' else freq_int_3;
	
	spi_data <= "00000010" &				-- address
					"00100000" &				-- 1
					"00001100" &				-- 2
					"010100" &					-- 3
					to_unsigned(1,10) &		-- R
					(6 downto 0=>'0')&N&"0" &	-- N
					"01100011" &				-- 7
					"0110101"&div3 &			-- 8
					"00010100" &				-- 9
					"11000000";					-- a
	spi_romAddr1 <= 87-spi_romAddr(6 downto 0) when falling_edge(spi_clk);
	spi_romData <= spi_data(to_integer(spi_romAddr1));
	spi_clk <= clock_1_5;
	spiTx1: spiRomTx generic map(16) port map(spi_clk,spi_doTx and sw_spec,to_unsigned(88,8),spi_romAddr,spi_cs,spi_clken);
	spi_doTx1 <= not (KEY(0) and KEY(1)) when rising_edge(spi_clk);
	spi_doTx <= (not (KEY(0) and KEY(1))) and (not spi_doTx1) when rising_edge(spi_clk);
	GPIO_1(28) <= not spi_cs;
	GPIO_1(29) <= spi_clk and spi_clken;
	GPIO_1(27) <= spi_romData;
	GPIO_1(34) <= clock_10;
	GPIO_1(35) <= not clock_10;
	
	
	
	MD <= MD_next when rising_edge(uiclock);
	MD_next <= MD_next1 when sw_pll='1' else MD;
	MD_next1 <= MD-16 when KEY(3)='0' else
				MD+16 when KEY(2)='0' else
				MD-1024 when KEY(1)='0' else
				MD+1024 when KEY(0)='0' else
				MD;
	hd2: hexarraydisplay port map("00"&MD&"0000",HEX_freq2,"000001");
	io_scl <= i2cclkout;
	io_sdaout <= i2csr(i2ccycles);
	--						ADDR		R		SUBADDR
	i2cdata <= "10" & "110001000" & "000010000" &
	--		A					B
			"001000010" & "101000" & MD(17)&MD(16) & "0" &
	--		C								D
			MD(15 downto 8)&"0" & MD(7 downto 0)&"0"
	--		stop bit
			&"0";
	
	
	i2c_do_tx <= clockdiv(16) when rising_edge(i2cclk1);
	
	i2cclk1 <= CLOCK_62k;
	i2cclk2 <= CLOCK_62k when falling_edge(CLOCK_125k);
	-- i2c shift register
	i2c_do_tx1 <= i2c_do_tx when rising_edge(i2cclk1);
	i2csr <= i2csrnext when falling_edge(i2cclk2);
	i2csrnext <= i2cdata when i2c_do_tx1='0' else i2csr(i2ccycles-1 downto 0)&'1';
	i2ccnt <= i2ccntnext when rising_edge(i2cclk1);
	i2ccntnext <= X"0000" when i2c_do_tx='0' else
		i2ccnt when i2ccnt=i2ccycles else
		i2ccnt+1;
	i2cclken <= '0' when i2ccnt=X"0000" or i2ccnt=i2ccycles else '1';
	i2cclken1 <= i2cclken when rising_edge(i2cclk1);
	i2cclkout <= (not i2cclken1) or i2cclk1;
	
	--pll2 control
	pll2_clk <= CLOCK_62k;
	pll2_state <= pll2_stateNext when rising_edge(pll2_clk);
	pll2_addr <= pll2_addrNext when rising_edge(pll2_clk);
	pll2_cnt <= pll2_cntNext when rising_edge(pll2_clk);
	pll2_sr <= pll2_srNext when rising_edge(pll2_clk);
	pll2_stateNext <= load when pll2_state=stop and pll2_doSend='1' else
							send when pll2_state=load else
							done when pll2_state=send and pll2_cnt=23 else
							stop when pll2_state=done and pll2_addr="10" else
							load when pll2_state=done else
							pll2_state;
	pll2_cntNext <= to_unsigned(0,8) when pll2_state=stop else
						pll2_cnt+1 when pll2_state=send else
						to_unsigned(0,8); --when pll2_state=done else
	pll2_addrNext <= pll2_addr+1 when pll2_state=done else
						"00" when pll2_state=stop else
						pll2_addr;
	pll2_srNext <= pll2_sr(22 downto 0)&"0" when pll2_state=send else
						pll2_data;
	pll2_data <=
		--	 PPDCCCCCCTTTTFF3PMMMDR
			"0001110001111110100100" & "11" when pll2_addr="00" else
		--	 XDSPTTWW		R
			"00010000" & "00000000001010" & "00" when pll2_addr="01" else
		--	 XXG		B			A
			"001" & pll2_B & pll2_A & "01";
	
	pll2_A <= "000"&pll2_N(2 downto 0);
	pll2_B <= "000000"&pll2_N(9 downto 3);
	
	pll2_le <= pll2_leNext when rising_edge(pll2_clk);
	pll2_leNext <= '0' when pll2_state=send else
						'0' when pll2_state=done else
						'1';
	pll2_clken <= pll2_clkenNext when rising_edge(pll2_clk);
	pll2_clkenNext <= '1' when pll2_state=send else '0';
	pll2_outClk <= pll2_clken and (not pll2_clk);
	pll2_outData <= pll2_sr(23) when rising_edge(pll2_clk);
	pll2_outLe <= pll2_le;
	
	--pll2 ui
	pll2_k01 <= KEY(0) when rising_edge(pll2_clk);
	pll2_k11 <= KEY(1) when rising_edge(pll2_clk);
	pll2_XNext <= pll2_X+1 when sw_pll2='1' and KEY(0)='0' and pll2_k01='1' else
						pll2_X-1 when sw_pll2='1' and KEY(1)='0' and pll2_k11='1' else
						pll2_X;
	pll2_X <= pll2_XNext when rising_edge(pll2_clk);
	pll2_N <= pll2_X+to_unsigned(880,10) when rising_edge(pll2_clk);
	pll2_doSend <= '1' when ((KEY(0)='0' and pll2_k01='1') or
										(KEY(1)='0' and pll2_k11='1')) and sw_pll2='1'
										and rising_edge(pll2_clk)
								else '0' when rising_edge(pll2_clk);
	hd3: hexarraydisplay port map(X"000"&"00"&pll2_N,pll2_hex,"111000");
	--HPS
	hps: reducedHPSInterface port map(CLOCK_50, HPS_CONV_USB_N,HPS_ENET_INT_N,HPS_ENET_MDIO,
			HPS_GSENSOR_INT, HPS_I2C1_SCLK, HPS_I2C1_SDAT, HPS_I2C2_SCLK, HPS_I2C2_SDAT, 
			HPS_I2C_CONTROL, HPS_KEY, HPS_LED,HPS_SD_CMD, HPS_SPIM_SS, HPS_DDR3_CAS_N,
			HPS_DDR3_CKE,HPS_DDR3_CK_N, HPS_DDR3_CK_P, HPS_DDR3_CS_N, HPS_DDR3_ODT,
			HPS_DDR3_RAS_N, HPS_DDR3_RESET_N, HPS_DDR3_WE_N, HPS_ENET_GTX_CLK, HPS_ENET_MDC,
			HPS_ENET_TX_EN, HPS_FLASH_DCLK, HPS_FLASH_NCSO, HPS_SD_CLK, HPS_SPIM_CLK,
			HPS_SPIM_MOSI, HPS_UART_TX, HPS_USB_STP, HPS_DDR3_RZQ,HPS_ENET_RX_CLK,
			HPS_ENET_RX_DV, HPS_SPIM_MISO,HPS_UART_RX,HPS_USB_CLKOUT, HPS_USB_DIR,
			HPS_USB_NXT, HPS_DDR3_DM,HPS_ENET_TX_DATA,HPS_DDR3_DQS_N,HPS_DDR3_DQS_P,
			HPS_SD_DATA, HPS_FLASH_DATA, HPS_ENET_RX_DATA, HPS_DDR3_ADDR, HPS_DDR3_BA,
			HPS_DDR3_DQ, HPS_GPIO, HPS_USB_DATA,
			(others=>'0'), s2hData,s2hClk,busClk);
	expander: dataExpander generic map(8,64) port map(std_logic_vector(adc_in),aclk,s2hData,s2hClk);
	
	
	--switching
	sw_pll <= '0';
	sw_pll2 <= SW(7);
	sw_spec <= not SW(7);
	HEXout <= HEX_freq1 when sw_spec='1' else pll2_hex;
	-- I/O pins
--	io_cmpin <= GPIO_0(2);
--	io_sdain <= GPIO_0(3);
--	GPIO_0(4) <= clock_4;
--	GPIO_0(3) <= io_sdaout;
--	GPIO_0(5) <= io_scl;
	GPIO_0(2) <= not pll2_outClk;
	GPIO_0(3) <= not pll2_outData;
	GPIO_0(4) <= not pll2_outLe;
	GPIO_0(5) <= clock_10;
	
	HEX0 <= HEXout(0);
	HEX1 <= HEXout(1);
	HEX2 <= HEXout(2);
	HEX3 <= HEXout(3);
	HEX4 <= HEXout(4);
	HEX5 <= HEXout(5);
end architecture;
