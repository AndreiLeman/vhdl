----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:10:11 05/11/2016 
-- Design Name: 
-- Module Name:    serdes_test - a 
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
library unisim;
use unisim.vcomponents.all;

entity serdes_test is
    Port ( CLOCK_25 : in  STD_LOGIC;
           dout_p : out  STD_LOGIC;
           dout_n : out  STD_LOGIC);
end serdes_test;

architecture a of serdes_test is
	signal clkfbout,clkfbout_buf: std_logic;
	signal clkin0,clkout0,serdesclk,serdesclkdiv,
		locked,bufpll_locked,ioce,serdesq: std_logic;
	signal clkout1, clkout2_unused, clkout3_unused,
			clkout4_unused, clkout5_unused: std_logic;
begin
	clkin0_buf : BUFG port map (O => clkin0, I => CLOCK_25);
	--PLL
	pll_base_inst : PLL_BASE generic map
		(BANDWIDTH            => "OPTIMIZED",
		 CLK_FEEDBACK         => "CLKFBOUT",
		 COMPENSATION         => "SYSTEM_SYNCHRONOUS",
		 DIVCLK_DIVIDE        => 1,
		 CLKFBOUT_MULT        => 38,
		 CLKFBOUT_PHASE       => 0.000,
		 
		 CLKOUT0_DIVIDE       => 1,
		 CLKOUT0_PHASE        => 0.000,
		 CLKOUT0_DUTY_CYCLE   => 0.500,
		 
		 CLKOUT1_DIVIDE       => 4,
		 CLKOUT1_PHASE        => 0.000,
		 CLKOUT1_DUTY_CYCLE   => 0.500,
		 
		 CLKIN_PERIOD         => 40.000,
		 REF_JITTER           => 0.003)
		port map
		 -- Output clocks
		(CLKFBOUT            => clkfbout,
		 CLKOUT0             => clkout0,
		 CLKOUT1             => clkout1,
		 CLKOUT2             => clkout2_unused,
		 CLKOUT3             => clkout3_unused,
		 CLKOUT4             => clkout4_unused,
		 CLKOUT5             => clkout5_unused,
		 -- Status and control signals
		 LOCKED              => locked,
		 RST                 => '0',
		 -- Input clock control
		 CLKFBIN             => clkfbout_buf,
		 CLKIN               => clkin0);
	-- Output buffering
	-------------------------------------
	clkf_buf : BUFG port map (O => clkfbout_buf, I => clkfbout);
	
	clk0_buf : BUFPLL generic map(DIVIDE=>4)
		port map (PLLIN => clkout0, GCLK=>serdesclkdiv,
			LOCKED=>locked, IOCLK => serdesclk,
			SERDESSTROBE=>ioce, LOCK=>bufpll_locked);
	clk1_buf : BUFG port map (O   => serdesclkdiv, I   => clkout1);
	
--	serdes: OSERDES2 generic map(DATA_RATE_OQ=>"SDR",
--			DATA_RATE_OT=>"SDR", DATA_WIDTH=>4)
--		port map(CLK0=>serdesclk, CLK1=>'0', CLKDIV=>serdesclkdiv,
--			IOCE=>ioce,D4=>'1', D3=>'0', D2=>'1', D1=>'0',OCE=>'1',
--			RST=>'0', T1=>'0', T2=>'0', T3=>'0', T4=>'0', TCE=>'1',
--			TRAIN=>'0',
--			OQ=>serdesq, SHIFTIN1=>'0', SHIFTIN2=>'0',
--			SHIFTIN3=>'0', SHIFTIN4=>'0');

	
	OSERDES_master_inst: OSERDES2 
		generic map (
			DATA_WIDTH     => 4,          -- SERDES word width.  This should match the setting is BUFPLL
			DATA_RATE_OQ   => "SDR",      -- <SDR>, DDR
			DATA_RATE_OT   => "SDR",      -- <SDR>, DDR
			SERDES_MODE    => "MASTER",   -- <DEFAULT>, MASTER, SLAVE
			OUTPUT_MODE    => "DIFFERENTIAL"
		)
		port map (
			OQ          => serdesq,
			OCE         => '1',
			CLK0        => serdesclk,
			CLK1        => '0',
			IOCE        => ioce,
			RST         => not bufpll_locked,
			CLKDIV      => serdesclkdiv,
			D4          => '0',
			D3          => '1',
			D2          => '0',
			D1          => '1',
			TQ          => open,
			T1          => '0',
			T2          => '0',
			T3          => '0',
			T4          => '0',
			TRAIN       => '0',
			TCE         => '1',
			SHIFTIN1    => '1',       -- Dummy input in Master
			SHIFTIN2    => '1',       -- Dummy input in Master
			SHIFTIN3    => '1',  -- Cascade output N data from slave
			SHIFTIN4    => '1',  -- Cascade output T data from slave
			SHIFTOUT1   => open,  -- Cascade input N data to slave
			SHIFTOUT2   => open,  -- Cascade input T data to slave
			SHIFTOUT3   => open,      -- Dummy output in Master
			SHIFTOUT4   => open       -- Dummy output in Master
		);
	--outbuf: ODDR2 generic map(DDR_ALIGNMENT=>"NONE",SRTYPE=>"SYNC")
	--	port map(C0=>serdesclk, C1=>not serdesclk,CE=>'1',D0=>'1',D1=>'0',Q=>serdesq);
	obuf0: OBUFDS port map(I=>serdesq,O=>dout_p,OB=>dout_n);
end a;

