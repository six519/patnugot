%include "include.inc"

	global		main
	extern		printf, perror, tcsetattr, tcgetattr, read, iscntrl, die, exit, check_ctrl_key

	section		.data

err_read:
	db			"read", 0
err_tcsetattr:
	db			"tcsetattr", 0
err_tcgetattr:
	db			"tcgetattr", 0
output1:
	db			"%d", 0xd, 0xa, 0
output2:
	db			"%d ('%c')", 0xd, 0xa, 0
intro:
	db			"Type from your keyboard. Press CTRL + q to exit.", 0xd, 0xa, 0

struc TERMIOS
	c_iflag: resd 1
	c_oflag: resd 1
	c_cflag: resd 1
	c_lflag: resd 1
	c_cc: resb 255
endstruc

orig_termios: istruc TERMIOS
	at c_iflag, dd 0
	at c_oflag, dd 0
	at c_cflag, dd 0
	at c_lflag, dd 0
	at c_cc, db ""
iend

raw_termios: istruc TERMIOS
	at c_iflag, dd 0
	at c_oflag, dd 0
	at c_cflag, dd 0
	at c_lflag, dd 0
	at c_cc, db ""
iend

char_quit:
	dd			'q'

	section		.bss
input_char:
	resb		1

	section		.text

main:
	print		intro
	get_termios	orig_termios
	get_termios	raw_termios

	;enable raw mode
	;set c_iflag
	mov			r15, BRKINT
	or			r15, ICRNL
	or			r15, INPCK
	or			r15, ISTRIP
	or			r15, IXON
	not			r15
	mov			r14, [raw_termios + c_iflag]
	and			r14, r15
	mov			[raw_termios + c_iflag], r14

	;set c_oflag
	mov			r15, OPOST
	not			r15
	mov			r14, [raw_termios + c_oflag]
	and			r14, r15
	mov			[raw_termios + c_oflag], r14

	;set c_cflag
	mov			r15, CS8
	mov			r14, [raw_termios + c_cflag]
	or			r14, r15
	mov			[raw_termios + c_cflag], r14

	;set c_lflag
	mov			r15, ECHO
	or			r15, ICANON
	or			r15, IEXTEN
	or			r15, ISIG
	not			r15
	mov			r14, [raw_termios + c_lflag]
	and			r14, r15
	mov			[raw_termios + c_lflag], r14

	;set VMIN and VTIME
	mov			r15, raw_termios + c_cc
	mov			byte [r15 + VMIN], 0
	mov			byte [r15 + VTIME], 1
	mov			[raw_termios + c_cc], r15

	set_termios	raw_termios
	;end of enable raw mode

main_loop:
	mov			[input_char], byte 0
	mov			rdi, STDIN_FILENO
	mov			rsi, input_char
	mov			rdx, 1
	call		read
	mov			rdi, err_read
	cmp			rax, -1
	je			call_die

	mov			rdi, [input_char]
	call		iscntrl
	cmp			rax, 0
	je			isnotctrl

	cmp			byte [input_char], 0
	je			ender

	mov			rsi, [input_char]
	print		output1

ender:
	mov			rdi, [char_quit]
	call		check_ctrl_key
	cmp			rax, [input_char]
	je			break

	jmp			main_loop

isnotctrl:
	mov			rdx, [input_char]
	mov			rsi, [input_char]
	print		output2

	jmp			ender	

break:
	set_termios	orig_termios
	mov			rdi, 0
	call		exit

call_die:
	call		die