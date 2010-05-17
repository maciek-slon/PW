; Simple test program for VHDL general-purpose CPU
; Authors:
; 	Maciej Stefanczyk
;	Kacper Szkudlarek

; reset device
RESET
JMP 0x50
LDI	R1, -14
ADD	R2, R1, R0
; store result in RAM
STORE	R2, 0xf0ff
STOP
