;
; Author : t.tsivinskaya
; Task : SPI
; Description : master transmits led's number (using port D for led), slave turns on the led
; MODE : SLAVE
;

.include "m168def.inc"
;.include "m328pdef.inc"

.def rtemp = R16

; LEDs (I/O port D)
.equ LEDS_PORT = PORTD
.equ LEDS_DDR = DDRD
.equ LEDS_PIN = PIND

; SPI PORT
.equ SPI_PORT = PORTB
.equ SPI_DDR = DDRB

.equ SPI_MOSI = PB3
.equ SPI_MISO = PB4
.equ SPI_SCK = PB5
.equ SPI_SS = PB2

; rflags -- flag register
; SPI_INPRG = 1 -- if SPI transmission is in progress
.def rflags = R17
.equ SPI_INPRG = 0

.DSEG
.CSEG

.org 0x000 rjmp start
.org SPIaddr rjmp spi_interrupt_handler

start:
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	call leds_init_function
	call spi_init_function
	sei

main:
	sbrc rflags, SPI_INPRG
	jmp spi_in_progress

	; we can read data
	in rtemp, SPDR
	out LEDS_PIN, rtemp
	sbr rflags, (1 << SPI_INPRG)

	jmp end

spi_in_progress:
end:
	jmp main

;------------------------------- SPI init function; no args, no ret
spi_init_function:
	ldi rflags, (1 << SPI_INPRG)

	; PRSPI bit must be disabled to enable SPI
	lds rtemp, PRR
	cbr rtemp, (1 << PRSPI)
	sts PRR, rtemp

	; Set MISO output, all others input
	ldi rtemp, (0 << SPI_MOSI) | (0 << SPI_SCK) | (0 << SPI_SS) | (1 << SPI_MISO)
	out SPI_DDR, rtemp

	; Enable SPI, Slave, set clock rate Fosc/16, interrupt enable
	ldi rtemp, (1 << SPE) | (0 << MSTR) | (1 << SPIE) | (1 << SPR0)
	out SPCR, rtemp

	ret
;-------------------------------

;------------------------------- LED init function; no args, no ret
leds_init_function:
	ldi rtemp, 0xFF
	out DDRD, rtemp
	ldi rtemp, 0
	out PORTD, rtemp

	ret
;-------------------------------

;------------------------------- SPI interrupt handler
spi_interrupt_handler:
	push rtemp
	in rtemp, SREG
	push rtemp

	cbr rflags, (1 << SPI_INPRG)

	pop rtemp
	out SREG, rtemp
	pop rtemp

	reti
;-------------------------------