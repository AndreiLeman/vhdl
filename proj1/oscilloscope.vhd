
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out;
use work.AudioSubSystemMono;
use work.osc_ram;
use work.counter;
entity oscilloscope is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			CLOCK_50: in std_logic);
end entity;
architecture a of oscilloscope is
	component pll_65 is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component pll_65;
	constant W: integer := 1280;
	constant H: integer := 1024;
	signal clk: std_logic;
	signal x,y: unsigned(11 downto 0);
	type pixel is array(0 to 2) of unsigned(7 downto 0);
	signal p,p1: pixel;
	
	signal real_ain,ain,ain1,aout: std_logic_vector(47 downto 0);
	signal monoin: signed(23 downto 0);
	signal monoin1: signed(14 downto 0);
	signal rec_in,rec_in1,rec_in2: unsigned(11 downto 0);
	signal aclk: std_logic;
	signal rd_addr,wr_addr: unsigned(11 downto 0);
	signal ram_d,ram_q: std_logic_vector(23 downto 0);
	
	signal do_sample_waddr,do_sample_waddr1: std_logic;
	signal raddr_base: unsigned(11 downto 0);
	signal q1,q2: unsigned(11 downto 0);
	signal cntval: unsigned(19 downto 0);
	signal nextpixel,nextpixel1,nextpixel2: std_logic;
	signal cur_max,next_max,cur_min,next_min: unsigned(11 downto 0);
begin
	pll: component pll_65 port map(refclk=>CLOCK_50,outclk_0=>clk);
	vga_timer: vga_out generic map(W=>W,H=>H,syncdelay=>3)
		port map(VGA_SYNC_N=>VGA_SYNC_N,VGA_BLANK_N=>VGA_BLANK_N,
		VGA_VS=>VGA_VS,VGA_HS=>VGA_HS,clk=>clk,cx=>x,cy=>y);
	VGA_CLK <= clk;
	VGA_R <= p(0) when falling_edge(clk);
	VGA_G <= p(1) when falling_edge(clk);
	VGA_B <= p(2) when falling_edge(clk);
	p <= p1 when rising_edge(clk);
	
	audio1: AudioSubSystemMono port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),RawIn=>real_ain,
			RawOut=>aout,MonoIn=>monoin,SamClk=>aclk);
	ain1 <= real_ain when rising_edge(aclk);
	--ain(63 downto 32) <= (3 downto 0=>ain1(63)) & ain1(63 downto 36);
	--ain(31 downto 0) <= (3 downto 0=>ain1(31)) & ain1(31 downto 4);
	ain <= ain1;
	aout <= ain;
	
	cnt: counter generic map(N=>20,max=>245) port map(clk=>aclk,outp=>cntval);
	nextpixel <= '1' when cntval=to_unsigned(0,20) else '0';
	nextpixel1 <= nextpixel when rising_edge(aclk);
	nextpixel2 <= nextpixel1 when falling_edge(aclk);
	
	cur_max <= next_max when rising_edge(aclk);
	cur_min <= next_min when rising_edge(aclk);
	next_max <= rec_in1 when rec_in1>cur_max or nextpixel1='1' else cur_max;
	next_min <= rec_in1 when rec_in1<cur_min or nextpixel1='1' else cur_min;
	
	monoin1 <= monoin(23 downto 9);
	rec_in <= to_unsigned(0,12) when monoin1>0 and unsigned(monoin1)>H/2 else
		to_unsigned(H-1,12) when monoin1<0 and unsigned(-monoin1)>H/2 else
		H/2+unsigned(-monoin1(11 downto 0));
	rec_in1 <= rec_in when rising_edge(aclk);
	--rec_in2 <= rec_in1 when rising_edge(aclk);
	--ram_d(11 downto 0) <= std_logic_vector(rec_in1) when rec_in1<rec_in2 else std_logic_vector(rec_in2);
	--ram_d(23 downto 12) <= std_logic_vector(rec_in1) when rec_in1>rec_in2 else std_logic_vector(rec_in2);
	ram_d <= std_logic_vector(cur_max) & std_logic_vector(cur_min);
	wr_addr <= wr_addr+1 when rising_edge(nextpixel2);
	mem: osc_ram port map(wrclock=>nextpixel2,wraddress=>std_logic_vector(wr_addr),
		data=>std_logic_vector(ram_d),wren=>'1',
		rdaddress=>std_logic_vector(rd_addr),rdclock=>clk,q=>ram_q);
	
	do_sample_waddr1 <= '1' when y=H-1 and x=W-2 else '0';
	do_sample_waddr <= do_sample_waddr1 when rising_edge(clk);
	raddr_base <= wr_addr-W when rising_edge(do_sample_waddr);
	--addr input of ram is already registered
	rd_addr <= x+raddr_base;-- when rising_edge(clk);
	
	q1 <= unsigned(ram_q(11 downto 0));
	q2 <= unsigned(ram_q(23 downto 12));
	
	p(1) <= X"ff" when (y>=q1 and y<=q2) or y=H/2 else X"00";
	--p(0) <= X"ff" when signed(ram_q(11 downto 0))=(H/2)-signed(y) else X"00";
	p(2) <= p(1);
	p(0) <= X"ff" when y=H/2 else X"00";
end architecture;

