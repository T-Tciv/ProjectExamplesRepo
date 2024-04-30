;
; Author : t.tsivinskaya
; Task : Matrix keyboard
; Description : 3x3 matrix keyboard (key = column&row intersection = 1..9), 
;               turn on voltage on first row, check columns (using PCI0..2)
;               repeat on each row to find intersections
;				to avoid contact bounce we just wait
;

.include "m168def.inc"
;.include "m328pdef.inc"

.def rtemp = R16
.def rarg = R17

; KEYBOARD
; rrow -- current row's number (0..2)
.def rrow = R18
; rkey (1..9) = 3 * row's number (0..2) + column number (0..2) + 1
.def rkey = R19
; rows port
.equ ROWS_PORT = PORTB
.equ ROWS_DDR = DDRB
.equ ROW0 = PB6
.equ ROW1 = PB7
.equ ROW2 = PB5

.def rcolumn  = R20
; columns ports
.equ COLUMNS_PORT = PORTD
.equ COLUMNS_DDR = DDRD
.equ COLUMNS_PIN = PIND
.equ COLUMN0 = PD0
.equ COLUMN1 = PD1
.equ COLUMN2 = PD2


; TC0 (we need timer to handle contact bounce)
; waiting time = 60 / (clk I/O [16.000.000] / prescaler [1024] / TC0_CLKS [256]) sec = ~16 ms
; clock source = clk I/O / 1024 -> CS02:0=101
.equ CLK_SRC_BITS = (1 << CS02) | (0 << CS01) | (1 << CS00)

.DSEG
.CSEG

.org 0x000 rjmp start

start:
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	cli

	call keyboard_init_function
	call tc0_init_function

main:
	sbi ROWS_PORT, ROW0
	call debouncing_wait_function
	in rarg, COLUMNS_PIN
	call get_pressed_key_function
	cbi ROWS_PORT, ROW0
	inc rrow

	sbi ROWS_PORT, ROW1
	call debouncing_wait_function
	in rarg, COLUMNS_PIN
	call get_pressed_key_function
	cbi ROWS_PORT, ROW1
	inc rrow

	sbi ROWS_PORT, ROW2
	call debouncing_wait_function
	in rarg, COLUMNS_PIN
	call get_pressed_key_function
	cbi ROWS_PORT, ROW2
	ldi rrow, 0

	jmp main

;------------------------------- keyboard init function; no args, no ret
keyboard_init_function:
	ldi rrow, 0
	ldi rcolumn, 0
	ldi rkey, 0xFF

	ldi rtemp, 0
	out ROWS_PORT, rtemp
	out COLUMNS_PORT, rtemp

	; output pins (rows)
	ldi rtemp, (1 << ROW0) | (1 << ROW1) | (1 << ROW2)
	out ROWS_DDR, rtemp

	; input pins (columns)
	ldi rtemp, (0 << COLUMN0) | (0 << COLUMN1) | (0 << COLUMN2)
	out COLUMNS_DDR, rtemp

	ret
;-------------------------------

;------------------------------- get pressed key function; 1 arg -- columns pin, no ret
get_pressed_key_function:
	cpi rarg, 0
	breq not_pressed
	sbrc rarg, COLUMN0
	ldi rcolumn, COLUMN0
	sbrc rarg, COLUMN1
	ldi rcolumn, COLUMN1
	sbrc rarg, COLUMN2
	ldi rcolumn, COLUMN2

	; rkey = 3 * rrow + rarg (column number) + 1
	mov rtemp, rrow
	add rtemp, rtemp
	add rtemp, rrow
	add rtemp, rcolumn
	inc rtemp
	mov rkey, rtemp

not_pressed:

	ret
;-------------------------------

;------------------------------- function to wait for contact bounce completion; no args, no ret
debouncing_wait_function:
	call start_tc0_function
db_wait_cycle:
	sbis TIFR0, TOV0
	jmp db_wait_cycle
	sbi TIFR0, TOV0
	call stop_tc0_function

	ret
;-------------------------------

;------------------------------- function to start TC0 (sets clock source); no args, no ret
start_tc0_function:
	in rtemp, TCCR0B
	sbr rtemp, CLK_SRC_BITS
	out TCCR0B, rtemp

	ret
;-------------------------------

;------------------------------- function to stop TC0 (clears clock source); no args, no ret
stop_tc0_function:
	in rtemp, TCCR0B
	cbr rtemp, CLK_SRC_BITS
	out TCCR0B, rtemp

	ret
;-------------------------------

;------------------------------- timer TC0 init function (for debouncing); no args, no init
tc0_init_function:
	; PRR: set PRTIM0 = 0 to enable timer/counter0
	lds rtemp, PRR
	cbr rtemp, (1 << PRTIM0)
	sts PRR, rtemp

	; TIMSK0 (interrup mask register) -- we will use flags 
	ldi rtemp, 0
	sts TIMSK0, rtemp

	; TCCR0A: normal mode -> WGM01:0 = 0
	ldi rtemp, 0
	out TCCR0A, rtemp

	; TCCR0B: first clock source = no clock source, normal mode -> WGM02 = 0
	ldi rtemp, 0
	out TCCR0B, rtemp

	ret
;-------------------------------