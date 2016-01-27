library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--clkDivision: how many clock cycles per sample
entity deltaSigmaModulator2 is
	generic(timeConstant_order: integer := 11);
	port(clk: in std_logic;
			datain: in unsigned(31 downto 0);
			dataout: out unsigned(3 downto 0));
end entity;
architecture a of deltaSigmaModulator2 is
	signal nextValue,nextValue1,nextValue0,prevValue: unsigned(31 downto 0);
	signal curOutput: unsigned(3 downto 0);
	signal timeConstant1: unsigned(23 downto 0);
	signal datain1: unsigned(31 downto 0);
	signal tmp: signed(32 downto 0);
	--signal tmp_out1: signed(33 downto 0);
	--signal tmp_out: signed(5 downto 0);
	signal diff1,diff2: signed(32 downto 0);
	signal tmp_out: signed(timeConstant_order+4 downto 0);
	--constant timeConstant1_c: real := real(integer(2)**24)/real(timeConstant);
begin
	--timeConstant1 <= to_unsigned(natural(timeConstant1_c),24);
	dataout <= curOutput when rising_edge(clk);
	prevValue <= nextValue when rising_edge(clk);
	-- dV/dt = (outputV-V)/(timeConstant)
	
	tmp <= signed("0"&curOutput&(27 downto 0=>'0'))-signed("0"&prevValue);
	nextValue <= prevValue + ((timeConstant_order-2 downto 0=>tmp(32))&unsigned(tmp(32 downto timeConstant_order)));
	
	datain1 <= datain;
	diff1 <= signed("0"&datain1)-signed("0"&prevValue);
	diff2 <= diff1+signed("0"&prevValue(31 downto timeConstant_order));
	tmp_out <= diff2(32 downto 32-timeConstant_order-4) when datain1<=prevValue else
		diff2(32 downto 32-timeConstant_order-4)+1;

--	tmp_out1 <= signed("0"&datain1&"0")-signed("0"&prevValue);
--	tmp_out <= tmp_out1(33 downto 28) when datain1<=prevValue else
--		tmp_out1(33 downto 28)+1;
	
	curOutput <= "1111" when tmp_out>"01111" else
					"0000" when tmp_out<0 else
					unsigned(tmp_out(3 downto 0));
end architecture;
