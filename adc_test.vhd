library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.simple_oscilloscope;
use work.AudioSubSystemStereo;
use work.simple_altera_pll;
entity adc_test is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(0 downto 0);
			ADC_SCLK,ADC_DIN,ADC_CS_N: out std_logic;
			ADC_DOUT: in std_logic;
			
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT,AUD_XCK: out std_logic;
			
			GPIO_0,GPIO_1: inout std_logic_vector(5 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of adc_test is
	component pll_20m is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			locked   : out std_logic         -- export
		);
	end component pll_20m;
	signal conf: std_logic_vector(11 downto 0) := "110000111010";
	signal data,data_next,last_data: signed(11 downto 0);
	signal conf_out,conf_out_next: std_logic_vector(11 downto 0);
	type states is (init,sendconf,receiving,waiting);
	signal state,nextstate: states;
	signal next_cs,next_cs_n,cs_n: std_logic;
	signal count1: unsigned(11 downto 0);
	signal sclk1,sclk_locked,sclk,vclk: std_logic;
	signal osc_speed_sw: unsigned(3 downto 0);
	signal vga: unsigned(27 downto 0);
	
	signal aclk: std_logic;
	signal ainL,ainR,aout,aoutL,aoutR: signed(15 downto 0);
	signal aout1: signed(17 downto 0);
	
	signal CLOCK_1: std_logic;
begin
	pll: component pll_20m port map(refclk=>CLOCK_50,outclk_0=>sclk1,locked=>sclk_locked);
	sclk <= sclk1 and sclk_locked;
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	aoutL <= aout;
	aoutR <= aout;
	aout1 <= ("0"&signed(SW(7 downto 3)))*last_data;
	aout <= aout1(16 downto 1) when rising_edge(aclk);
	
	state <= nextstate when rising_edge(sclk);
	count1 <= to_unsigned(0,12) when (not (nextstate=state)) and rising_edge(sclk)
		else count1+1 when rising_edge(sclk);
	nextstate <= init when KEY(0)='0' else
			sendconf when state=init and count1>1000 else
			waiting when state=sendconf and count1>=16 else
			init when state=init else
			sendconf when state=sendconf else
			waiting when state=receiving and count1>=16 else
			receiving;-- when state=waiting or state=receiving;
	next_cs <= '1' when nextstate=receiving or nextstate=sendconf else '0';
	next_cs_n <= not next_cs;
	cs_n <= next_cs_n when rising_edge(sclk);
	ADC_CS_N <= cs_n;
	conf_out <= conf_out_next when rising_edge(sclk);
	conf_out_next <= conf when state=init else
		conf_out(10 downto 0) & "0";
	ADC_DIN <= conf_out(11);
	ADC_SCLK <= sclk;
	
	data_next <= data(10 downto 0) & ADC_DOUT;
	data <= data_next when rising_edge(sclk);
	last_data <= data when state=receiving and count1=16 and rising_edge(sclk);
	
	osc_speed_sw <= unsigned(SW(3 downto 0));
	o: simple_oscilloscope port map(CLOCK_50,cs_n,vga,last_data&"0000",
		(3 downto 0=>'0')&(osc_speed_sw*osc_speed_sw*osc_speed_sw*osc_speed_sw));
	--vga output
	vclk <= vga(27);
	VGA_CLK <= vclk;
	VGA_R <= vga(7 downto 0) when falling_edge(vclk);
	VGA_G <= vga(15 downto 8) when falling_edge(vclk);
	VGA_B <= vga(23 downto 16) when falling_edge(vclk);
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= not vga(24);
	VGA_HS <= not vga(25);
	VGA_VS <= not vga(26);
	
	pll2: simple_altera_pll generic map("50 MHz","1 MHz")
		port map(CLOCK_50,CLOCK_1);
	GPIO_1(0) <= CLOCK_1;
	GPIO_1(2) <= not CLOCK_1;
end architecture;
