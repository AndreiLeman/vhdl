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
entity serial7seg2 is
	generic(bits: integer := 32);
    Port ( clk : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (bits-1 downto 0);
           buttons: out std_logic_vector(2 downto 0);
           scl,cs,sdi : inout  STD_LOGIC);
end serial7seg2;

architecture a of serial7seg2 is
	constant b: integer := integer(ceil(log2(real(bits))));
	
	subtype HEXBitstream is std_logic_vector(bits-1 downto 0);
	
	signal phase: unsigned(0 downto 0);
	signal state,stateNext: unsigned(5 downto 0);
	--hex output
	signal hexSr,hexSrNext: HEXBitstream;
	signal counter,counterNext: unsigned(b-1 downto 0);
	signal hex_cs1: std_logic;
	
	signal outscl,outcs,outsdi,outsclNext,outcsNext: std_logic;
	signal oe,oeNext: std_logic;
	
	--buttons
	signal sampleButtons: std_logic;
	signal b1,b2: std_logic_vector(2 downto 0);
begin
	phase <= phase+1 when rising_edge(clk);
	state <= stateNext when phase=1 and rising_edge(clk);
	stateNext <= "000000" when state=bits+3 else state+1;
	
	hexSrNext <= data when state=0 else "0" & hexSr(bits-1 downto 1);
	hexSr <= hexSrNext when phase=0 and rising_edge(clk);
	
	oeNext <= '1' when state<=bits else '0';
	outsclNext <= '1' when state<bits and phase=1 else '0';
	outcsNext <= '1' when state=bits and phase=1 else
					'1' when state=bits+1 else
					'0';
	
	oe <= oeNext when rising_edge(clk);
	outscl <= outsclNext when rising_edge(clk);
	outcs <= outcsNext when rising_edge(clk);
	outsdi <= hexSr(0);

	scl <= outscl when oe='1' else 'Z';
	cs <= outcs when oe='1' else 'Z';
	sdi <= outsdi when oe='1' else 'Z';
	
	
	sampleButtons <= '1' when state=bits+2 and phase=1 else '0';
	b1(0) <= not cs when sampleButtons='1' and rising_edge(clk);
	b1(1) <= not sdi when sampleButtons='1' and rising_edge(clk);
	b1(2) <= not scl when sampleButtons='1' and rising_edge(clk);
	
	b2 <= b1 when sampleButtons='1' and rising_edge(clk);
	buttons <= b2 when b1=b2 and state=bits+3 and rising_edge(clk);
end a;

