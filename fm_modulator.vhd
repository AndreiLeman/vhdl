library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity slow_clock2 is
	generic (bits: integer := 32);
	port (clk: in std_logic;
			period: in unsigned(bits-1 downto 0);
			o: out std_logic);
end;
architecture a of slow_clock2 is
	signal cs,ns: unsigned(bits-1 downto 0);
	signal next_out: std_logic;
begin
	cs <= ns when rising_edge(clk);
	ns <= cs+1 when cs<period else to_unsigned(0,bits);
	next_out <= '1' when cs<("0"&period(bits-1 downto 1)) else '0';
	o <= next_out when rising_edge(clk);
end architecture;

--modClk should be around 300MHz
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.slow_clock2;
entity fm_modulator is
	port(clk: in std_logic;
			data: in signed(9 downto 0);
			outp: out std_logic);
end entity;
architecture a of fm_modulator is
	signal fm_period: unsigned(10 downto 0);
begin
	fm_period <= (unsigned(data(9)&data))+to_unsigned(600,11) when rising_edge(clk);
	fm: slow_clock2 generic map(11) port map(clk=>clk,o=>outp,period=>fm_period);
end architecture;
