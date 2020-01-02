//	Nicolas Rodriguez
//	V00919074
//	The great collatz system is implemented once again, but this time in C
//	12/9/2019

#include <string.h> //Include the standard library string functions
#include <avr/io.h>
#include "CSC230.h"

#define  ADC_BTN_RIGHT 0x032
#define  ADC_BTN_UP 0x0C3
#define  ADC_BTN_DOWN 0x17C
#define  ADC_BTN_LEFT 0x22B
#define  ADC_BTN_SELECT 0x316


#define NUM_PATTERNS 6
 


volatile int delay1 = 0;
volatile uint8_t current = 0;
volatile int cursor = 0;
volatile int cursor_pos = 3;
volatile int visibility = 0;
char str[100];
char str2[100];
volatile long count = 0;
volatile long collatz_number = 0;
volatile long speed = 4;
volatile long n = 000;
volatile int button = 0; //1 right, 2 up, 3 down, 4 left, 5 select
volatile int a =0;
volatile int b=0;
volatile int c=0;
volatile int held = 0;
volatile char space = ' ';
volatile long speed_num = 0;
volatile int go_bool = 0;
volatile int last_speed = 0;

//A short is 16 bits wide, so the entire ADC result can be stored
//in an unsigned short.
unsigned short poll_adc(){
	unsigned short adc_result = 0; //16 bits
	
	ADCSRA |= 0x40;
	while((ADCSRA & 0x40) == 0x40); //Busy-wait
	
	unsigned short result_low = ADCL;
	unsigned short result_high = ADCH;
	
	adc_result = (result_high<<8)|result_low;
	return adc_result;
}

int main(){
    DDRL = 0b10101010;
    PORTL = 0b10000000;

	lcd_init();
	


	//ADC Set up
	ADCSRA = 0x87;
	ADMUX = 0x40;

	lcd_xy(0,0);
	lcd_puts("Nico Rodriguez");
	lcd_xy(0,1);
	lcd_puts("CSC230-Fall 2019");
		
	_delay_ms(1000);
	lcd_xy(0,1);
	lcd_blank(16);
	lcd_xy(0,0);
	lcd_blank(16);

	// Set up Timer 0
	TCCR1A = 0;
	TCCR1B = (1<<CS12)|(1<<CS10);	// Prescaler of 1024
	TCNT1 = 0xFFFF - 15626;			// Initial count (1 second)
	TIMSK1 = 1<<TOIE1;
	sei();
	
	TCCR4A = 0;
	TCCR4B = (1<<CS42)|(1<<CS40);	// Prescaler of 1024
	TCNT4 = 0xFFFF - 15626;			// Initial count (1 second)
	TIMSK4 = 1<<TOIE4;
	sei();

	TCCR3A = 0;
	TCCR3B = (1<<CS32)|(1<<CS30);	// Prescaler of 1024
	TCNT3 = 0xFFFF - 0;			// Initial count (1 second)
	TIMSK3 = 1<<TOIE3;
	sei();

	while(1){
		lcd_update();
	}
	
	return 0;
	
}

ISR(TIMER1_OVF_vect) { //checkbuttons
	delay1= 15626/8;
	TCNT1 = 0xFFFF - delay1;
	checkbuttons();
}

ISR(TIMER3_OVF_vect){ //collatz
	if(go_bool){
		TCNT3 = 0xFFFF - speed_num;
		collatz();
	}
	else
	{
		TCNT1 = 0xFFFF - 0;
		PORTL = 0b00010010;
	}
}

void checkbuttons()
{
	// Update a variable
	unsigned short adc_result = poll_adc();
	char s[10];
	
	a = n/100;
	//(123//10)%10
	b = (n/10)%10;
	c = n%10;
	if(held==0){
		if(adc_result<ADC_BTN_RIGHT) //right
		{
			held =1;
			button = 1;
			PORTL = 0b11111111;
			if(cursor==4){
				cursor = 0;
			}
			else{
				cursor++;
			}
		}
		if(adc_result<ADC_BTN_UP && adc_result>ADC_BTN_RIGHT) //up
		{
			held =1;
			PORTL = 0b11111111;
			button =2;
			if(cursor==4)
			{
				last_speed = speed;
			}
			if(cursor==0 && a==9){
				a=0;
			}
			if(cursor==1 && (b==9))
			{
				b=0;
			}
			if(cursor==2 && (c==9))
			{
				c=0;

			}
			if(cursor==4 && speed==9)
			{
				speed=0;
			}
			if(cursor == 0 && (a!=9))
			{
				a++;
			}
			if(cursor == 1 && (b!=9))
			{
				b++;
			}
			if(cursor == 2 && (c!=9))
			{
				c++;
			}
			if(cursor == 4 && (speed!=9))
			{
				speed++;
			}
			
			if(cursor==3)
			{
				go();
			}
			
			
		}
		if(adc_result<ADC_BTN_DOWN && adc_result>ADC_BTN_UP) //down
		{
			held =1;
			PORTL = 0b11111111;
			button = 3;
			if(cursor==4)
			{
				last_speed = speed;
			}
			if(cursor==0 && a==0){
				a=9;
			}
			if(cursor==1 && (b==0))
			{
				b=9;
			}
			if(cursor==2 && (c==0))
			{
				c=9;
			}
			if(cursor==4 && speed==0)
			{
				speed=9;
			}
			if(cursor == 0 && (a!=0))
			{
				a--;
			}
			if(cursor == 1 && (b!=0))
			{
				b--;
			}
			if(cursor == 2 && (c!=0))
			{
				c--;
			}
			if(cursor == 4 && (speed!=0))
			{
				speed--;
			}
			if(cursor==3)
			{
				go();
			}
			
		}
		if(adc_result<ADC_BTN_LEFT && adc_result>ADC_BTN_DOWN) //left
		{
			held =1;
			PORTL = 0b11111111;
			button =4;
			if(cursor==0){
				cursor = 4;
			}
			else{
				cursor--;
			}
		}
		if(adc_result>ADC_BTN_LEFT && adc_result<ADC_BTN_SELECT)
		{
			speed = last_speed;
		}
	}
	if(adc_result>ADC_BTN_SELECT)
	{
		held = 0;
	}
	switch(cursor)
	{
		case 0:
			cursor_pos = 3;
			PORTL = 0b00010010;
			break;
		case 1:
			cursor_pos = 4;
			PORTL = 0b00011000;
			break;
		case 2:
			cursor_pos = 5;
			break;
		case 3:
			cursor_pos = 6;
			break;
		case 4:
			cursor_pos = 14;
			break;		
	}
	switch(speed)
	{
		case 0:
			speed_num = 0xFFFF;
			break;
		case 1:
			speed_num = 15626/16;
			break;
		case 2:
			speed_num = 15626/8;
			break;
		case 3:
			speed_num = 15626/4;
			break;
		case 4:
			speed_num = 15626/2;
			break;
		case 5:
			speed_num = 15626;
			break;
		case 6:
			speed_num = 15626*1.5;
			break;
		case 7:
			speed_num = 15626*2;
			break;
		case 8:
			speed_num = 15626*2.5;
			break;
		case 9:
			speed_num = 15626*3;	
	}
	n = (a*100) + (b*10) + c;
}

ISR(TIMER4_OVF_vect) {
	// Reset the initial count
	TCNT4 = 0xFFFF - delay1*4;
	//PORTL = 0b00010000;
	visibility = visibility^1;
}

void go()
{
	count = 0;
	go_bool = 1;
	TCNT3 = 0xFFFF - speed_num;	
	collatz_number = n;
	collatz();
}

void collatz()
{
	if(collatz_number%2)
	{
		collatz_number= (3*collatz_number) + 1;
	}
	else
	{
		collatz_number /= 2;
	}
	if(collatz_number==1)
	{
		go_bool=0;
	}
	count++;
	PORTL = 0b01010010;	
}

void lcd_update()
{
	sprintf(str, " n=%03lu*   SPD:%1lu", n, speed);
	if(visibility){
		str[cursor_pos]= ' ';
	}
	sprintf(str2, "cnt:%3lu v:%6lu", count, collatz_number);
	lcd_xy(0,0);
	lcd_puts(str);
	lcd_xy(15,0);
	lcd_puts(" ");
	lcd_xy(0,1);
	lcd_puts(str2);
	lcd_xy(0,0);	
}

