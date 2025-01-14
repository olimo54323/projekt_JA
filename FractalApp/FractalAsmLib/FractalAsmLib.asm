; Dodaj referencjê do funkcji HeapAlloc z Windows API
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
    sub rsp, 32                   ; Shadow space dla wywo³ania funkcji
    call GetProcessHeap
    add rsp, 32
    
    ; Alokuj pamiêæ
    mov rcx, rax                  ; heap handle
    xor rdx, rdx                  ; flags = 0
    mov r8, [rsp+8]              ; rozmiar (wczeœniej zachowany na stosie)
    sub rsp, 32
    call HeapAlloc
    add rsp, 32
    
    ; SprawdŸ czy alokacja siê powiod³a
    test rax, rax
    jz fail
    
    ; Przywróæ parametry
    pop r8                        ; rozmiar
    pop r9                        ; width
    pop r10                       ; iterations
    pop rdx                       ; im
    pop rcx                       ; re
    
    ; Tu bêdzie kod generuj¹cy fraktal...
    ; Na razie wstawimy testow¹ wartoœæ
    mov byte ptr [rax], 255
    
    ; Zwróæ wskaŸnik do bufora
    leave
    ret

fail:
    xor rax, rax                  ; Zwróæ null
    leave
    ret

JuliaFractalASM ENDP
END