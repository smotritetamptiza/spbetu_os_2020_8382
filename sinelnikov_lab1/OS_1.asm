TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H ; резервирование места для PSP
START:	JMP begin

PC db 'PC',0DH,0AH,'$'
XT db 'PC/XT',0DH,0AH,'$'
AT db 'AT',0DH,0AH,'$'
PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PS2_80 db  'PS2 model 80',0DH,0AH,'$'
PCjr db  'PCjr',0DH,0AH,'$'
PC_Covertible db  'PC Convertible',0DH,0AH,'$'

OTHER_MODEL db  'Other model:',0DH,0AH,'$'
VERSION db 'Version:0 $'
POINT db  '.$'
MODIFICATION db '0 ',0DH,0AH,'$'
OEM db  'OEM:   ',0DH,0AH,'$'
SERIAL_NUMBER db 'SERIAL NUMBER:       ', 0DH,0AH,'$'

begin:
	mov ax,0F000H
	mov es,ax
	mov al,es:[0FFFEH] 
	cmp al,0FFH
	je PC_label
	cmp al,0FEH
	je XT_label
	cmp al,0FBH	
	je XT_label
	cmp al,0FCH
	je AT_label
	cmp al,0FAH
	je PS2_30_label
	cmp al,0F8H
	je PS2_80_label
	cmp al,0FDH
	je PCjr_label
	cmp al, PC_Covertible_label
	jmp Other_version_label


PC_label:
	mov dx,offset PC
	jmp writeModel

XT_label:
	mov dx,offset XT
	jmp writeModel

AT_label:
	mov dx,offset AT
	jmp writeModel

PS2_30_label:
	mov dx,offset PS2_30
	jmp writeModel

PS2_80_label:
	mov dx,offset PS2_80
	jmp writeModel

PCjr_label:
	mov dx,offset PCjr
	jmp writeModel

PC_Covertible_label:
	mov dx,offset PC_Covertible
	jmp writeModel

Other_version_label:
	mov dx,offset OTHER_MODEL
	push ax
	mov ah,09h
	int 21h
	pop ax
	call BYTE_TO_HEX
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	pop ax
	jmp OS_version_label

writeModel:
	push ax
	mov ah,09h
	int 21h
	pop ax

OS_version_label:
	mov ah,30h
	int 21h
	cmp al,0
	je MOD_label
	mov si, offset VERSION
	add si,8
	cmp al,9
	jg continue1
	add si,1
	continue1:
	push ax
	call BYTE_TO_DEC
	mov dx, offset VERSION
	mov ah, 09h
	int 21h
	pop ax
	jmp MOD_label

MOD_label:
	push ax
	mov dx,offset POINT
	mov ah, 09h
	int 21h
	pop ax
	push ax
	mov si, offset MODIFICATION
	mov al,ah
	cmp al,9
	jg continue2
	add si,1
	continue2:
	call BYTE_TO_DEC
	mov dx, offset MODIFICATION 
	mov ah, 09h
	int 21h
	pop ax

OEM_label:
	push ax
	mov si, offset OEM
	add si,5
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	mov ah, 09h
	int 21h
	pop ax

SERIAL_NUMBER_label:
	mov di, offset SERIAL_NUMBER
	add di,20
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di,2
	mov [di], ax
	mov dx, offset SERIAL_NUMBER
	mov ah, 09h
	int 21h


TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

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
	
	
	
