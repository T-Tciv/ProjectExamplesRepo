;
; Author : t.tsivinskaya
; Task : leds lab
; Description : make led flash (period = 1 sec)
;               interrupt = timer0 overflow
;

;.include "m168def.inc"
.include "m328pdef.inc"

.def rtemp = R16

; rcounter
.def rcounter = R17 
; timer clk = clkIO / CLK_PRESCALER, 8 bit counter limit = TIMER_CLKS
; -> led period = OSC_FREQ / CLK_PRESCALER / TIMER_CLKS / RCOUNTER_LIMIT ~ 1 sec
.equ OSC_FREQ = 16_000_000
.equ CLK_PRESCALER = 1024
.equ TIMER_CLKS = 256
.equ RCOUNTER_LIMIT = OSC_FREQ / CLK_PRESCALER / TIMER_CLKS

; LED (I/O port D)
.equ LED = PD6
.equ LED_PORT = PORTD
.equ LED_DDR = DDRD
.equ LED_PIN = PIND

.DSEG
.CSEG

.org 0x000 rjmp start
.org OVF0addr rjmp inter_timer0_ovf

start:
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	call led_init_function
	call tc0_init_function
	sei

main:
	rjmp main

;------------------------------- timer/counter TC0 init function; no args, no ret
tc0_init_function:
	; PRR: set PRTIM0 = 0 to enable timer/counter0
	lds rtemp, PRR
	cbr rtemp, (1 << PRTIM0)
	sts PRR, rtemp

	; TIMSK0 (interrup mask register): 
	ldi rtemp, (0 << OCIE0B) | (0 << OCIE0A) | (1 << TOIE0)
	sts TIMSK0, rtemp

	; TCCR0A: normal mode -> WGM01:0 = 0
	ldi rtemp, 0
	out TCCR0A, rtemp

	; TCCR0B: clock source = clk I/O / 1024 -> CS02:0=101, normal mode -> WGM02 = 0
	ldi rtemp, (1 << CS02) | (0 << CS01) | (1 << CS00)
	out TCCR0B, rtemp

	ret
;-------------------------------

;------------------------------- LED init function; no args, no ret
led_init_function:
	ldi rtemp, (1 << LED)
	out LED_DDR, rtemp
	ldi rtemp, (0 << LED)
	out LED_PORT, rtemp

	ret
;-------------------------------

;------------------------------- interrupt handler for timer0 overflow
inter_timer0_ovf:
	; store SREG in stack
	in rtemp, SREG
	push rtemp

	inc rcounter
	cpi rcounter, RCOUNTER_LIMIT
	brne less
	sbi LED_PIN, LED
	ldi rcounter, 0

less:
	pop rtemp
	out SREG, rtemp
	reti
;-------------------------------