----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:14:48 05/01/2016 
-- Design Name: 
-- Module Name:    spartan6_burn - Behavioral 
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
use work.spartan6_burn_slice;
entity spartan6_burn is
    Port ( clk : in  STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (7 downto 0);
           dout : out  STD_LOGIC_VECTOR (7 downto 0));
end spartan6_burn;

architecture a of spartan6_burn is
	constant N: integer := 1000;
	type stages_t is array(N-1 downto 0) of std_logic_vector(7 downto 0);
	signal stages: stages_t;
begin
g:	for I in 0 to N-2 generate
		sl: entity spartan6_burn_slice port map(clk,stages(I),stages(I+1));
	end generate;
	stages(0) <= din;
	dout <= stages(N-1);
end a;

