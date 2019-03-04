
GHDL := ghdl


fft_types.o: ../fft_types.vhd
	$(GHDL) -a $<

fft4.o: ../fft4.vhd fft_types.o
	$(GHDL) -a $<

fft4_serial.o: ../fft4_serial.vhd fft_types.o
	$(GHDL) -a $<

twiddle_generator.o: ../twiddle_generator.vhd fft_types.o
	$(GHDL) -a $<

twiddle_rom_16.o: ../twiddle_rom_16.vhd
	$(GHDL) -a $<

sr.o: ../../sr.vhd
	$(GHDL) -a $<

complex_ram.o: ../complex_ram.vhd
	$(GHDL) -a $<

complex_multiply.o: ../complex_multiply.vhd
	$(GHDL) -a $<

fft16_serial.o: ../fft16_serial.vhd fft_types.o fft4_serial.o twiddle_generator.o sr.o complex_ram.o complex_multiply.o
	$(GHDL) -a $<

testutil.o: testutil.vhd
	$(GHDL) -a $<

fft4: fft4.o
	$(GHDL) -a test_fft4.vhd
	$(GHDL) -e test_fft4
	$(GHDL) -r test_fft4

fft4_serial: fft4_serial.o
	$(GHDL) -a test_fft4_serial.vhd
	$(GHDL) -e test_fft4_serial
	$(GHDL) -r test_fft4_serial

fft16_serial: fft16_serial.o twiddle_rom_16.o
	$(GHDL) -a test_fft16_serial.vhd
	$(GHDL) -e test_fft16_serial
	$(GHDL) -r test_fft16_serial --ieee-asserts=disable

twiddle1: testutil.o twiddle_generator.o twiddle_rom_16.o
	$(GHDL) -a test_twiddle1.vhd
	$(GHDL) -e test_twiddle1
	$(GHDL) -r test_twiddle1



clean:
	rm -f *.o work-obj93.cf

