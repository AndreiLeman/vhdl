library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--clkDivision: how many clock cycles per sample
entity deltaSigmaModulator is
	generic(timeConstant_order: integer := 11);
	port(clk: in std_logic;
			datain: in unsigned(31 downto 0);
			dataout: out std_logic);
end entity;
architecture a of deltaSigmaModulator is
	signal nextValue,nextValue1,nextValue0,prevValue: unsigned(31 downto 0);
	signal curOutput: std_logic;
	signal timeConstant1: unsigned(23 downto 0);
	signal tmp1,tmp0: unsigned(31 downto 0);
	--constant timeConstant1_c: real := real(integer(2)**24)/real(timeConstant);
begin
	--timeConstant1 <= to_unsigned(natural(timeConstant1_c),24);
	dataout <= curOutput when rising_edge(clk);
	prevValue <= nextValue when rising_edge(clk);
	-- dV/dt = (outputV-V)/(timeConstant)
	
	tmp1 <= (not prevValue);
	nextValue1 <= prevValue + tmp1(31 downto timeConstant_order);
	tmp0 <= prevValue;
	nextValue0 <= prevValue - tmp0(31 downto timeConstant_order);
	
	nextValue <= nextValue0 when curOutput='0' else nextValue1;
	
	curOutput <= '1' when datain>prevValue else '0';
end architecture;
