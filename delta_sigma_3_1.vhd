library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- accumulation rate is specified in 1/cycle
entity deltaSigmaModulator3 is
	generic(--accumulation_rate: real := 0.00174216;
				accumulation_rate_order: integer := 10;
				--threshold: real := 0.022
				threshold: signed(31 downto 0) := "00000001000000000000000000000000"-1
				);
	port(clk: in std_logic;
			datain: in signed(31 downto 0);
			dataout: out std_logic);
end entity;
architecture a of deltaSigmaModulator3 is
	signal integral: signed(31 downto 0);
	signal sum1,sum2,tmpsum: signed(31 downto 0);
	--signal sum_scaled: signed(47 downto 0);
	signal cmpout,lastout: std_logic;
	signal tmp,tmp1,tmp2: signed(31 downto 0);
	--constant asdfg: integer := integer(accumulation_rate*real(real(2)**15));
begin
	--sum1 <= (datain(31)&datain(31 downto 1))+to_signed(1073741823,32);
	--sum2 <= (datain(31)&datain(31 downto 1))-to_signed(1073741823,32);
	tmp <= to_signed(1073741824,32) when cmpout='0' else to_signed(-1073741824,32);
	tmpsum <= (datain(31)&datain(31 downto 1))+tmp;
	--sum_scaled <= tmpsum*to_signed(asdfg,16);
	--sum_scaled <= tmpsum(31 downto accumulation_rate_order);
	integral <= integral+tmpsum(31 downto accumulation_rate_order) when rising_edge(clk);
	lastout <= cmpout when rising_edge(clk);
	cmpout <= '1' when lastout='0' and integral>threshold else
				'0' when lastout='1' and integral<-threshold else
				lastout;
	
	--cmpout <= not integral(31);
	dataout <= lastout when rising_edge(clk);
end architecture;
