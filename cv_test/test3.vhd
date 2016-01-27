
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.simple_altera_pll;
use work.slow_clock2;
use work.AudioSubSystemStereo;
use work.deltaSigmaModulator;
use work.sineGenerator;
entity test3 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic);
end entity;

architecture a of test3 is
	signal CLOCK_300,CLOCK_200,CLOCK_10,led_out,tmpclk,tmpclk0,aclk,ain_m: std_logic;
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal ain: signed(16 downto 0);
	signal ain_u: unsigned(16 downto 0);
	signal sine1: signed(8 downto 0);
	signal tmp_am: signed(26 downto 0);
	signal tmp_am2: unsigned(7 downto 0);
	signal clk_150: std_logic;
begin
	--GPIO_1(0) <= CLOCK_200;
	pll: simple_altera_pll generic map("50 MHz","200 MHz") port map(CLOCK_50,CLOCK_200);
	pll2: simple_altera_pll generic map("50 MHz","10 MHz") port map(CLOCK_50,CLOCK_10);
	pll3: simple_altera_pll generic map("50 MHz","300 MHz") port map(CLOCK_50,CLOCK_300);
	GPIO_1(5 downto 2) <= (others=>(KEY(0) and led_out));
	sc: slow_clock2 generic map(10) port map(CLOCK_200,unsigned(SW),tmpclk0);
	tmpclk <= CLOCK_200 when SW="0000000001" else tmpclk0;
	led_out <= tmpclk and ain_m;
	LEDR <= (others=>led_out);
	
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	ain <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	ain_u <= unsigned(ain)+"10000000000000000" when rising_edge(aclk);
	dsm: deltaSigmaModulator port map(CLOCK_10,ain_u&(14 downto 0=>'0'),ain_m);
	
	--sg: sineGenerator port map(CLOCK_300,to_unsigned(89478485,28),sine1);
	clk_150 <= not clk_150 when rising_edge(CLOCK_200);
	sine1 <= "011111111" when clk_150='1' else "100000001";
	tmp_am <= sine1*signed("0"&ain_u) when rising_edge(CLOCK_200);
	tmp_am2 <= unsigned(tmp_am(25 downto 18))+"10000000" when rising_edge(CLOCK_200);
	
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= '1';
	VGA_R <= tmp_am2;
	VGA_G <= tmp_am2;
	VGA_B <= tmp_am2;
	VGA_CLK <= CLOCK_200;
end architecture;
