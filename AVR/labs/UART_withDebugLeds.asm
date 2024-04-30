;
; Author : t.tsivinskaya
; Task : USART lab (async)
; Description : we receive byte, modify it (byte + 1) and transmit back -- with debug leds
;

.include "m168def.inc"

.def rtemp = R16

; register for received and modified byte
.def rbyte = R18

; flags register
; 0 bit = recvflg - flag, that we use to check if rbyte is ready to be modified
; 1 bit = trflg - flag, that we use to check if rbyte is ready to be transmitted
; 2 bit = recvovr - overrun flag (= 1 if we got new data before reading current)
.def rflags = R19
.equ RECVFLG = 0
.equ TRFLG = 1
.equ RECVOVR = 2

; leds (I/O port D)
.equ RX_LED = PD6 ; toggles rx LED 
.equ TX_LED = PD4 ; toggles tx LED
.equ DBG_LED = PD7 ; debug LED
.equ LEDS_PORT = PORTD
.equ LEDS_DDR = DDRD
.equ LEDS_PIN = PIND

; baud rate configuration (Fosc = 16 MHz, bps = 9600, U2X0 = 0 --> UBRR0 = 103)
.equ OSC_FREQ = 16_000_000
.equ BAUD = 9600
.equ UBRR = OSC_FREQ / (16 * BAUD) - 1

.DSEG
.CSEG

.org 0x0000 rjmp start
.org 0x0024 rjmp inter_rx_complete
.org 0x0028 rjmp inter_tx_complete

start:
; init SP
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	cli

; init diodes
	call leds_init_function

; init uart
	call uart_init_function

	sei

main:
	sbrs rflags, RECVFLG ; sbrs = skip next instruction if bit is set
	jmp not_ready
	sbrs rflags, TRFLG
	jmp not_ready


	cli
	cbr rflags, (1 << RECVFLG) | (1 << TRFLG) ; cbr = clear bits in register (Rd = Rd * ($FF - K))
	sei

	; modify data (just increment)
	inc rbyte
	; transmit modified data (1 byte)
	sts UDR0, rbyte


not_ready:
	sbi PORTD, DBG_LED
	cbi PORTD, DBG_LED
; end
	rjmp main

;------------------------------- LEDs init function; no args, no ret
leds_init_function:
	ldi rtemp, (1 << RX_LED) | (1 << TX_LED) | (1 << DBG_LED)
	out DDRD, rtemp
	ldi rtemp, (0 << RX_LED) | (0 << TX_LED)  | (0 << DBG_LED)
	out PORTD, rtemp

	ret
;-------------------------------

;------------------------------- uart init function; no args, no ret
uart_init_function:
; configure UBRR0
	ldi rtemp, high(UBRR)
	sts UBRR0H, rtemp
	ldi rtemp, low(UBRR)
	sts UBRR0L, rtemp

; UCSR0A: bits 7-5 are flags, bits FE0, UPE0, DOR0 must be 0, bit U2X0 doubles async transfer rate
	ldi rtemp, 0
	sts UCSR0A, rtemp

; UCSR0B: size (8 bit, UCSZ02 = 0), enable TX complete interrupt, enable transmitter, enable RX complete interrupt, enable receiver
	ldi rtemp, (0 << UCSZ02) | (1 << TXCIE0) | (1 << TXEN0) | (1 << RXCIE0) | (1 << RXEN0)
	sts UCSR0B, rtemp

; UCSR0C: select USART mode (async = 00), parity (even = 10), stop bit (1 = 0), size (8 bit, UCSZ01:0 = 11), no clock polarity (since async)
	ldi rtemp, (0 << UMSEL01) | (0 << UMSEL00) | (0 << UPM01) | (0 << UPM00) | (0 << USBS0) | (1 << UCSZ01) | (1 << UCSZ00)
	sts UCSR0C, rtemp

; init flags
	ldi rflags, (1 << TRFLG)

	ret
;-------------------------------

;------------------------------- receiver interrupt handler (rx complete)
inter_rx_complete:
	push rtemp
	; store SREG in stack
	in rtemp, SREG
	push rtemp

	sbi PIND, RX_LED

	; check flag (should be 0, but maybe we got new data byte before reading current)
	sbrc rflags, RECVFLG
	sbr rflags, (1 << RECVOVR)

	; read our byte from UDR0 to byte register rbyte, set rflag to 1
	lds rbyte, UDR0
	sbr rflags, (1 << RECVFLG)

	pop rtemp
	out SREG, rtemp
	pop rtemp
	reti
;-------------------------------

;------------------------------- transmitter interrupt handler (tx complete)
inter_tx_complete:
	push rtemp
	; store SREG in stack
	in rtemp, SREG
	push rtemp

	sbi PIND, TX_LED
	sbr rflags, (1 << TRFLG)

	pop rtemp
	out SREG, rtemp
	pop rtemp
	reti
;-------------------------------