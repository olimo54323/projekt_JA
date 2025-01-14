; Dodaj referencj� do funkcji HeapAlloc z Windows API
EXTERN GetProcessHeap: PROC
EXTERN HeapAlloc: PROC

.code
PUBLIC JuliaFractalASM
JuliaFractalASM PROC
    ; rcx - re (double)
    ; rdx - im (double)
    ; r8 - iterations (int)
    ; r9 - width (int)
    ; [rsp+40] - height (int)
    ; [rsp+48] - threads (int)
    
    push rbp
    mov rbp, rsp
    sub rsp, 32                   ; Shadow space dla Windows x64 calling convention
    
    ; Zachowaj parametry
    push rcx                      ; re
    push rdx                      ; im
    push r8                       ; iterations
    push r9                       ; width
    
    ; Oblicz rozmiar bufora
    mov rax, r9                   ; width
    mov rcx, [rsp+40+32]         ; height (32 to offset dla shadow space)
    mul rcx                       ; rax = width * height
    push rax                      ; zachowaj rozmiar
    
    ; Pobierz handle do sterty procesu
    sub rsp, 32                   ; Shadow space dla wywo�ania funkcji
    call GetProcessHeap
    add rsp, 32
    
    ; Alokuj pami��
    mov rcx, rax                  ; heap handle
    xor rdx, rdx                  ; flags = 0
    mov r8, [rsp+8]              ; rozmiar (wcze�niej zachowany na stosie)
    sub rsp, 32
    call HeapAlloc
    add rsp, 32
    
    ; Sprawd� czy alokacja si� powiod�a
    test rax, rax
    jz fail
    
    ; Przywr�� parametry
    pop r8                        ; rozmiar
    pop r9                        ; width
    pop r10                       ; iterations
    pop rdx                       ; im
    pop rcx                       ; re
    
    ; Tu b�dzie kod generuj�cy fraktal...
    ; Na razie wstawimy testow� warto��
    mov byte ptr [rax], 255
    
    ; Zwr�� wska�nik do bufora
    leave
    ret

fail:
    xor rax, rax                  ; Zwr�� null
    leave
    ret

JuliaFractalASM ENDP
END