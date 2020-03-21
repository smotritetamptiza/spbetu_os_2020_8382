TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H ; резервирование места для PSP
START:	JMP BEGIN

PC db  'PC',0DH,0AH,'$'
XT db  'PC/XT',0DH,0AH,'$'
tAT db  'AT',0DH,0AH,'$'
PS2_30 db  'PS2 model 30',0DH,0AH,'$'
PS2_80 db  'PS2 model 80',0DH,0AH,'$'
PCJR db  'PCjr',0DH,0AH,'$'
PC_CONVERTIBLE db  'PC Convertible',0DH,0AH,'$'
OTHER_TYPE db  'Other type:',0DH,0AH,'$'
END_LINE db '       ', 0DH,0AH,'$'

VERSION db  'Version: ',0DH,0AH,'$'
VERS db ' $'
MODIFICATION db  '.$'
VERSION2 db  'Version <2.0',0DH,0AH,'$'
OEM db  'OEM number:',0DH,0AH,'$'
SERIAL_NUMBER db 'User serial number:', 0AH, '      ', 0DH,0AH,'$'


BEGIN:
		mov ax,0F000H
		mov es,ax 
		mov al,es:[0FFFEH] 
		
		cmp al, 0FFH
		je itIsPC
		cmp al, 0FEH
		je itIsPC_XT
		cmp al, 0FBH
		je itIsPC_XT	
		cmp al, 0FCH
		je itIsAT	
		cmp al, 0FAH
		je itIsPS2_30	
		cmp al, 0F8H
		je itIsPS2_80	
		cmp al, 0FDH
		je itIsPCjr	
		cmp al, 0F9H
		je itIsPCconvertible
		
		cmp al, 0F9H 
		jne itIsOther
		
;--------------------------------------
; Для вывода типа
itIsPC:
		mov dx, offset PC
		jmp writeType
		
itIsPC_XT:
		mov dx, offset XT
		jmp writeType

itIsAT:
		mov dx, offset tAT
		jmp writeType
		
itIsPS2_30:
		mov dx, offset PS2_30
		jmp writeType
		
itIsPS2_80:
		mov dx, offset PS2_80
		jmp writeType
	
itIsPCjr:
		mov dx, offset PCJR
		jmp writeType

itIsPCconvertible:
		mov dx, offset PC_CONVERTIBLE
		jmp writeType
		
itIsOther:
		mov dx, offset OTHER_TYPE
		mov ah, 09h
		int 21h
		call BYTE_TO_HEX
		call PRINT_NUM
		mov al, ah
		call PRINT_NUM
		call PRINT_END_LINE
		jmp OS_VERSION
		
writeType:
		mov ah, 09h
		int 21h
		jmp OS_VERSION
;--------------------------------------------		
		
		
;--------------------------------------------
; Для вывода версии системы

OS_VERSION:
		mov ah, 30h
		int 21h
		push cx
		push bx
		
printVer:
		push ax
		cmp al, 0
		je ver2
	
		mov dx, offset VERSION
		push ax
		mov ah, 09h
		int 21h
		pop ax
		
		mov si, offset VERS
		call BYTE_TO_DEC
		add si, 1
		mov dx, offset VERS
		mov ah, 09h
		int 21h
		pop ax
		jmp numMod		
	
ver2:
		mov dx, offset VERSION2
		mov ah, 09h
		int 21h
		pop ax

numMod:
		mov dx, offset MODIFICATION
		push ax
		mov ah, 09h
		int 21h
		pop ax
		mov si, offset END_LINE
		mov al, ah
		call BYTE_TO_DEC
		add si, 1
		mov dx, offset END_LINE
		mov ah, 09h
		int 21h
		
numOEM:
		mov dx, offset OEM
		push ax
		mov ah, 09h
		int 21h
		pop ax
		mov si, offset END_LINE
		mov al, bh
		call BYTE_TO_DEC
		add si, 1
		mov dx, offset END_LINE
		mov ah, 09h
		int 21h
		
serialNumb:
	;	mov dx, offset SERIAL_NUMBER
	;	push ax
	;	mov ah, 09h
	;	int 21h
		
		mov di, offset SERIAL_NUMBER
		add di, 25
		mov ax, cx
		call WRD_TO_HEX
		mov al, bl
		call BYTE_TO_HEX
		sub di, 2
		mov [di], ax
		mov dx, offset SERIAL_NUMBER
		mov ah, 09h
		int 21h
		

ext:		
		xor al, al
		mov ah, 4Ch
		int 21h
		


;---------------------------------------------		
	
PRINT_END_LINE PROC near
		push ax
		mov dx, offset END_LINE
		mov ah, 09h
		int 21h
		pop ax
PRINT_END_LINE ENDP
	
	
		
PRINT_NUM PROC near
		; вывод  al
		push ax
		mov dx, ax
		mov ah, 02h
		int 21h
		pop ax
		ret
PRINT_NUM ENDP		
		
		
		
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
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


	
		
TESTPC	ENDS
		END START

