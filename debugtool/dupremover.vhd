----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:36:29 04/23/2016 
-- Design Name: 
-- Module Name:    dupremover - a 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
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

entity dupremover is
	generic(width: integer := 8);
    Port ( clk : in  STD_LOGIC;
           datain_valid : in  STD_LOGIC;
           dataout_valid : out  STD_LOGIC;
           datain : in  STD_LOGIC_VECTOR (width-1 downto 0);
           dataout : out  STD_LOGIC_VECTOR (width-1 downto 0);
			  dupcount: out unsigned(7 downto 0));
end dupremover;
architecture a of dupremover is
	signal data1,data2: std_logic_vector(width-1 downto 0);
	signal valid1,isdup1: std_logic;
	signal dup,dupNext: unsigned(7 downto 0);
begin
	data1 <= datain when datain_valid='1' and rising_edge(clk);
	data2 <= data1 when datain_valid='1' and rising_edge(clk);
	valid1 <= datain_valid when rising_edge(clk);
	isdup1 <= '1' when data1=data2 else '0';
	
	dupNext <= X"ff" when isdup1='1' and dup=X"ff" else
		dup+1 when isdup1='1' else "00000000";
	dup <= dupNext when rising_edge(clk);
	
	dataout_valid <= valid1 when rising_edge(clk);
	dupcount <= dup;
	dataout <= data1 when rising_edge(clk);
end a;

