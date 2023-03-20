%include "include.inc"

	global		main
	extern		printf, write, perror, tcsetattr, tcgetattr, read, iscntrl

	section		.data

err_read:
	db			"read", 0
err_tcsetattr:
	db			"tcsetattr", 0
err_tcgetattr:
	db			"tcgetattr", 0

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

ref_str:
	db			`\x1b[2J`
tp_str:
	db			`\x1b[H`
ctrl_check:
	dd			0x1f
char_quit:
	dd			'q'

	section		.bss
input_char:
	resb		1

	section		.text

main:
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
	call		refresh
	call		process_key

	jmp			main_loop

;process key
process_key:
	mov			rdi, STDIN_FILENO
	mov			rsi, input_char
	mov			rdx, 1
	call		read
	mov			rdi, err_read
	cmp			rax, -1
	je			call_die
	cmp			rax, 1
	jne			process_key
	mov			rax, [input_char]
	mov			r15, rax
	call		read_key
	ret
;end of process key

read_key:
	mov			rdi, [char_quit]
	call		check_ctrl_key
	cmp			rax, r15
	je			disable_raw
	ret

refresh:
	call		clear_screen
	ret

clear_screen:
	wrt			ref_str, 4 ;clear screen
	wrt			tp_str, 3 ;set cursor position to top-left corner
	ret

disable_raw:
	set_termios	orig_termios
	call		clear_screen
	mov			rdi, 0
	call		exit

call_die:
	call		die

die:
	call		clear_screen
	call		perror
	mov			rdi, 1
	call		exit
	ret

exit:
	mov			rax, 0x3c
	syscall
	ret

check_ctrl_key:
	and			rdi, [ctrl_check]
	mov			rax, rdi
	ret