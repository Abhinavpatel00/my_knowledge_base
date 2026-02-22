	.file	"ok.c"
# GNU C99 (GCC) version 15.2.1 20260103 (x86_64-pc-linux-gnu)
#	compiled by GNU C version 15.2.1 20260103, GMP version 6.3.0, MPFR version 4.2.2, MPC version 1.3.1, isl version isl-0.27-GMP

# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -mtune=generic -march=x86-64 -std=c99 -fsanitize=undefined -fstack-protector-strong
	.text
	.data
	.align 2
	.type	.Lubsan_type0, @object
	.size	.Lubsan_type0, 10
.Lubsan_type0:
# __typekind:
	.value	0
# __typeinfo:
	.value	11
# __typename:
	.string	"'int'"
	.section	.rodata
.LC0:
	.string	"demo/ok.c"
	.section	.data.rel.local,"aw"
	.align 16
	.type	.Lubsan_data1, @object
	.size	.Lubsan_data1, 24
.Lubsan_data1:
# <anonymous>:
# __filename:
	.quad	.LC0
# __line:
	.long	6
# __column:
	.long	6
# <anonymous>:
	.quad	.Lubsan_type0
	.section	.rodata
.LC1:
	.string	"%d"
	.text
	.globl	ok
	.type	ok, @function
ok:
.LFB0:
	.cfi_startproc
	pushq	%rbp	#
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp	#,
	.cfi_def_cfa_register 6
	pushq	%rbx	#
	subq	$24, %rsp	#,
	.cfi_offset 3, -24
# demo/ok.c:6:     a++;
	movl	-20(%rbp), %eax	# a, tmp99
	addl	$1, %eax	#, tmp99
	movl	%eax, %ebx	# tmp99, tmp98
	jno	.L2	#,
	movl	-20(%rbp), %eax	# a, tmp101
	cltq
	leaq	.Lubsan_data1(%rip), %rcx	#, tmp102
	movl	$1, %edx	#,
	movq	%rax, %rsi	# tmp100,
	movq	%rcx, %rdi	# tmp102,
	call	__ubsan_handle_add_overflow@PLT	#
.L2:
	movl	%ebx, -20(%rbp)	# tmp98, a
# demo/ok.c:7:     printf("%d", a);
	movl	-20(%rbp), %eax	# a, tmp103
	leaq	.LC1(%rip), %rdx	#, tmp104
	movl	%eax, %esi	# tmp103,
	movq	%rdx, %rdi	# tmp104,
	movl	$0, %eax	#,
	call	printf@PLT	#
# demo/ok.c:8: }
	nop	
	movq	-8(%rbp), %rbx	#,
	leave	
	.cfi_def_cfa 7, 8
	ret	
	.cfi_endproc
.LFE0:
	.size	ok, .-ok
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	pushq	%rbp	#
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp	#,
	.cfi_def_cfa_register 6
# demo/ok.c:12:     ok();
	movl	$0, %eax	#,
	call	ok	#
# demo/ok.c:13:     ok();
	movl	$0, %eax	#,
	call	ok	#
# demo/ok.c:14:     ok();
	movl	$0, %eax	#,
	call	ok	#
# demo/ok.c:15:     ok();
	movl	$0, %eax	#,
	call	ok	#
# demo/ok.c:16:     ok();
	movl	$0, %eax	#,
	call	ok	#
# demo/ok.c:18:     return 0;
	movl	$0, %eax	#, _7
# demo/ok.c:19: }
	popq	%rbp	#
	.cfi_def_cfa 7, 8
	ret	
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.section	.data.rel.local
	.align 32
	.type	.Lubsan_data0, @object
	.size	.Lubsan_data0, 40
.Lubsan_data0:
# <anonymous>:
# __filename:
	.quad	.LC0
# __line:
	.long	7
# __column:
	.long	5
# <anonymous>:
# __filename:
	.quad	0
# __line:
	.long	0
# __column:
	.long	0
# <anonymous>:
	.long	1
	.zero	4
	.ident	"GCC: (GNU) 15.2.1 20260103"
	.section	.note.GNU-stack,"",@progbits
