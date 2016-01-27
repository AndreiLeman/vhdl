library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.simple_altera_pll;
entity test3 is
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
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0)
			);
end entity;
architecture a of test3 is
	constant i2ccycles: integer := 56;
	signal io_sdain,io_sdaout,io_scl,io_cmpin: std_logic;
	signal CLOCK_1,CLOCK_4,CLOCK_500k,CLOCK_250k,CLOCK_125k,CLOCK_62k: std_logic;
	signal do_tx,do_tx1,i2cclk1,i2cclk2,i2cclken,i2cclken1,i2cclkout: std_logic;
	signal i2csr,i2csrnext,i2cdata: unsigned(i2ccycles downto 0);
	signal i2ccnt,i2ccntnext: unsigned(15 downto 0);
	signal MD,MD_next: unsigned(17 downto 0);
	signal tmp: unsigned(8 downto 0);
	signal freq_int,freq_int_next,freq_int_d0,freq_int_d1,freq_int_d2: unsigned(9 downto 0);
	signal clockdiv: unsigned(16 downto 0);
	
begin
	pll1: simple_altera_pll generic map("50MHz","1MHz","false") port map(CLOCK_50,CLOCK_1);
	pll2: simple_altera_pll generic map("50MHz","4MHz","false") port map(CLOCK_50,CLOCK_4);
	CLOCK_500k <= not CLOCK_500k when rising_edge(CLOCK_1);
	CLOCK_250k <= not CLOCK_250k when rising_edge(CLOCK_500k);
	CLOCK_125k <= not CLOCK_125k when rising_edge(CLOCK_250k);
	CLOCK_62k <= not CLOCK_62k when rising_edge(CLOCK_125k);
	i2cclk1 <= CLOCK_62k;
	i2cclk2 <= CLOCK_62k when falling_edge(CLOCK_125k);
	clockdiv <= clockdiv+1 when rising_edge(CLOCK_1);
	-- I/O pins
	io_cmpin <= GPIO_1(2);
	io_sdain <= GPIO_1(3);
	GPIO_1(4) <= CLOCK_4;
	GPIO_1(3) <= io_sdaout;
	GPIO_1(5) <= io_scl;
	--tmp <= tmp+1 when rising_edge(GPIO_1(4));
	
	LEDR(0) <= io_cmpin;
	
--	freq_int <= freq_int_next when rising_edge(clockdiv(16));
--	freq_int_next <= freq_int-1 when KEY(3)='0' else
--				freq_int+1 when KEY(2)='0' else
--				freq_int;
--	freq_int_d2 <= freq_int/100;
--	freq_int_d1 <= (freq_int/10) mod 10;
--	freq_int_d0 <= freq_int mod 10;
--	hd1: hexdisplay port map(freq_int_d0(3 downto 0),HEX1);
--	hd2: hexdisplay port map(freq_int_d1(3 downto 0),HEX2);
--	hd3: hexdisplay port map(freq_int_d2(3 downto 0),HEX3);
--	HEX0 <= (others=>'1');
--	HEX4 <= (others=>'1');
--	HEX5 <= (others=>'1');
	
	MD <= MD_next when rising_edge(clockdiv(15));
	MD_next <= MD-16 when KEY(3)='0' else
				MD+16 when KEY(2)='0' else
				MD-1024 when KEY(1)='0' else
				MD+1024 when KEY(0)='0' else
				MD;
	hd1: hexdisplay port map(MD(3 downto 0),HEX1);
	hd2: hexdisplay port map(MD(7 downto 4),HEX2);
	hd3: hexdisplay port map(MD(11 downto 8),HEX3);
	hd4: hexdisplay port map(MD(15 downto 12),HEX4);
	hd5: hexdisplay port map("00"&MD(17 downto 16),HEX5);
	HEX0 <= (others=>'1');
	
	--LEDR(9 downto 1) <= std_logic_vector(tmp);
	io_scl <= i2cclkout;
	io_sdaout <= i2csr(i2ccycles);
	
	-- cfg
	--MD <= (1 downto 0=>'0') & (freq_int*to_unsigned(10,4)) & (1 downto 0=>'0');
	
	--						ADDR		R		SUBADDR
	i2cdata <= "10" & "110001000" & "000010000" &
	--		A					B
			"001000010" & "101100" & MD(17)&MD(16) & "0" &
	--		C								D
			MD(15 downto 8)&"0" & MD(7 downto 0)&"0"
	--		stop bit
			&"0";
	do_tx <= clockdiv(16) when rising_edge(i2cclk1);
	
	-- i2c shift register
	do_tx1 <= do_tx when rising_edge(i2cclk1);
	i2csr <= i2csrnext when falling_edge(i2cclk2);
	i2csrnext <= i2cdata when do_tx1='0' else i2csr(i2ccycles-1 downto 0)&'1';
	i2ccnt <= i2ccntnext when rising_edge(i2cclk1);
	i2ccntnext <= X"0000" when do_tx='0' else
		i2ccnt when i2ccnt=i2ccycles else
		i2ccnt+1;
	i2cclken <= '0' when i2ccnt=X"0000" or i2ccnt=i2ccycles else '1';
	i2cclken1 <= i2cclken when rising_edge(i2cclk1);
	i2cclkout <= (not i2cclken1) or i2cclk1;
	
end architecture;
