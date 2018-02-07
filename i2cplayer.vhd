----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:05:21 05/05/2016 
-- Design Name: 
-- Module Name:    i2cplayer - a 
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


-- whenever do_tx changes state (1 to 0 or 0 to 1),
-- the state machine begins reading the rom in reverse
-- order (from highestaddr to 0) by putting the read
-- address on romaddr, and latching romdata and romctrl
-- on the next clock cycle; romdata is directly connected to
-- sda, and romctrl controls scl as follows:
--  - if romctrl=1 and was 0 in the previous transmit cycle,
--    scl=0 for this transmit cycle
--  - if romctrl=0 and was 1 in the previous transmit cycle,
--    scl=0 for this transmit cycle
--  - otherwise, if romctrl=0, the state machine automatically
--    pulses scl in this transmit cycle
--  - otherwise, if romctrl=1, scl=1 in this transmit cycle
-- each transmit cycle is 4 clk cycles
entity i2cplayer is
	generic(romaddrlen: integer := 8);
	Port ( clk : in  STD_LOGIC;
			do_tx: in std_logic;
		  i2cDataRom,i2cCtrlRom: in std_logic_vector((2**romaddrlen)-1 downto 0);
		  outsda,outscl,outctrl: out std_logic;
		  highestaddr : in  unsigned(romaddrlen-1 downto 0));
end i2cplayer;

architecture a of i2cplayer is
	type i2cstates is (IDLE,SENDING);
	signal i2cstate: i2cstates := IDLE;
	signal i2cphase,outphase: unsigned(1 downto 0);
	signal i2ccnt: unsigned(romaddrlen-1 downto 0);
	signal i2cclk,i2csda,i2cscl,i2cctrl,i2cprevctrl: std_logic;
	signal prev_do_tx: std_logic;
begin
	i2cclk <= clk;
	process(i2cclk)
	begin
		if rising_edge(i2cclk) then
			i2cphase <= i2cphase+1;
			if i2cphase=0 then
				case i2cstate is
					when IDLE=>
						if do_tx/=prev_do_tx then
							i2cstate <= SENDING;
							i2ccnt <= highestaddr;
						end if;
						prev_do_tx <= do_tx;
						i2cprevctrl <= '1';
					when SENDING=>
						i2cprevctrl <= i2cctrl;
						if i2ccnt=0 then
							i2cstate <= IDLE;
							i2ccnt <= to_unsigned(0,romaddrlen);
						else
							i2ccnt <= i2ccnt-1;
						end if;
				end case; --i2cstate
				
				case i2cstate is
					when IDLE=>
						i2cscl <= '1';
						i2csda <= '1';
					when SENDING=>
						i2csda <= i2cDataRom(to_integer(i2ccnt));
						i2cctrl <= i2cCtrlRom(to_integer(i2ccnt));
				end case; --i2cstate
			end if; --i2cphase=0
			
			
			if i2cstate=SENDING then
				if i2cctrl/=i2cprevctrl then
					i2cscl <= '0';
				elsif i2cctrl='1' then
					i2cscl <= '1';
				else
					if i2cphase=1 or i2cphase=2 then
						i2cscl <= '1';
					else
						i2cscl <= '0';
					end if;
				end if;
			end if; --i2cstate=sending
		end if; --rising_edge(i2cclk)
	end process;
	outscl <= i2cscl when rising_edge(i2cclk);
	outsda <= i2csda when rising_edge(i2cclk);
	outctrl <= i2cctrl when rising_edge(i2cclk);
end a;

