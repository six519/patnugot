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
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_FTRUNCATE 77
%define TAB_STOP 8

%macro terminate_without_termios 1
	call		clear_screen
	mov			rdi, %1
	call		perror
	mov			rdi, 1
	call		exit
%endmacro

%macro get_termios 1
	mov			rdi, STDIN_FILENO
	mov			rsi, %1
	call		tcgetattr
%endmacro

%macro set_termios 1
	mov			rdi, STDIN_FILENO
	mov			rsi, TCSAFLUSH
	mov			rdx, %1
	call		tcsetattr
%endmacro

%macro terminate_with_termios 1
	set_termios	orig_termios
	call		clear_screen
	mov			rdi, %1
	call		perror
	mov			rdi, 1
	call		exit
	ret
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
	mov			[buff + r11], r14
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

%macro align_stack 0
	sub			rsp, 8
%endmacro

%macro restore_stack 0
	add			rsp, 8
%endmacro

	default		rel
	global		main
	extern		printf, perror, tcsetattr, tcgetattr, iscntrl, read_key, get_size, snprintf, strlen, set_xy, get_x, get_y, set_rx, get_rx, move_cursor, open_editor, get_rows_count, get_row_size, get_row_rsize, get_row_chars, get_row_render, get_row_offset, set_row_offset, get_col_offset, set_col_offset, set_tab_stop, to_render, insert_char, rows_to_string, free, del_char, insert_newline

	section		.data

err_tcsetattr:
	db			"tcsetattr", 0
err_tcgetattr:
	db			"tcgetattr", 0
err_get_window_size:
	db			"get_window_size", 0
err_fopen:
	db			"fopen", 0
err_read_key:
	db			"read_key", 0
test_int:
	db			"The value is: %d", 0xa, 0
file_flags:
	dq			0x41 ; O_RDWR | O_CREAT
file_mode:
	dq			0x180 ; 0644

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

test_str:
	db			"The value is: %s", 0xa, 0
test_chr:
	db			"The value is: %c", 0xa, 0

tilde_char:
	db			"~", 0
newline_char:
	db			0xa, 0
carriage_char:
	db			0xd, 0
prefix_char:
	db			`\x1b`, 0
open_brace_char:
	db			"[", 0
two_char:
	db			"2", 0
uj_char:
	db			"J", 0
uh_char:
	db			"H", 0
qm_char:
	db			"?", 0
five_char:
	db			"5", 0
ll_char:
	db			"l", 0
lh_char:
	db			"h", 0
uk_char:
	db			"K", 0
space_char:
	db			" ", 0

ref_str:
	db			`\x1b[2J`, 0
tp_str:
	db			`\x1b[H`, 0
cursor_str:
	db			`\x1b[%d;%dH`, 0
ctrl_check:
	dd			0x1f, 0
char_quit:
	dd			'q', 0
char_save:
	dd			's', 0
char_refresh:
	dd			'l', 0

char_up:
	dd			1000, 0
char_down:
	dd			1001, 0
char_left:
	dd			1003, 0
char_right:
	dd			1002, 0
char_home:
	dd			1004, 0
char_del:
	dd			1005, 0
char_end:
	dd			1006, 0
char_page_up:
	dd			1007, 0
char_page_down:
	dd			1008, 0
char_backspace:
	dd			127, 0
char_enter:
	dd			13, 0
char_escape:
	dd			27, 0
char_control_l:
	dd			12, 0
char_control_s:
	dd			19, 0

version_text:
	db			"Patnugot v1.0.0 by six519", 0
version_length: 	equ			$-version_text

	section		.bss

row_str_len:
	resq		1
fname:
	resq		1
temp_count:
	resw		4
input_char:
	resb		1
screen_rows:
	resw		4
screen_cols:
	resw		4
boundary:
	resw		4
cursor_boundary:
	resw		4
loop_counter:
	resw		4
padding:
	resw		4
buff:
	resb		1048576 ; 1 MB buffer
buff_cursor:
	resb		32
cursor_y:
	resw		4
cursor_x:
	resw		4
temp_cursor_y:
	resw		4
temp_cursor_x:
	resw		4

	section		.text

main:
	sub			rsp, 8
	mov			[temp_count], rdi
	cmp			word [temp_count], 2
	jl			no_param

	mov			rax, [rsi + 8]
	mov			[fname], rax

no_param:
	mov			rdi, TAB_STOP
	call		set_tab_stop
	get_termios	orig_termios
	cmp			rax, -1
	jne			main_get_termios
	terminate_without_termios err_tcgetattr

main_get_termios:
	get_termios	raw_termios
	cmp			rax, -1
	jne			main_enable_raw_mode
	terminate_without_termios err_tcgetattr

main_enable_raw_mode:
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
	cmp			rax, -1
	jne			main_init_editor
	terminate_without_termios	err_tcsetattr

main_init_editor:
	call		init_editor

	;check cmd argument
	cmp			word [temp_count], 2
	jne			main_loop ;no argument

	;with argument
	mov			rdi, [fname]
	call		open_editor
	cmp			rax, 6519
	jne			main_loop
	terminate_with_termios	err_fopen
	;end with argument

main_loop:
	align_stack
	call		refresh
	restore_stack
	align_stack
	call		process_key
	restore_stack

	jmp			main_loop

;process key
process_key:
	call		get_x
	mov			[cursor_x], rax
	call		get_y
	mov			[cursor_y], rax

	call		read_key
	cmp			rax, 6519
	jne			process_key_continue
	terminate_with_termios	err_read_key

process_key_continue:
	mov			r15, rax
	mov			rdi, [char_quit]
	call		check_ctrl_key
	cmp			rax, r15
	je			disable_raw

	cmp			[char_up], r15
	je			move_up
	cmp			[char_down], r15
	je			move_down
	cmp			[char_left], r15
	je			move_left
	cmp			[char_right], r15
	je			move_right
	cmp			[char_home], r15
	je			move_home_key
	cmp			[char_end], r15
	je			move_end_key
	cmp			[char_page_up], r15
	je			move_page_up
	cmp			[char_page_down], r15
	je			move_page_down
	cmp			[char_backspace], r15
	je			backspace_key
	cmp			[char_enter], r15
	je			enter_key
	cmp			[char_del], r15
	je			del_key
	cmp			[char_escape], r15
	je			escape_key

	mov			rdi, [char_refresh]
	call		check_ctrl_key
	cmp			rax, r15
	je			control_l_key

	mov			rdi, [char_save]
	call		check_ctrl_key
	cmp			rax, r15
	je			control_s_key

	jmp			other_key

control_s_key:
	call		save_file
	cmp			rax, 1
	je			disable_raw
	jmp			process_key_ret

control_l_key:
	; do nothing
	jmp			process_key_ret

escape_key:
	; do nothing
	jmp			process_key_ret

backspace_key:
	; handle backspace
	call		del_char
	jmp			process_key_ret

enter_key:
	; handle enter
	call		insert_newline
	jmp			process_key_ret

del_key:
	; handle del key
	mov			r10, -1
	call		get_rows_count
	mov			r14, rax
	cmp			[cursor_y], r14
	jge			del_key_dont_check_right
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			r10, rax
	inc			r10 ; NOT SURE IF THIS IS A PERMANET FIX!
del_key_dont_check_right:
	cmp			[cursor_x], r10
	jge			del_key_right_end_of_line
	inc			word [cursor_x]
del_key_right_end_of_line:
	cmp			[cursor_x], r10
	jne			del_key_move_end
	inc			word [cursor_y]
	mov			word [cursor_x], 0
	jmp			del_key_move_end
del_key_move_end:
	mov			r10, -1
	call		get_rows_count
	mov			r14, rax
	cmp			[cursor_y], r14
	jge			del_key_ignore_set_rowlen1
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			r10, rax
del_key_ignore_set_rowlen1:
	mov			r14, 0
	cmp			r10, -1
	je			del_key_ignore_set_rowlen2
	mov			r14, r10
del_key_ignore_set_rowlen2:
	cmp			[cursor_x], r14
	jle			del_key_ignore_set_rowlen3
	mov			[cursor_x], r14
del_key_ignore_set_rowlen3:

	mov			rdi, [cursor_x]
	mov			rsi, [cursor_y]
	call		set_xy
	
	call		del_char
	jmp			process_key_ret

move_page_up:

	call		get_row_offset
	mov			[cursor_y], rax

pg_up:
	mov			r8, [screen_rows]
	mov			r9, 0
pg_up_loop:
	; editor move cursor
	cmp			word [cursor_y], 0
	je			move_end
	dec			word [cursor_y]
	inc			r9
	cmp			r8, r9
	jne			pg_up_loop
	jmp			move_end

move_page_down:

	call		get_row_offset
	add			rax, [screen_rows]
	dec			rax
	mov			[cursor_y], rax
	call		get_rows_count
	cmp			[cursor_y], rax
	jle			pg_down
	mov			[cursor_y], rax

pg_down:
	mov			r8, [screen_rows]
	mov			r9, 0
pg_down_loop:
	; editor move cursor
	call		get_rows_count
	mov			r10, rax
	cmp			[cursor_y], r10
	jge			move_end
	inc			word [cursor_y]
	inc			r9
	cmp			r8, r9
	jne			pg_down_loop
	jmp			move_end

move_home_key:
	mov			word [cursor_x], 0
	jmp			move_end

move_end_key:
	;mov			r10, [screen_cols]
	;dec			r10
	;mov			[cursor_x], r10
	;jmp			move_end

	call		get_rows_count
	cmp			[cursor_y], rax
	jge			move_end
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			[cursor_x], rax
	jmp			move_end

move_left:
	cmp			word [cursor_x], 0
	je			check_zero		
	dec			word [cursor_x]
	jmp			move_end
check_zero:
	cmp			word [cursor_y], 0
	jle			move_end
	dec			word [cursor_y]
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			[cursor_x], rax
	jmp			move_end

move_right:
	;mov			r10, [screen_cols]
	;dec			r10
	;cmp			[cursor_x], r10
	;je			move_end
	mov			r10, -1
	call		get_rows_count
	mov			r14, rax
	cmp			[cursor_y], r14
	jge			dont_check_right
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			r10, rax
	inc			r10 ; NOT SURE IF THIS IS A PERMANET FIX!

dont_check_right:

	cmp			[cursor_x], r10
	jge			right_end_of_line
	inc			word [cursor_x]

right_end_of_line:

	cmp			[cursor_x], r10
	jne			move_end
	inc			word [cursor_y]
	mov			word [cursor_x], 0
	jmp			move_end
move_up:
	cmp			word [cursor_y], 0
	je			move_end
	dec			word [cursor_y]
	jmp			move_end
move_down:
	call		get_rows_count
	mov			r10, rax
	cmp			[cursor_y], r10
	jge			move_end
	inc			word [cursor_y]
	jmp			move_end

other_key:
	mov			rdi, r15
	call		insert_char
	jmp			process_key_ret
move_end:

	mov			r10, -1
	call		get_rows_count
	mov			r14, rax

	cmp			[cursor_y], r14
	jge			ignore_set_rowlen1
	mov			rdi, [cursor_y]
	call		get_row_size
	mov			r10, rax
ignore_set_rowlen1:
	mov			r14, 0
	cmp			r10, -1
	je			ignore_set_rowlen2
	mov			r14, r10
ignore_set_rowlen2:
	cmp			[cursor_x], r14
	jle			ignore_set_rowlen3
	mov			[cursor_x], r14
ignore_set_rowlen3:

	mov			rdi, [cursor_x]
	mov			rsi, [cursor_y]
	call		set_xy
process_key_ret:
	ret

refresh:
	mov			byte [buff + 0], 0

	mov			rdi, 0
	call		set_rx
	call		to_render

	mov			r10, [cursor_y]
	call		get_row_offset
	mov			r11, rax

	cmp			r10, r11
	jge			cond_1
	mov			rdi, r10
	call		set_row_offset
cond_1:

	add			r11, [screen_rows]
	cmp			r10, r11
	jl			cond_2
	sub			r10, [screen_rows]
	inc			r10
	mov			rdi, r10
	call		set_row_offset

cond_2:

	call		get_rx
	mov			r10, rax
	call		get_col_offset
	mov			r11, rax

	cmp			r10, r11
	jge			cond_3
	mov			rdi, r10
	call		set_col_offset
cond_3:

	add			r11, [screen_cols]
	cmp			r10, r11
	jl			cond_4
	sub			r10, [screen_cols]
	inc			r10
	mov			rdi, r10
	call		set_col_offset

cond_4:

	;mov			r10, buff
	mov			r11, 0

	rm_mac
	;ref_mac
	tp_mac

;draw rows
	mov			r12, 0
	mov			r13, [screen_rows]
draw_loop:
	call		get_row_offset
	mov			r15, rax
	add			r15, r12

	call		get_rows_count
	cmp			r15, rax
	jl			else_draw_rows

	mov			word [temp_count], 0
	cmp			rax, 0
	jne			check_div
	inc			word [temp_count]

check_div:
	mov			r8, 3 ;divisor
	xor			rdx, rdx
	mov			rax, [screen_rows] ;dividend
	idiv		r8

	cmp			rax, r12
	jne			check_tilde
	inc			word [temp_count]

check_tilde:
	cmp			word [temp_count], 2
	jne			draw_tilde

;draw title
	cmp			word [screen_cols], version_length
	jl			rlt_label
	mov			r14, version_length
	jmp			check_done
rlt_label:
	mov			r14, [screen_cols]
check_done:
	mov			[boundary], r14

	;padding code here
	mov			r14, [screen_cols]
	mov			[padding], r14
	mov			r14, [boundary]
	sub			[padding], r14
	mov			r8, 2 ;divisor
	xor			rdx, rdx
	mov			rax, [padding] ;dividend
	idiv		r8
	mov			[padding], rax
	cmp			rax, 0
	jle			while_padding_check
	abuff		[tilde_char]
	dec			word [padding]
while_padding_check:
	cmp			word [padding], 0
	jle			while_padding_end
while_padding_loop:
	abuff		[space_char]
	dec			word [padding]
	cmp			word [padding], 0
	jne			while_padding_loop
while_padding_end:
	;end of padding code here

	mov			r14, 0
	mov			[loop_counter], r14

check_done_loop:
	abuff		[version_text + r14]
	inc			word [loop_counter]
	mov			r14, [loop_counter]
	cmp			r14, [boundary]
	jne			check_done_loop

;end of draw title

	jmp			no_tilde
draw_tilde:
	abuff		[tilde_char]
	jmp			no_tilde

else_draw_rows:

	call		get_row_offset
	mov			r15, rax
	add			r15, r12

	call		get_col_offset
	mov			r10, rax
	
	mov			rdi, r15
	call		get_row_rsize
	sub			rax, r10
	mov			r10, rax

	cmp			r10, 0
	jge			dont_zero
	mov			r10, 0

dont_zero:

	cmp			r10, [screen_cols]
	jle			len_less
	mov			r14, [screen_cols]
	mov			[boundary], r14
	jmp			append_contents

len_less:
	mov			[boundary], r10

append_contents:
	call		get_col_offset
	mov			r10, rax

	mov			rdi, r15
	mov			rsi, r10
	call		get_row_render

	mov			r14, 0
	mov			[loop_counter], r14

	cmp			word [boundary], 0
	jle			no_tilde

check_done_loop_contents:
	abuff		[rax + r14]
	inc			word [loop_counter]
	mov			r14, [loop_counter]
	cmp			r14, [boundary]
	jl			check_done_loop_contents

no_tilde:
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

	;tp_mac
	sm_mac

	wrt			buff, r11
	call		move_cursor
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

exit:
	mov			rax, 0x3c
	syscall
	ret

check_ctrl_key:
	and			rdi, [ctrl_check]
	mov			rax, rdi
	ret

init_editor:
	call		get_x
	mov			[cursor_x], rax
	call		get_y
	mov			[cursor_y], rax

	call		get_window_size
	cmp			rax, -1
	jne			init_editor_return
	terminate_with_termios	err_get_window_size
init_editor_return:
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

save_file:
	mov			rax, [fname]
	test		rax, rax
	jz			set_return_to_zero

	mov			rdi, row_str_len
	call		rows_to_string
	mov			rbx, rax

	mov			rdi, [fname]
	mov			rsi, [file_flags]
	mov			rdx, [file_mode]
	mov			rax, SYS_OPEN
	syscall
	mov			r8, rax

	mov			rdi, r8
	mov			rsi, [row_str_len]
	mov			rax, SYS_FTRUNCATE
	syscall

	; write to file
	mov			rdi, r8
	mov			rsi, rbx
	mov			rdx, [row_str_len]
	mov			rax, SYS_WRITE
	syscall

	; close file and free buffer
	mov			rdi, r8
	mov			rax, SYS_CLOSE
	syscall

	mov			rdi, rbx
	call		free
	mov			rax, 1
	jmp			save_file_return

set_return_to_zero:
	mov			rax, 0
save_file_return:
	ret