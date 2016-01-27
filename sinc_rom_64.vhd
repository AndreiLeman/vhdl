library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity sinc_rom_64 is
	port(addr1,addr2: in unsigned(5 downto 0);
			clk1,clk2: in std_logic;
			--output consists of 8 16-bit signed 2's complement
			--fractions (all bits fractional);
			--data[0] is sinc(0)&sinc(1)&sinc(2)...
			--data[1] is sinc(0+1/64)&sinc(1+1/64)&...
			q1,q2: out signed(127 downto 0));
end entity;
architecture a of sinc_rom_64 is
	type rom1t is array(0 to 63) of signed(127 downto 0);
	signal rom1: rom1t := (
X"ffbfff7701b7fce6047cfa5806707fff",
X"ffbaff860195fd280403fb3a04737ff3",
X"ffb6ff950174fd6a038afc1a02837fce",
X"ffb2ffa30152fdac0311fcf800a27f92",
X"ffaeffb10131fdee0298fdd4fed07f3d",
X"ffabffbf010ffe30021ffeacfd0d7ed0",
X"ffa8ffcd00eefe7301a8ff81fb597e4b",
X"ffa5ffdb00cdfeb401320052f9b67daf",
X"ffa3ffe800acfef600bd011ff8227cfb",
X"ffa2fff4008cff36004a01e7f69f7c30",
X"ffa00000006cff76ffd902abf52d7b4e",
X"ffa0000c004cffb5ff6a0369f3cb7a55",
X"ff9f0017002dfff3fefd0421f27b7946",
X"ffa00022000f002ffe9204d4f13b7821",
X"ffa0002cfff2006afe2b0580f00e76e6",
X"ffa10036ffd500a4fdc60626eef17596",
X"ffa3003fffba00dcfd6506c5ede67432",
X"ffa50048ff9f0113fd06075eecec72ba",
X"ffa7004fff850148fcab07efec04712d",
X"ffaa0057ff6c017bfc540879eb2e6f8e",
X"ffad005dff5501acfc0008fcea696ddc",
X"ffb10063ff3e01dbfbb00977e9b56c18",
X"ffb50068ff280208fb6509eae9126a43",
X"ffb9006dff140233fb1d0a56e881685d",
X"ffbe0071ff01025bfad90ab9e8016667",
X"ffc30074feef0282fa9a0b15e7916461",
X"ffc80077fedf02a6fa5e0b68e732624d",
X"ffcd0079fecf02c7fa280bb4e6e4602a",
X"ffd3007afec102e7f9f50bf7e6a55dfa",
X"ffd9007bfeb40303f9c70c33e6775bbe",
X"ffe0007bfea9031ef99e0c66e6585976",
X"ffe6007afe9f0335f9790c91e6485723",
X"ffed0079fe96034bf9580cb4e64754c5",
X"fff40077fe8e035ef93c0cd0e655525e",
X"fffa0075fe88036ef9250ce3e6714fee",
X"00010072fe83037cf9120cefe69a4d77",
X"0008006ffe7f0387f9030cf3e6d24af8",
X"0010006bfe7c0390f8f90cefe7164873",
X"00170067fe7b0397f8f30ce5e76645e8",
X"001e0062fe7a039bf8f10cd3e7c34359",
X"0025005dfe7b039df8f40cbae82c40c6",
X"002c0058fe7d039cf8fa0c9ae89f3e30",
X"00320052fe80039af9050c73e91d3b98",
X"0039004cfe840395f9130c46e9a638fe",
X"00400046fe89038ef9260c13ea383664",
X"0046003ffe8f0385f93c0bd9ead333ca",
X"004c0038fe960379f9560b9aeb763131",
X"00520032fe9e036cf9730b55ec222e9a",
X"0058002afea7035df9930b0becd62c06",
X"005e0023feb0034df9b70abced902975",
X"0063001cfeba033af9de0a69ee5126e8",
X"00680015fec50326fa070a10ef182460",
X"006c000dfed10311fa3409b4efe421dd",
X"00700006fedd02f9fa630953f0b51f61",
X"0074fffffee902e1fa9408eff18a1ced",
X"0078fff7fef602c7fac80888f2631a80",
X"007bfff0ff0402adfafe081df340181b",
X"007effe9ff110291fb3607b0f41f15bf",
X"0080ffe3ff1f0274fb700740f500136e",
X"0082ffdcff2e0256fbab06cef5e31126",
X"0083ffd6ff3c0237fbe8065af6c70eea",
X"0084ffd0ff4b0218fc2605e4f7ab0cb9",
X"0085ffcaff5a01f8fc65056df8900a94",
X"0085ffc4ff6901d7fca504f5f974087c"
);
	signal addr11,addr21: unsigned(5 downto 0);
begin
	addr11 <= addr1 when rising_edge(clk1);
	addr21 <= addr2 when rising_edge(clk2);
	q1 <= rom1(to_integer(addr11));
	q2 <= rom1(to_integer(addr21));
end architecture;
