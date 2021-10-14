; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
; MCU:	PIC16F84A
; CLK:	4MHz
;
; Repository:	https://github.com/HelloWorld-Braille-display/Hardware/pic16f84a
;
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


	list		p=16f84a

		
; =-=-=- Includes -=-=-=
	
#include	<p16f84a.inc>


; =-=-=- FUSE bits -=-=-=

	__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF


; =-=-=- Memory pagination -=-=-=

#define	bank0	bcf	STATUS,RP0								; Instruction to select memory bank 0
#define	bank1	bsf	STATUS,RP0								; Instruction to select memory bank 1


; =-=-=- General purpose registers -=-=-=

	cblock	H'0C'

	SNDS_CMD													; Send-SET command
	SNDC_CMD													; Send-CLEAR command
	COORD													; Last coordinate received
	
	endc


; =-=-=- Reset vector -=-=-=

	org		H'0000'
	goto	init


; =-=-=- Interruption vector -=-=-=

	org 		H'0004'
	retfie


; #-#-#- Labels -#-#-#

; =-=-=- Reset I/O -=-=-=

default_io:

	bsf		PORTA,RA0										; PORTA[RA0] = 1

	bank1													; Switch to bank 1
	
	movlw	H'7F'											; B'01111111'
	movwf	TRISB											; TRISB = B'01111111'
	
	bank0													; Switch to bank 0
	
	bcf		PORTA,RA1										; PORTA[RA1] = 0
	bcf		PORTA,RA2										; PORTA[RA2] = 0
	
	return
	
; =-=-=- Not a command I/O -=-=-=

ncmd_io:

	movf	PORTB,W											; Work = PORTB
	movwf	COORD											; COORD = PORTB

	bcf		PORTA,RA0										; PORTA[RA0] = 0

	bank1													; Switch to bank 1
	
	movlw	H'00'											; B'00000000'
	movwf	TRISB											; TRISB = B'00000000'
	
	bank0													; Switch to bank 0
	
	movf	COORD,W											; Work = COORD
	movwf	PORTB											; PORTB = COORD
	
	bsf		PORTA,RA1										; PORTA[RA1] = 1
	
	return
	

; =-=-=- Send command I/O -=-=-=

snd_cmd_io:

	bank1													; Switch to bank 1
	
	movlw	H'00'											; B'00000000'
	movwf	TRISB											; TRISB = B'00000000'
	
	bank0													; Switch to bank 0
	
	bcf		PORTA,RA0										; PORTA[RA0] = 0
	bsf		PORTA,RA2										; PORTA[RA2] = 1
	
	return
	

; =-=-=- Not a command -=-=-=

ncmd:
	
	call 	ncmd_io
	call	default_io
	
	goto	main_loop
	
	
; =-=-=- Send-SET command -=-=-=

snds_cmd:

	bsf		PORTB,RB7										; PORTB[RB7] = 1
	
	call 	snd_cmd_io
	call	default_io
	
	bcf		PORTB,RB7										; PORTB[RB7] = 0
	
	goto	main_loop
	
	
; =-=-=- Send-SET command -=-=-=

sndc_cmd:
	
	call 	snd_cmd_io
	call	default_io
	
	goto	main_loop


; =-=-=- MainLoop -=-=-=

main_loop:

	movf	SNDS_CMD,W										; Work = SNDS_CMD
	xorwf	PORTB,W											; PORTB xor SNDS_CMD
	btfsc	STATUS,Z											; If PORTB != SNDS_CMD, skip
	goto	snds_cmd											; Execute this if PORTB is the Send-SET command
	
	movf	SNDC_CMD,W										; Work = SNDC_CMD
	xorwf	PORTB,W											; PORTB xor SNDC_CMD
	btfsc	STATUS,Z											; If PORTB != SNDC_CMD, skip
	goto	sndc_cmd											; Execute this if PORTB is the Send-CLEAR command
	
	goto	ncmd												; Execute this if PORTB is not a command
	
		
	goto	main_loop
	

; =-=-=- Init -=-=-=

init:

	; -- General purpose registers initialization --

	movlw	H'7F'											; B'01111111'
	movwf	SNDS_CMD											; Send-SET command = B'01111111'
	
	movlw 	H'3F'											; B'00111111'
	movwf	SNDC_CMD											; Send-CLEAR command = B'00111111'
	
	
	; -- I/O default --

	bank1													; Switch to bank 1
	
	movlw	H'F8'											; B'11111000'
	movwf	TRISA											; [~RA2]: output | [RA3~]: input
	
	bank0													; Switch to bank 0
	
	call	default_io										
	call 	main_loop
	
	end