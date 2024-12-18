AS := nasm

BIN    := patnugot
SRC    := $(wildcard *.asm)
OBJ    := ${SRC:%.asm=%.o}

ASFLAGS += -felf64 -gdwarf

${BIN}: ${OBJ}
	gcc -no-pie -g -o $@ $(LDFLAGS) $^ util.c

%.o: %.asm
	$(AS) -o $@ $(ASFLAGS) $<

clean:
	$(RM) ${BIN} ${OBJ}

.PHONY: clean