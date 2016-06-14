----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:06:12 06/12/2016 
-- Design Name: 
-- Module Name:    pulse_extender - a 
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
--use IEEE.NUMERIC_STD.ALL;
entity pulseExtender is
	generic(registered: boolean := true; --whether to register the output
				extend: integer := 1);
	Port (clk : in  STD_LOGIC;
			inp: in std_logic;
			outp: out std_logic);
end pulseExtender;

architecture a of pulseExtender is
	signal sr: std_logic_vector(extend downto 0);
	signal ors: std_logic_vector(extend downto 0);
begin
g:	for I in 1 to extend generate
		sr(I) <= sr(I-1) when rising_edge(clk);
		ors(I) <= ors(I-1) or sr(I);
	end generate;
	sr(0) <= inp;
	ors(0) <= inp;
g2:if registered generate
		outp <= ors(extend) when rising_edge(clk);
	end generate;
g3:if not registered generate
		outp <= ors(extend);
	end generate;
end a;

