library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
--conf register map:
--[2..0]		flags
--		[0]		chip enable
--[31..3]	base address (in 8-byte words)
--[63..35]	end address (in 8-byte words)

--info register map:
--[31..0]	current address

entity stream2hps2 is
	port(
			--avalon master
			addr: out std_logic_vector(31 downto 0);
			write: out std_logic;
			writedata: out std_logic_vector(63 downto 0);
			waitrequest,clk: in std_logic;
			burstcount: out std_logic_vector(5 downto 0);
			--interrupts (rising_edge)
			int0: out std_logic;
			--reset & disable device; reset is synchronous to confclk
			reset: in std_logic;
			--configuration & info conduit; see documentation above
			conf: in std_logic_vector(63 downto 0);
			info: out std_logic_vector(31 downto 0);
			confclk: in std_logic;
			--data input
			datain: in std_logic_vector(63 downto 0);
			dataclk: in std_logic);
end entity;
architecture a of stream2hps2 is
	constant WORDSIZE: integer := 8;
	constant WORDSIZE_ORDER: integer := 3;
	constant WORDBITS: integer := WORDSIZE*8;
	constant FIFOSIZE_ORDER: integer := 7;
	constant FIFOSIZE: integer := 127;	--ensure this is equal to 2^FIFOSIZE_ORDER-1
	constant BURSTSIZE_ORDER: integer := 4;
	constant BURSTSIZE: integer := 16;	-- ensure this is equal to 2^BURSTSIZE_ORDER
	constant ALIGNMENT_ORDER: integer := BURSTSIZE_ORDER+WORDSIZE_ORDER;
	component dcfifo
		generic (
			add_ram_output_register	:	string := "OFF";
			add_usedw_msb_bit	:	string := "OFF";
			clocks_are_synchronized	:	string := "FALSE";
			delay_rdusedw	:	natural := 1;
			delay_wrusedw	:	natural := 1;
			intended_device_family	:	string := "unused";
			lpm_numwords	:	natural;
			lpm_showahead	:	string := "OFF";
			lpm_width	:	natural;
			lpm_widthu	:	natural := 1;
			overflow_checking	:	string := "ON";
			rdsync_delaypipe	:	natural := 0;
			read_aclr_synch	:	string := "OFF";
			underflow_checking	:	string := "ON";
			use_eab	:	string := "ON";
			write_aclr_synch	:	string := "OFF";
			wrsync_delaypipe	:	natural := 0;
			lpm_hint	:	string := "UNUSED";
			lpm_type	:	string := "dcfifo"
		);
		port(
			aclr	:	in std_logic := '0';
			data	:	in std_logic_vector(lpm_width-1 downto 0);
			q	:	out std_logic_vector(lpm_width-1 downto 0);
			rdclk	:	in std_logic;
			rdempty	:	out std_logic;
			rdfull	:	out std_logic;
			rdreq	:	in std_logic;
			rdusedw	:	out std_logic_vector(lpm_widthu-1 downto 0);
			wrclk	:	in std_logic;
			wrempty	:	out std_logic;
			wrfull	:	out std_logic;
			wrreq	:	in std_logic;
			wrusedw	:	out std_logic_vector(lpm_widthu-1 downto 0)
		);
	end component;
	--config data
	signal cfg_baseAddr,cfg_endAddr: unsigned(31 downto 0);
	signal cfg_chipEnable: std_logic;
	signal baseAddr,endAddr: unsigned(31 downto ALIGNMENT_ORDER);
	signal prevChipEnable,chipEnable,chipEnable_1,chipEnable_2,chipEnable_3: std_logic;
	
	signal info1: std_logic_vector(31 downto 0);
	--interrupt generation
	signal midAddr: unsigned(31 downto ALIGNMENT_ORDER);
	signal int01,int02,doInterrupt0,fireInterrupt0: std_logic;
	--fifo signals
	signal fifo_datain,fifo_dataout: std_logic_vector(WORDBITS-1 downto 0);
	signal fifo_rdclk,fifo_wrclk,fifo_almostempty,fifo_rdreq,
		fifo_rdempty,fifo_rdfull,fifo_rdempty1,fifo_rdfull1: std_logic;
	signal fifo_rdusedw,fifo_rdusedw1: std_logic_vector(FIFOSIZE_ORDER-1 downto 0);
	--avalon state machine
	type stateType is (stop,start,writing);
	signal state: stateType := stop;
	signal stateNext: stateType;
	signal shouldStartTransfer,wrapAround: std_logic;
	signal cnt,cntNext: unsigned(5 downto 0); --burst counter
	signal canRead,canReadNext: std_logic;
	signal sampleAddrs: std_logic; --whether to sample configured addresses
	--counters below are in units of bursts (burstsize*wordsize bytes)
	signal curAddr,curAddrNext,curAddrP1,curAddrP1Next: unsigned(31 downto ALIGNMENT_ORDER);
begin
	--configs
	--extract address aligned to burst size
	cfg_baseAddr <= unsigned(conf(31 downto 3))&"000";
	cfg_endAddr <= unsigned(conf(63 downto 32+3))&"000";
	cfg_chipEnable <= conf(0);
	
	baseAddr <= cfg_baseAddr(31 downto ALIGNMENT_ORDER) when rising_edge(clk);
	endAddr <= cfg_endAddr(31 downto ALIGNMENT_ORDER) when sampleAddrs='1' and rising_edge(clk);
	midAddr <= ("0"&baseAddr(31 downto ALIGNMENT_ORDER+1))
					+("0"&endAddr(31 downto ALIGNMENT_ORDER+1)) when rising_edge(clk);
	
	chipEnable_3 <= cfg_chipEnable when rising_edge(clk);
	chipEnable_2 <= chipEnable_3 when rising_edge(clk);
	chipEnable_1 <= chipEnable_2 when rising_edge(clk);
	chipEnable <= chipEnable_1 when rising_edge(clk);
	prevChipEnable <= chipEnable when rising_edge(clk);
	
	--info output
	info1 <= std_logic_vector(curAddr&(ALIGNMENT_ORDER-1 downto 0=>'0')) when rising_edge(confclk);
	info <= info1 when rising_edge(confclk);
	
	--interrupt output
	int02 <= fireInterrupt0 when rising_edge(clk);
	int01 <= int02 when rising_edge(clk);
	int0 <= int01 or int02 when rising_edge(clk);
	
	--fifo
	fifo: dcfifo generic map(lpm_width=>WORDBITS,lpm_widthu=>FIFOSIZE_ORDER,
			lpm_numwords=>FIFOSIZE,lpm_showahead=>"on",
			overflow_checking=>"on",rdsync_delaypipe=>5,wrsync_delaypipe=>5)
		port map(data=>fifo_datain,q=>fifo_dataout,rdclk=>fifo_rdclk,
			rdempty=>fifo_rdempty1,rdfull=>fifo_rdfull1,rdusedw=>fifo_rdusedw1,rdreq=>fifo_rdreq,
			wrclk=>fifo_wrclk,wrreq=>'1');
	
	
	--input side
	fifo_datain <= datain;
	fifo_wrclk <= dataclk;
	
	--output side
	fifo_rdempty <= fifo_rdempty1 when rising_edge(clk);
	fifo_rdfull <= fifo_rdfull1 when rising_edge(clk);
	fifo_rdusedw <= fifo_rdusedw1 when rising_edge(clk);
	fifo_almostempty <= '1' when (unsigned(fifo_rdusedw)<=(BURSTSIZE+5) or fifo_rdempty='1')
		and fifo_rdfull='0'
		and rising_edge(clk) else '0' when rising_edge(clk);
	
	burstcount <= std_logic_vector(to_unsigned(BURSTSIZE,6));
	writedata <= fifo_dataout;
	fifo_rdclk <= clk;
	
	--state machine
	shouldStartTransfer <= chipEnable and (not fifo_almostempty) when rising_edge(clk);
	wrapAround <= '1' when curAddrP1=endAddr else '0';
	canReadNext <= '1' when (stateNext/=stop) else '0';
	fifo_rdreq <= '1' when canRead='1' and waitrequest='0' else '0';
	
	-- delay by one cycle; when doInterrupt0='1', that means in the PREVIOUS cycle
	-- curAddr+1=endAddr or curAddr+1=midAddr
	--doInterrupt0 <= '1' when (curAddrP1=endAddr or curAddrP1=midAddr)
	--	and state=writing and rising_edge(clk) else '0' when rising_edge(clk);
	--fireInterrupt0 <= '1' when doInterrupt0='1' and state/=writing else '0';
	fireInterrupt0 <= doInterrupt0 when rising_edge(clk);
	sampleAddrs <= doInterrupt0;
	process(state,shouldStartTransfer,wrapAround,waitrequest,curAddrP1,curAddr,
			cnt,baseAddr)
	begin
		if state=stop then
			doInterrupt0 <= chipEnable and not prevChipEnable;
			if shouldStartTransfer='1' then
				stateNext <= start;
			else
				stateNext <= stop;
			end if;
			if chipEnable='1' then
				curAddrNext <= curAddr;
				curAddrP1Next <= curAddr+1;
			else
				curAddrNext <= baseAddr;
				curAddrP1Next <= baseAddr+1;
			end if;
			write <= '0';
			cntNext <= to_unsigned(1,6);
		elsif state=start then
			doInterrupt0 <= '0';
			if waitrequest='1' then
				--hold everything constant
				stateNext <= state;
			else
				stateNext <= writing;
			end if;
			cntNext <= to_unsigned(2,6);
			curAddrNext <= curAddr;
			curAddrP1Next <= curAddr+1;
			write <= '1';
		else --state=writing
			if waitrequest='1' then
				doInterrupt0 <= '0';
				--hold everything constant
				stateNext <= state;
				cntNext <= cnt;
				curAddrNext <= curAddr;
				curAddrP1Next <= curAddr+1;
			else
				cntNext <= cnt+1;
				if cnt=BURSTSIZE then
					doInterrupt0 <= wrapAround;
					--this is the last word of this burst
					if shouldStartTransfer='1' then
						stateNext <= start;
					else
						stateNext <= stop;
					end if;
					if wrapAround='0' then
						curAddrNext <= curAddrP1;
						curAddrP1Next <= curAddr+2;
					else
						curAddrNext <= baseAddr;
						curAddrP1Next <= baseAddr+1;
					end if;
				else
					doInterrupt0 <= '0';
					stateNext <= state;
					curAddrNext <= curAddr;
					curAddrP1Next <= curAddr+1;
				end if;
			end if;
			write <= '1';
		end if;
	end process;
	--flip-flops
	state <= stateNext when rising_edge(clk);
	cnt <= cntNext when rising_edge(clk);
	curAddr <= curAddrNext when rising_edge(clk);
	curAddrP1 <= curAddrP1Next when rising_edge(clk);
	addr <= std_logic_vector(curAddr)&(ALIGNMENT_ORDER-1 downto 0=>'0');
	canRead <= canReadNext when rising_edge(clk);
end architecture;

