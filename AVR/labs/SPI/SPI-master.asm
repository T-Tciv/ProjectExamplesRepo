;
; Author : t.tsivinskaya
; Task : SPI
; Description : master transmits led's number (using port D for led), slave turns on the led
; MODE : MASTER
;

.include "m168def.inc"
;.include "m328pdef.inc"

.def rtemp = R16

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

; led's number
.equ LED_NUMBER = 3

.DSEG
.CSEG

.org 0x000 rjmp start
.org SPIaddr rjmp spi_interrupt_handler

start:
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	sei

	call spi_init_function


main:
	sbrc rflags, SPI_INPRG
	jmp spi_in_progress

	; we can transmit data
	sbr rflags, (1 << SPI_INPRG)
	ldi rtemp, (1 << LED_NUMBER)
	cbi SPI_port, SPI_SS
	out SPDR, rtemp

	jmp end

spi_in_progress:
end:
	jmp main

;------------------------------- SPI init function; no args, no ret
spi_init_function:
	ldi rflags, 0

	; PRSPI bit must be disabled to enable SPI
	lds rtemp, PRR
	cbr rtemp, (1 << PRSPI)
	sts PRR, rtemp

	ldi rtemp, (1 << SPI_SS)
	out SPI_PORT, rtemp

	; Set MISO input, all others output
	ldi rtemp, (1 << SPI_MOSI) | (1 << SPI_SCK) | (1 << SPI_SS) | (0 << SPI_MISO)
	out SPI_DDR, rtemp

	; Enable SPI, Master, set clock rate Fosc/16, interrupt enable
	ldi rtemp, (1 << SPE) | (1 << MSTR) | (1 << SPIE) | (1 << SPR0)
	out SPCR, rtemp

	ret
;-------------------------------


;------------------------------- SPI interrupt handler
spi_interrupt_handler:
	push rtemp
	in rtemp, SREG
	push rtemp

	cbr rflags, (1 << SPI_INPRG)
	sbi SPI_port, SPI_SS

	pop rtemp
	out SREG, rtemp
	pop rtemp

	reti
;-------------------------------