library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity memread is
	port(addr: out std_logic_vector(31 downto 0);
			read: out std_logic;
			readdata: in std_logic_vector(63 downto 0);
			waitrequest,clk,rst,rdclk,rd_en,readdatavalid: in std_logic;
			burstcount: out std_logic_vector(5 downto 0);
			fake_rst: in std_logic;
			conduit1: in std_logic_vector(31 downto 0);
			conduit2: out std_logic_vector(31 downto 0));
end entity;
architecture a of memread is
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
	signal wrreq,wrfull: std_logic;
	signal a,next_a: unsigned(31 downto 0);
	signal wrusedw: std_logic_vector(8 downto 0);
	signal outstanding1,next_outstanding1,outstanding2,next_outstanding2,
		outstanding: unsigned(7 downto 0);
	signal read0: std_logic;
	signal totalqueued: unsigned(8 downto 0);
	signal should_submit: std_logic;
	signal rst1,rst2,aclr: std_logic;
	signal wr_en: std_logic;
	signal wr_data: std_logic_vector(63 downto 0);
	constant fifo_depth: integer := 512;
	constant burstc: integer := 16;
begin
	rst1 <= rst when rising_edge(clk);
	rst2 <= rst1 when rising_edge(clk);
	state <= ns when rising_edge(clk);
	previous_state <= state when rising_edge(clk);
	addr <= std_logic_vector(a);
	next_a <= unsigned(conduit1) when rst2='1' else
		a+8*burstc*128 when previous_state='0' and state='1' else a;
	a <= next_a when rising_edge(clk);
	burstcount <= std_logic_vector(to_unsigned(burstc,6));
	
	
	totalqueued <= (unsigned(wrusedw))+("0"&outstanding) when rising_edge(clk);
	should_submit <= '1' when totalqueued<(fifo_depth-50) else '0';
	ns <= '0' when rst2='1' else
			should_submit when state='0' else
			waitrequest;
	next_read <= ns;
	read0 <= next_read when rising_edge(clk);
	read <= read0;
	
	outstanding <= outstanding1+outstanding2;
	outstanding1 <= next_outstanding1 when rising_edge(clk);
	next_outstanding1 <= to_unsigned(0,8) when rst2='1' else
		outstanding1+burstc when previous_state='0' and state='1' else outstanding1;
	
	outstanding2 <= next_outstanding2 when rising_edge(clk);
	next_outstanding2 <= to_unsigned(0,8) when rst2='1' else
		outstanding2-1 when wr_en='1' else outstanding2;
	--conduit2 <= readdata when ns='0' and rising_edge(clk);
	--wrreq <= '1' when state='1' and waitrequest='0' else '0';
	wr_en <= readdatavalid when rising_edge(clk);
	wr_data <= readdata when rising_edge(clk);
	f: fifo1 port map(data=>wr_data,rdclk=>rdclk,rdreq=>(rd_en and not rst),wrclk=>clk,
		wrreq=>wr_en,q=>conduit2,wrfull=>wrfull,wrusedw=>wrusedw,aclr=>aclr);
	aclr <= rst2;
end architecture;

