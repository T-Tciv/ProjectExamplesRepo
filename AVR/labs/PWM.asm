;
; Author : t.tsivinskaya
; Task : PWM
; Description : Configure PWM with D (duty cycle) = 50%
;

.include "m168def.inc"

.equ DDR_OC0A = DDRD
.equ OC0A = 6

.def rtemp1 = R16
.def rtemp2 = R17

.DSEG
.CSEG

.org 0x000 rjmp start

start:
	ldi rtemp1, low(RAMEND)                                                  ; init SP
	out SPL, rtemp1
	ldi rtemp1, high(RAMEND)
	out SPH, rtemp1

	ldi rtemp1, 128                                                          ; set OCR0A to 128 (50 %)
	out OCR0A, rtemp1
      
	ldi rtemp1, (1 << COM0A1) | (1 << COM0A0) | (1 << WGM01) | (1 << WGM00)  ; TCCR0A: WGM01:0 = 11 (Fast PWM mode)
	out TCCR0A, rtemp1                                                       ; AND COM0A1:0 = 11 (OC0A inverting mode)

	sbi DDR_OC0A, OC0A                                                       ; set OC0A (bit 6 in DDRD) direction to output
               
	ldi rtemp1, (0 << CS02) | (0 << CS01) | (1 << CS00) | (0 << WGM02)       ; TCCR0B: clock source = clk I/O  -> CS02:0=001
	out TCCR0B, rtemp1                                                       ; AND WGM02 is 0 (Fast PWM mode)

main:
	ldi rtemp1, 1
	ldi rtemp2, 2
	add rtemp1, rtemp2
	rjmp main
