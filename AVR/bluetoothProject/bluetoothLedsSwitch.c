/*
 * Project : GCC_NSU_Project.c
 * Author : t.tsivinskaya
 * Description : Receive ledCode+instruction through Bluetooth using UART, execute it
 *
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>

// rate configuration definitions
#define OSC_FREQ 16000000
#define BAUD 9600

// UART receive var
uint8_t uart_data;

// my UART flags (receiver state)
uint8_t flags;
#define RCV_FLG 0
#define LED_FLG 1

// instructions and LEDs codes
#define LED_ON '1'
#define LED_OFF '2'
#define BLUE_CODE '1'
#define RED_CODE '2'

// LEDs
#define BLUE_LED PD6
#define RED_LED PD7
#define LEDS_PORT PORTD
#define LEDS_DDR DDRD

// Bluetooth
#define BLUETOOTH_CONFIG_PIN PD5
#define BLUETOOTH_CONFIG_PORT PORTD
#define BLUETOOTH_CONFIG_DDR DDRD


ISR(USART_RX_vect)
{
	flags |= (1 << RCV_FLG);
	uart_data = UDR0;
}

int init_uart()
{
	long ubrr = OSC_FREQ / 16 / BAUD - 1;
	UBRR0H = (uint8_t)(ubrr >> 8);
	UBRR0L = (uint8_t)(ubrr & 0xFF);
	
	// UCSR0A: bits 7-5 are flags, bits FE0, UPE0, DOR0 must be 0, bit U2X0 doubles async transfer rate
	UCSR0A |= 0;
	// UCSR0B: size (8 bit, UCSZ02 = 0), enable RX complete interrupt, enable receiver
	UCSR0B |= (0 << UCSZ02) | (1 << RXCIE0) | (1 << RXEN0);
	// UCSR0C: select USART mode (async = 00), parity (even = 10), stop bit (1 = 0), size (8 bit, UCSZ01:0 = 11)
	UCSR0C |= (0 << UMSEL01) | (0 << UMSEL00) | (0 << UPM01) | (0 << UPM00) | (0 << USBS0) | (1 << UCSZ01) | (1 << UCSZ00);
	
	flags = 0;
	uart_data = 0;
	
	return 0;
}

int init_leds()
{
	LEDS_DDR |= (1 << BLUE_LED) | (1 << RED_LED);
	LEDS_PORT |= (0 << BLUE_LED)  | (0 << RED_LED);
	
	return 0;
}

int configure_bluetooth()
{
	BLUETOOTH_CONFIG_DDR |= (1 << BLUETOOTH_CONFIG_PIN);
	BLUETOOTH_CONFIG_PORT |= (0 << BLUETOOTH_CONFIG_PIN);
	
	return 0;
}

int turn_led_on(int led_number)
{
	LEDS_PORT |= (1 << led_number);
	return 0;
}

int turn_led_off(int led_number)
{
	LEDS_PORT &= ~(1 << led_number);
	return 0;
}

int get_led_number(uint8_t led_code)
{
	if (led_code == BLUE_CODE)
		return BLUE_LED;
	if (led_code == RED_CODE)
		return RED_LED;
		
	return 0;
}

int run_led_instr(uint8_t led_code, uint8_t instr)
{	
	int led_number = get_led_number(led_code);
	
	if (instr == LED_ON) {
		turn_led_on(led_number);
	} else if (instr == LED_OFF) {
		turn_led_off(led_number);
	}
	
	return 0;
}

int main(void)
{
	uint8_t current_instrunction = 0;
	uint8_t current_led = 0;
	init_uart();
	init_leds();
	configure_bluetooth();

	sei();
	
	
    while (1) 
    {
		// Check if we received sth
		if (flags & (1 << RCV_FLG)) {
			// Clear receive flag
			flags &= ~(1 << RCV_FLG);
			
			// Check if we already got led (true -> get instruction, false -> get led)
			if (flags & (1 << LED_FLG)) {
				// Clear 'have led' flag
				flags &= ~(1 << LED_FLG);
				current_instrunction = uart_data;
				run_led_instr(current_led, current_instrunction);
			} else {
				flags |= (1 << LED_FLG);
				current_led = uart_data;
			}
		}
		 
		 // ...
    }
	
	return 0;
}



