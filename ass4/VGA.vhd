library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Package VGA is

-- VGA Mode Resolution parameters
	Constant TotalPix : natural := 794;
	Constant WidthPix : natural := 640;
	Constant HFPpix : natural := 15;
	Constant HSTpix : natural := 95;
	Constant HBPpix : natural := TotalPix-WidthPix-HFPpix-HSTpix; -- should be 44
 
	Constant TotalLines : natural := 525;
	Constant HeightLines : natural := 480;
	Constant VFPlines : natural := 10;
	Constant VSTlines : natural := 2;
	Constant VBPlines : natural := TotalLines-HeightLines-VFPlines-VSTlines; -- should be 33

	
-- Useful 30-bit RGB colour values	
	Constant FullMix : std_logic_vector(9 downto 0) := "1111111111";
	Constant NoneMix : std_logic_vector(9 downto 0) := "0000000000";
	Constant HalfMix : std_logic_vector(9 downto 0) := "1000000000";
	Constant SevenEight : std_logic_vector(9 downto 0) := "1110000000";

	Constant RedMix : std_logic_vector(29 downto 0) := FullMix & NoneMix & NoneMix;
	Constant GreenMix : std_logic_vector(29 downto 0) := NoneMix & FullMix & NoneMix;
	Constant BlueMix : std_logic_vector(29 downto 0) := NoneMix & NoneMix & FullMix;
	Constant BlackMix : std_logic_vector(29 downto 0) := NoneMix & NoneMix & NoneMix;
	Constant WhiteMix : std_logic_vector(29 downto 0) := FullMix & FullMix & FullMix;
	Constant BrownMix : std_logic_vector(29 downto 0) := "1000000000" & "0100000000" & "0001000000";
	Constant PinkMix : std_logic_vector(29 downto 0) := FullMix & SevenEight & SevenEight;
	Constant YellowMix : std_logic_vector(29 downto 0) := FullMix & FullMix & NoneMix;
	
--Sprite Information	
	Constant BoxW : natural := 16;
	Constant BoxH : natural := 16;

-- 0 = black, 1 = red, 2 = green, 3 = blue,
-- 4 = yellow, 5 = brown, 6 = pink, 7 = background	
	subtype ColourCode is natural range 0 to 7;
	type SpriteROM is array (0 to 255) of ColourCode;
	Constant MarioSpriteROM : SpriteROM := (
				7,7,7,7,7,7,1,1,1,7,7,7,7,7,7,7,
				7,7,7,7,7,1,1,1,1,1,7,7,6,6,6,7,
				7,7,7,7,1,1,1,1,1,1,1,1,1,6,6,7,
				7,7,7,7,5,5,5,6,6,0,6,7,1,1,1,7,
				7,7,7,5,6,5,6,6,6,0,6,6,6,1,1,7,
				7,7,7,5,6,5,5,6,6,6,0,6,6,6,1,7,
				7,7,7,5,5,6,6,6,6,0,0,0,0,1,7,7,
				7,7,7,7,7,6,6,6,6,6,6,6,1,1,7,7,
				7,7,1,1,1,1,3,1,1,1,3,1,1,7,7,5,
				6,6,1,1,1,1,1,3,1,1,1,3,7,7,5,5,
				6,6,6,1,1,1,1,3,3,3,3,4,3,3,5,5,
				7,6,7,7,3,1,3,3,4,3,3,3,3,3,5,5,
				7,7,5,5,5,3,3,3,3,3,3,3,3,3,5,5,
				7,5,5,5,3,3,3,3,3,3,7,7,7,7,7,7,
				7,5,5,7,7,7,7,7,7,7,7,7,7,7,7,7,
				7,5,5,7,7,7,7,7,7,7,7,7,7,7,7,7 );

	subtype RGBColour is std_logic_vector( 29 downto 0 );
	type ColourTable is array (0 to 7) of RGBColour;

	Constant MarioColourTable : ColourTable := (
				BlackMix, RedMix, GreenMix, BlueMix, YellowMix,
				BrownMix, PinkMix, BlackMix );

	
End Package VGA;