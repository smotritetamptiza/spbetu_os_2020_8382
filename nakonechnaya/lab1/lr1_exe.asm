AStack    SEGMENT  STACK
          DW 200 DUP(?)   
AStack    ENDS

DATA SEGMENT
; Данные
PC_STR db 'Type PC', 0DH,0AH,'$'
PC_XT_STR db 'Type PC/XT', 0DH,0AH,'$'
AT_STR db 'Type AT', 0DH,0AH,'$'
PS2_30_STR db 'Type PS2 model 30', 0DH,0AH,'$'
PS2_80_STR db 'Type PS2 model 80', 0DH,0AH,'$'
PCjr_STR db 'Type PCjr', 0DH,0AH,'$'
PC_C_STR db 'Type PC Convertible', 0DH,0AH,'$'
SYS_VER_STR db 'Version  .  ',0DH,0AH,'$'
SYS_VER_STR_2 db 'Version < 2.0',0DH,0AH,'$'
OEM_STR db 'OEM  ', 0DH,0AH,'$'
USER_STR db  'User       $'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near	
	and AL,0Fh
	cmp AL,09
	jbe next
	add AL,07
	NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------

BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX 	    ;в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------

WRD_TO_HEX PROC near
; перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
; перевод в 10с/с, SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd:
		div CX
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
	end_l:
		pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP
;-------------------------------

; Код
BEGIN:

TYPE_PC PROC near
; Определение типа PC
	mov AX,0F000H
	mov ES,AX
	mov AL,ES:[0FFFEH]
	cmp AL,0FFH	;это PC?
		je PC
	cmp AL,0FEH ;это PC/XT?
		je PC_XT
	cmp AL,0FBH ;это PC/XT?
		je PC_XT
	cmp AL,0FCH ;это AT?
		je AT
	cmp AL,0FAH ;это PS2 модель 30?
		je PS2_30
	cmp AL,0F8H ;это PS2 модель 80?
		je PS2_80
	cmp AL,0FDH ;это PCjr?
		je PCjr
	cmp AL,0F9H ;это PC Convertible?
		je PC_C
		
	PC:
		mov DX,offset PC_STR
		jmp WRITE	
	PC_XT:
		mov DX,offset PC_XT_STR
		jmp WRITE
	AT:
		mov DX,offset AT_STR
		jmp WRITE
	PS2_30:
		mov DX,offset PS2_30_STR
		jmp WRITE
	PS2_80:
		mov DX,offset PS2_80_STR
		jmp WRITE
	PCjr:
		mov DX,offset PCjr_STR
		jmp WRITE
	PC_C:
		mov DX,offset PC_C_STR
		jmp WRITE
	WRITE:
		mov AH,09h
		int 21h
		call MS_DOS
	ret
TYPE_PC ENDP

MS_DOS PROC near
; Определение версии MS_DOS
VER:	
	mov AH,30h
	int 21h
	push AX
	cmp AL, 0
		je VER_2
	mov SI,offset SYS_VER_STR
	add SI,8
	call BYTE_TO_DEC
   	pop AX
   	mov AL,AH
   	add SI,3
	call BYTE_TO_DEC
	mov DX,offset SYS_VER_STR
	mov AH,09h
	int 21h
	jmp OEM

VER_2:
	mov DX,offset SYS_VER_STR_2
	mov AH,09h
	int 21h
	pop AX
	jmp OEM	

OEM:
	mov SI,offset OEM_STR
	add SI,5
	mov AL,BH
	call BYTE_TO_DEC
	mov DX,offset OEM_STR
	mov AH,09h
	int 21h
	jmp USER

USER:
	mov DI,offset USER_STR
	add DI,10
	mov AX,CX
	call WRD_TO_HEX
	mov AL,BL
	call BYTE_TO_HEX
	sub DI,2
	mov [DI],AX
	mov DX,offset USER_STR
	mov AH,09h
	int 21h
	ret
MS_DOS ENDP

MAIN PROC far
   	push AX
   	mov AX,DATA
   	mov DS,AX
	call TYPE_PC

	; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
MAIN ENDP
CODE ENDS
END Main
