all:
	nasm cat.asm -f elf64 -o cat.o && ld -N cat.o -o cat && strip ./cat

clean:
	rm -rf cat.o cat
