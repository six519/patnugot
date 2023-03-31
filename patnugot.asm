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
%define SYS_WRITE 1

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
	mov			rax, SYS_WRITE
	mov			rdi, STDOUT_FILENO
	mov			rsi, %1
	mov			rdx, %2
	syscall
%endmacro

%macro abuff 1
	mov			r14, %1
	mov			[r10 + r11], r14
	inc			r11
%endmacro

%macro ref_mac 0
	abuff		[prefix_char]
	abuff		[open_brace_char]
	abuff		[two_char]
	abuff		[uj_char]
%endmacro

%macro tp_mac 0
	abuff		[prefix_char]
	abuff		[open_brace_char]
	abuff		[uh_char]
%endmacro

%macro sm_mac 0
	abuff		[prefix_char]
	abuff		[open_brace_char]
	abuff		[qm_char]
	abuff		[two_char]
	abuff		[five_char]
	abuff		[lh_char]
%endmacro

%macro rm_mac 0
	abuff		[prefix_char]
	abuff		[open_brace_char]
	abuff		[qm_char]
	abuff		[two_char]
	abuff		[five_char]
	abuff		[ll_char]
%endmacro

%macro cl_mac 0
	abuff		[prefix_char]
	abuff		[open_brace_char]
	abuff		[uk_char]
%endmacro

	global		main, terminate
	extern		printf, perror, tcsetattr, tcgetattr, iscntrl, read_key, get_size

	section		.data

err_tcsetattr:
	db			"tcsetattr", 0
err_tcgetattr:
	db			"tcgetattr", 0
err_get_window_size:
	db			"get_window_size", 0
test:
	db			"The value is: %d", 0xa, 0

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

tilde_char:
	db			"~"
newline_char:
	db			0xa
carriage_char:
	db			0xd
prefix_char:
	db			`\x1b`
open_brace_char:
	db			"["
two_char:
	db			"2"
uj_char:
	db			"J"
uh_char:
	db			"H"
qm_char:
	db			"?"
five_char:
	db			"5"
ll_char:
	db			"l"
lh_char:
	db			"h"
uk_char:
	db			"K"

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
screen_rows:
	resw		4
screen_cols:
	resw		4
buff:
	resb		255

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

	call		init_editor

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

refresh:
	mov			r10, buff
	mov			r11, 0

	rm_mac
	;ref_mac
	tp_mac

;draw rows
	mov			r12, 0
	mov			r13, [screen_rows]
draw_loop:	
	abuff		[tilde_char]
	cl_mac
	inc			r12

	cmp			r12, r13
	je			dr_cont

	abuff		[carriage_char]
	abuff		[newline_char]
dr_cont:
	cmp			r12, r13
	jne			draw_loop
;end of draw rows

	tp_mac
	sm_mac

	wrt			r10, r11
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

init_editor:
	call		get_window_size
	mov			rdi, err_get_window_size
	cmp			rax, -1
	je			call_terminate
	ret

get_window_size:
	mov			rdi, screen_rows
	mov			rsi, screen_cols
	call		get_size
	cmp			rax, -1
	je			gws_err
	mov			r10, [screen_cols]
	cmp			r10, 0
	je			gws_err

	jmp			gws_ok
gws_err:
	mov			rax, -1
	jmp			gws_end
gws_ok:
	mov			rax, 0
gws_end:
	ret