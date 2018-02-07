library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.autoSampler;
use work.slow_clock;
use work.cic_lpf_2_d;
entity adcPreprocess is
    port(
		adcSClk: in std_logic;
		ADC: in std_logic_vector(9 downto 0);
		adcClk,adcFClk: out std_logic;
		
		adcRaw: out signed(9 downto 0);			--synchronous to adcClk
		adcFiltered: out signed(17 downto 0);	--synchronous to adcFClk
		
		failcnt: out unsigned(15 downto 0) := (others=>'X') --synchronous to adcSClk
		);
end entity;

architecture a of adcPreprocess is
	--adc
	signal adcClk0: std_logic;
	signal do_tx_adc,adc_valid0,adc_valid1,adc_valid,adc_shifted_valid: std_logic;
	signal adc_sampled: std_logic_vector(9 downto 0);
	signal adc_shifted,adc_shifted_resynced: signed(9 downto 0);
	signal adc_failcnt: unsigned(15 downto 0);
	signal adc_checksum: std_logic;
	
	--cic filter (lowpass)
	signal adcFClk0: std_logic;
begin
	adc_sampler: entity autoSampler generic map(clkdiv=>4, width=>10)
		port map(clk=>adcSclk,datain=>ADC,dataout=>adc_sampled,dataoutvalid=>adc_valid,
			failcnt=>failcnt);

	adc_shifted <= signed(adc_sampled)+"1000000000" when rising_edge(adcSclk);
	adc_shifted_valid <= adc_valid when rising_edge(adcSclk);
	
	--resynchronize adc data to adcClk0
	adc_sc: entity slow_clock generic map(4,2) port map(adcSclk,adcClk0,adc_shifted_valid);
	adc_shifted_resynced <= adc_shifted when rising_edge(adcClk0);
	
	--filter adc data
	adc_sc_f: entity slow_clock generic map(12,6) port map(adcSclk,adcFClk0);
	filt: entity cic_lpf_2_d generic map(inbits=>10,outbits=>18,decimation=>3,stages=>5,bw_div=>1)
		port map(adcClk0,adcFClk0,adc_shifted_resynced,adcFiltered);
	
	
	adcClk <= adcClk0;
	adcFClk <= adcFClk0;
	adcRaw <= adc_shifted_resynced;
end a;
