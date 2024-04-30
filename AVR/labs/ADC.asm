;
; Author : t.tsivinskaya
; Task : ADC
; Description : configure ADC
;

.include "m168def.inc"
;.include "m328pdef.inc"

.def rtemp = R16
.def radcl = R17
.def radch = R18

; ADC_CONV enabled = 'ADC convesrion result is ready'
; ADC_RUN enabled = 'ADC convesrion in progress'
.def rflags = R19
.equ ADC_CONV = 0
.equ ADC_RUN = 1

.DSEG
.CSEG

.org 0x000 rjmp start
.org ADCCaddr rjmp adc_interrupt_handler

start:
	ldi rtemp, low(RAMEND)
	out SPL, rtemp
	ldi rtemp, high(RAMEND)
	out SPH, rtemp

	cli
	call adc_init_function
	sei

main:
	; if ADC_RUN is cleared, we can start new conversion
	sbrc rflags, ADC_RUN
	jmp conv_is_running

	call run_single_conversion_function
	jmp end

	; if ADC_RUN is set, we are waiting for result of current conversion
conv_is_running:
	; if we didn't get it, we wait
	sbrs rflags, ADC_CONV
	jmp end
	; else we can read result and start next conversion
	call read_adc_data_function

end:
	jmp main

;------------------------------- ADC init function; no args, no ret
adc_init_function:
	; init rflag register
	ldi rflags, 0

	; PRADC bit must be disabled to enable ADC
	lds rtemp, PRR
	cbr rtemp, (1 << PRADC)
	sts PRR, rtemp

	; ADMUX: Vref selection = REFS1:0 (11 = Internal 1.1V), Vin channel = MUX3:0 (0000 = ADC0)
	ldi rtemp, (1 << REFS1) | (1 << REFS0) | (0 << MUX3) | (0 << MUX2) | (0 << MUX1) | (0 << MUX0)
	sts ADMUX, rtemp

	; ADCSRB
	ldi rtemp, 0
	sts ADCSRB, rtemp

	; DIDR0: disable all except ADC0
	ldi rtemp, (1 << ADC5D) | (1 << ADC4D) | (1 << ADC3D) | (1 << ADC2D) | (1 << ADC1D)
	sts DIDR0, rtemp

	; ADCSRA: enable ADC, enable ADC interrupt
	ldi rtemp, (1 << ADEN) | (1 << ADIE) 
	sts ADCSRA, rtemp

	ret
;-------------------------------

;------------------------------- run single conversion function; no args, no ret
;								 to start a single conversion: disable PRADC (in init) + enable ADSC
run_single_conversion_function:
	sbr rflags, (1 << ADC_RUN)
	; ADCSRA: enable ADSC (cleared by hardware when the conversion is complited)
	lds rtemp, ADCSRA
	sbr rtemp, (1 << ADSC)
	sts ADCSRA, rtemp

	ret
;-------------------------------

;------------------------------- read adc data function for right adjusted case; no args, 2 ret values (ADCL, ADCH)
read_adc_data_function:
	cbr rflags, (1 << ADC_CONV) | (1 << ADC_RUN)

	; read ADCL
	lds radcl, ADCL
	; ADC access to Data Registers is blocked, so ADCH has correct data
	; read ADCH
	lds radch, ADCH
	; ADC access re-enabled

	ret
;-------------------------------

;------------------------------- ADC interrupt handler
adc_interrupt_handler:
	push rtemp
	in rtemp, SREG
	push rtemp
	push radcl
	push radch

	sbr rflags, (1 << ADC_CONV)

	pop radch
	pop radcl
	pop rtemp
	out SREG, rtemp
	pop rtemp
	reti
;-------------------------------