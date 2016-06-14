----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:52:45 05/09/2016 
-- Design Name: 
-- Module Name:    sync - Behavioral 
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


entity debugtool_sync is
    Port ( clk : in  STD_LOGIC;
           din : in  STD_LOGIC;
           dout : out  STD_LOGIC);
end debugtool_sync;

architecture Behavioral of debugtool_sync is
	constant b: integer := 13;
	signal counter,counterPrev: unsigned(b-1 downto 0);
	
	constant depth: integer := 2**b;
	type ram1t is array(depth-1 downto 0) of std_logic;
	signal ram1: ram1t;
	signal ram1raddr,ram1waddr: unsigned(b-1 downto 0);
begin
	--inferred ram
	process(clk)
	begin
		if(rising_edge(clk)) then
			ram1(to_integer(counterPrev)) <= din;
			dout <= ram1(to_integer(counter));
		end if;
	end process;
	
	counter <= counter+1 when rising_edge(clk);
	counterPrev <= counter when rising_edge(clk);
end Behavioral;

