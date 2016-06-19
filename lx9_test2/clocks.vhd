-- file: clk_wiz_v3_6.vhd
-- 
-- (c) Copyright 2008 - 2011 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clocks is
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLOCK_225          : out    std_logic;
  CLOCK_300          : out    std_logic;
  CLOCK_60          : out    std_logic;
  -- Status and control signals
  LOCKED            : out    std_logic
 );
end clocks;

architecture xilinx of clocks is
  -- Input clock buffering / unused connectors
  signal clkin1      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal CLOCK_225u, CLOCK_300u,CLOCK_60u: std_logic;
	signal unused0,unused1,unused2,unused3: std_logic;
begin
	clkin1 <= CLK_IN1;
	-- Clocking primitive
	--------------------------------------
	-- Instantiation of the PLL primitive
	--    * Unused inputs are tied off
	--    * Unused outputs are labeled unused

	pll_base_inst : PLL_BASE
		generic map(
			BANDWIDTH            => "OPTIMIZED",
			CLK_FEEDBACK         => "CLKFBOUT",
			COMPENSATION         => "SYSTEM_SYNCHRONOUS",
			DIVCLK_DIVIDE        => 1,
			CLKFBOUT_MULT        => 36,
			CLKFBOUT_PHASE       => 0.000,
			CLKOUT0_DIVIDE       => 10,
			CLKOUT0_PHASE        => 0.000,
			CLKOUT0_DUTY_CYCLE   => 0.500,
			CLKOUT1_DIVIDE       => 3,
			CLKOUT1_PHASE        => 0.000,
			CLKOUT1_DUTY_CYCLE   => 0.500,
			CLKOUT2_DIVIDE       => 15,
			CLKOUT2_PHASE        => 0.000,
			CLKOUT2_DUTY_CYCLE   => 0.500,
			CLKOUT3_DIVIDE       => 4,
			CLKOUT3_PHASE        => 0.000,
			CLKOUT3_DUTY_CYCLE   => 0.500,
			CLKOUT4_DIVIDE       => 40,
			CLKOUT4_PHASE        => 0.000,
			CLKOUT4_DUTY_CYCLE   => 0.500,
			CLKIN_PERIOD         => 40.000,
			REF_JITTER           => 0.003)
		port map
		-- Output clocks
			(CLKFBOUT            => clkfbout,
			CLKOUT0             => unused0,
			CLKOUT1             => CLOCK_300u,
			CLKOUT2             => CLOCK_60u,
			CLKOUT3             => CLOCK_225u,
			CLKOUT4             => unused2,
			CLKOUT5             => unused3,
			-- Status and control signals
			LOCKED              => LOCKED,
			RST                 => '0',
			-- Input clock control
			CLKFBIN             => clkfbout_buf,
			CLKIN               => clkin1);

	-- Output buffering
	-------------------------------------
	clkf_buf : BUFG port map
		(O => clkfbout_buf,
		I => clkfbout);


	clkout300_buf : BUFG port map
		(O   => CLOCK_300,
		I   => CLOCK_300u);

	clkout60_buf : BUFG port map
		(O   => CLOCK_60,
		I   => CLOCK_60u);

	clkout240_buf : BUFG port map
		(O   => CLOCK_225,
		I   => CLOCK_225u);

end xilinx;
