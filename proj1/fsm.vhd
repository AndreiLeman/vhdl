

-- circuit structure: 2 state variables; ns1 represents whether there is a pending extension (1 bit);
-- ns2 represents the output cycle (values can be 0 to 4 inclusive; 0 represents idle)
-- there are 9 possible states in total:
-- state "ns1=1 ns2=0" is not included (it is never encountered)

-- fsm_ns1: combinatorial sub-circuit for calculating the next state "ns1"
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity fsm_ns1 is
	port(trigger,cs1: in std_logic;
			cs2: in unsigned(2 downto 0);
			ns1: out std_logic);
end entity;
architecture a of fsm_ns1 is
begin
	ns1 <= '1' when ((not (cs2=0)) and (trigger='1' or cs1='1') and ((not (cs2=4)) or trigger='1')) else '0';
end architecture;

-- fsm_ns2: combinatorial sub-circuit for calculating the next state "ns2"
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity fsm_ns2 is
	port(trigger,cs1: in std_logic;
			cs2: in unsigned(2 downto 0);
			ns2: out unsigned(2 downto 0));
end entity;
architecture a of fsm_ns2 is
begin
	ns2 <= to_unsigned(0,3) when (cs2=0 and trigger='0') or (cs2=4 and trigger='0' and cs1='0') else
			 --to_unsigned(1,3) when (cs2=0 and trigger='1') or (cs2=4 and (trigger='1' or cs1='1')) else
			 to_unsigned(1,3) when (cs2=0) or (cs2=4) else
			 cs2+1;
end architecture;


-- main outer circuitry
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.all;
entity fsm is
	port (clk, inp: in std_logic;
			outp: out std_logic;
			state: out std_logic_vector(3 downto 0));
end entity;
architecture a of fsm is
	signal cs1,ns1: std_logic;					--whether there is an extension
	signal cs2,ns2: unsigned(2 downto 0);	--# of clk cycles since start of last output cycle
	signal last_inp: std_logic;
	signal trigger: std_logic;
begin
	cs1 <= ns1 when rising_edge(clk);
	cs2 <= ns2 when rising_edge(clk);
	last_inp <= inp when rising_edge(clk);
	trigger <= '1' when last_inp='0' and inp='1' else '0';
	
	combinatorial_ns1: fsm_ns1 port map(trigger=>trigger,cs1=>cs1,cs2=>cs2,ns1=>ns1);
	combinatorial_ns2: fsm_ns2 port map(trigger=>trigger,cs1=>cs1,cs2=>cs2,ns2=>ns2);
	
	outp <= '0' when cs2=0 else '1';
	state(0) <= cs1;
	state(1) <= cs2(0);
	state(2) <= cs2(1);
	state(3) <= cs2(2);
end;


