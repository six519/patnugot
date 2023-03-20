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
	je			call_die
%endmacro

%macro set_termios 1
	mov			rdi, STDIN_FILENO
	mov			rsi, TCSAFLUSH
	mov			rdx, %1
	call		tcsetattr
	mov			rdi, err_tcsetattr
	cmp			rax, -1
	je			call_die
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