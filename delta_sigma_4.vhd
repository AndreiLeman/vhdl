library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- accumulation rate is specified in 1/cycle
entity deltaSigmaModulator4 is
	generic(--accumulation_rate: real := 0.00174216;
				timeConstant_order: integer := 12);
	port(clk: in std_logic;
			datain: in signed(31 downto 0);
			dataout: out std_logic;
			threshold: in signed(31 downto 0));
end entity;
architecture a of deltaSigmaModulator4 is
	signal datain1,acc,acc_not,accNext: unsigned(31 downto 0);
	signal err,tmp0,tmp1: signed(32 downto 0);
	signal cmpout,lastout: std_logic;
begin
	datain1 <= unsigned(datain+"10000000000000000000000000000000") when rising_edge(clk);
	err <= signed("0"&datain1)-signed("0"&acc) when rising_edge(clk);
	lastout <= cmpout when rising_edge(clk);
	cmpout <= '1' when lastout='0' and err>threshold else
				'0' when lastout='1' and err<-threshold else
				lastout;
	
	accNext <= acc - acc(31 downto timeConstant_order) when lastout='0' else
				acc + (not acc(31 downto timeConstant_order));
	acc <= accNext when rising_edge(clk);
	dataout <= lastout when rising_edge(clk);
end architecture;
