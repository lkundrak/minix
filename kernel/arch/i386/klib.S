/* sections */


#include <minix/config.h>
#include <minix/const.h>
#include <machine/asm.h>
#include <machine/interrupt.h>
#include <machine/vm.h>
#include "archconst.h"
#include "kernel/const.h"
#include "sconst.h"
#include <machine/multiboot.h>


/* Easy way to make functions */

/* Make a function of the form func(arg) */

#define STACKARG 8(%ebp)

#define ARG_EAX_ACTION(FUNCTION, ACTION)        ;\
ENTRY(FUNCTION)                         ;\
        push    %ebp                    ;\
        mov     %esp, %ebp              ;\
        mov     STACKARG, %eax           ;\
        ACTION                          ;\
        pop     %ebp                    ;\
        ret

/* Make a function of the form ret = func() */
#define ARG_EAX_RETURN(FUNCTION, EXPR)        ;\
ENTRY(FUNCTION)                         ;\
        push    %ebp                    ;\
        mov     %esp, %ebp              ;\
        mov	EXPR, %eax              ;\
        pop     %ebp                    ;\
	ret

/* Make a function of the form ret = func() */
#define ARG_EAX_SET(FUNCTION, DEST)        ;\
ENTRY(FUNCTION)                         ;\
        push    %ebp                    ;\
        mov     %esp, %ebp              ;\
	mov     STACKARG, %eax		;\
        mov	%eax, DEST              ;\
	jmp 0f /* a jump is required for some sets */ ;\
0: 	pop     %ebp                    ;\
        ret	

/* Make a function of the form ret = func() */
#define ARG_AX_SET(FUNCTION, DEST)        ;\
ENTRY(FUNCTION)                         ;\
        push    %ebp                    ;\
        mov     %esp, %ebp              ;\
	mov     STACKARG, %eax		;\
        mov	%ax, DEST               ;\
	jmp 0f /* a jump is required for some sets */ ;\
0: 	pop     %ebp                    ;\
        ret	

/*
 * This file contains a number of assembly code utility routines needed by the
 * kernel.
 */

ENTRY(__main)
	ret


/*===========================================================================*/
/*				phys_insw				     */
/*===========================================================================*/
/*
 * PUBLIC void phys_insw(Port_t port, phys_bytes buf, size_t count); 
 * Input an array from an I/O port.  Absolute address version of insw(). 
 */
/* transfer data from (disk controller) port to memory */
ENTRY(phys_insw)
	push	%ebp
	mov	%esp, %ebp
	cld
	push	%edi
	push	%es

	mov	$FLAT_DS_SELECTOR, %ecx
	mov	%cx, %es
	mov	8(%ebp), %edx	/* port to read from */
	mov	12(%ebp), %edi	/* destination addr */
	mov	16(%ebp), %ecx	/* byte count */
	shr	$1, %ecx	/* word count */
	rep insw	/* input many words */
	pop	%es
	pop	%edi
	pop	%ebp
	ret


/*===========================================================================*/
/*				phys_insb				     */
/*===========================================================================*/
/*
 * PUBLIC void phys_insb(Port_t port, phys_bytes buf, size_t count); 
 * Input an array from an I/O port.  Absolute address version of insb(). 
 */
/* transfer data from (disk controller) port to memory byte by byte */
ENTRY(phys_insb)
	push	%ebp
	mov	%esp, %ebp
	cld
	push	%edi
	push	%es

	mov	$FLAT_DS_SELECTOR, %ecx
	mov	%cx, %es
	mov	8(%ebp), %edx	/* port to read from */
	mov	12(%ebp), %edi	/* destination addr */
	mov	16(%ebp), %ecx	/* byte count */
	rep insb	/* input many bytes */
	pop	%es
	pop	%edi
	pop	%ebp
	ret


/*===========================================================================*/
/*				phys_outsw				     */
/*===========================================================================*/
/*
 * PUBLIC void phys_outsw(Port_t port, phys_bytes buf, size_t count); 
 * Output an array to an I/O port.  Absolute address version of outsw(). 
 */
/* transfer data from memory to (disk controller) port */
ENTRY(phys_outsw)
	push	%ebp
	mov	%esp, %ebp
	cld
	push	%esi
	push	%ds

	mov	$FLAT_DS_SELECTOR, %ecx
	mov	%cx, %ds
	mov	8(%ebp), %edx	/* port to write to */
	mov	12(%ebp), %esi	/* source addr */
	mov	16(%ebp), %ecx	/* byte count */
	shr	$1, %ecx	/* word count */
	rep outsw	/* output many words */
	pop	%ds
	pop	%esi
	pop	%ebp
	ret


/*===========================================================================*/
/*				phys_outsb				     */
/*===========================================================================*/
/* 
 * PUBLIC void phys_outsb(Port_t port, phys_bytes buf, size_t count);
 * Output an array to an I/O port.  Absolute address version of outsb().
 */
/* transfer data from memory to (disk controller) port byte by byte */
ENTRY(phys_outsb)
	push	%ebp
	mov	%esp, %ebp
	cld
	push	%esi
	push	%ds

	mov	$FLAT_DS_SELECTOR, %ecx
	mov	%cx, %ds
	mov	8(%ebp), %edx	/* port to write to */
	mov	12(%ebp), %esi	/* source addr */
	mov	16(%ebp), %ecx	/* byte count */
	rep outsb	/* output many bytes */
	pop	%ds
	pop	%esi
	pop	%ebp
	ret


/*===========================================================================*/
/*				phys_copy				     */
/*===========================================================================*/
/*
 * PUBLIC phys_bytes phys_copy(phys_bytes source, phys_bytes destination,
 *			phys_bytes bytecount); 
 * Copy a block of data from anywhere to anywhere in physical memory.
 */
	PC_ARGS = 4+4+4+4	/* 4 + 4 + 4 */
/*		es edi esi eip	 src dst len */
ENTRY(phys_copy)
	cld
	push	%esi
	push	%edi
	push	%es

	mov	$FLAT_DS_SELECTOR, %eax
	mov	%ax, %es

	mov	PC_ARGS(%esp), %esi
	mov	PC_ARGS+4(%esp), %edi
	mov	PC_ARGS+4+4(%esp), %eax

	cmp	$10, %eax	/* avoid align overhead for small counts */
	jb	pc_small
	mov	%esi, %ecx	/* align source, hope target is too */
	neg	%ecx
	and	$3, %ecx	/* count for alignment */
	sub	%ecx, %eax

	rep 	movsb %es:(%esi), %es:(%edi)
	mov	%eax, %ecx
	shr	$2, %ecx	/* count of dwords */

	rep 	movsl %es:(%esi), %es:(%edi)
	and	$3, %eax
pc_small:
	xchg	%eax, %ecx	/* remainder */

	rep 	movsb %es:(%esi), %es:(%edi)

	mov	$0, %eax		/* 0 means: no fault */
LABEL(phys_copy_fault)		/* kernel can send us here */
	pop	%es
	pop	%edi
	pop	%esi
	ret

LABEL(phys_copy_fault_in_kernel)	/* kernel can send us here */
	pop	%es
	pop	%edi
	pop	%esi
	mov	%cr2, %eax
	ret

/*===========================================================================*/
/*				copy_msg_from_user			     */
/*===========================================================================*/
/*
 * int copy_msg_from_user(struct proc * p, message * user_mbuf, message * dst);
 *
 * Copies a message of 36 bytes from user process space to a kernel buffer. This
 * function assumes that the process address space is installed (cr3 loaded) and
 * the local descriptor table of this process is loaded too.
 *
 * The %gs segment register is used to access the userspace memory. We load the
 * process' data segment in this register.
 *
 * This function from the callers point of view either succeeds or returns an
 * error which gives the caller a chance to respond accordingly. In fact it
 * either succeeds or if it generates a pagefault, general protection or other
 * exception, the trap handler has to redirect the execution to
 * __user_copy_msg_pointer_failure where the error is reported to the caller
 * without resolving the pagefault. It is not kernel's problem to deal with
 * wrong pointers from userspace and the caller should return an error to
 * userspace as if wrong values or request were passed to the kernel
 */
ENTRY(copy_msg_from_user)
	push	%gs

	mov	8(%esp), %eax
	movw	DSREG(%eax), %gs

	/* load the source pointer */
	mov	12(%esp), %ecx
	/* load the destination pointer */
	mov	16(%esp), %edx

	mov	%gs:0*4(%ecx), %eax
	mov	%eax, 0*4(%edx)
	mov	%gs:1*4(%ecx), %eax
	mov	%eax, 1*4(%edx)
	mov	%gs:2*4(%ecx), %eax
	mov	%eax, 2*4(%edx)
	mov	%gs:3*4(%ecx), %eax
	mov	%eax, 3*4(%edx)
	mov	%gs:4*4(%ecx), %eax
	mov	%eax, 4*4(%edx)
	mov	%gs:5*4(%ecx), %eax
	mov	%eax, 5*4(%edx)
	mov	%gs:6*4(%ecx), %eax
	mov	%eax, 6*4(%edx)
	mov	%gs:7*4(%ecx), %eax
	mov	%eax, 7*4(%edx)
	mov	%gs:8*4(%ecx), %eax
	mov	%eax, 8*4(%edx)

LABEL(__copy_msg_from_user_end)

	pop	%gs

	movl	$0, %eax
	ret

/*===========================================================================*/
/*				copy_msg_to_user			     */
/*===========================================================================*/
/*
 * void copy_msg_to_user(struct proc * p, message * src, message * user_mbuf);
 *
 * Copies a message of 36 bytes to user process space from a kernel buffer. This
 * function assumes that the process address space is installed (cr3 loaded) and
 * the local descriptor table of this process is loaded too.
 *
 * All the other copy_msg_from_user() comments apply here as well!
 */
ENTRY(copy_msg_to_user)
	push	%gs

	mov	8(%esp), %eax
	movw	DSREG(%eax), %gs

	/* load the source pointer */
	mov	12(%esp), %ecx
	/* load the destination pointer */
	mov	16(%esp), %edx

	mov	0*4(%ecx), %eax
	mov	%eax, %gs:0*4(%edx)
	mov	1*4(%ecx), %eax
	mov	%eax, %gs:1*4(%edx)
	mov	2*4(%ecx), %eax
	mov	%eax, %gs:2*4(%edx)
	mov	3*4(%ecx), %eax
	mov	%eax, %gs:3*4(%edx)
	mov	4*4(%ecx), %eax
	mov	%eax, %gs:4*4(%edx)
	mov	5*4(%ecx), %eax
	mov	%eax, %gs:5*4(%edx)
	mov	6*4(%ecx), %eax
	mov	%eax, %gs:6*4(%edx)
	mov	7*4(%ecx), %eax
	mov	%eax, %gs:7*4(%edx)
	mov	8*4(%ecx), %eax
	mov	%eax, %gs:8*4(%edx)

LABEL(__copy_msg_to_user_end)

	pop	%gs

	movl	$0, %eax
	ret

/*
 * if a function from a selected set of copies from or to userspace fails, it is
 * because of a wrong pointer supplied by the userspace. We have to clean up and
 * and return -1 to indicated that something wrong has happend. The place it was
 * called from has to handle this situation. The exception handler redirect us
 * here to continue, clean up and report the error
 */
ENTRY(__user_copy_msg_pointer_failure)
	pop	%gs

	movl	$-1, %eax
	ret

/*===========================================================================*/
/*				phys_memset				     */
/*===========================================================================*/
/*
 * PUBLIC void phys_memset(phys_bytes source, unsigned long pattern, 
 *	phys_bytes bytecount); 
 * Fill a block of physical memory with pattern. 
 */
ENTRY(phys_memset)
	push	%ebp
	mov	%esp, %ebp
	push	%esi
	push	%ebx
	push	%ds

	mov	8(%ebp), %esi
	mov	16(%ebp), %eax
	mov	$FLAT_DS_SELECTOR, %ebx
	mov	%bx, %ds
	mov	12(%ebp), %ebx
	shr	$2, %eax
fill_start:
	mov	%ebx, (%esi)
	add	$4, %esi
	dec	%eax
	jne	fill_start
/* Any remaining bytes? */
	mov	16(%ebp), %eax
	and	$3, %eax
remain_fill:
	cmp	$0, %eax
	je	fill_done
	movb	12(%ebp), %bl
	movb	%bl, (%esi)
	add	$1, %esi
	inc	%ebp
	dec	%eax
	jmp	remain_fill

fill_done:
LABEL(memset_fault)		/* kernel can send us here */
	mov	$0, %eax		/* 0 means: no fault */
	pop	%ds
	pop	%ebx
	pop	%esi
	pop	%ebp
	ret

LABEL(memset_fault_in_kernel)		/* kernel can send us here */
	pop	%ds
	pop	%ebx
	pop	%esi
	pop	%ebp
	mov	%cr2, %eax
	ret


/*===========================================================================*/
/*				mem_rdw					     */
/*===========================================================================*/
/* 
 * PUBLIC u16_t mem_rdw(U16_t segment, u16_t *offset); 
 * Load and return word at far pointer segment:offset. 
 */
ENTRY(mem_rdw)
	mov	%ds, %cx
	mov	4(%esp), %ds
	mov	4+4(%esp), %eax	/* offset */
	movzwl	(%eax), %eax	/* word to return */
	mov	%cx, %ds
	ret


/*===========================================================================*/
/*				x86_triplefault				     */
/*===========================================================================*/
/*
 * PUBLIC void x86_triplefault(); 
 * Reset the system by loading IDT with offset 0 and interrupting. 
 */
ENTRY(x86_triplefault)
	lidt	idt_zero
	int	$3	/* anything goes, the 386 will not like it */
.data
idt_zero:
.long	0, 0
.text


/*===========================================================================*/
/*			      	halt_cpu				     */
/*===========================================================================*/
/*
 * PUBLIC void halt_cpu(void);
 * reanables interrupts and puts the cpu in the halts state. Once an interrupt
 * is handled the execution resumes by disabling interrupts and continues
 */
ENTRY(halt_cpu)
	sti
	hlt /* interrupts enabled only after this instruction is executed! */
	/*
	 * interrupt handlers make sure that the interrupts are disabled when we
	 * get here so we take only _one_ interrupt after halting the CPU
	 */
	ret

/*===========================================================================*/
/*			      read_flags				     */
/*===========================================================================*/
/*
 * PUBLIC unsigned long read_cpu_flags(void);
 * Read CPU status flags from C.
 */
ENTRY(read_cpu_flags)
	pushf
	mov	(%esp), %eax
	add	$4, %esp
	ret

ENTRY(read_ds)
	mov	$0, %eax
	mov	%ds, %ax
	ret

ENTRY(read_cs)
	mov	$0, %eax
	mov	%cs, %ax
	ret

ENTRY(read_ss)
	mov	$0, %eax
	mov	%ss, %ax
	ret

/*===========================================================================*/
/*                            fpu_routines                                   */
/*===========================================================================*/

/* non-waiting FPU initialization */
ENTRY(fninit)
	fninit
	ret

ENTRY(clts)
	clts
	ret

/* store status word (non-waiting) */
ENTRY(fnstsw)
	xor     %eax, %eax

	/* DO NOT CHANGE THE OPERAND!!! gas2ack does not handle it yet */
	fnstsw	%ax
	ret

/*===========================================================================*/
/*				fxrstor					     */
/*===========================================================================*/
ENTRY(fxrstor)
	mov	4(%esp), %eax
	fxrstor	(%eax)
ENTRY(__fxrstor_end)
	xor     %eax, %eax
	ret

/*===========================================================================*/
/*				frstor					     */
/*===========================================================================*/
ENTRY(frstor)
	mov	4(%esp), %eax
	frstor	(%eax)
ENTRY(__frstor_end)
	xor     %eax, %eax
	ret

/* Shared exception handler for both fxrstor and frstor. */
ENTRY(__frstor_failure)
	mov	$1, %eax
	ret

/* Read/write control registers */
ARG_EAX_RETURN(read_cr0, %cr0);
ARG_EAX_RETURN(read_cr2, %cr2);
ARG_EAX_RETURN(read_cr3, %cr3);
ARG_EAX_RETURN(read_cr4, %cr4);
ARG_EAX_SET(write_cr4, %cr4);
ARG_EAX_SET(write_cr0, %cr0);
ARG_EAX_SET(write_cr3, %cr3);

/* Read/write various descriptor tables */
ARG_EAX_ACTION(x86_ltr, ltr STACKARG );
ARG_EAX_ACTION(x86_lidt, lidtl (%eax));
ARG_EAX_ACTION(x86_lgdt, lgdt (%eax));
ARG_EAX_ACTION(x86_lldt, lldt STACKARG);
ARG_EAX_ACTION(x86_sgdt, sgdt (%eax));
ARG_EAX_ACTION(x86_sidt, sidt (%eax));

/* Load segments */
ARG_AX_SET(x86_load_ds, %ds)
ARG_AX_SET(x86_load_es, %es)
ARG_AX_SET(x86_load_fs, %fs)
ARG_AX_SET(x86_load_gs, %gs)
ARG_AX_SET(x86_load_ss, %ss)

/* FPU */
ARG_EAX_ACTION(fnsave, fnsave (%eax) ; fwait);
ARG_EAX_ACTION(fxsave, fxsave (%eax));
ARG_EAX_ACTION(fnstcw, fnstcw (%eax));

/* invlpg */
ARG_EAX_ACTION(i386_invlpg, invlpg (%eax));

/*===========================================================================*/
/*				getcr3val				     */
/*===========================================================================*/
/* PUBLIC unsigned long getcr3val(void); */
ENTRY(getcr3val)
	mov	%cr3, %eax
	ret

/*
 * Read the Model Specific Register (MSR) of IA32 architecture
 *
 * void ia32_msr_read(u32_t reg, u32_t * hi, u32_t * lo)
 */
ENTRY(ia32_msr_read)
	push	%ebp
	mov	%esp, %ebp

	mov	8(%ebp), %ecx
	rdmsr
	mov	12(%ebp), %ecx
	mov	%edx, (%ecx)
	mov	16(%ebp), %ecx
	mov	%eax, (%ecx)

	pop	%ebp
	ret

/*
 * Write the Model Specific Register (MSR) of IA32 architecture
 *
 * void ia32_msr_write(u32_t reg, u32_t hi, u32_t lo)
 */
ENTRY(ia32_msr_write)
	push	%ebp
	mov	%esp, %ebp

	mov	12(%ebp), %edx
	mov	16(%ebp), %eax
	mov	8(%ebp), %ecx
	wrmsr

	pop	%ebp
	ret

/*===========================================================================*/
/*			      idt_reload				     */
/*===========================================================================*/
/*  PUBLIC void idt_reload (void); */
/* reload idt when returning to monitor. */
ENTRY(idt_reload)
	lidt	_C_LABEL(gdt)+IDT_SELECTOR /*  reload interrupt descriptor table */
	ret

/*
 * void reload_segment_regs(void)
 */

#define RELOAD_SEG_REG(reg)	\
	mov	reg, %ax	;\
	mov	%ax, reg	;

ENTRY(reload_ds)
	RELOAD_SEG_REG(%ds)
	ret

/*===========================================================================*/
/*			      __switch_address_space			     */
/*===========================================================================*/
/* PUBLIC void __switch_address_space(struct proc *p, struct ** ptproc)
 *
 * sets the %cr3 register to the supplied value if it is not already set to the
 * same value in which case it would only result in an extra TLB flush which is
 * not desirable
 */
ENTRY(__switch_address_space)
	/* read the process pointer */
	mov	4(%esp), %edx
	/* enable process' segment descriptors  */
	lldt	P_LDT_SEL(%edx)
	/* get the new cr3 value */
	movl	P_CR3(%edx), %eax
	/* test if the new cr3 != NULL */
	cmpl	$0, %eax
	je	0f

	/*
	 * test if the cr3 is loaded with the current value to avoid unnecessary
	 * TLB flushes
	 */
	mov	%cr3, %ecx
	cmp	%ecx, %eax
	je	0f
	mov	%eax, %cr3
	/* get ptproc */
	mov	8(%esp), %eax
	mov	%edx, (%eax)
0:
	ret

/*===========================================================================*/
/*				poweroff					     */
/*===========================================================================*/
/* PUBLIC void poweroff(); */
/* Jump to 16-bit poweroff code */
ENTRY(poweroff_jmp)
	cli
	/* Make real mode descriptor */
	mov	$(_C_LABEL(gdt) + SS_SELECTOR), %edi
	mov	$0x100, %eax
	movw %ax, 2(%edi)
	shr	$16, %eax
	movb	%al, 4(%edi)
	and	$0xff00, %ax
	andw	$0xff, 6(%edi)
	or	%ax, 6(%edi)
	mov	$0xffff, %eax
	movw	%ax, (%edi)
	shr	$16, %eax
	and	$0xf, %ax
	andb	$0xf0, 6(%edi)
	or	%ax, 6(%edi)
	
	/* Flush TLB */
	xor	%eax, %eax
	mov	%eax, %cr3
	
	xor	%esp, %esp /* clear esp for real mode*/
	
	/* Reset IDTR */
	lidt	idt_ptr
	
	mov	$SS_SELECTOR, %ax
	mov	%ax, %ds
	mov	%ax, %es
	mov	%ax, %fs
	mov	%ax, %gs
	mov	%ax, %ss
	
	/* Save real mode cr0 in eax */
	mov	%cr0, %eax
	andl	$~I386_CR0_PE, %eax
	
	/* Jump to 16-bit code that is copied to below 1MB */
	ljmp	$MON_CS_SELECTOR, $0

/* acknowledge just the master PIC */
ENTRY(eoi_8259_master)
	movb	$END_OF_INT, %al
	outb	$INT_CTL
	ret
	
/* we have to acknowledge both PICs */
ENTRY(eoi_8259_slave)
	movb	$END_OF_INT, %al
	outb	$INT_CTL
	outb	$INT2_CTL
	ret
	
/* in some cases we need to force TLB update, reloading cr3 does the trick */
ENTRY(refresh_tlb)
	mov	%cr3, %eax
	mov	%eax, %cr3
	ret

#ifdef CONFIG_SMP

/*===========================================================================*/
/*			      smp_get_htt				     */
/*===========================================================================*/
/*  PUBLIC int smp_get_htt(void); */
/*  return true if the processor is hyper-threaded. */
ENTRY(smp_get_htt)
	push	%ebp
	mov	%esp, %ebp
	pushf
	pop	%eax
	mov	%eax, %ebx
	and	$0x200000, %eax
	je	0f
	mov	$0x1, %eax
/* FIXME don't use the byte code */
.byte	0x0f, 0xa2	/*  opcode for cpuid  */
	mov	%edx, %eax
	pop	%ebp
	ret
0:
	xor	%eax, %eax
	pop	%ebp
	ret

/*===========================================================================*/
/*			      smp_get_num_htt				     */
/*===========================================================================*/
/*  PUBLIC int smp_get_num_htt(void); */
/*  Get the number of hyper-threaded processor cores */
ENTRY(smp_get_num_htt)
	push	%ebp
	mov	%esp, %ebp
	pushf
	pop	%eax
	mov	%eax, %ebx
	and	$0x200000, %eax
	je	0f
	mov	$0x1, %eax
/* FIXME don't use the byte code */
.byte	0x0f, 0xa2	/*  opcode for cpuid  */
	mov	%ebx, %eax
	pop	%ebp
	ret
0:
	xor	%eax, %eax
	pop	%ebp
	ret

/*===========================================================================*/
/*			      smp_get_cores				    */
/*===========================================================================*/
/*  PUBLIC int smp_get_cores(void); */
/*  Get the number of cores. */
ENTRY(smp_get_cores)
	push	%ebp
	mov	%esp, %ebp
	pushf
	pop	%eax
	mov	%eax, %ebx
	and	$0x200000, %eax
	je	0f
	push	%ecx
	xor	%ecx, %ecx
	mov	$0x4, %eax
/* FIXME don't use the byte code */
.byte	0x0f, 0xa2	/*  opcode for cpuid  */
	pop	%ebp
	ret
0:
	xor	%eax, %eax
	pop	%ebp
	ret

/*===========================================================================*/
/*				arch_spinlock_lock				    */
/*===========================================================================*/
/* void arch_spinlock_lock (u32_t  *lock_data)
 * {
 * 	while (test_and_set(lock_data) == 1)
 *		while (*lock_data == 1)
 *			;
 * }
 * eax register is clobbered.
 */
ENTRY(arch_spinlock_lock)
	mov	4(%esp), %eax
	mov	$1, %edx
2:
	mov	$1, %ecx
	xchg	%ecx, (%eax)
	test	%ecx, %ecx
	je	0f

	cmp	$(1<< 16), %edx
	je	1f
	shl	%edx
1:
	mov	%edx, %ecx
3:
	pause
	sub	$1, %ecx
	test	%ecx, %ecx
	jz	2b
	jmp	3b
0:
	mfence
	ret

/*===========================================================================*/
/*				arch_spinlock_unlock	                             */
/*===========================================================================*/
/* * void arch_spinlock_unlock (unsigned int *lockp) */
/*  spin lock release routine. */
ENTRY(arch_spinlock_unlock)
	mov	4(%esp), %eax
	mov	$0, %ecx
	xchg	%ecx, (%eax)
	mfence
	ret

#endif /* CONFIG_SMP */

/*===========================================================================*/
/*			      mfence					     */
/*===========================================================================*/
/*  PUBLIC void mfence (void); */
/*  architecture specific memory barrier routine. */
ENTRY(mfence)
	mfence
	ret

/*===========================================================================*/
/*			      arch_pause				     */
/*===========================================================================*/
/*  PUBLIC void arch_pause (void); */
/*  architecture specific pause routine. */
ENTRY(arch_pause)
	pause
	ret

/*===========================================================================*/
/*			      read_ebp				     	     */
/*===========================================================================*/
/*  PUBLIC u16_t cpuid(void) */
ENTRY(read_ebp)
	mov	%ebp, %eax
	ret

ENTRY(interrupts_enable)
	sti
	ret

ENTRY(interrupts_disable)
	cli
	ret


/*
 * void switch_k_stack(void * esp, void (* continuation)(void));
 *
 * sets the current stack pointer to the given value and continues execution at
 * the given address
 */
ENTRY(switch_k_stack)
	/* get the arguments from the stack */
	mov	8(%esp), %eax
	mov	4(%esp), %ecx
	mov	$0, %ebp	/* reset %ebp for stack trace */
	mov	%ecx, %esp	/* set the new stack */
	jmp	*%eax		/* and jump to the continuation */

	/* NOT_REACHABLE */
0:	jmp	0b

.data
idt_ptr:
	.short 0x3ff
	.long 0x0
