flash:
	sudo openFPGALoader --cable dirtyJtag -v --file-type bin top.bit

play:
	python3 stream_wav_uart.py /dev/ttyACM0 Original_Kore.wav

fplay:
	make flash; python3 stream_wav_uart.py /dev/ttyACM0 Original_Kore.wav
