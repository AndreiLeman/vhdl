library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.graphics_types.all;
use work.sr_unsigned;
entity ili9327Out is
	generic(pixeldelay: integer := 3);
    port(clk: in std_logic;
		p: out position;	--registered
		offscreen: out std_logic;	--registered; 1 if currently in offscreen area
		pixel: in color;	--unregistered
		
		--device signals
		lcd_rs,lcd_wr_n: out std_logic;
		lcd_data: out unsigned(15 downto 0));
end entity;
architecture a of ili9327Out is
	constant lcdCmdCount: integer := 12;
	constant W: integer := 320;
	constant H: integer := 240;
	constant lcdAddrMax: integer := lcdCmdCount+W*H-1;
	constant addrBits: integer := 17;
	--the lcdAddr at which the x and y counter will be reset to 0
	-- (at the next clock cycle)
	constant startAddr: integer := lcdCmdCount-1;

	--keep track of state
	signal lcdClk,lcdIsReplayingRom: std_logic;
	signal lcdAddr,lcdAddrNext,lcdDelayedAddr,lcdDelayedAddr1: unsigned(addrBits-1 downto 0);
	signal curX,curY,nextX,nextY: unsigned(8 downto 0);
	signal offscreen1: std_logic;
	
	signal color,colorNext: unsigned(15 downto 0);
	
	--roms
	type rom1_t is array(0 to 15) of unsigned(8 downto 0);
	signal lcdRomsAddr: unsigned(3 downto 0);
	signal lcdRom: rom1_t;
	signal lcdRomData: unsigned(8 downto 0);
	signal lcdRomDData: unsigned(7 downto 0);
	signal lcdRomRSData: std_logic;
	
	--intermediate outputs
	signal pixelData: unsigned(15 downto 0);
	signal lcdOutData: unsigned(15 downto 0);
	signal lcdOutRS: std_logic;
begin
	lcdClk <= clk;
	
	-- rom for the RS and data pins; MSB is RS pin.
	lcdRom <= (
		"0" & X"11",					--exit sleep
		"0" & X"29",					--enable display
		
		"0" & X"3A",					--set pixel format
		"1" & "01010101",				--16 bits per pixel
		
		"0" & X"36",					--set address mode
		"1" & "00100000",				--x/y reversed
		
		"0" & X"2A",					--set column address
		"1" & X"00",					-- (start address 1/2)
		"1" & X"00",					-- (start address 2/2)
		"1" & X"01",					-- (end address 1/2)
		"1" & X"AF",					-- (end address 2/2)
		
		"0" & X"2C",					--write GRAM

		"1" & X"00",
		"1" & X"00",
		"1" & X"00",
		"1" & X"00"
	);
	
	lcdAddrNext <= to_unsigned(0,addrBits) when lcdAddr=lcdAddrMax
		else lcdAddr+1;
	lcdAddr <= lcdAddrNext when rising_edge(lcdclk);

	--keep track of position
	offscreen1 <= '1' when lcdAddr<startAddr else '0';
	nextX <= to_unsigned(0,9) when lcdAddr=startAddr
		else to_unsigned(0,9) when curX=(W-1) else curX+1;
	nextY <= to_unsigned(0,9) when lcdAddr=startAddr
		else curY+1 when curX=(W-1) else curY;
	
	offscreen <= offscreen1 when rising_edge(lcdClk);
	curX <= nextX when rising_edge(lcdClk);
	curY <= nextY when rising_edge(lcdClk);
	p <= ("000"&curX, "000"&curY);
	
	--delay state variable by pixeldelay cycles
	sr1: entity sr_unsigned generic map(bits=>addrBits,len=>pixeldelay)
		port map(clk=>lcdClk,din=>lcdAddr,dout=>lcdDelayedAddr);
	
	-- read from command roms
	lcdRomsAddr <= lcdDelayedAddr(3 downto 0);
	lcdRomData <= lcdRom(to_integer(lcdRomsAddr)) when rising_edge(lcdClk);
	lcdRomRSData <= lcdRomData(8);
	lcdRomDData <= lcdRomData(7 downto 0);

	-- synchronized to lcdRom[*]Data
	lcdDelayedAddr1 <= lcdDelayedAddr when rising_edge(lcdclk);
	lcdIsReplayingRom <= '1' when lcdDelayedAddr1<lcdCmdCount else '0';
	
	pixelData <= pixel(2)(7 downto 3) & pixel(1)(7 downto 2) & pixel(0)(7 downto 3)
		when rising_edge(lcdClk);
	lcdOutData <= X"00" & lcdRomDData when lcdIsReplayingRom='1' else pixelData;
	lcdOutRS <= lcdRomRSData when lcdIsReplayingRom='1' else '1';
	
	--outputs
	lcd_wr_n <= lcdClk;
	lcd_rs <= lcdOutRs when rising_edge(lcdClk);
	lcd_data <= lcdOutData when rising_edge(lcdClk);
end a;
