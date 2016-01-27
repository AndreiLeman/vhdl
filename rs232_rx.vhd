library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity rs232_rx is
	port(rxdata,clk: in std_logic;
			clk_divide: in unsigned(7 downto 0);
			
			q: out std_logic_vector(7 downto 0);
			q_valid: out std_logic);
end entity;
architecture a of rs232_rx is
	type states is (idle,startbit,receiving,stopbit);
	signal state,ns: states;
	signal counter: unsigned(7 downto 0);
	signal bitcount: unsigned(3 downto 0);
	signal rxdata2,x: std_logic;
	signal rxdone,shift_en,sb_done: std_logic;
	signal shift_reg: std_logic_vector(7 downto 0);
begin
	rxdata2 <= rxdata when rising_edge(clk);
	x <= rxdata2 when rising_edge(clk);
	ns <= idle when state=idle and x='1' else
			startbit when state=idle else
			startbit when state=startbit and sb_done='1' else
			receiving when state=startbit else
			receiving when state=receiving and rxdone='0' else
			stopbit when state=receiving else
			stopbit when state=stopbit and x='0' else
			idle;
	state <= ns when rising_edge(clk);
	
	--datapath
	counter <= X"00" when state=idle and rising_edge(clk) else
					counter+1 when rising_edge(clk);
	shift_reg <= x & shift_reg(7 downto 1) when shift_en='1' and rising_edge(clk);
	shift_en <= '1' when state=receiving and counter=("0"&clk_divide(7 downto 1)) else '0';
	
	bitcount <= bitcount+1 when state=receiving and shift_en='1' and rising_edge(clk) else
					X"0" when state/=receiving and rising_edge(clk);
	rxdone <= '1' when bitcount=X"8" else '0';
	sb_done <= '1' when counter/=(clk_divide-1) else '0';
	q <= shift_reg;
	q_valid <= '1' when rxdone='1' and state=receiving else '0';
end architecture;
