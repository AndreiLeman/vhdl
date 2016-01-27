library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity spiTx is
	generic(N: integer := 16;
				lenbits: integer := 8);
	port(clk,doSend: in std_logic;
			data: in unsigned(N-1 downto 0);
			len: in unsigned(lenbits-1 downto 0);
			cs,sdo,clken: out std_logic);
end entity;

architecture a of spiTx is
	signal len1: unsigned(lenbits-1 downto 0);
	signal state,stateNext: unsigned(lenbits-1 downto 0);
	signal sr,srNext: unsigned(N-1 downto 0);
	signal csNext,clkenNext: std_logic;
begin
	len1 <= len+1;
	stateNext <= to_unsigned(1,lenbits) when state=0 and doSend='1' else
		to_unsigned(0,lenbits) when state>len1 or state=0 else
		state+1; -- when state!=0;
	state <= stateNext when falling_edge(clk);
	srNext <= data when state<=1 else sr(N-2 downto 0)&"0";
	sr <= srNext when falling_edge(clk);
	sdo <= sr(N-1);
	
	csNext <= '0' when state=0 or state>len1 else '1';
	cs <= csNext when falling_edge(clk);
	clkenNext <= '0' when state=0 or state>=len1 else '1';
	clken <= clkenNext when falling_edge(clk);
end architecture;
