library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- raised cosine filter rom
-- clock division factor: 16
-- signal frequency division factor: 100
-- depth: 8 periods
entity lpf_rom_rc_16_100 is
	port(addr1,addr2: in unsigned(3 downto 0);
			clk: in std_logic;
			--output consists of 64 8-bit signed 2's complement
			--fractions (all bits fractional);
			--data[0] is sinc(0)&sinc(1)&sinc(2)...
			--data[1] is sinc(0+1/125)&sinc(1+1/125)&...
			q1,q2: out signed(511 downto 0));
end entity;
architecture a of lpf_rom_rc_16_100 is
	type rom1t is array(0 to 15) of signed(511 downto 0);
	signal rom1: rom1t := (
X"ffff0000010202020100fffefdfdfeff01020404040200fefcfbfafbfd00030607070603fffbf8f6f6f8fd03080d0f0f0a03faf1e9e5e7eefd1129425a6e7b7f",
X"ffff0000010202020100fffefdfdfeff01020404040201fefcfbfafbfd00030607070603fffbf8f6f6f8fd02080d0f0f0b04fbf1e9e5e6eefc0f2741596d7a7f",
X"ffffff00010202020100fffefdfdfeff01020304040301fefcfbfafbfd00030507070603fffbf8f6f6f8fc02080d0f0f0b04fbf2eae5e6edfb0e263f576c797f",
X"ffffff00010202020100fffefdfdfeff01020304040301fffdfbfafbfd0003050708060400fcf8f6f6f8fc02070c0f0f0b05fcf2eae5e6ecfa0d243d566a797f",
X"ffffff00010202020100fffefdfdfeff00020304040301fffdfbfafbfdff02050708060400fcf8f6f6f8fc01070c0f0f0c05fcf3ebe6e6ecf90b233c5469787f",
X"ffffff00010202020100fffefdfdfeff00020304040301fffdfbfafbfdff02050708070400fcf8f6f6f7fb01070c0f0f0c06fdf3ebe6e5ebf80a213a5368777f",
X"ffffff00010202020100fffefdfdfeff00020304040301fffdfbfafbfcff02050708070400fcf9f6f6f7fb00060c0f0f0c06fef4ece6e5ebf70920395267777e",
X"ffffff00010102020100fffefdfdfeff00020304040301fffdfbfafbfcff02050708070401fdf9f6f6f7fb00060b0f0f0d07fef5ece6e5eaf6071e375066767e",
X"ffffff00010102020100fffefdfdfdff00020304040301fffdfbfafbfcff02050708070501fdf9f6f6f7fa00060b0f0f0d07fff5ece6e5eaf5061c364f65757e",
X"ffffff00010102020101fffefdfdfdfe00020304040302fffdfbfafbfcfe01040708070501fdf9f6f6f7faff050b0e0f0d08fff6ede7e5e9f4051b344d63747e",
X"ffffff00010102020101fffefdfdfdfe0001030404030200fdfcfbfbfcfe01040608070501fdf9f7f6f7faff050a0e100d0800f6ede7e5e9f3041a324c62737d",
X"ffffff0001010202010100fefdfdfdfe0001030404030200fefcfbfbfcfe01040608070502fefaf7f6f6faff050a0e100e0800f7eee7e5e8f20218314a61737d",
X"ffffff0001010202020100fefefdfdfe0001030404030200fefcfbfbfcfe01040607070502fefaf7f6f6f9fe040a0e100e0901f8eee8e5e8f101172f4860727c",
X"ffffff0000010202020100fffefdfdfe0001030404030200fefcfbfbfcfe01040607070502fefaf7f6f6f9fe04090e100e0902f8efe8e5e7f100152e475e717c",
X"ffffff0000010202020100fffefdfdfeff01030404040200fefcfbfafcfe00030607070602fefaf7f6f6f9fe03090e0f0e0a02f9f0e8e5e7f0ff142c455d707c",
X"ffffff0000010202020100fffefdfdfeff01030404040200fefcfbfafbfd00030607070603fffbf7f6f6f9fd03090d0f0e0a03f9f0e9e5e7effe122a445c6f7b"
);
	signal addr11,addr21: unsigned(3 downto 0);
begin
	addr11 <= addr1 when rising_edge(clk);
	addr21 <= addr2 when rising_edge(clk);
	q1 <= rom1(to_integer(addr11)) when rising_edge(clk);
	q2 <= rom1(to_integer(addr21)) when rising_edge(clk);
end architecture;
