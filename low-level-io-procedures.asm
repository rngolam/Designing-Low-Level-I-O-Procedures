TITLE Low-Level I/O Procedures     (low-level-io-procedures.asm)

; Author: Richard Ngo-Lam
; Last Modified: 3/14/2021
; Email address: rngolam@gmail.com
; Description: This program will implement macros for string processing in order to validate and convert a user's
;	numeric string inputs to integers, calculate the sum and average of the integers, then cast the values back
;	to strings and display the results.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt, then writes the user's keyboard input into a memory location.
;
; Preconditions: prompt, buffer, and byteCount must be addresses passed by reference.
;
; Receives:
;	prompt = address of string prompt for user
;	buffer = address of user's input string
;	bufferSize = maximum length in bytes that will be read and written to memory
;	byteCount = address of bytes read
;
; Returns:
;	buffer contains user string read by ReadString; byteCount contains number of bytes
;		read after calling ReadString
; ---------------------------------------------------------------------------------
mGetString	MACRO	prompt, buffer, bufferSize, byteCount

	PUSH	EAX		; Save EAX register
	PUSH	EDX		; Save EDX register
	PUSH	ECX		; Save ECX register

	mDisplayString prompt
	MOV		EDX, buffer		; point to the buffer address
	MOV		ECX, bufferSize	; specify maximum number of characters to be read
	CALL	ReadString
	MOV		EDI, byteCount	; store bytes read in byteCount
	MOV		[EDI], EAX

	POP		ECX		; Restore ECX
	POP		EDX		; Restore EDX
	POP		EAX		; Restore EAX

ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Writes a null-terminated string stored at a specified memory location to the output.
;
; Preconditions: buffer must be an address passed by reference.
;
; Receives:
;	buffer = address of string to be displayed
;
; Returns: string displayed in console output.
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	buffer

	PUSH	EDX		; Save EDX register

	MOV		EDX, buffer
	CALL	WriteString

	POP		EDX		; Restore EDX

ENDM



BUFFER_SIZE = 255
INTEGER_COUNT = 10


.data
programTitle	BYTE	"Designing Low-Level I/O Procedures",13,10
				BYTE	"Written by: Richard Ngo-Lam",13,10,0
description		BYTE	"Please provide 10 signed decimal integers.",13,10
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register. "
				BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,0
prompt			BYTE	"Please enter a signed number: ",0
error			BYTE	"ERROR: You did not enter a signed number or your number was too big",13,10,0
retryPrompt		BYTE	"Please try again: ",0

numListString	BYTE	"You entered the following numbers:",13,10,0
sumString		BYTE	"The sum of these numbers is: ",0
averageString	BYTE	"The rounded average is: ",0

goodbye			BYTE	"Thanks for playing!",13,10,0

inputString		BYTE	BUFFER_SIZE DUP(?)
inputInt		SDWORD	?
bytesRead		DWORD	?
userIntegers	SDWORD	INTEGER_COUNT DUP(?)
intString		BYTE	BUFFER_SIZE DUP(?)

sum				SDWORD	0
average			SDWORD	?

space			BYTE	20h,0
comma			BYTE	2Ch,0
period			BYTE	2Eh,0

validInputCount	DWORD	1


.code
main PROC

; --------------------------
; Invokes the mDisplayString macro to displays program title, description, and
; extra credit being attempted.

; --------------------------
_introduction:
	mDisplayString OFFSET programTitle
	CALL	CrLf
	mDisplayString OFFSET description
	CALL	CrLf


; --------------------------
; Calls ReadVal to get a validated integer converted from the user's input string and
; stores the validated integer in an array of user integers. Repeats this process for
; the number of integers specified by the INTEGER_COUNT constant.

; --------------------------
	MOV		ECX, INTEGER_COUNT
	MOV		EDI, OFFSET userIntegers

_getInputs:
	; Get user string input
	PUSH	OFFSET space
	PUSH	OFFSET period
	PUSH	OFFSET validInputCount
	PUSH	OFFSET prompt
	PUSH	OFFSET error
	PUSH	OFFSET retryPrompt
	PUSH	OFFSET inputString
	PUSH	OFFSET inputInt
	PUSH	OFFSET bytesRead
	CALL	ReadVal
	
	; Store validated integer in array of user integers
	MOV		EAX, [inputInt]
	MOV		[EDI], EAX
	ADD		EDI, TYPE userIntegers
	LOOP	_getInputs

	CALL	CrLf

; --------------------------
; Iterates over the array of user integers, calling WriteVal to convert each
; integer to a string output, and invokes mDisplayString for commma delineation
; between the displayed array elements.

; --------------------------
	MOV		ESI, OFFSET userIntegers		; Address of userIntegers array in ESI
	MOV		ECX, LENGTHOF userIntegers
	mDisplayString OFFSET numListString		; Title for string to be displayed

_displayNumList:
	; Writes current array element as string output
	PUSH	[ESI]
	CALL	WriteVal

	CMP		ECX, 1
	JE		_lastElement		; Exclude trailing comma for final element

	; Delineates array elements with comma
	mDisplayString OFFSET comma
	mDisplayString OFFSET space

	ADD		ESI, TYPE userIntegers	; increment array element pointer
	LOOP	_displayNumList

_lastElement:
	CALL	CrLf


; --------------------------
; Calculates the sum of all elements in the array of user integers and
; displays it by invoking WriteVal.

; --------------------------
_displaySum:
	
	PUSH	OFFSET sum
	PUSH	TYPE userIntegers
	PUSH	OFFSET userIntegers
	CALL	calculateSum

	mDisplayString OFFSET sumString
	PUSH	sum
	CALL	WriteVal
	CALL	CrLf

; --------------------------
; Calculates the rounded average of user integers and
; displays it by invoking WriteVal.

; --------------------------
_displayAverage:

	PUSH	OFFSET average
	PUSH	sum
	CALL	calculateAverage

	mDisplayString OFFSET averageString
	PUSH	average
	CALL	WriteVal
	
	CALL	CrLf
	CALL	CrLf

; --------------------------
; Displays parting message for the user.

; --------------------------
_goodbye:
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; ---------------------------------------------------------------------------------
; Name: ReadVal
; 
; Gets a string input from the user by invoking the mGetString macro, calls on a subprocedure
;	to convert it to an integer and validate it, then either returns the input as an integer
;	if valid or re-prompts the user for input if invalid.
;
; Preconditions: BUFFER_SIZE is a constant, BUFFER_SIZE > 0; input must be a string
;
; Postconditions: number of string bytes in bytesRead
;
; Receives:
;	[EBP + 40]	= address of space character
;	[EBP + 36]	= address of period character
;	[EBP + 32]	= address of valid input count, the subtotal of inputs that have been validated (extra credit)
;	[EBP + 28]	= address of string prompting user for input
;	[EBP + 24]	= address of error message string
;	[EBP + 20]	= address of message string re-prompting user for input
;	[EBP + 16]	= address of input string, the raw string read from the user
;	[EBP + 12]	= address of user integer converted from string
;	[EBP + 8]	= address of the byte count read from the user's string
;	BUFFER_SIZE is a global constant.
;
; Returns: inputInt = validated SDWORD integer, validInputCount = running total of valid inputs
; ---------------------------------------------------------------------------------
ReadVal PROC
	LOCAL	validInput:BYTE		; local boolean value

	PUSHAD	; preserve all general purpose registers

_getInput:
	; Display line number (extra credit)
	MOV		ESI, [EBP + 32]		; validInputCount in ESI
	PUSH	[ESI]				; value of validInputCount pushed to stack
	CALL	WriteVal
	mDisplayString [EBP + 36]	; print period
	mDisplayString [EBP + 40]	; print space

	; Prompt user for input
	mGetString [EBP + 28], [EBP + 16], BUFFER_SIZE, [EBP + 8]	; address of prompt, address of inputString, buffer size, address of bytes read

_convertString:
	
	; validInput defaults to boolean value of True
	MOV		validInput, 1
	LEA		EDX, validInput
	
	PUSH	[EBP + 12]	; address of converted user integer
	PUSH	EDX			; address of validInput boolean
	PUSH	[EBP + 16]	; address of user string
	PUSH	[EBP + 8]	; address of bytes read
	CALL	stringToInt

	CMP		validInput, 0
	JE		_invalidInput
	JMP		_endProc

_invalidInput:
	mDisplayString [EBP + 24]	; address of error message

	; Display line number (extra credit)
	MOV		ESI, [EBP + 32]		; address of validInputCount in ESI
	PUSH	[ESI]				; value of validInputCount pushed to stack
	CALL	WriteVal
	mDisplayString [EBP + 36]	; print period
	mDisplayString [EBP + 40]	; print space

	; Reprompt user for string
	mGetString [EBP + 20], [EBP + 16], BUFFER_SIZE, [EBP + 8]
	JMP		_convertString

_endProc:
	; Increment validInputCount
	MOV		EDI, [EBP + 32]
	INC		DWORD PTR [EDI]

	POPAD	; restore all general purpose registers
	RET		36
ReadVal ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
; 
; Converts a 4-byte integer to a string and displays it by invoking the
;	mDisplayString macro.
;
; Preconditions: Integer must be 4 bytes in size.
;
; Postconditions: None.
;
; Receives:
;	[EBP + 8]	= 4-byte integer value
;
; Returns: integer cast to string and displayed in the output
; ---------------------------------------------------------------------------------
WriteVal PROC
	LOCAL	stringLength:DWORD, emptyString[12]:BYTE, reverseString[12]:BYTE	; local variables--emptyString is the string where digits cast to ASCII values will be written from right to left, reverseString will be generated by reversing the emptyString

	PUSHAD	; preserve all general purpose registers

; --------------------------
; Through sequential division by 10, the input integer will be truncated, with the remainders of
; each operation cast to ASCII values and appended to an empty string, which will build a string
; representation of the integer read from right to left. To have this string read from left to right,
; a new string will be generated that reverses the string built from sequential division. This final
; string will be passed as a parameter to the mDisplayString macro to be printed in the output.

; --------------------------
	MOV		stringLength, 0

	; Append null-terminating character to empty string
	LEA		EDI, emptyString
	MOV		EAX, 0
	MOV		[EDI], EAX
	INC		EDI
	INC		stringLength
	
	MOV		EAX, [EBP + 8]		; 4-byte integer in EAX

_truncate:
	; Perform sequential division by 10
	CDQ
	MOV		EBX, 10
	IDIV	EBX

	CMP		EDX, 0
	JL		_convertNegativeRemainder
	JMP		_buildString

_convertNegativeRemainder:
	NEG		EDX	

_buildString:
	; Cast remainder to ASCII value, append it to the string being built, and increment destination pointer and stringLength value
	ADD		EDX, 30h
	MOV		[EDI], DL
	INC		EDI
	INC		stringLength
	CMP		EAX, 0
	JNE		_truncate

	; If integer is negative, append sign to end of the string
	MOV		EAX, [EBP + 8]
	CMP		EAX, 0
	JL		_appendNegativeSign
	DEC		EDI				; Shift EDI pointer back to last character in the built string
	JMP		_reverseString

_appendNegativeSign:
	MOV		AL, 2Dh
	MOV		[EDI], AL
	INC		stringLength

_reverseString:
	; EDI currently at end of the built string. Set ESI to this address to prepare to copy string in reverse.
	MOV		ECX, stringLength
	MOV		ESI, EDI
	LEA		EDI, reverseString

_reverseLoop:
	STD		; set direction flag to move backwards through built / source string
	LODSB	; load character from source string into AL; increment ESI
	CLD		; set direction flag tto move forward through reversed / destination string
	STOSB	; copy character in AL to destination address; increment EDI
	LOOP	_reverseLoop

	; Display the final, reversed string
	LEA		EAX, reverseString
	mDisplayString EAX

	POPAD	; restore all general-purpose registers

	RET		4
WriteVal ENDP


; ---------------------------------------------------------------------------------
; Name: stringToInt
; 
; Validates and converts a string to an SDWORD integer value if possible. If the input
;	is invalid, returns a False boolean value instead.
;
; Preconditions: Desired integer value must fit in a 32-bit register to be considered valid; string
;	may not contain non-numerical characters other than a + or - sign at the beginning. Length of
;	string may not exceed the allocated BUFFER_SIZE.
;
; Postconditions: None.
;
; Receives:
;	[EBP + 20]	= address of SDWORD integer converted from string
;	[EBP + 16]	= address of validInput boolean (local variable to ReadVal proc)
;	[EBP + 12]	= address of input string to be converted/validated
;	[EBP + 8]	= number of bytes read from the string / string length
;
; Returns: inputInt = SDWORD integer converted from string and/or boolean value for valid input
;	(either unchanged from True or changed to False)
; ---------------------------------------------------------------------------------
stringToInt PROC
	LOCAL	sign:BYTE

; --------------------------
; First determines the sign of the input, which is either explicitly positive or negative, or implicitly
; positive if no sign is given. If the sign is explicitly defined, loads the next value of the string into
; AL and manually decrements ECX. Next, the algorithm checks for the presence of leading 0s. For every leading 0
; loads the next value of the string into AL and manually decrements ECX. This will leave the remaining digits
; to be parsed, which will have its own steps outlined below.

; --------------------------
	PUSHAD					; preserve all general purpose registers

	MOV		sign, 2Bh		; sign defaults to positive
	
	CLD						; clear direction flag to move forward through the string
	MOV		ESI, [EBP + 8]
	MOV		ECX, [ESI]		; string length in ECX
	MOV		ESI, [EBP + 12]	; address of user string in ESI

	CMP		ECX, BUFFER_SIZE
	JG		_invalidInput	; string length must fit within size allocated by buffer

	MOV		EBX, 0			; running total of converted integer value in EBX

_sign:
	; checks sign of first character in string
	LODSB					; loads byte into AL
	CMP		AL, 2Bh			; + character
	JE		_explicitPositiveSign
	CMP		AL, 2Dh			; - character
	JE		_negativeSign

	; implicit positive value
	CMP		AL, 0
	JE		_leadingZeros
	JMP		_parseDigits

_explicitPositiveSign:
	; Load next character and decrements the remaining length of the string to be parsed
	LODSB
	DEC		ECX
	CMP		AL, 0
	JE		_leadingZeros
	JMP		_parseDigits

_negativeSign:
	; Change the sign value, Load next character, and decrements the remaining length of the string to be parsed
	MOV		sign, 2Dh
	LODSB
	DEC		ECX
	CMP		AL, 0
	JE		_leadingZeros
	JMP		_parseDigits

_leadingZeros:
	; Truncates leading 0s until a nonzero character is reached, or until a zero is reached that happens to be the last character in the string.
	CMP		ECX, 1
	JE		_parseDigits	; if last digit is a 0, parse it
	
	LODSB
	DEC		ECX
	CMP		AL, 0
	JE		_leadingZeros

_parseDigits:
; --------------------------
; Loads the string character at the source pointer's address into AL and casts it to an integer value. This value represents the ones place,
; which is preserved and added on to the current running total. The running total and ones place value are concatenated by multiplying the
; running total by 10, effectively shifting each value leftward by one place. If any of non-numerical characters are encountered or if the
; overflow flag is triggered, the input is invalid.

; --------------------------
	; ECX is equal to number of digits to be parsed, excluding leading zeros and +/- signs
	; Validate digit is between 0-9
	CMP		AL, 30h
	JL		_invalidInput
	CMP		AL, 39h
	JG		_invalidInput

	SUB		AL, 30h			; convert ASCII to integer
	XOR		EDX, EDX
	MOV		DL, AL
	PUSH	EDX				; push integer to stack

	XOR		EDX, EDX
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX
	POP		EDX
	JO		_invalidInput	; overflow flag triggered
	ADD		EAX, EDX
	MOV		EBX, EAX		; save running total in EBX
	JO		_checkEdgeCases
	
	LODSB

	LOOP	_parseDigits

	; If the string's sign is negative, convert the integer to its two's-complement form
	CMP		sign, 2Dh
	JE		_convertToNegative
	JMP		_endProc

_convertToNegative:
	NEG		EBX
	JMP		_endProc

_checkEdgeCases:
	CMP		sign, 2Bh
	JE		_invalidInput
	CMP		ECX, 1			; accounts for -2147483648X, where X represents overflowing digits
	JG		_invalidInput
	CMP		EAX, 80000000h	; +2147483648 does not fit in a 32-bit register, but -2147483648 does
	JE		_endProc

_invalidInput:
	MOV		EDI, [EBP + 16]		; address of valid input boolean parameter
	MOV		EAX, 0
	MOV		[EDI], EAX

_endProc:
	MOV		EDI, [EBP + 20]		; address of converted user integer in EDI
	MOV		[EDI], EBX
	
	POPAD
	RET		16
stringToInt ENDP


; ---------------------------------------------------------------------------------
; Name: calculateSum
; 
; Iterates over the array of user integers and calculates the sum of all values.
;
; Preconditions: INTEGER_COUNT is a constant; INTEGER_COUNT > 0.
;
; Postconditions: None.
;
; Receives:
;	[EBP + 16]	= address of sum
;	[EBP + 12]	= value of the array type
;	[EBP + 8]	= address of the user integer array
;	INTEGER_COUNT is a global constant.
;
; Returns: sum = sum of all values in the array of user's integers.
;
; ---------------------------------------------------------------------------------
calculateSum PROC
	
	PUSH	EBP
	MOV		EBP, ESP

	PUSHAD		; preserve all general purpose registers

	MOV		ESI, [EBP + 8]		; address of user integer array in ESI
	MOV		EDI, [EBP + 16]		; address of sum in EDI
	MOV		ECX, INTEGER_COUNT

_addArrayValues:
	MOV		EAX, [ESI]
	ADD		[EDI], EAX
	ADD		ESI, [EBP + 12]		; increment ESI by array type
	LOOP	_addArrayValues

_endProc:
	POPAD		; restore all general purpose registers

	POP		EBP
	RET		12
calculateSum ENDP


; ---------------------------------------------------------------------------------
; Name: calculateAverage
; 
; Calculates the rounded average of the integers in an array, using floor rounding.
;
; Preconditions: INTEGER_COUNT is a constant; INTEGER_COUNT > 0.
;
; Postconditions: None.
;
; Receives:
;	[EBP + 12]	= value of the the average value
;	[EBP + 8]	= address of the sum of array values
;	INTEGER_COUNT is a global constant.
;
; Returns: average = average of the integers in an array, using floor rounding.
;
; ---------------------------------------------------------------------------------
calculateAverage PROC

	PUSH	EBP
	MOV		EBP, ESP

	PUSHAD

	MOV		EDI, [EBP + 12]	; address of average in EDI

	MOV		EAX, [EBP + 8]	; sum in EAX
	CDQ
	MOV		EBX, INTEGER_COUNT	; number of integers in EBX
	IDIV	EBX

	CMP		EDX, 0
	JL		_negativeFloorRounding
	JMP		_endProc

_negativeFloorRounding:
	; If remainder is negative, round down to the nearest integer
	DEC		EAX

_endProc:
	MOV		[EDI], EAX	; average written to memory

	POPAD

	POP		EBP
	RET		4

calculateAverage ENDP

END main
