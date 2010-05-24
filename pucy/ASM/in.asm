; Simple test program for VHDL general-purpose CPU
; Authors:
; 	Maciej Stefanczyk
;	Kacper Szkudlarek

	IN	R0, -1
	IN	R1, -1
	ADD R2, R1, R0
	OUT	R2, 0
	IN	R1, -1
	MUL	R3, R1, R2
	OUT	R3, 0

; stop operation
	STOP
