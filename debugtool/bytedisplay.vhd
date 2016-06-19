library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay_custom;
use work.debugtool_queue;
use work.dupremover;

-- displays first N bytes of received data, with user navigation
entity debugtool_bytedisplay is
port(hex_scl,hex_cs,hex_sdi: out std_logic;
	uiclk: in std_logic; -- apply any ~1MHz clock
	button: in std_logic;	-- synchronized to dataclk
	dataclk,datavalid: in std_logic;
	data: in unsigned(7 downto 0);
	dot1,dot0: in std_logic := '0';
	full: out std_logic := 'X';
	isWriting: out std_logic := 'X');
end entity;

architecture a of debugtool_bytedisplay is
	constant datalen: integer := 10;
	constant hexcount: integer := 4;
	constant hexbitcount: integer := hexcount*8;
	constant use_queue: boolean := true;
	
	signal flashclk_div: unsigned(9 downto 0);
	signal flashclk: std_logic;
	
	signal capturing,capturingNext: std_logic;
	
	type HEXArray4x8 is array(3 downto 0) of std_logic_vector(7 downto 0);
	subtype HEXBitstream is std_logic_vector(hexbitcount-1 downto 0);
	
	--hex output
	signal hex,hexbytes: HEXArray4x8;
	signal hex_b,hex_sr,hex_sr_next: HEXBitstream;
	signal hex_sr_counter: unsigned(4 downto 0);
	
	signal combineddata: unsigned(datalen-1 downto 0);
	--after duplicate detection
	signal writeprev: std_logic;
	signal dupcount: unsigned(7 downto 0);
	signal realdata,displaydata: std_logic_vector(datalen+8-1 downto 0); --isdup bit & data
	signal realdatavalid: std_logic;
	--control logic
	signal latched,latchedNext: std_logic := '0';
	signal queueWritable: std_logic;
	
	signal hex_cs1: std_logic;
	signal tmp: unsigned(3 downto 0);
	signal tmp1: std_logic_vector(3 downto 0);
begin
	--hex unpack
g: for I in 0 to hexcount-1 generate
		hex_b((I+1)*8-1 downto I*8) <= hex(I);
	end generate;
	--hex serial output
	hex_sr_counter <= hex_sr_counter+1 when rising_edge(uiclk);
	hex_sr_next <= hex_b when hex_sr_counter="00000"
		else "0"&hex_sr(hexbitcount-1 downto 1);
	hex_sr <= hex_sr_next when rising_edge(uiclk);
	hex_scl <= not uiclk;
	hex_sdi <= hex_sr(0);
	hex_cs1 <= '1' when hex_sr_counter="00000" else '0';
	hex_cs <= hex_cs1 when rising_edge(uiclk);
	
	combineddata <= dot1&dot0&data;
	dr: entity work.dupremover generic map(datalen)
		port map(dataclk,datavalid and capturing,realdatavalid,
			std_logic_vector(combineddata),realdata(datalen-1 downto 0),dupcount);
	realdata(datalen+8-1 downto datalen) <= std_logic_vector(dupcount);
	writeprev <= '1' when dupcount/=0 else '0';
	isWriting <= realdatavalid and not writeprev when rising_edge(dataclk);
	
	capturingNext <= '1' when latched='0' else
		'0' when queueWritable='0' else capturing;
	capturing <= capturingNext when rising_edge(dataclk);
g1:
	if use_queue generate
		que: entity debugtool_queue generic map(datalen+8,9)
			port map(dataclk,button,realdatavalid,latched,queueWritable,
				std_logic_vector(realdata),displaydata,writeprev=>writeprev);
		full <= not queueWritable;
	end generate;
--g2:
--	if not use_queue generate
--		displaydata <= realdata when realdatavalid='1' and latched='0' and rising_edge(dataclk);
--		latchedNext <= '1' when realdatavalid='1' else
--			'0' when button='1' else latched;
--		latched <= latchedNext when rising_edge(dataclk);
--		full <= latched;
--	end generate;
	
	--ui
	flashclk_div <= flashclk_div+1 when rising_edge(uiclk);
	flashclk <= flashclk_div(9);
	
	
	hd3: entity hexdisplay_custom port map(unsigned(displaydata(7 downto 4)),
		hexbytes(3), displaydata(9));
	hd2: entity hexdisplay_custom port map(unsigned(displaydata(3 downto 0)),
		hexbytes(2), displaydata(8));
	hd1: entity hexdisplay_custom port map(unsigned(displaydata(17 downto 14)),
		hexbytes(1));
	hd0: entity hexdisplay_custom port map(unsigned(displaydata(13 downto 10)),
		hexbytes(0));
	
	hex <= hexbytes when latched='1' else ("01000000","01000000","01000000","01000000");
end architecture;
