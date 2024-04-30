;
; Author : t.tsivinskaya
; Task : EEPROM
; Description : allocate space for an array in EEPROM, fill the array, find a given number
;

.include "m168def.inc"

.equ size = 4          ; array size
.equ value = 3         ; value to find
.def rtemp1 = R16
.def rtemp2 = R17
.def rarg1 = R18
.def rarg2 = R19
.def rarg3 = R20
.def rarg4 = R21
.def rarg5 = R22
.def rret = R23
.def rcounter = R24

.DSEG

.CSEG

.org 0x000 rjmp start

start:
	ldi rtemp1, low(RAMEND); init SP
	out SPl, rtemp1
	ldi rtemp1, high(RAMEND)
	out SPh, rtemp1

	ldi rarg1, size        ; use R18 as argument register with array size
	call fill_array        ; and call subroutine

	ldi rarg1, value       ; use R18 as argument register with value to find
	ldi rarg2, size        ; use R19 as argument register with array size
	call find_value        ; and call subroutine

	rjmp start

// --------------------------- function "fill array": fills array with numbers from 0 to size; 1 arg - size; no return

fill_array:
	in rtemp1, SREG        ; store SREG in stack
	push rtemp1

	ldi rcounter, 0          ; start index

fill_loop:
	cp rcounter, rarg1
	breq end_fill_loop
	ldi rarg3, 0
	mov rarg4, rcounter
	mov rarg5, rcounter
	call eeprom_write
	inc rcounter
	rjmp fill_loop

end_fill_loop:
	pop rtemp1             ; restore SREG
	out SREG, rtemp1

	ret                    ; return

// --------------------------- 

// --------------------------- function "find value"; 2 args - value, size; return index

find_value:
	in rtemp1, SREG        ; store SREG in stack
	push rtemp1

	ldi rcounter, 0          ; start index in array

find_loop:
	cp rcounter, rarg2 
	breq end_find_loop
	ldi rarg3, 0
	mov rarg4, rcounter
	call eeprom_read
	cp rret, rarg1
	breq end_find_loop
	inc rcounter
	rjmp find_loop

end_find_loop:
	mov rret, rcounter      ; set index as return value

	pop rtemp1             ; restore SREG
	out SREG, rtemp1

	ret                    ; return

// --------------------------- 

// --------------------------- function "eeprom write"; 3 args - 1st,2nd for address, 3rd for data, size; no return
eeprom_write:
	in rtemp1, SREG        ; store SREG in stack
	push rtemp1

	cli                    ; disable interrupts

write:
	sbic EECR, EEPE        ; wait for completion of previous write
	rjmp write

	out EEARH, rarg3       ; set up address in address register
	out EEARL, rarg4       ; set up address in address register	 

	out EEDR, rarg5        ; write data to data register

	sbi EECR, EEMPE        ; write 1 to EEMPE (determines wheteher setting EEPE to 1 causes EEPROM to be written)
	sbi EECR, EEPE         ; write 1 to EEPE to start EEPROM write

	pop rtemp1             ; restore SREG
	out SREG, rtemp1

	ret                    ; return
// --------------------------- 

// --------------------------- function "eeprom read"; 2 args for address, size; 1 return - data
eeprom_read:
	in rtemp1, SREG        ; store SREG in stack
	push rtemp1

	cli                    ; disable interrupts

read:
	sbic EECR, EEPE        ; wait for completion of previous write
	rjmp read

	out EEARH, rarg3       ; set up address in address register
	out EEARL, rarg4       ; set up address in address register	 

	sbi EECR, EERE         ; write 1 to EERE to start EEPROM read

	in rret, EEDR          ; read from data register

	pop rtemp1             ; restore SREG
	out SREG, rtemp1

	ret                    ; return
// --------------------------- 

