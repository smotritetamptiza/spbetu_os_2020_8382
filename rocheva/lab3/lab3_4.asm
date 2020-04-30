LAB3	SEGMENT
		ASSUME CS:LAB3, DS:LAB3, ES:NOTHING, SS:NOTHING
		ORG 100H ; резервирование места для PSP
START:	JMP BEGIN

availableMemory db 'Amont of available memory:        B.', 0DH,0AH, '$'
extendedMemory db 'Amont of extended memory:       KB.', 0DH,0AH, '$'
endLine db 0DH,0AH, '$'
mcbline db 'New MCB:', 0DH,0AH, 'Type: $'
mcbsector db 'h. Sector: $'
mcbsize db 'h. Size:        B$'
lastBytes db '. Information in last bytes: $'
memError db 'Memory cannot be allocated.$'

BEGIN:
		; кол-во доступной памяти
		mov ah, 4ah
		mov bx, 0ffffh
		int 21h
		mov ax, bx
		mov bx, 16
		mul bx
		lea si, availableMemory + 32
		call WRD_TO_DEC
		lea	dx, availableMemory
		call WRITE
		
		; + 64 кб
		mov ah, 48h
		mov bx, 1000h
		int 21h
		jc	allocError
		jmp continue
allocError:
		lea dx, memError
		call WRITE
		
continue:
		; освобождение 
		mov ah, 4ah
		mov bx, offset LAB_END
		int 21h
		
		
		; размер расширинной памяти
		xor ax, ax
		xor dx, dx
		mov al, 30h
		out 70h, al
		in al, 71h
		mov bl, al
		mov al, 31h
		out 70h, al
		in al, 71h
		mov bh, al
		mov ax, bx
		lea si, extendedMemory + 30
		call WRD_TO_DEC
		lea	dx, extendedMemory
		call WRITE
		
		; блоки
		xor ax, ax
		mov ah, 52h
		int 21h
		mov cx, es:[bx-2]
		mov es, cx
mcb:
		lea	dx, mcbline
		call WRITE
		
		; тип
		mov al, es:[00h]
		call WRITE_BYTE
		
		; сектор
		lea dx, mcbsector
		call WRITE
		mov ax, es:[01h]
		mov ch, ah
		mov ah, al
		mov al, ch
		call WRITE_BYTE
		mov ch, ah
		mov ah, al
		mov al, ch
		call WRITE_BYTE
		
		; размер
		mov ax, es:[03h]
		mov bx, 10h
		mul bx
		mov si, offset mcbsize
		add si, 14
		call WRD_TO_DEC
		mov dx, offset mcbsize
		call WRITE
		
		; информация в последних восьми байтах
		lea dx, lastBytes
		call WRITE
		xor bx, bx
last:		
		mov dl, es:[bx+08h]
		mov ah, 02h
		int 21h
		inc bx
		cmp bx, 8
		jl last
		
		lea	dx, endLine
		call WRITE
		; если последний тип
		mov al, es:[00h]
		cmp al, 5Ah
		je endmcb
		
		xor cx, cx
		mov cx, es:[03h]
		mov bx, es
		add bx, cx
		inc bx
		mov es, bx
		jmp mcb

		
endmcb:
		xor al, al
		mov ah, 4Ch
		int 21h


WRITE_BYTE PROC near
	push ax
	push dx
	push cx
	call BYTE_TO_HEX
	xor cx, cx
	mov ch, ah
	mov dl, al
	mov ah, 02h
	int 21h
	mov dl, ch
	mov ah, 02h
	int 21h
	pop cx
	pop dx
	pop ax
	ret
WRITE_BYTE    ENDP

WRITE PROC near
		mov ah, 09
		int 21h
WRITE ENDP
	
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
;------------------------------------
WRD_TO_DEC PROC NEAR
		push 	cx
		push 	dx
		mov 	cx,10
loop_b: div 	cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor 	dx,dx
		cmp 	ax,10
		jae 	loop_b
		cmp 	al,00h
		je 		endl
		or 		al,30h
		mov 	[si],al
endl:	pop 	dx
		pop 	cx
		ret
WRD_TO_DEC ENDP
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

LAB_END:
LAB3	ENDS
		END START
