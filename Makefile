.PHONY: run

forth.512: forth.s
	nasm -f bin -o forth.512 forth.s

run: forth.512
	qemu-system-i386 -curses -hda forth.512
