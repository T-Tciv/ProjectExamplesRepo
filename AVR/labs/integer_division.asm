;
; Author : t.tsivinskaya
; Task : integer division
; Description : implement integer division
;

.include "m168def.inc"

.equ DIVIDEND = 11
.equ DIVIDER = 3
.equ BITS = 8

.def rtemp1 = R16
.def rtemp2 = R24

.def rarg1 = R17              ; argumet 1 register
.def rarg2 = R18

.def rret1 = R19              ; return 1 argument
.def rret2 = R20              ; return 2 argument

.def rquot = R21              ; quotient register
.def rrem = R22               ; remainder register
.def rbit = R23               ; bit register

.DSEG
.CSEG

.org 0x000 rjmp start

start:
	ldi rtemp1, low(RAMEND)    ; init SP
	out SPL, rtemp1
	ldi rtemp1, high(RAMEND)
	out SPH, rtemp1

main:
	ldi rarg1, DIVIDEND
	ldi rarg2, DIVIDER
	ldi rtemp1, 1
	call div_subroutine
	rjmp main

// --------------------------- function "div_subroutine"; 2 args - dividend, divider;  2 return values - quotient, remainder
div_subroutine:
	in rtemp1, SREG           ; store SREG in stack
	push rtemp1

	ldi rquot, 0
	ldi rrem, 0
	ldi rbit, BITS

div_loop:                     ; for each bit from 7 to 0:
                              ; add it to remainder, check if remainder became bigger than divider
							  ; rem >= divr: increment quot, rem = rem - divr
							  ; rem < divr: do nothing
							  ; then quot = quot*2, rem = rem*2
	add rquot, rquot
	add rrem, rrem
	dec rbit
	mov rtemp1, rbit
	mov rtemp2, rarg1

get_current_bit_loop:
	cpi rtemp1, 0             ; move current bit in 0 position
	breq compare_divr_rem
	dec rtemp1
	lsr rtemp2
	rjmp get_current_bit_loop

compare_divr_rem:   
	sbrc rtemp2, 0            ; if current bit is set, increment remainder
	inc rrem
	cp rrem, rarg2            ; check if divider < remainder
	brlo rem_less_divr
	inc rquot
	sub rrem, rarg2

rem_less_divr:
	cpi rbit, 0
	breq div_end
	rjmp div_loop

div_end:
	mov rret1, rquot
	mov rret2, rrem
	pop rtemp1                ; restore SREG
	out SREG, rtemp1

	ret                      ; return
// ---------------------------