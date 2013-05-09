/*
 * Handin3.asm
 *
 *  Created: 06.11.2012 10:06:13
 *   Author: User
 */ 

.INCLUDE "LegoInterface.asm"

.INCLUDE "InterruptVectorTable.asm"

.ORG 0x0100
.DEF LIGHT_AVERAGE = R16 

Main:
	; Setup stack
	LDI R16, 0xFF
	OUT SPL, R16
	LDI R16, 0x21
	OUT SPH, R16

	; Enable port A for LED's
	LDI R16, 0xFF
	OUT DDRA, R16
	OUT PORTA, R16

	SUB R1, R12
	CALL init_lego_interface

	; Interrupt enable
	SEI

MainLoop:
	CALL WaitSwitch

	LDI LIGHT_AVERAGE, 0x40

	PUSH R18
	CALL ReadLight
	POP R18
	OUT PORTA, R18
	
	CP LIGHT_AVERAGE, R18 
	BRSH MoveRight
	;BRLO MoveRight
	;JMP MainLoop

MoveLeft:
	LDI R17, 127
	JMP Move
MoveRight:
	LDI R17, -126
Move:
	PUSH R17
	CALL RotateMotor
	POP R17

	; delay
	LDI R17, 0xFF
	PUSH R17
	LDI R17, 0xC0
	PUSH R17
	CALL Delay
	POP R17
	POP R17

	CALL StopMotor

	JMP MainLoop

; Waits for SW7 to be pressed and released
; @input:	none
; @output:	none
WaitSwitch:
	PUSH R16
	LDI R16, 0xFF
WaitPress:
	IN	R16, PINC
	CPI R16, 0x7F
	BRNE WaitPress
WaitRelease:
	IN	R16, PINC
	CPI R16, 0xFF
	BRNE WaitRelease
	POP R16
	RET

; Reads a value from the light sensor
; @input:	none
; @output:	light reading (1 byte)
ReadLight:
	; Save working registers
	PUSH R24
	PUSH R25
	PUSH R26
	PUSH R27

	; Do magic
	LDI R24, 0x00
	LDI R25, 0x00
	CALL light_sensor	
	OR R24, R25
	;COM R24

	; Save output value
	IN R26, SPL
	IN R27, SPH
	ADIW R26, 8
	ST X, R24

	; Restore the registers and return
	POP R27
	POP R26
	POP R25
	POP R24
	RET


Delay:
	PUSH R16
	PUSH R17
	PUSH R26
	PUSH R27
	PUSH R18

	IN R26, SPL
	IN R27, SPH
	ADIW R26, 11
	LD R16, -X
	LD R17, -X

Outer:
	CPI R16, 0x00
	BREQ End_delay
	DEC R16
	MOV R18, R17

Inner:
	CPI R18, 0x00
	BREQ Outer
	DEC R18
	JMP Inner

End_delay:
	POP R18
	POP R27
	POP R26
	POP R17
	POP R16
	RET

; Rotates the motor
; @input:	motor speed -127 to 127 
; @output:	none
RotateMotor:
	; Save working registers
	PUSH R22
	PUSH R24
	PUSH R26
	PUSH R27

	; Get input param
	IN R26, SPL
	IN R27, SPH
	ADIW R26, 8	;motor speed
	LD R22, X
	LDI R24, 0	; motor port
	CALL motor_speed

	; Restore registers and return
	POP R27
	POP R26
	POP R24
	POP R22
	RET

; Stops the motor
; @input:	none
; @output:	none
StopMotor:
	PUSH R16
	LDI R16, 0
	PUSH R16
	CALL RotateMotor
	POP R16
	POP R16
	RET

End:
	JMP End