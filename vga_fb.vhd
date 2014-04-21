library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_out2;
use work.graphics_types.all;
use work.synchronizer;

--register map:
--[31..0]	fb_addr
--[47..32]	width
--[63..48]	height
--[127..64]	misc:
--		[9..0]	h_predelay (pixels)
--		[19..10]	h_postdelay
--		[29..20]	h_duration
--		[39..30]	v_predelay (lines)
--		[49..40]	v_postdelay
--		[59..50]	v_duration
--		[60]		chip enable
--output conduit:
--[31..0]	cur_position
--		[15..0]	x
--		[31..16]	y
--[59..32]	vgadata:
--		[7..0]	R
--		[15..8]	G
--		[23..16]	B
--		[24]		blank
--		[25]		hsync
--		[26]		vsync
--		[27]		clock
--[128]		fb refresh enable
entity vga_fb is
	port(addr: out std_logic_vector(31 downto 0);
			read: out std_logic;
			readdata: in std_logic_vector(63 downto 0);
			waitrequest,clk,vclk,readdatavalid: in std_logic;
			burstcount: out std_logic_vector(5 downto 0);
			real_rst: in std_logic;
			conf: in std_logic_vector(128 downto 0);
			conf_clk: in std_logic;
			vga: out std_logic_vector(59 downto 0));
end entity;
architecture a of vga_fb is
	component fifo1
		PORT
		(
			aclr		: IN STD_LOGIC  := '0';
			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdempty		: OUT STD_LOGIC ;
			wrfull		: OUT STD_LOGIC ;
			wrusedw		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	end component;
	signal state,ns,previous_state: std_logic := '0';
	signal next_read: std_logic;
	signal a,next_a: unsigned(31 downto 0) := to_unsigned(0,32);
	signal wrusedw: std_logic_vector(8 downto 0);
	signal outstanding1,next_outstanding1,outstanding2,next_outstanding2,
		outstanding: unsigned(7 downto 0);
	signal read0: std_logic;
	signal totalqueued: unsigned(8 downto 0);
	signal should_submit,should_submit1: std_logic;
	signal rst1,rst2,aclr: std_logic;
	signal wr_en: std_logic;
	signal wr_data: std_logic_vector(63 downto 0);
	constant fifo_depth: integer := 512;
	constant burstc: integer := 16;
	
	signal fifo_q,fifo_q1: std_logic_vector(31 downto 0);
	signal p: position;
	signal fifo_rd_en,rst: std_logic;
	signal a_overflow: std_logic;
	signal a_end: unsigned(31 downto 0) := to_unsigned(0,32);
	
	signal conf_w,conf_h: unsigned(11 downto 0);
	signal conf_addr,fbsize: unsigned(31 downto 0);
	signal fbsize0: unsigned(47 downto 0);
	signal conf_misc: unsigned(63 downto 0);
	signal syn1in,syn1out: std_logic_vector(63 downto 0);
	
	signal chip_en: std_logic := '0';
	
	signal vgadata: std_logic_vector(27 downto 0);
begin
	chip_en <= conf(124) when rising_edge(clk);
	conf_w <= unsigned(conf(43 downto 32));
	conf_h <= unsigned(conf(59 downto 48));
	conf_misc <= unsigned(conf(127 downto 64));
	fbsize0 <= conf_w*conf_h*4;
	
	syn1in <= std_logic_vector(fbsize0(31 downto 0)) & conf(31 downto 0);
	conf_addr <= unsigned(syn1out(31 downto 0));
	fbsize <= unsigned(syn1out(63 downto 32));
	syn: synchronizer generic map(64) port map(conf_clk,clk,syn1in,syn1out);
	a_end <= conf_addr+fbsize when rst2='1' and rising_edge(clk);

	vga_timer: vga_out2 generic map(syncdelay=>3)
		port map(vgadata(24),vgadata(26),vgadata(25),vclk,p,conf_w,conf_h,
			conf_misc(9 downto 0),conf_misc(19 downto 10),conf_misc(29 downto 20),
			conf_misc(39 downto 30),conf_misc(49 downto 40),conf_misc(59 downto 50));
	rst <= '1' when p(1)=conf_h and rising_edge(vclk) else
		'0' when rising_edge(vclk);
	fifo_rd_en <= '1' when p(1)<conf_h and p(0)<conf_w and conf(128)='1' else '0';
	fifo_q1 <= fifo_q when rising_edge(vclk);
	vgadata(23 downto 0) <= fifo_q1(23 downto 0);
	vgadata(27) <= vclk;
	vga(59 downto 32) <= vgadata;
	vga(31 downto 0) <= "0000"&std_logic_vector(p(1))&"0000"&std_logic_vector(p(0))
		when rising_edge(vclk);

	rst1 <= rst when rising_edge(clk);
	rst2 <= rst1 or real_rst when rising_edge(clk);
	previous_state <= state when rising_edge(clk);
	addr <= std_logic_vector(a);
	next_a <= conf_addr when rst2='1' or a+8*burstc>=a_end else
		a+8*burstc;
	a <= conf_addr when rst2='1' else next_a when falling_edge(state);
	a_overflow <= '1' when a>a_end else '0';
	
	
	burstcount <= std_logic_vector(to_unsigned(burstc,6));
	
	totalqueued <= (unsigned(wrusedw))+("0"&outstanding) when rising_edge(clk);
	should_submit <= '1' when totalqueued<(fifo_depth-50) else '0';
	should_submit1 <= should_submit when rising_edge(clk);
	state <= ns when rising_edge(clk);
	ns <= '0' when rst2='1' or chip_en='0' else
			should_submit1 when state='0' else
			waitrequest;
	read0 <= state;
	read <= read0;

	outstanding <= outstanding1+outstanding2;
	outstanding1 <= next_outstanding1 when rising_edge(clk);
	next_outstanding1 <= to_unsigned(0,8) when rst2='1' else
		outstanding1+burstc when previous_state='0' and state='1' else outstanding1;
	
	outstanding2 <= next_outstanding2 when rising_edge(clk);
	next_outstanding2 <= to_unsigned(0,8) when rst2='1' else
		outstanding2-1 when wr_en='1' else outstanding2;

	wr_en <= readdatavalid when rising_edge(clk);
	wr_data <= readdata when rising_edge(clk);
	f: fifo1 port map(data=>wr_data,rdclk=>vclk,rdreq=>fifo_rd_en,wrclk=>clk,
		wrreq=>wr_en,q=>fifo_q,wrusedw=>wrusedw,aclr=>aclr);
	aclr <= rst2;
end architecture;

