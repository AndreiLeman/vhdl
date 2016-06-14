----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:55:37 05/01/2016 
-- Design Name: 
-- Module Name:    serial_7seg - Behavioral 
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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
entity serial_7seg is
	generic(bits: integer := 32);
    Port ( clk : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (bits-1 downto 0);
			  
           scl,cs,sdi : out  STD_LOGIC);
end serial_7seg;

architecture a of serial_7seg is
	constant b: integer := integer(ceil(log2(real(bits))));
	
	subtype HEXBitstream is std_logic_vector(bits-1 downto 0);
	--hex output
	signal hex_sr,hex_sr_next: HEXBitstream;
	signal counter,counterNext: unsigned(b-1 downto 0);
	signal hex_cs1: std_logic;
begin
	--hex serial output
	counterNext <= to_unsigned(0,b) when counter=(bits-1)
		else counter+1;
	counter <= counterNext when rising_edge(clk);
	
	
	hex_sr_next <= data when counter=0
		else "0" & hex_sr(bits-1 downto 1);
	hex_sr <= hex_sr_next when rising_edge(clk);
	
	scl <= not clk;
	sdi <= hex_sr(0);
	hex_cs1 <= '1' when counter=0 else '0';
	cs <= hex_cs1 when rising_edge(clk);
end a;

