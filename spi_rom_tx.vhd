library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- assumes rom has 1 clock cycle of delay
entity spiRomTx is
	generic(N: integer := 16;
				lenbits: integer := 8);
	port(clk,doSend: in std_logic;
			len: in unsigned(lenbits-1 downto 0);
			romAddr: out unsigned(lenbits-1 downto 0);
			cs,clken: out std_logic);
end entity;

architecture a of spiRomTx is
	signal len1: unsigned(lenbits-1 downto 0);
	signal romAddrNext: unsigned(lenbits-1 downto 0);
	signal state,stateNext: unsigned(lenbits-1 downto 0);
	signal sr,srNext: unsigned(N-1 downto 0);
	signal csNext,clkenNext: std_logic;
begin
	len1 <= len+1;
	stateNext <= to_unsigned(1,lenbits) when state=0 and doSend='1' else
		to_unsigned(0,lenbits) when state>len1 or state=0 else
		state+1; -- when state!=0;
	state <= stateNext when falling_edge(clk);
	--romAddrNext <= state;
	romAddr <= state when falling_edge(clk);
	
	csNext <= '0' when state=0 or state>len1 else '1';
	cs <= csNext when falling_edge(clk);
	clkenNext <= '0' when state=0 or state>=len1 else '1';
	clken <= clkenNext when falling_edge(clk);
end architecture;
