AStack	SEGMENT  STACK
		DW 100h DUP(0)   
AStack	ENDS


DATA	SEGMENT
; ДАННЫЕ
TYPE_PC					db 'PC', 13, 10, '$'
TYPE_PCorXT				db 'PC/XT', 13, 10, '$'
TYPE_PS2_30				db 'PS2 model 30', 13, 10, '$'
TYPE_PS2_50or60			db 'PS2 model 50 or 60', 13, 10, '$'
TYPE_PS2_80				db 'PS2 model 80', 13, 10, '$'
TYPE_PCjr				db 'PCjr', 13, 10, '$'
TYPE_PC_Convertible		db 'PC Convertible', 13, 10, '$'
TYPE_ANOTHER_MESSAGE	db 'Another: ', 13, 10, '$'
TYPE_ANOTHER			db '00', 13, 10, '$'

OS_VER_MESSAGE			db 'DOS version: ', '$'
OS_VER					db '00.00', 13, 10, '$'
OS_VER_BELOW_2			db 'OS ver <2.0', 13, 10, '$'
OEM_MESSAGE				db 'OEM: ', '$'
OEM						db '000', 13, 10, '$'
USER_NUMBER_MESSAGE		db 'User Number: ', '$'
USER_NUMBER				db '00000000', 13, 10, '$'
DATA ENDS


CODE	SEGMENT
		ASSUME CS:CODE, DS:DATA, SS:AStack

; ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
; младшая шестн. цифра AL в шестн. цифру ASCII
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT: 	add AL,30h
		ret
TETR_TO_HEX ENDP 

;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два шестн. числа ASCII в AX
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX 	; в AL старшая цифра
		pop CX 				; в AH младшая
		;xchg AL,AH			;; а теперь наоборот!
		ret
BYTE_TO_HEX ENDP 

;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/с 16-разрядного числа
; в AX – число, DI – адрес последнего символа
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
WRD_TO_HEX ENDP 

;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с/с, SI – адрес поля младшей цифры
		push CX
		push DX
		xor AH,AH
		xor DX,DX
		mov CX,10
loop_bd:div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_bd
		cmp AL,00h
		je end_l
		or AL,30h
		mov [SI],AL
		dec si
end_l: 	pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP 



;--------------------------------------------------
PRINT_STRING PROC near
; Просто выводит строку с уже указанным в dx смещением, очень сложная функция
		push ax
		
		mov ah, 09h
		int 21h
		
		pop ax
		ret
PRINT_STRING ENDP

;--------------------------------------------------
PRINT_WORD PROC near
; Выводит регистр AX
		push ax
		push dx
		
		mov dl, ah
		mov ah, 02h
		int 21h
		
		mov dl, al
		int 21h
		
		pop dx
		pop ax
		ret
PRINT_WORD ENDP

;--------------------------------------------------
PRINT_ENDL PROC near
; Выводит регистр 13, 10
		push ax
		push dx
		
		mov dl, 13
		mov ah, 02h
		int 21h
		
		mov dl, 10
		int 21h
		
		pop dx
		pop ax
		ret
PRINT_ENDL ENDP



;-------------------------------
; КОД
MAIN PROC FAR
		mov ax, DATA
		mov ds, ax

		mov ax, 0F000h
		mov es, ax
		mov al, es:[0FFFEh]
		
		
PRINT_PC:
		mov dx, offset TYPE_PC
		jmp PRINT_TYPE
		
PRINT_PCorXT:
		mov dx, offset TYPE_PCorXT
		jmp PRINT_TYPE

PRINT_PS2_30:
		mov dx, offset TYPE_PS2_30
		jmp PRINT_TYPE

PRINT_PS2_50or60:
		mov dx, offset TYPE_PS2_50or60
		jmp PRINT_TYPE

PRINT_PS2_80:
		mov dx, offset TYPE_PS2_80
		jmp PRINT_TYPE

PRINT_PCjr:
		mov dx, offset TYPE_PCjr
		jmp PRINT_TYPE

PRINT_PC_Convertible:
		mov dx, offset TYPE_PC_Convertible
		jmp PRINT_TYPE
		
PRINT_TYPE:
		call PRINT_STRING
		jmp DOS_VERSION
		
PRINT_ANOTHER:
		mov dx, offset TYPE_ANOTHER_MESSAGE
		mov ah, 09h
		int 21h
		call BYTE_TO_HEX
		xchg ah, al
		call PRINT_WORD
		call PRINT_ENDL


DOS_VERSION:
		mov ah, 30h
		int 21h

		mov dx, offset OS_VER_MESSAGE
		call PRINT_STRING

		cmp al, 0
		je	DOS_VER_LESS_2
		mov si, offset OS_VER
		inc si
		
		push ax
		mov ah, 0
		call BYTE_TO_DEC
		pop ax
		
		add si, 4
		xchg ah, al
		mov ah, 0
		call BYTE_TO_DEC
		
		mov dx, offset OS_VER
		call PRINT_STRING
		
		jmp PRINT_OEM
		
		
DOS_VER_LESS_2:
		mov dx, offset OS_VER_BELOW_2
		mov ah, 09h
		int 21h
		
		
PRINT_OEM:
		mov dx, offset OEM_MESSAGE
		call PRINT_STRING
		
		mov si, offset OEM
		add si, 2
		mov al, bh
		mov ah, 0
		call BYTE_TO_DEC
		
		mov dx, offset OEM
		call PRINT_STRING
		
		
PRINT_USER_NUM:
		mov dx, offset USER_NUMBER_MESSAGE
		call PRINT_STRING
		
		mov si, offset USER_NUMBER
		add si, 7
		mov ax, cx
		call BYTE_TO_DEC
		
		;dec si
		mov al, bl
		mov ah, 0
		call BYTE_TO_DEC
		
		mov dx, offset USER_NUMBER
		call PRINT_STRING
		

		xor AL,AL
		mov AH,4Ch
		int 21H	

MAIN	ENDP
CODE	ENDS
		END MAIN ; конец модуля, START – точка входа
		