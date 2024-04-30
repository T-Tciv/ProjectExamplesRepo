;
; Author : t.tsivinskaya
; Task : Array elements sending
; Description : create and fill array (size = 10), then receive byte (UART)
;				- if byte = '0'...'8' send element = array[0...8]
;				- if byte = '9' wait for another data byte, save it in array[9], send back
;
;				* to get number from byte we just substract ascii code of '0' from byte
; Functions :
;		- leds_init_function: no args -> no return
;		- uart_init_function: no args -> no return
;		- fill_array: size -> no return
;		- get_element: index -> element
;		- set_element: element, index -> no return
;		- get_number_from_byte: byte (symbol) -> number
;

.include "m168def.inc"

.def rtemp1 = R16
.def rtemp2 = R17
.def rarg1 = R18
.def rarg2 = R19
.def rret = R20

; register for received byte
.def rbyte = R21

; flags register
; 0 bit = recvflg - flag, that we use to check if rbyte is ready to be modified
; 1 bit = trflg - flag, that we use to check if rbyte is ready to be transmitted
; 2 bit = recvovr - overrun flag (= 1 if we got new data before reading current)
; 3 bit = waitflg - flag that indicates, that we wait for 9th element data
.def rflags = R22
.equ RECVFLG = 0
.equ TRFLG = 1
.equ RECVOVR = 2
.equ WAITFLG = 3

; UART baud rate configuration (Fosc = 16 MHz, bps = 9600, U2X0 = 0 --> UBRR0 = 103)
.equ OSC_FREQ = 16_000_000
.equ BAUD = 9600
.equ UBRR = OSC_FREQ / (16 * BAUD) - 1

; array size
.equ SIZE = 10

; ASCII code of '0'
.equ ZERO_CODE = '0'

; leds (I/O port D)
.equ RX_LED = PD6 ; toggles rx LED 
.equ TX_LED = PD4 ; toggles tx LED
.equ DBG_LED = PD7 ; debug LED
.equ LEDS_PORT = PORTD
.equ LEDS_DDR = DDRD
.equ LEDS_PIN = PIND

.DSEG

array: .BYTE SIZE

.CSEG

.org 0x0000 rjmp start
.org 0x0024 rjmp inter_rx_complete
.org 0x0028 rjmp inter_tx_complete

start:
	ldi rtemp1, low(RAMEND)
	out SPL, rtemp1
	ldi rtemp1, high(RAMEND)
	out SPH, rtemp1

	cli

	call leds_init_function
	call uart_init_function

	sei

	ldi rarg1, SIZE 
	call fill_array

main:
	sbrs rflags, RECVFLG
	jmp end
	sbrs rflags, TRFLG
	jmp end

	cli
	cbr rflags, (1 << RECVFLG)
	mov rarg1, rbyte
	sei

	sbrc rflags, WAITFLG
	jmp got_last_element

	call get_number_from_byte

; check if number < 9, = 9 or > 9
	cpi rret, SIZE - 1
	brlo first_indices
	breq last_index
	jmp end

first_indices:
	mov rarg1, rret
	call get_element
	
	cli
	cbr rflags, (1 << TRFLG)
	sei

	sts UDR0, rret
	jmp end

last_index:
	cli
	sbr rflags, (1 << WAITFLG)
	sei

	jmp end

got_last_element:
	cli
	cbr rflags, (1 << TRFLG)
	sei

	ldi rarg1, SIZE - 1
	call get_element
	sts UDR0, rret

	cli
	mov rarg1, rbyte
	cbr rflags, (1 << WAITFLG) | (1 << TRFLG)
	sei

	ldi rarg2, SIZE - 1
	call set_element
	jmp end

end:
; end
	jmp main

;------------------------------- LEDs init function; no args, no ret
leds_init_function:
	ldi rtemp1, (1 << RX_LED) | (1 << TX_LED) | (1 << DBG_LED)
	out DDRD, rtemp1
	ldi rtemp1, (0 << RX_LED) | (0 << TX_LED)  | (0 << DBG_LED)
	out PORTD, rtemp1

	ret
;-------------------------------

;------------------------------- uart init function; no args, no ret
uart_init_function:
; configure UBRR0
	ldi rtemp1, high(UBRR)
	sts UBRR0H, rtemp1
	ldi rtemp1, low(UBRR)
	sts UBRR0L, rtemp1

; UCSR0A: bits 7-5 are flags, bits FE0, UPE0, DOR0 must be 0, bit U2X0 doubles async transfer rate
	ldi rtemp1, 0
	sts UCSR0A, rtemp1

; UCSR0B: size (8 bit, UCSZ02 = 0), enable TX complete interrupt, enable transmitter, enable RX complete interrupt, enable receiver
	ldi rtemp1, (0 << UCSZ02) | (1 << TXCIE0) | (1 << TXEN0) | (1 << RXCIE0) | (1 << RXEN0)
	sts UCSR0B, rtemp1

; UCSR0C: select USART mode (async = 00), parity (even = 10), stop bit (1 = 0), size (8 bit, UCSZ01:0 = 11), no clock polarity (since async)
	ldi rtemp1, (0 << UMSEL01) | (0 << UMSEL00) | (0 << UPM01) | (0 << UPM00) | (0 << USBS0) | (1 << UCSZ01) | (1 << UCSZ00)
	sts UCSR0C, rtemp1

; init flags
	ldi rflags, (0 << RECVFLG) | (1 << TRFLG) | (0 << RECVOVR) | (0 << WAITFLG)

	ret
;-------------------------------

;------------------------------- function "fill array"; 1 arg - size; no return
fill_array:
	ldi XL, low(array)    ; set array start address in X register
	ldi XH, high(array)

	ldi rtemp1, 0          ; start index

fill_loop:
	cp rtemp1, rarg1
	breq end_fill_loop
	ldi rtemp2, 'a'
	inc rtemp1
	add rtemp2, rtemp1
	st X+, rtemp2
	rjmp fill_loop

end_fill_loop:

	ret
;-------------------------------

;------------------------------- function "get element" to get array element; 1 arg - index; returns element
get_element:
	ldi XL, low(array)
	ldi XH, high(array)

	ldi rtemp1, 0
	add XL, rarg1
	adc XH, rtemp1

	ld rret, X

	ret
;-------------------------------

;------------------------------- function "set element" to set array element; 2 args - element, index; no return
set_element:
	ldi XL, low(array)
	ldi XH, high(array)
	ldi rtemp1, 0
	add XL, rarg2
	adc XH, rtemp1

	st X, rarg1

	ret
;-------------------------------

;------------------------------- function get number from byte (just byte - '0'); 1 arg - byte; returns number
get_number_from_byte:
	mov rret, rarg1 
	subi rret, ZERO_CODE

	ret
;-------------------------------

;------------------------------- receiver interrupt handler (rx complete)
inter_rx_complete:
	push rtemp1
	in rtemp1, SREG
	push rtemp1

	sbi PIND, RX_LED

	; check flag (should be 0, but maybe we got new data byte before reading current)
	sbrc rflags, RECVFLG
	sbr rflags, (1 << RECVOVR)

	; read our byte from UDR0 to byte register rbyte, set rflag to 1
	lds rbyte, UDR0
	sbr rflags, (1 << RECVFLG)

	pop rtemp1
	out SREG, rtemp1
	pop rtemp1
	reti
;-------------------------------

;------------------------------- transmitter interrupt handler (tx complete)
inter_tx_complete:
	push rtemp1
	in rtemp1, SREG
	push rtemp1

	sbi PIND, TX_LED
	sbr rflags, (1 << TRFLG)

	pop rtemp1
	out SREG, rtemp1
	pop rtemp1
	reti
;-------------------------------