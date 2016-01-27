library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc;
use work.AudioSubSystemStereo;
use work.lpf_rom_125_250;
use work.lpf;
use work.ejxGenerator;
use work.hexdisplay;

entity fm_receiver is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of fm_receiver is
	signal mixerClk: std_logic;
	signal osc_data: signed(16 downto 0);
	signal samples_per_px,samples_per_px1: unsigned(19 downto 0);
	signal adcclk,aclk,audioclk: std_logic;
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal adc_in: unsigned(7 downto 0);
	signal adc_in_s: signed(7 downto 0);
	
	signal rom1_addr1,rom1_addr2,rom2_addr1,rom2_addr2: unsigned(6 downto 0);
	signal rom1_clk,rom2_clk: std_logic;
	signal rom1_q1,rom1_q2,rom2_q1,rom2_q2: signed(95 downto 0);
	
	signal lpf1_clk,lpf2_clk: std_logic;
	
	signal lo_cos,lo_sin: signed(8 downto 0);
	signal if_i,if_q: signed(16 downto 0);
	
	signal i1,q1,i2,q2,i3,q3,di,dq: signed(7 downto 0);
	signal ds: signed(15 downto 0);
	signal ds_avg: signed(18 downto 0);
	signal audioclks1,audioclks2: std_logic;
	
	signal freq_int,freq_int_d0,freq_int_d1,freq_int_d2: unsigned(6 downto 0);
	signal freq_int1,freq_f1,freq_sum: unsigned(31 downto 0);
	
	component adcpll is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			outclk_1 : out std_logic         -- outclk1.clk
		);
	end component adcpll;
begin
gen:
	for I in 0 to 15 generate
		samples_per_px1(I) <= '1' when unsigned(SW(3 downto 0))=to_unsigned(I,4) else '0';
	end generate;
	samples_per_px <= samples_per_px1 when KEY(3)='1' else (others=>'0');
	--samples_per_px <= unsigned(SW)*unsigned(SW) when rising_edge(CLOCK_50);
	o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
		adc_in_s&(7 downto 0=>'0'),samples_per_px,CLOCK_50,aclk);
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>audioclk);
	--osc_data <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	--aoutL <= ainL;
	--aoutR <= ainR;
	
	pll: adcpll port map(CLOCK_50,'0',adcclk,aclk);
	pll2: work.simple_altera_pll generic map("50MHz","87MHz") port map(CLOCK_50,mixerClk);
	GPIO_1(27) <= adcclk;
	GPIO_1(26) <= '0';
	GPIO_1(1) <= mixerClk and SW(9);
	adc_in <= unsigned(GPIO_1(35 downto 28)) when rising_edge(aclk);
	adc_in_s <= signed(adc_in)+"10000000";
	osc_data <= i1&"000000000" when rising_edge(lpf1_clk);
	
	-- f = freq*2**32/500
	freq_int <= unsigned("0"&SW(9 downto 4));
	freq_int1 <= freq_int*to_unsigned(8589935,25);
	
	sg: ejxGenerator port map(aclk,to_unsigned(integer(0.06*2**28),28),lo_cos,lo_sin);
	if_i <= lo_cos*adc_in_s when rising_edge(aclk);
	if_q <= lo_sin*adc_in_s when rising_edge(aclk);
	
	rom1: lpf_rom_125_250 port map(rom1_addr1,rom1_addr2,rom1_clk,rom1_q1,rom1_q2);
	lpf1: lpf generic map(125,12) port map(if_i(16 downto 9),aclk,i1,lpf1_clk,
		rom1_addr1,rom1_addr2,rom1_clk,rom1_q1,rom1_q2);
	rom2: lpf_rom_125_250 port map(rom2_addr1,rom2_addr2,rom2_clk,rom2_q1,rom2_q2);
	lpf2: lpf generic map(125,12) port map(if_q(16 downto 9),aclk,q1,lpf2_clk,
		rom2_addr1,rom2_addr2,rom2_clk,rom2_q1,rom2_q2);
	
	
	i2 <= i1 when rising_edge(lpf1_clk);
	q2 <= q1 when rising_edge(lpf1_clk);
	i3 <= i2 when rising_edge(lpf1_clk);
	q3 <= q2 when rising_edge(lpf1_clk);
	di <= i1-i3 when rising_edge(lpf1_clk);
	dq <= q1-q3 when rising_edge(lpf1_clk);
	
	ds <= dq*i2-di*q2 when rising_edge(lpf1_clk);
	
	audioclks1 <= audioclk when rising_edge(lpf1_clk);
	audioclks2 <= audioclks1 when rising_edge(lpf1_clk);
	ds_avg <= to_signed(0,19) when audioclks2='0' and audioclks1='1'
		and rising_edge(lpf1_clk) else 
		ds_avg+ds when rising_edge(lpf1_clk);
	aoutL <= ds_avg(18 downto 3) when rising_edge(audioclk);
	aoutR <= ds_avg(18 downto 3) when rising_edge(audioclk);
	
	
	--frequency display
	freq_int_d2 <= freq_int/100;
	freq_int_d1 <= (freq_int/10) mod 10;
	freq_int_d0 <= freq_int mod 10;
	hd0: hexdisplay port map(freq_int_d0(3 downto 0),HEX0);
	hd1: hexdisplay port map(freq_int_d1(3 downto 0),HEX1);
	hd2: hexdisplay port map(freq_int_d2(3 downto 0),HEX2);
end architecture;
