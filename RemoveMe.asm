TITLE Remove Me!     (RemoveMe.asm)

; Author: 	Stephen Redfield
; Last Modified:	May 11, 2020
; Course number/section:   CS271 Section ???
; Description: This file is provided so you have something to remove from a Solution

INCLUDE Irvine32.inc

.data
Greeting	BYTE	"If you're seeing this, you haven't removed this .asm file yet!",0


.code
main PROC
	ThisWillBreakThings
	MOV	EDX, OFFSET Greeting
	Call WriteString
	Call CrLf

	Invoke ExitProcess,0	; exit to operating system
main ENDP


END main
