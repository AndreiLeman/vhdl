----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:50:22 05/07/2016 
-- Design Name: 
-- Module Name:    auto_sampler - a 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		samples an incoming signal at rate freq(clk) / clkdiv
--		and automatically finds the correct alignment to sample at
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
entity autoSampler is
	generic(clkdiv: integer := 4;
			width: integer := 8);
	Port ( clk : in  STD_LOGIC;
		  datain : in  STD_LOGIC_VECTOR (width-1 downto 0);
		  dataout : out  STD_LOGIC_VECTOR (width-1 downto 0);
		  dataoutvalid : out  STD_LOGIC;
		  failcnt: out unsigned(15 downto 0));
end autoSampler;

architecture a of autoSampler is
	constant b: integer := integer(ceil(log2(real(clkdiv+1))));
	
	signal datain1,datain2 :  STD_LOGIC_VECTOR (width-1 downto 0);
	signal counter,counterNext: unsigned(b-1 downto 0);
	
	signal sampled0,sampled1: std_logic_vector(width-1 downto 0);
	signal doSkip,doSkip1,dataoutvalid1: std_logic;
	signal failcnt1: unsigned(15 downto 0);
begin
	assert clkdiv>=4 report "clkdiv too small" severity failure;
	
	datain1 <= datain when rising_edge(clk);
	datain2 <= datain1 when rising_edge(clk);
	
	counterNext <= to_unsigned(0,b) when doSkip='1' and counter=clkdiv
		else to_unsigned(0,b) when doSkip='0' and counter=(clkdiv-1)
		else counter+1;
	counter <= counterNext when rising_edge(clk);
	
	sampled0 <= datain2 when counter=0 and rising_edge(clk);
	sampled1 <= datain2 when counter=1 and rising_edge(clk);
	
	doSkip1 <= '1' when sampled0(0)/=sampled1(0) else '0';
	doSkip <= doSkip1 when counter=2 and rising_edge(clk);
	
	dataoutvalid1 <= '1' when counter=2 and doSkip='0' else '0';
	dataout <= sampled1 when rising_edge(clk);
	dataoutvalid <= dataoutvalid1 when rising_edge(clk);
	
	failcnt1 <= failcnt1+1 when doSkip='1' and counter=3 and rising_edge(clk);
	failcnt <= failcnt1;
end a;

