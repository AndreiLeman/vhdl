library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.ulpi_serial;
use work.slow_clock;
use work.slow_clock_odd;
use work.deltaSigmaModulator;
use work.deltaSigmaModulator3;
use work.usbgpio;
use work.debugtool_buttonCleanup;
use work.hexdisplay_custom;
use work.serial7seg2;
use work.clkgen_i2c;
use work.clkgen_external_i2c;
use work.autoSampler;
use work.serdes_test;
use work.clocks;
use work.dcfifo;
use work.sineGenerator;
use work.cic_lpf_2_d;
use work.cic_lpf_2_nd;
use work.dsssTest1Top;
use work.dsssTest2Top;
use work.ledPreprocess;
use work.agc;
use work.spiDataTx;
use work.resetGenerator;

entity top2 is
    port(
		LED: out std_logic_vector(1 downto 0);
		SW: in std_logic_vector(1 downto 0);
		LVDSCLK_P,LVDSCLK_N: inout std_logic;
		LVDS_P, LVDS_N: inout std_logic_vector(2 downto 0);
		GPIOB: inout std_logic_vector(4 downto 0);
		GPIOR: inout std_logic_vector(8 downto 0);
		ANALOG: out std_logic_vector(2 downto 0);
		AUDIO: out std_logic_vector(1 downto 0);
		CLOCK_25: in std_logic;
		
		CLKGEN_SCL,CLKGEN_SDA: inout std_logic;
		CLKGEN_MOSFET: out std_logic;
		
		ADC: in std_logic_vector(9 downto 0);
		ADC_STBY: out std_logic;
		DAC_R,DAC_G,DAC_B: out unsigned(9 downto 0);
		DAC_PSAVE_N,DAC_BLANK_N,DAC_SYNC_N: out std_logic;
		--usb ulpi
		USB_DIR: in std_logic;
		USB_NXT: in std_logic;
		USB_DATA: inout std_logic_vector(7 downto 0);
		USB_RESET_B: out std_logic;
		USB_STP: out std_logic;
		USB_REFCLK: out std_logic
		);
end top2;

architecture a of top2 is
	constant ENABLE_AUDIO: boolean := false;
	constant ENABLE_USBGPIO: boolean := true;
	-- feed usb input data to downconverting mixer of dsss receiver
	constant ENABLE_DSSSLOOPBACK: boolean := false;
	-- feed usb input directly to dsss decoder
	constant ENABLE_DSSSLOOPBACK2: boolean := false;

	--ui
	signal SW_clean: std_logic_vector(1 downto 0);
	signal led_usbserial: std_logic;
	signal led_dim1,led_dim2: std_logic; -- a low duty cycle clock
	signal ebuttons,ebuttonsPrev: std_logic_vector(2 downto 0);
	
	--tx buffer space display
	signal bufspc_reset, displayDots: std_logic;
	signal txroom1,bufspc_min,bufspc_minNext: unsigned(15 downto 0);
	
	--7seg display
	signal sseg: std_logic_vector(31 downto 0);
	signal displayInt: unsigned(15 downto 0);
	signal ssegclk,hex_scl,hex_cs,hex_sdi: std_logic;
	
	--clocks
	signal CLOCK_25b: std_logic;
	signal CLOCK_225,CLOCK_60,CLOCK_1,
		CLOCK_300, CLOCK_15,internalclk: std_logic;
	signal usbclk,dacClk: std_logic;
	signal clkgen_en: std_logic := '0';
	signal reset,reset_gen: std_logic;
	
	--usb_serial data interface
	signal rxval,rxrdy,realrxval,rxclk,txval,txrdy,txclk: std_logic;
	signal rxdat,txdat: std_logic_vector(7 downto 0);
	signal txroom: unsigned(13 downto 0);
	signal tmp: unsigned(7 downto 0);
	
	signal usbtxval,usbtxrdy,usbrxval,usbrxrdy: std_logic;
	signal usbtxdat,usbrxdat: std_logic_vector(7 downto 0);
	signal fifo1empty,fifo1full: std_logic;
	
	--adc
	signal adcSclk,adcClk: std_logic;
	signal do_tx_adc,adc_valid0,adc_valid1,adc_valid,adc_shifted_valid: std_logic;
	signal adc_reduced: signed(7 downto 0);
	signal adc_sampled: std_logic_vector(9 downto 0);
	signal adc_shifted,adc_shifted_resynced: signed(9 downto 0);
	signal adc_failcnt: unsigned(15 downto 0);
	signal adc_checksum: std_logic;
	
	--cic filter (lowpass)
	signal adcFClk: std_logic;
	signal adcFiltered: signed(17 downto 0);

	--usb serial audio interface
	signal audioRecvd: std_logic_vector(48 downto 0);
	signal audioScaled: signed(15 downto 0);
	signal audioDoRx, rxdat_indicator: std_logic; --MSB of rxdat
	signal rxdat_lower: signed(6 downto 0); --rest of rxdat
	signal rxphase,rxphaseNext: unsigned(2 downto 0);
	signal adataLatch,adataLatchNext: std_logic;
	signal adata,adataNext,adataResampled,adataResampled1,adataResampled2: signed(47 downto 0);
	
	signal do_tx,usbgpio_do_rx: std_logic;
	
	signal audio_ds0,audio_ds1: std_logic;
	
	--usb gpio
	--signal gpioout: std_logic_vector(48 downto 0);
	--signal gpioin: std_logic_vector(13 downto 0);
	type gpios_t is array(0 to 15) of std_logic_vector(3 downto 0);
	signal gpioout: gpios_t;
	
	
	--i2c
	signal i2c_do_tx,i2cclk: std_logic;
	signal outscl,outsda,outctrl,outscl2,outsda2: std_logic;
	signal realsda1,realscl1,realsda2,realscl2: std_logic;
	
	--spi
	signal pll2_R: std_logic_vector(9 downto 0);
	signal pll2_mod: std_logic_vector(11 downto 0);
	signal pll2_N: std_logic_vector(15 downto 0);
	signal adf4350_clk,adf4350_le,adf4350_data: std_logic;
	
	--fm modulator
	signal fmAudioScaled: signed(23 downto 0);
	signal freq_int,freq_intNext: unsigned(6 downto 0) := to_unsigned(100,7);
	signal freq_int_d0,freq_int_d1,freq_int_d2: unsigned(6 downto 0);
	signal freq_f: unsigned(3 downto 0);
	signal freq_int1,freq_f1,freq_sum: unsigned(31 downto 0);
	signal base_freq: unsigned(27 downto 0);
	signal fm_freq: unsigned(27 downto 0);
	signal fm1,fm1Next,fm1_src: signed(8 downto 0);
	signal fm2,fm2i: unsigned(8 downto 0);
	signal encClk: std_logic;
	
	--dsss decoder
	signal dsss_up,dsss_down: std_logic;
	signal dsssDebugDisplay,dsss_cnt,dsss_cntNext: unsigned(15 downto 0);
	
	
	signal lcd_scl,lcd_sdi,lcd_cs,lcd_dc,lcd_rst,lcdclk: std_logic;
	signal sin1BaseFreq,sin1Freq: unsigned(27 downto 0);
	signal sin1Adj,sin1AdjNext: signed(7 downto 0);
	signal sin1Offset: signed(27 downto 0);
	
	signal sin1: signed(8 downto 0);
	signal mix1in: signed(9 downto 0);
	signal mix1: signed(18 downto 0);
	signal adcFiltered2: signed(29 downto 0);
	signal adcFiltered2TOffset: signed(39 downto 0);
	signal adcFiltered2T,adcFiltered2Truncated,dsssIn: signed(19 downto 0);
	signal adcF2TxEn: std_logic;
	signal oscDataClk: std_logic;
	signal oscDataIn: signed(15 downto 0);
	signal debugTxDat: signed(7 downto 0);
	signal dsssDataClk: std_logic;
begin
	assert not (ENABLE_AUDIO and ENABLE_USBGPIO)
		report "ENABLE_AUDIO and ENABLE_USBGPIO are exclusive" severity failure;
--	DAC_R <= (others=>'0');
--	DAC_G <= (others=>'0');
--	DAC_B <= (others=>'0');
	DAC_PSAVE_N <= '1';
	DAC_BLANK_N <= '1';
	DAC_SYNC_N <= '1';
	
	INST_STARTUP: STARTUP_SPARTAN6
        port map(
         CFGCLK => open,
         CFGMCLK => internalclk,
         CLK => '0',
         EOS => open,
         GSR => '0',
         GTS => '0',
         KEYCLEARB => '0');
	
	-- 250kHz state machine clock => 62.5kHz i2c clock
	i2cc: entity slow_clock generic map(200,100) port map(internalclk,i2cclk);
	-- 50kHz 7-segment spi clock
	ssc: entity slow_clock generic map(1000,500) port map(internalclk,ssegclk);

	ANALOG <= "000";
	--AUDIO <= "00";
	clkin1_buf : IBUFG port map (O => CLOCK_25b, I => CLOCK_25);
	pll: entity clocks port map(
		CLK_IN1=>CLOCK_25b,
		CLOCK_60=>CLOCK_60,
		CLOCK_225=>CLOCK_225,
		CLOCK_300=>CLOCK_300,
		LOCKED=>open);
	
	--CLOCK_60 <= internalclk;
	usbclk <= CLOCK_60;
	
	-- usb serial port device
	usbdev: entity ulpi_serial port map(USB_DATA, USB_DIR, USB_NXT,
		USB_STP, open, usbclk, usbrxval,usbrxrdy,usbtxval,usbtxrdy, usbrxdat,usbtxdat,
		LED=>led_usbserial, txroom=>txroom);
	USB_RESET_B <= '1';
	outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
		port map(C0=>usbclk, C1=>not usbclk,CE=>'1',D0=>'1',D1=>'0',Q=>USB_REFCLK);

	
	fifo1: entity dcfifo generic map(8,13) port map(usbclk,txclk,
		usbtxval,usbtxrdy,usbtxdat,open,
		txval,txrdy,txdat,open);
	fifo2: entity dcfifo generic map(8,12) port map(rxclk,usbclk,
		rxval,rxrdy,rxdat,open,
		usbrxval,usbrxrdy,usbrxdat,open);
	
	--usbtxval <= txval;
	--txrdy <= usbtxrdy;
	--usbtxdat <= txdat;

	-- simple (8 bit) gpio
cond_usbgpio:
	if ENABLE_USBGPIO generate
		rxclk <= usbclk;
		rxrdy <= usbgpio_do_rx;
g2:		for I in 0 to 2 generate
			gpioout(I) <= rxdat(3 downto 0) when rxrdy='1' and rxval='1' and unsigned(rxdat(7 downto 4))=I and rising_edge(usbclk);
		end generate;
		rxen: entity slow_clock generic map(30,1) port map(usbclk,usbgpio_do_rx);
	end generate;
	-- audio
cond_audio:
	if ENABLE_AUDIO generate
		rxclk <= usbclk;
		usbg: entity usbgpio generic map(7,2) port map(usbclk,rxval,rxrdy,rxdat,open,open,
			audioRecvd,(others=>'0'),'0',audioDoRx);
		audio_rxen: entity slow_clock generic map(1360,1) port map(usbclk,audioDoRx);
		
		
		agc0: entity agc generic map(16,8) port map(usbclk,
			signed(audioRecvd(23 downto 8)),audioScaled(7 downto 0),audioDoRx);
		agc1: entity agc generic map(16,8) port map(usbclk,
			signed(audioRecvd(47 downto 32)),audioScaled(15 downto 8),audioDoRx);
		
		
		dacClk <= CLOCK_300;
		--adataResampled1 <= signed(audioRecvd(47 downto 0)) when rising_edge(dacClk);
		adataResampled1 <= (3 downto 0=>audioScaled(15))&audioScaled(15 downto 8)&X"000"
			&(3 downto 0=>audioScaled(7))&audioScaled(7 downto 0)&X"000" when rising_edge(dacClk);
		adataResampled2 <= adataResampled1 when rising_edge(dacClk);
		adataResampled <= adataResampled2 when adataResampled1=adataResampled2 and rising_edge(dacClk);

		dsm0: entity deltaSigmaModulator3 port map(dacClk,adataResampled(23 downto 0)&X"00",audio_ds0);
		dsm1: entity deltaSigmaModulator3 port map(dacClk,adataResampled(47 downto 24)&X"00",audio_ds1);
		AUDIO(0) <= audio_ds0;
		AUDIO(1) <= audio_ds1;
	end generate;
cond_audio_n:
	if not ENABLE_AUDIO generate
		AUDIO(0) <= '0';
		AUDIO(1) <= '0';
	end generate;
	-- adc data
	adcSclk <= CLOCK_300;
	adc_sampler: entity autoSampler generic map(clkdiv=>4, width=>10)
		port map(clk=>adcSclk,datain=>ADC,dataout=>adc_sampled,dataoutvalid=>adc_valid,
			failcnt=>adc_failcnt);

	adc_shifted <= signed(adc_sampled)+"1000000000" when rising_edge(adcSclk);
	adc_shifted_valid <= adc_valid when rising_edge(adcSclk);
	
	--resynchronize adc data to adcClk
	adc_sc: entity slow_clock generic map(4,2) port map(adcSclk,adcClk,adc_shifted_valid);
	adc_shifted_resynced <= adc_shifted when rising_edge(adcClk);
	
	--filter adc data
	adc_sc_f: entity slow_clock generic map(12,6) port map(adcSclk,adcFClk);
	filt: entity cic_lpf_2_d generic map(inbits=>10,outbits=>18,decimation=>3,stages=>5,bw_div=>1)
		port map(adcClk,adcFClk,adc_shifted_resynced,adcFiltered);
	
	adc_reduced <= adcFiltered2T(18 downto 11) when SW_clean(1)='0' else adcFiltered(16 downto 9);
	--adc_reduced <= adc_shifted(9 downto 2);
	
	-- uncomment for ADC data into usb
	
	sc_tx_en: entity slow_clock generic map(8,1) port map(adcFClk,adcF2TxEn);
	txclk <= adcFClk;
	txval <= adcF2TxEn when SW_clean(1)='0' else '1'; --adc_shifted_valid when rising_edge(adcSclk);
	txdat <= std_logic_vector(adc_reduced(7 downto 0)) when rising_edge(adcFClk);
	
	--leds
	ledc1: entity slow_clock generic map(5000,500) port map(internalclk,led_dim1);
	ledc2: entity slow_clock generic map(5000,300) port map(internalclk,led_dim2);
	ledp1: entity ledPreprocess port map(led_dim1,not txrdy,LED(1));
	ledp0: entity ledPreprocess port map(led_dim2,led_usbserial,LED(0));
	
	--hex display
	bufspc_rstc: entity slow_clock generic map(10000000,1) port map(internalclk,bufspc_reset);
	txroom1 <= resize(txroom,16) when rising_edge(usbclk);
	bufspc_minNext <= X"ffff" when bufspc_reset='1' else
		txroom1 when txroom1<bufspc_min else
		bufspc_min;
	bufspc_min <= bufspc_minNext when rising_edge(usbclk);
	
cond_audio2:
	if ENABLE_AUDIO generate
		displayInt <= X"00"&"0"&freq_int;
	end generate;
cond_audio2_n:
	if not ENABLE_AUDIO generate
		displayInt <= adc_failcnt(7 downto 0) & unsigned(sin1Adj);
	end generate;
	
	displayDots <= '0'; --'1' when bufspc_min=0 else '0';
g:	for I in 0 to 3 generate
		hd: entity hexdisplay_custom port map(displayInt((I+1)*4-1 downto I*4),
			sseg((I+1)*8-1 downto I*8), displayDots);
	end generate;
	s7seg: entity serial7seg2 port map(ssegclk,sseg,ebuttons,
		GPIOB(0),GPIOB(1),GPIOB(2));
	ebuttonsPrev <= ebuttons when rising_edge(ssegclk);
	GPIOB(3) <= '1';
	--GPIOB(4) <= '1';
	
	bc: entity debugtool_buttonCleanup generic map(2) port map(i2cclk,SW,SW_clean);
	
	--i2c
	i2c1: entity clkgen_i2c port map(i2cclk,outscl,outsda,outctrl,reset);
	i2c2: entity clkgen_external_i2c port map(i2cclk,outscl2,outsda2,open,reset);
	
	--spi
	--pll2_R <= std_logic_vector(to_unsigned(26,10));
	pll2_R <= std_logic_vector(to_unsigned(1,10));
	pll2_mod <= std_logic_vector(to_unsigned(32,12));
	--pll2_N <= std_logic_vector(to_unsigned(3026,16));
	pll2_N <= std_logic_vector(to_unsigned(116,16));
	spi1: entity spiDataTx generic map(words=>6,wordsize=>32) port map(
	--	 XXXXXXXXLLXXXXXXXXXXXXXXXXXXX101
		"00000000010000000000000000000101" &
	--	 XXXXXXXXFOOOBBBBBBBBVMAAAAROO100
		"00000000101011111111000000111100" &
		"00000000000000000000000000000011" &
		"01100100" & pll2_R & "01111101000010" &
		"00001000000000001" & pll2_mod & "001" &
		"0" & pll2_N & "000000000000000",
		i2cclk, reset, adf4350_clk, adf4350_le, adf4350_data);
	
	--hardwired i2c outputs
--	CLKGEN_SCL <= '0' when outscl='0' else 'Z';
--	CLKGEN_SDA <= '0' when outsda='0' else 'Z';
--	GPIOR(7) <= '0' when outscl2='0' else 'Z';
--	GPIOR(8) <= '0' when outsda2='0' else 'Z';
	
	--configurable i2c outputs
	realscl1 <= outscl when gpioout(1)(0)='0' else gpioout(0)(0);
	realsda1 <= outsda when gpioout(1)(1)='0' else gpioout(0)(1);
	realscl2 <= outscl2 when gpioout(1)(2)='0' else gpioout(0)(2);
	realsda2 <= outsda2 when gpioout(1)(3)='0' else gpioout(0)(3);
	
	CLKGEN_SCL <= '0' when realscl1='0' else 'Z';
	CLKGEN_SDA <= '0' when realsda1='0' else 'Z';
	GPIOR(7) <= '0' when realscl2='0' else 'Z';
	GPIOR(8) <= '0' when realsda2='0' else 'Z';
	
	--external spi pll (adf4350)
	GPIOR(2) <= gpioout(2)(0) when gpioout(2)(3)='1' else adf4350_clk;
	GPIOR(5) <= gpioout(2)(1) when gpioout(2)(3)='1' else adf4350_le;
	GPIOR(6) <= gpioout(2)(2) when gpioout(2)(3)='1' else adf4350_data;
	
cond_audio3:
	if ENABLE_AUDIO generate
		--fm modulator
		freq_intNext <= freq_int-1 when ebuttonsPrev(1)='0' and ebuttons(1)='1'
			else freq_int+1 when ebuttonsPrev(2)='0' and ebuttons(2)='1'
			else freq_int;
		freq_int <= freq_intNext when rising_edge(ssegclk);
		fmAudioScaled <= signed(audioRecvd(23 downto 0));
		encClk <= usbclk;
		freq_int1 <= freq_int*to_unsigned(14316558,25); -- uncomment for f=freq_int*1MHz
		--freq_int1 <= freq_int*to_unsigned(1431656,25); -- uncomment for f=freq_int*100kHz
		--freq_f1 <= freq_f*to_unsigned(1431655,28);
		freq_sum <= freq_int1; --+freq_f1;
		base_freq <= freq_sum(31 downto 4);
		fm_freq <= base_freq+((5 downto 0=>fmAudioScaled(23))&unsigned(fmAudioScaled(23 downto 2)))
			when rising_edge(encClk);
		sg: entity sineGenerator port map(CLOCK_300,fm_freq,fm1_src);
		fm1 <= fm1_src when SW_clean(1)='1' and rising_edge(CLOCK_300);
		fm2 <= unsigned(fm1)+"100000000" when rising_edge(CLOCK_300);
		fm2i <= unsigned(-fm1)+"100000000" when rising_edge(CLOCK_300);
		
		DAC_R <= fm2&"0";
		DAC_G <= (others=>'0'); --fm2&"0";
		DAC_B <= (others=>'0'); --fm2&"0";
	end generate;
cond_audio3_n:
	if not ENABLE_AUDIO generate
		DAC_R <= (others=>'0');
		DAC_G <= (others=>'0');
		DAC_B <= (others=>'0');
	end generate;
	
	--dsss decoder
	
	dsss_cntNext <= dsss_cnt+1 when dsss_up='1' else
		dsss_cnt-1 when dsss_down='1' else
		dsss_cnt;
	dsss_cnt <= dsss_cntNext when rising_edge(adcClk);
	--dsss: entity dsssDecoder generic map(10)
	--	port map(adcClk,adc_shifted_resynced,dsssDebugDisplay,LED(0),LED(1),ebuttons(1),dsss_up,dsss_down);
	--displayInt <= dsssDebugDisplay when SW_clean(0)='0' else dsss_cnt;
	
	--downconvert signal
	--sin1Freq <= to_unsigned(60845370,28);	--5.66666667MHz @ 25Msps
	--sin1Freq <= to_unsigned(70509046,28);	--6.56666667MHz @ 25Msps
	--sin1Freq <= to_unsigned(54760833,28);	--5.1MHz @ 25Msps
	--sin1Freq <= to_unsigned(42949673,28);	--4MHz @ 25Msps
	--sin1Freq <= to_unsigned(123480310,28);	--11.5MHz @ 25Msps
	--sin1BaseFreq <= to_unsigned(18157191,28);	--1.6910201869904995MHz @ 25Msps, for 106MHz reception, with correction applied for de1-soc -> custom fpga board
	--sin1BaseFreq <= to_unsigned(53679795,28);		--~5MHz @ 25Msps, with correction for 864MHz reception from de1-soc -> custom fpga board
	--sin1BaseFreq <= to_unsigned(47311744,28);		--~4.4MHz @ 25Msps, with correction for 864.6MHz reception from de1-soc -> custom fpga board
	sin1BaseFreq <= to_unsigned(37580964,28);		--3.5MHz @ 25Msps
	
	sin1AdjNext <= sin1Adj+1 when ebuttons(2)='1' and ebuttonsPrev(2)='0' else
				sin1Adj-1 when ebuttons(1)='1' and ebuttonsPrev(1)='0' else
				sin1Adj;
	sin1Adj <= sin1AdjNext when rising_edge(ssegclk);
	sin1Offset <= resize(sin1Adj&"000000",28);
	
	sin1Freq <= sin1BaseFreq+unsigned(sin1Offset);
	
	sg: entity sineGenerator port map(adcFClk,sin1Freq,sin1);
	
cond_dsss:
	if ENABLE_DSSSLOOPBACK generate
		mix1in <= signed(rxdat) & "00";
		rxrdy <= '1';
		rxclk <= adcFClk;
	end generate;
cond_dsss_n:
	if not ENABLE_DSSSLOOPBACK generate
		mix1in <= adcFiltered(17 downto 8);
	end generate;
	
	mix1 <= sin1*mix1in when rising_edge(adcFClk);
	
	
	--mix1 <= sin1 & "0000000000";
	--mix1's MSB can be dropped because "10000000..." is never reached,
	--since sine generator never outputs the most negative value

	--filter signal to 1.25MHz bandwidth
	filt2: entity cic_lpf_2_nd generic map(inbits=>10,outbits=>30,stages=>6,bw_div=>10)
		port map(adcFClk,mix1(17 downto 8),adcFiltered2);
	adcFiltered2T <= adcFiltered2(29 downto 10);
	adcFiltered2TOffset <= adcFiltered2TOffset+resize(adcFiltered2Truncated,40) when rising_edge(adcFClk);
	adcFiltered2Truncated <= adcFiltered2T-adcFiltered2TOffset(39 downto 20) when rising_edge(adcFClk);
	
	
	-- 18.75MHz lcd clock
	lcdc: entity slow_clock generic map(12,6) port map(CLOCK_225,lcdclk);
	
	--dsss submodule
	
	oscDataClk <= adcClk;
	oscDataIn <= adc_shifted_resynced&"000000";
	
cond_dsss2:
	if ENABLE_DSSSLOOPBACK2 generate
		dsssIn <= signed(rxdat) & "000000000000";
		rxrdy <= '1';
		rxclk <= dsssDataClk;
	end generate;
cond_dsss2_n:
	if not ENABLE_DSSSLOOPBACK2 generate
		dsssIn <= adcFiltered2Truncated when rising_edge(dsssDataClk);
	end generate;

	dsss_test: entity dsssTest2Top port map(CLOCK_300,CLOCK_225,lcdclk,oscDataClk,adcFClk,
		oscDataIn,dsssIn,debugTxDat,dsssDataClk,lcd_scl,lcd_sdi,lcd_cs,lcd_dc,lcd_rst,SW,ebuttons);
	
	
	--I/Os
	GPIOR(0) <= lcd_sdi when falling_edge(lcdclk);
	GPIOR(1) <= lcd_dc when falling_edge(lcdclk);
	GPIOR(4) <= lcd_scl;
	GPIOR(3) <= lcd_cs when falling_edge(lcdclk);
	--GPIOR(5) <= lcd_rst;
	
	--txclk <= lcdclk;
	--txval <= '1';
	--txdat <= lcd_rst&lcd_dc&lcd_cs&lcd_sdi&"0000";
	
	
	--misc
	reset <= ebuttons(0) or reset_gen;
	CLKGEN_MOSFET <= not clkgen_en;
	clkgen_en <= '1' when reset='1' and rising_edge(internalclk);
	ADC_STBY <= '0';
	sdtest: entity serdes_test port map(CLOCK_25b,LVDS_P(0),LVDS_N(0));
	
	rg: entity resetGenerator generic map(25000) port map(i2cclk,reset_gen);
end a;

