AS := nasm

BIN    := patnugot
SRC    := $(wildcard *.asm)
OBJ    := ${SRC:%.asm=%.o}

ASFLAGS += -felf64

${BIN}: ${OBJ}
	gcc -o $@ $(LDFLAGS) $^

%.o: %.asm
	$(AS) -o $@ $(ASFLAGS) $<

clean:
	$(RM) ${BIN} ${OBJ}

.PHONY: clean