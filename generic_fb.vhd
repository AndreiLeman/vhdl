library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity generic_fb is
	generic(burstLength: integer := 16);
	port(
		--configuration
			conf_addrStart: in std_logic_vector(31 downto 0);
			conf_addrEnd: in std_logic_vector(31 downto 0);
			conf_deviceEnable: in std_logic;

		--axi memory mapped master
			aclk,rst: in std_logic;
			arready: in std_logic;
			arvalid: out std_logic;
			araddr: out std_logic_vector(31 downto 0);
			arprot: out std_logic_vector(2 downto 0);
			arlen: out std_logic_vector(7 downto 0);
			
			rvalid: in std_logic;
			rready: out std_logic;
			rdata: in std_logic_vector(63 downto 0);
			
			--unused
			awaddr: out std_logic_vector(31 downto 0);
			awprot: out std_logic_vector(2 downto 0);
			awvalid: out std_logic;
			awready: in std_logic;
			wdata: out std_logic_vector(63 downto 0);
			wlast: out std_logic;
			wvalid: out std_logic;
			wready: in std_logic;
			bvalid: in std_logic;
			bready: out std_logic;
			

		--data output interface
			videoclk,offscreen: in std_logic;
			dataout: out std_logic_vector(31 downto 0)
		);
end entity;
architecture a of generic_fb is
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
	
	constant fifoSize: integer := 512;
	
	constant memAddrWidth: integer := 32;
	constant memWordWidth: integer := 64;
	constant outWordWidth: integer := 32;
	constant addrIncr: integer := burstLength*(memWordWidth/8);
	
	subtype memAddr_t is unsigned(memAddrWidth-1 downto 0);
	subtype memWord_t is std_logic_vector(memWordWidth-1 downto 0);
	subtype outWord_t is std_logic_vector(outWordWidth-1 downto 0);
	
	--fifo signals
	signal fifoWClk,fifoWEn,fifoWFull: std_logic;
	signal fifoWData: memWord_t;
	signal fifoWUsed: std_logic_vector(8 downto 0);
	
	signal fifoRClk,fifoREn,fifoREmpty: std_logic;
	signal fifoRData: outWord_t;
	
	
	--config variables
	signal conf_addrStart1: std_logic_vector(31 downto 0);
	signal conf_addrEnd1: std_logic_vector(31 downto 0);
	signal conf_deviceEnable1: std_logic;
	signal addrStart,addrEnd: memAddr_t;
	signal deviceEnable: std_logic;
	
	--sample 'offscreen' signal into aclk domain
	signal offscreen1: std_logic;
	signal srOffscreen: std_logic_vector(3 downto 0);
	
	--memory fetcher
	signal addr,addrNext: memAddr_t;
	signal doIncr,doIncrNext: std_logic;
	signal doRead,doReadNext,willRead: std_logic;
	signal fetchEnabled, fetchEnabledNext: std_logic;
	signal outstanding,outstandingNext: unsigned(7 downto 0);
begin

	--unused signals
	awaddr <= (others=>'0');
	awprot <= "000";
	awvalid <= '0';
	wdata <= (others=>'0');
	wlast <= '0';
	wvalid <= '0';
	bready <= '1';

	--#########################################################
	--################ configuration variables ################
	conf_addrStart1 <= conf_addrStart when rising_edge(aclk);
	conf_addrEnd1 <= conf_addrEnd when rising_edge(aclk);
	conf_deviceEnable1 <= conf_deviceEnable when rising_edge(aclk);
	
	addrStart <= unsigned(conf_addrStart1) when rising_edge(aclk);
	addrEnd <= unsigned(conf_addrEnd1) when rising_edge(aclk);
	deviceEnable <= conf_deviceEnable1 when rising_edge(aclk);
	

	--delay 'offscreen' by 1 videoclk cycle so that data output side
	--has advance notice
	offscreen1 <= offscreen when rising_edge(videoclk);
	
	--#########################################################
	--################### memory fetch side ###################

	--sample 'offscreen1' into shift register (shift right)
	srOffscreen <= offscreen1 & srOffscreen(3 downto 1) when rising_edge(aclk);
	
	
	--whether fetch is active
	fetchEnabledNext <= '0' when deviceEnable='0'
		else '0' when rst='1'
		else '0' when addr>=(addrEnd-addrIncr) and willRead='1'
		else '1' when srOffscreen(1 downto 0)="10" else fetchEnabled;
	fetchEnabled <= fetchEnabledNext when rising_edge(aclk);

	--calculate address to fetch
	addrNext <= addrStart when fetchEnabled='0'
		else addr+addrIncr when willRead='1'
		else addr;
	addr <= addrNext when rising_edge(aclk);

	--whether to issue fetches
	doReadNext <= '1' when fetchEnabledNext='1' and fifoWFull='0'
		and unsigned(fifoWUsed)<(fifoSize-50)
		and outstanding<32 else '0';
	doRead <= doReadNext when rising_edge(aclk);
	
	--keep track of the number of outstanding words
	outstandingNext <= to_unsigned(0,8) when fetchEnabled='0'
		else outstanding+burstLength-1 when willRead='1' and rvalid='1' and fifoWFull='0'
		else outstanding+burstLength when willRead='1'
		else outstanding-1 when rvalid='1' and fifoWFull='0'
		else outstanding;
	outstanding <= outstandingNext when rising_edge(aclk);

	araddr <= std_logic_vector(addr);
	arprot <= "001";
	arvalid <= doRead;
	arlen <= std_logic_vector(to_unsigned(burstLength-1,8));
	willRead <= doRead and arready;
	
	--#########################################################
	--########### memory response (fifo write) side ###########
	
	fifoWClk <= aclk;
	fifoWEn <= rvalid;
	fifoWData <= rdata;
	rready <= not fifoWFull;
	
	--#########################################################
	--################### data output side ####################
	fifoRClk <= videoclk;
	fifoREn <= not (offscreen and offscreen1);
	dataout <= fifoRData;
	
	--fifo
	mainFifo: component fifo1 port map(wrusedw=>fifoWUsed,
		rdclk=>fifoRClk,rdreq=>fifoREn,q=>fifoRData,
		wrclk=>fifoWClk,wrreq=>fifoWEn,data=>fifoWData,
		rdempty=>fifoREmpty,wrfull=>fifoWFull);
	
end architecture;

