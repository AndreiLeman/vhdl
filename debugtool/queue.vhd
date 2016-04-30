library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
--single clock show-ahead queue with overflow detection
-- - to read from queue, whenever the queue is not empty,
--		readvalid will be asserted and data will be present on
--		rdata; to dequeue, assert readnext for one clock cycle
-- - to append to queue, put data on wdata and assert writeen
-- READ DELAY: 1 cycle (from readnext being asserted to next word
--		present on dataout)
-- 
entity debugtool_queue is
	generic(width: integer := 8;
				-- real depth is 2^depth_order
				depth_order: integer := 9);
	port(clk,readnext,writeen: in std_logic;
			readvalid,writefull: out std_logic;
			wdata: in std_logic_vector(width-1 downto 0);
			rdata: out std_logic_vector(width-1 downto 0);
			writeprev: in std_logic := '0');
end entity;
architecture a of debugtool_queue is
	constant depth: integer := 2**depth_order;
	
	--ram
	type ram1t is array(depth-1 downto 0) of
		std_logic_vector(width-1 downto 0);
	signal ram1: ram1t;
	signal ram1raddr,ram1waddr: unsigned(depth_order-1 downto 0);
	signal ram1wdata,ram1q: std_logic_vector(width-1 downto 0);
	signal ram1wen: std_logic;
	--queue logic
	signal rpos,wpos,wpos_prev,rposNext,wposNext: unsigned(depth_order-1 downto 0);
	signal full,empty,doRead,doWrite: std_logic;
begin
	--inferred ram
	process(clk)
	begin
		 if(rising_edge(clk)) then
			  if(ram1wen='1') then
					ram1(to_integer(ram1waddr)) <= ram1wdata;
			  end if;
			  ram1q <= ram1(to_integer(ram1raddr));
		 end if;
	end process;
	--queue logic
	full <= '1' when rpos=wpos+1 else '0';
	empty <= '1' when rpos=wpos else '0';
	doRead <= readnext and not empty;
	doWrite <= writeen and not full;
	
	rposNext <= rpos+1 when doRead='1' else rpos;
	wposNext <= wpos+1 when doWrite='1' and writeprev='0' else wpos;
	rpos <= rposNext when rising_edge(clk);
	wpos <= wposNext when rising_edge(clk);
	wpos_prev <= wpos when writeen='1' and writeprev='0' and rising_edge(clk);
	
	ram1raddr <= rposNext;
	ram1waddr <= wpos_prev when writeprev='1' else wpos;
	ram1wdata <= wdata;
	ram1wen <= doWrite;
	rdata <= ram1q;
	
	readvalid <= not empty;
	writefull <= full;
end architecture;
