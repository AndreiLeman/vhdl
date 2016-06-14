----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:40:15 05/02/2016 
-- Design Name: 
-- Module Name:    clkgen_i2c - Behavioral 
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
use work.i2cplayer;
entity clkgen_external_i2c is
    Port ( clk : in  STD_LOGIC;
           outscl,outsda,outctrl: out std_logic;
           do_tx : in  STD_LOGIC);
end clkgen_external_i2c;

architecture Behavioral of clkgen_external_i2c is
	signal i2cDataRom,i2cCtrlRom: std_logic_vector(255 downto 0);
	
	signal I2CRESTART_data: std_logic_vector(14 downto 0) := 
		-- stop & start
		"111100" &
		-- dev addr+W    ACK
		"11010100" & "1";
	signal I2CRESTART_ctrl: std_logic_vector(14 downto 0) := 
		-- stop & start
		"111110" &
		-- dev addr+W    ACK
		"00000000" & "0";
begin
	i2cDataRom <= 
		(13 downto 0=>'0') &		--padding
	-- start
		"00" &
	-- dev addr+W    ACK
		"11010100" & "1" &
	-- addr    ACK
		X"17" & "1" &
	-- data         ACK
		"00000111" & "1" &	-- 0x17 (feedback)
		"00000000" & "1" &	-- 0x18 (feedback)
		--"00000000" & "0" &	-- 0x19 (feedback fractional)
		--"00000000" & "0" &	-- 0x1a (feedback fractional)
		
		I2CRESTART_data &
	-- addr    ACK
		X"12" & "1" &
	-- data         ACK
		"11111100" & "1" &	-- 0x12 (crystal)
		"11111100" & "1" &	-- 0x13 (crystal)
		
		I2CRESTART_data &
	-- addr    ACK
		X"21" & "1" &
	-- data         ACK
		"10000001" & "1" &	-- 0x21 (clock1 control)
	
		I2CRESTART_data &
	-- addr    ACK
		X"2d" & "1" &
	-- data         ACK
		"00000000" & "1" &	-- 0x2d (clock1 divider)
		"11110000" & "1" &	-- 0x2e (clock1 divider)
	
		I2CRESTART_data &
	-- addr    ACK
		X"60" & "1" &
	-- data         ACK
		"10111011" & "1" &	-- 0x60 (clock1 cfg)
		"00000001" & "1" &	-- 0x61 (clock1 cfg)
		
		I2CRESTART_data &
	-- addr    ACK
		X"68" & "1" &
	-- data         ACK
		"00000111" & "1" &	-- 0x68 (CLK_OE)
		"11111100" & "1" &	-- 0x69 (CLK_OS)
		
	-- stop
		"000";
	
	--start: "10"
	--stop&start: "111110"
	--stop: "111"
	i2cCtrlRom <= 
		(13 downto 0=>'0') &		--padding
	-- start
		"10" &
	-- dev addr+W    ACK
		"00000000" & "0" &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x17 (feedback)
		"00000000" & "0" &	-- 0x18 (feedback)
		--"00000000" & "0" &	-- 0x19 (feedback fractional)
		--"00000000" & "0" &	-- 0x1a (feedback fractional)
		
		I2CRESTART_ctrl &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x12 (crystal)
		"00000000" & "0" &	-- 0x13 (crystal)
		
		I2CRESTART_ctrl &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x31 (clock2 control)
	
		I2CRESTART_ctrl &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x3d (clock2 divider)
		"00000000" & "0" &	-- 0x3e (clock2 divider)
	
		I2CRESTART_ctrl &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x62 (clock2 cfg)
		"00000000" & "0" &	-- 0x63 (clock2 cfg)
		
		I2CRESTART_ctrl &
	-- addr    ACK
		X"00" & "0" &
	-- data         ACK
		"00000000" & "0" &	-- 0x68 (CLK_OE)
		"00000000" & "0" &	-- 0x69 (CLK_OS)
	-- stop
		"111";
	
	i2cp: entity i2cplayer generic map(8) port map(clk,do_tx,i2cDataRom,i2cCtrlRom,
		outsda,outscl,outctrl,to_unsigned(241,8));
end Behavioral;

