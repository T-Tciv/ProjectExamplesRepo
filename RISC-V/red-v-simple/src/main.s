#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

.align 2

.equ DELAY, 0x00100000

.equ GPIO_BASE, 0x10012000
.equ GPIO_OUTPUT_EN,  0x08
.equ GPIO_OUTPUT_VAL, 0x0C
.equ GPIO_IOF_EN,     0x38

#---------------------------------------------------------------------------
.section .text
.global _start

_start:
    csrr  t0, mhartid
    bnez  t0, halt

    la    sp, stack_top

    #--- enable GPIO 5
    li    a0, GPIO_BASE + GPIO_OUTPUT_EN
    li    a1, 0x20
    amoor.w a2,a1,(a0)

    li    a0, GPIO_BASE + GPIO_IOF_EN
    li    a1, ~0x20
    amoand.w a2,a1,(a0)

    #---
main_loop:    
    li    a0, DELAY
    
delay:    
    addi  a0,a0,-1
    bnez  a0, delay
    li    a0, GPIO_BASE + GPIO_OUTPUT_VAL
    li    a1, 0x20
    amoxor.w a2,a1,(a0)
    j     main_loop   

halt:
    j     halt

    
        
    
    