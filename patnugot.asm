%define STDIN_FILENO 0
%define STDOUT_FILENO 1
%define TCSAFLUSH 2
%define VMIN 6
%define VTIME 5
%define BRKINT 0x2
%define ICRNL 0x100
%define INPCK 0x10
%define ISTRIP 0x20
%define IXON 0x400
%define OPOST 0x1
%define CS8 0x30
%define ECHO 0x8
%define ICANON 0x2
%define IEXTEN 0x8000
%define ISIG 0x1

%macro get_termios 1
	mov			rdi, STDIN_FILENO
	mov			rsi, %1
	call		tcgetattr
	mov			rdi, err_tcgetattr
	cmp			rax, -1
	je			call_terminate
%endmacro

%macro set_termios 1
	mov			rdi, STDIN_FILENO
	mov			rsi, TCSAFLUSH
	mov			rdx, %1
	call		tcsetattr
	mov			rdi, err_tcsetattr
	cmp			rax, -1
	je			call_terminate
%endmacro

%macro print 1
	mov			rdi, %1
	xor			rax, rax
	call		printf
%endmacro

%macro wrt 2
	;write
	mov			rdi, STDOUT_FILENO
	mov			rsi, %1
	mov			rdx, %2
	call		write
%endmacro

	global		main, terminate
	extern		printf, write, perror, tcsetattr, tcgetattr, read, iscntrl, read_key

	section		.data

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

tilde:
	db			"~", 0xd, 0xa, 0
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
	call		read_key
	mov			r15, rax
	mov			rdi, [char_quit]
	call		check_ctrl_key
	cmp			rax, r15
	je			disable_raw
	ret

draw_rows:
	mov			r12, 0
draw_loop:	
	wrt			tilde, 3
	inc			r12
	cmp			r12, 24
	jne			draw_loop
	ret

refresh:
	call		clear_screen
	call		draw_rows
	wrt			tp_str, 3
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

call_terminate:
	call		terminate

terminate:
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