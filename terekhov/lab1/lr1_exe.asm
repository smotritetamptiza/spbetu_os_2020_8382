AStack SEGMENT STACK
        DW 100h DUP(5353H)
AStack ENDS
; ===Данные===
DATA SEGMENT
TYPE_PC         db'Тип IBM PC: ','$'
MSDOS_VERSION   db'Версия MS-DOS:   .                   ',0DH,0AH,'$'
OEM_NUMBER      db'Серийный номер OEM:                  ',0DH,0AH,'$'
USER_NUMBER     db'Серийный номер пользователя:        H',0DH,0AH,'$'
CASE_FF         db'PC                                   ',0DH,0AH,'$'
CASE_FE_FB      db'PC/XT                                ',0DH,0AH,'$'
CASE_FC         db'AT or PS2 model 50-60                ',0DH,0AH,'$'
CASE_FA         db'PS2 model 30                         ',0DH,0AH,'$'
CASE_F8         db'PS2 model 80                         ',0DH,0AH,'$'
CASE_FD         db'PCjr                                 ',0DH,0AH,'$'
CASE_F9         db'PC Convertible                       ',0DH,0AH,'$'
ERROR_MSG       db'ERROR                                ',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:AStack

; Процедура печати строки
WriteMsg PROC near 
        mov ah,09h
        int 21h
        ret
WriteMsg ENDP
;-----------------------------------------------------
TETR_TO_HEX PROC near
        and al,0Fh
        cmp al,09
        jbe NEXT
        add al,07
NEXT:   add al,30h; код нуля
        ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_HEX PROC near
; байт в al переводится в два символа шестн. числа в ax 
        push cx
        mov ah,al
        call TETR_TO_HEX
        xchg al,ah
        mov cl,4
        shr al,cl
        call TETR_TO_HEX ;в al старшая цифра
        pop cx ;в ah младшая
        ret
BYTE_TO_HEX ENDP
;-----------------------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в ax - число, di - адрес последнего символа 
        push bx
        mov bh,ah
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        dec di
        mov al,bh
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        pop bx
        ret
WRD_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_DEC PROC near
; перевод байта в 10с/с, si - адрес поля младшей цифры
; al содержит исходный байт
        push ax 
        push cx
        push dx
        xor ah,ah
        xor dx,dx
        mov cx,10
loop_bd: div cx
        or dl,30h
        mov [si],dl
        dec si
        xor dx,dx
        cmp ax,10
        jae loop_bd
        cmp al,00h
        je end_l
        or al,30h
        mov [si],al
end_l:  pop dx
        pop cx
        pop ax
        ret
BYTE_TO_DEC ENDP
;-----------------------------------------------------
Main PROC FAR
        sub ax, ax
        push ax
        mov ax, DATA
        mov ds, ax
;получим тип IBM PC
        mov bx, 0F000h
        mov es, bx
        mov al, es:[0FFFEh]
        cmp al, 00FFh
        jne FE
        lea bx, CASE_FF
        jmp CONCAT
FE:
        cmp al, 00FEh
        jne FB
        lea bx, CASE_FE_FB
        jmp CONCAT
FB:
        cmp al, 00FBh
        jne FC
        lea bx, CASE_FE_FB
        jmp CONCAT
FC:
        cmp al, 00FCh
        jne FA
        lea bx, CASE_FC
        jmp CONCAT
FA:
        cmp al, 00FAh
        jne F8
        lea bx, CASE_FA
        jmp CONCAT
F8:
        cmp al, 00F8h
        jne FD
        lea bx, CASE_F8
        jmp CONCAT
FD:
        cmp al, 00FDh
        jne F9
        lea bx, CASE_FD
        jmp CONCAT
F9:
        cmp al, 00F9h
        jne ERROR
        lea bx, CASE_F9
        jmp CONCAT
CONCAT:
        lea dx, TYPE_PC
        call WriteMsg
        lea dx, [bx]
        call WriteMsg
        jmp DOSBOX_VERS
ERROR:
        lea dx, TYPE_PC
        call WriteMsg
        lea dx, ERROR_MSG
        call WriteMsg
; получим версию досбокса
DOSBOX_VERS:
        mov ah, 30h; функция вернет в al старший ah младший номер версии 
        int 21h
        lea si, MSDOS_VERSION
        add si, 16
        call BYTE_TO_DEC
        lea si, MSDOS_VERSION
        add si, 19
        mov al, ah
        call BYTE_TO_DEC
; серийный номер OEM
        mov ah, 30h 
        int 21h
        mov al, bh
        lea si, OEM_NUMBER
        add si, 22
        call BYTE_TO_DEC
; серийный номер пользователя
        mov ax, cx 
        lea di, USER_NUMBER
        add di, 34
        call WRD_TO_HEX
        mov al, bl
        call BYTE_TO_HEX
        lea di, USER_NUMBER 
        add di, 29
        mov [di], ax

        lea dx, MSDOS_VERSION
        call WriteMsg
        lea dx, OEM_NUMBER
        call WriteMsg
        lea dx, USER_NUMBER
        call WriteMsg
        xor al,al
        mov ah,4Ch
        int 21h
Main ENDP
CODE ENDS
END Main