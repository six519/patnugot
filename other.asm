	global		die, exit, check_ctrl_key

	section		.data
ctrl_check:
	dd			0x1f

	section		.text
	extern		perror

die:
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