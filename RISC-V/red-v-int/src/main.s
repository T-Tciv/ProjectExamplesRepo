#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

.align 2

.equ MTIME_ADDR,       0x0200BFF8
.equ MTIMECMP_ADDR,    0x02004000
.equ DELAY_LO32,       32768
.equ DELAY_HI32,       0

.equ MTIE_MASK,        0x00000080
.equ MIE_MASK,         0x00000008
.equ MPIE_MASK,        0x00000080

.equ MCAUSE_TIMER_INT, 7

.equ GPIO_BASE,        0x10012000
.equ GPIO_OUTPUT_EN,   0x08
.equ GPIO_OUTPUT_VAL,  0x0C
.equ GPIO_IOF_EN,      0x38

.equ GPIO_PIN_MASK,    0x20 # GPIO 5

#---------------------------------------------------------------------------
.section .text
.global _start

_start:
    #--- check is it hart 0
    csrr  t0, mhartid
    bnez  t0, halt

    #--- setup stack pointer
    la    sp, stack_top

    #--- enable GPIO(s)
    li    a0, GPIO_BASE + GPIO_OUTPUT_EN
    li    a1, GPIO_PIN_MASK
    amoor.w a2, a1, (a0)

    li    a0, GPIO_BASE + GPIO_IOF_EN
    li    a1, ~GPIO_PIN_MASK
    amoand.w a2, a1, (a0)

    #--- setup ih_counter = 0
    la    t0, ih_counter
    sw    zero, 0(t0)

    #--- setup 'mtimecmp'
    jal   ra, read_mtime
    li    a2, DELAY_LO32
    li    a3, DELAY_HI32
    jal   ra, add_u64
    jal   ra, set_mtimecmp

    #--- setup 'mtvec' (mode direct)
    la    t0, direct_mode_ih
    csrrw zero, mtvec, t0

    #--- set mie.MTIE = 1 (enable M mode timer interrupt)
    li    t0, MTIE_MASK
    csrrs zero, mie, t0

    #--- set mstatus.MIE = 1 (enable M mode interrupt)
    li    t0, MIE_MASK
    csrrs zero, mstatus, t0

halt:
    #wfi
    j     halt

#---------------------------------------------------------------------------
.global direct_mode_ih
.align 6
direct_mode_ih:
    #--- save registers 
    addi  sp, sp, -28 
    sw    ra, 24(sp)
    sw    t0, 20(sp)
    sw    t1, 16(sp)
    sw    a0, 12(sp)
    sw    a1,  8(sp)
    sw    a2,  4(sp)
    sw    a3,  0(sp)

    #--- check this is an m_timer interrupt
    csrrc t0, mcause, zero
    bgez  t0, bad_int          # interrupt causes are less than zero
    slli  t0, t0, 1            # shift off high bit
    srli  t0, t0, 1
    li    t1, MCAUSE_TIMER_INT # check this is an m_timer interrupt
    bne   t0, t1, bad_int

    #--- setup 'mtimecmp'
    jal   ra, read_mtime
    li    a2, DELAY_LO32
    li    a3, DELAY_HI32
    jal   ra, add_u64
    jal   ra, set_mtimecmp

    #============= clock rate computation
    #--- read mcycleh:mcycle pair
1$:
    csrr  a1, mcycleh
    csrr  a0, mcycle
    csrr  t1, mcycleh
    bne   a1, t1, 1$

    #--- read last_mcycle64
    la    t0, last_mcycle64
    lw    a2, 0(t0)
    lw    a3, 4(t0)

    #--- save actual mcycleh:mcycle value to last_mcycle64
    sw    a0, 0(t0)
    sw    a1, 4(t0)

    #--- compute clock_rate per used time interval (interval betwwen two timer interrupts)
    jal   ra, sub_u64

    #--- save clock_rate
    la    t0, clock_rate
    sw    a0, 0(t0)
    sw    a1, 4(t0)
    #============= clock rate computation (end)

    #--- increment ih_counter
    la    t0, ih_counter
    lw    t1, 0(t0)
    addi  t1, t1, 1
    sw    t1, 0(t0)

    #--- LED toggle
    li    a0, GPIO_BASE + GPIO_OUTPUT_VAL
    li    a1, GPIO_PIN_MASK
    amoxor.w a2,a1,(a0)

    #---
    j     ih_exit

bad_int:
    li    t0, MPIE_MASK
    csrrc zero, mstatus, t0    # disable interrupts by clearing mstatus.MPIE

ih_exit:
    #--- restore registers 
    lw    ra, 24(sp)
    lw    t0, 20(sp)
    lw    t1, 16(sp)
    lw    a0, 12(sp)
    lw    a1,  8(sp)
    lw    a2,  4(sp)
    lw    a3,  0(sp)
    addi  sp, sp, 28 
    mret    

#---------------------------------------------------------------------------
# mtime value returned in a1:a0
#---------------------------------------------------------------------------
read_mtime:
    la    t0, MTIME_ADDR 
1$:
    lw    a1, 4(t0)
    lw    a0, 0(t0)
    lw    t1, 4(t0)
    bne   a1, t1, 1$
    jalr  zero, ra, 0

#---------------------------------------------------------------------------
# new comparand passed in a1:a0
#---------------------------------------------------------------------------
set_mtimecmp:
    li    t0, -1
    la    t1, MTIMECMP_ADDR
    sw    t0, 0(t1) # no smaller than old value
    sw    a1, 4(t1) # no smaller than new value
    sw    a0, 0(t1) # new value
    jalr  zero, ra, 0

#---------------------------------------------------------------------------
# addition of 2 64-bit numbers
# r = a + b
#
# 'a' in a1:a0
# 'b' in a3:a2
# 'r' in a1:a0
#---------------------------------------------------------------------------
add_u64:
    add   a1, a1, a3
    add   a0, a0, a2
    sltu  a2, a0, a2
    add   a1, a1, a2
    jalr  zero, ra, 0

#---------------------------------------------------------------------------
# subtraction of 2 64-bit numbers
# r = a - b
#
# 'a' in a1:a0
# 'b' in a3:a2
# 'r' in a1:a0
#---------------------------------------------------------------------------
sub_u64:
    sltu  t0, a0, a2
    sub   a1, a1, a3
    sub   a1, a1, t0
    sub   a0, a0, a2
    jalr  zero, ra, 0

#---------------------------------------------------------------------------
.section .data
ih_counter:
    .word 0

last_mcycle64:
    .quad 0            

clock_rate:
    .quad 1            
