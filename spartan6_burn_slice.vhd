----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:40:42 05/01/2016 
-- Design Name: 
-- Module Name:    spartan6_burn_slice - a 
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- occupy 1 slice with random LUTs and flipflops
entity spartan6_burn_slice is
	port(clk : in  STD_LOGIC;
			din : in  STD_LOGIC_VECTOR (7 downto 0);
			dout : out  STD_LOGIC_VECTOR (7 downto 0));
end entity;
architecture a of spartan6_burn_slice is
	type roms is array(7 downto 0) of std_logic_vector(31 downto 0);
	signal rom: roms;
	type inputs_t is array(3 downto 0) of unsigned(4 downto 0);
	type outputs_t is array(3 downto 0) of unsigned(1 downto 0);
	signal inputs: inputs_t;
	signal outputs: outputs_t;
begin
	rom <= (
		"01001010101011111010110011111111",
		"00000000100001100001011101100011",
		"01101110011100100001101011011001",
		"10011011010100111111101000001110",
		"10001101100111110101000100111011",
		"11001001001000100110110111010100",
		"00001101011000010010000010000101",
		"10100111101011010110111101101110");
g1:for I in 0 to 3 generate
		outputs(I)(0) <= rom(I*2+0)(to_integer(inputs(I))) when rising_edge(clk);
		outputs(I)(1) <= rom(I*2+1)(to_integer(inputs(I))) when rising_edge(clk);
		dout(I*2+0) <= outputs(I)(0);
		dout(I*2+1) <= outputs(I)(1);
		inputs(I)(0) <= din(I*2+0);
		inputs(I)(1) <= din(I*2+1);
	end generate;
	
	inputs(0)(2) <= outputs(1)(0);
	inputs(0)(3) <= outputs(2)(1);
	inputs(0)(4) <= outputs(3)(0);
	
	inputs(1)(2) <= outputs(2)(0);
	inputs(1)(3) <= outputs(3)(1);
	inputs(1)(4) <= outputs(0)(0);
	
	inputs(2)(2) <= outputs(3)(0);
	inputs(2)(3) <= outputs(0)(1);
	inputs(2)(4) <= outputs(1)(0);
	
	inputs(3)(2) <= outputs(0)(0);
	inputs(3)(3) <= outputs(1)(1);
	inputs(3)(4) <= outputs(2)(0);
	
end a;


