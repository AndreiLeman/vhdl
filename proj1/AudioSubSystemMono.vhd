Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;

Library altera;
use altera.altera_primitives_components.all;


Entity AudioSubSystemMono is
	Port (
		Clock_50 : in std_logic;
		AudMclk : out std_logic;
		Init : in std_logic; --  +ve edge initiates I2C data.

		I2C_Sclk : out std_logic;
		I2C_Sdat : inout std_logic;
		
		Bclk, AdcLrc, DacLrc, AdcDat : in std_logic;
		DacDat : out std_logic;

		RawIn: out std_logic_vector(47 downto 0); --left & right
		RawOut: in std_logic_vector(47 downto 0);
		MonoIn: out signed(23 downto 0);
		SamClk : out std_logic );
End Entity AudioSubSystemMono;

Architecture Structural of AudioSubSystemMono is
	Signal I2CClk : std_logic;
	Signal Sdout, Sdin, Sclk : std_logic;

	Signal LStreamIN, LStreamOUT, RStreamIN, LStreamIN2, RStreamOUT : signed( 31 downto 0 );
	Signal Ch0In, Ch1In, Ch0Out, Ch1Out : signed(15 downto 0);
	Signal Ch0InAlign : signed(15 downto 0);
	signal mono_tmp: signed(24 downto 0);
Begin

CG: Entity Work.ClockGen port map (Clock_50, I2CClk, AudMclk);

--****************************************************************************
-- The I2C system initializes the Codec.
--****************************************************************************
	I2C_Sclk <= Sclk;
	Sdin <= I2C_SDat;
	ODB: OPNDRN port map (a_in => Sdout, a_out => I2C_SDat);
CI: Entity Work.CodecInit port map ( ModeIn => "10",
							I2CClk => I2CClk, Sclk => Sclk, Sdin => Sdin, Sdout => Sdout,
							Init => Init,	SwitchWord => (others=>'0') );

							
--****************************************************************************
-- The Audio interface to the Codec..
--****************************************************************************
AI: Entity Work.AudRx
		port map ( Bclk => Bclk , AdcLrc => AdcLrc,	AdcDat => AdcDat,
					  LAudio => LStreamIN, RAudio => RStreamIN );
AO: Entity Work.AudTx
		port map ( Bclk => Bclk , DacLrc => DacLrc, DacDat => DacDat,
					  LAudio => LStreamOUT, RAudio => RStreamOUT );

--*********************************************************************	
-- Entity Intermediate Audio Processing.
-- Assume 2 Channels, 16-bit sample words at 50 kSPS	
-- Assume that both input and output have the same sample rates.
--*********************************************************************
	LStreamIN2 <= LStreamIN when rising_edge(AdcLrc);
	RawIn <= std_logic_vector(LStreamIN2(31 downto 8)) & std_logic_vector(RStreamIN(31 downto 8));
	mono_tmp <= (LStreamIN2(31) & LStreamIN2(31 downto 8))+(RStreamIN(31) & RStreamIN(31 downto 8));
	MonoIn <= mono_tmp(24 downto 1) when rising_edge(AdcLrc);
	LStreamOUT <= signed(RawOut(47 downto 24)&X"00");
	RStreamOUT <= signed(RawOut(23 downto 0)&X"00") when rising_edge(AdcLrc);
	--LStreamOUT <= LStreamIN;
	--RStreamOUT <= RStreamIN;
	SamClk <= AdcLrc;
End Architecture Structural;
