.data
    four dq 4.0
    two dq 2.0
    scaleX dq 0.00375  ; 3.0 / 800
    scaleY dq 0.00333  ; 2.0 / 600
    centerX dq 400.0   ; sizeX/2
    centerY dq 300.0   ; height/2
    sizeX dq 800
    height dq 600
    iteration_scale dq 255.0

.code
GenerateJuliaFractalASM proc
    ; rcx - result array
    ; xmm1 - re
    ; xmm2 - im
    ; r9 - iterations
    ; [rsp+40] - startY
    ; [rsp+48] - endY
    
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; SprawdŸ poprawnoœæ wskaŸnika na tablicê wynikow¹
    test rcx, rcx
    jz done
    
    ; Zachowaj rejestry XMM
    movdqu [rsp], xmm6
    movdqu [rsp+16], xmm7
    movdqu [rsp+32], xmm8
    
    ; Broadcast sta³ych do rejestrów YMM
    vbroadcastsd ymm6, four
    vbroadcastsd ymm7, two
    vbroadcastsd ymm8, xmm1
    vbroadcastsd ymm9, xmm2  
    
    ; Pobierz szerokoœæ i wysokoœæ
    mov rdx, [sizeX]           ; sizeX
    mov r8, [height]           ; height
    
    ; Pobierz zakres Y ze stosu
    mov r10, [rbp+48]    ; startY (pi¹ty parametr)
    mov r11, [rbp+56]    ; endY (szósty parametr)
    
    ; SprawdŸ poprawnoœæ zakresu Y
    cmp r10, r8          ; startY < height?
    jge done
    cmp r11, r8          ; endY <= height?
    jg done
    
process_rows:
    cmp r10, r11
    jge done
    
    xor rax, rax         ; x = 0
    
process_pixels:
    cmp rax, rdx         ; x < sizeX?
    jge next_row
    
    ; Oblicz wspó³rzêdne w przestrzeni zespolonej
    vcvtsi2sd xmm2, xmm2, rax  ; x
    vsubsd xmm2, xmm2, centerX
    vmulsd xmm2, xmm2, scaleX  ; zx
    
    vcvtsi2sd xmm3, xmm3, r10  ; y
    vsubsd xmm3, xmm3, centerY
    vmulsd xmm3, xmm3, scaleY  ; zy
    
    xor r12, r12               ; i = 0
    
iterate:
    vmulsd xmm4, xmm2, xmm2    ; zx^2
    vmulsd xmm5, xmm3, xmm3    ; zy^2
    vaddsd xmm5, xmm4, xmm5    ; |z|^2
    
    vucomisd xmm5, four
    jae done_iterating
    
    cmp r12, r9
    jge done_iterating
    
    ; Nowe z = z^2 + c
    vmulsd xmm4, xmm2, xmm2    ; zx^2
    vmulsd xmm5, xmm3, xmm3    ; zy^2
    vsubsd xmm4, xmm4, xmm5    ; zx^2 - zy^2
    vaddsd xmm4, xmm4, xmm8    ; + re
    
    vmulsd xmm5, xmm2, xmm3    ; zx * zy
    vmulsd xmm5, xmm5, two     ; 2 * zx * zy
    vaddsd xmm5, xmm5, xmm9    ; + im
    
    movsd xmm2, xmm4           ; nowe zx
    movsd xmm3, xmm5           ; nowe zy
    
    inc r12
    jmp iterate
    
done_iterating:
    ; Oblicz kolor
    vcvtsi2sd xmm4, xmm4, r12
    vmulsd xmm4, xmm4, iteration_scale
    vcvtsi2sd xmm5, xmm5, r9
    vdivsd xmm4, xmm4, xmm5
    vcvttsd2si r13, xmm4
    
    ; Oblicz offset w tablicy wynikowej i sprawdŸ granice
    mov r14, r10
    imul r14, rdx              ; y * sizeX
    add r14, rax               ; + x
    
    ; SprawdŸ czy offset jest w granicach tablicy
    mov r15, rdx
    imul r15, r8               ; total size = sizeX * height
    cmp r14, r15
    jae pixel_done
    
    ; Zapisz wynik
    mov byte ptr [rcx+r14], r13b
    
pixel_done:
    inc rax
    jmp process_pixels
    
next_row:
    inc r10
    jmp process_rows
    
done:
    ; Przywróæ rejestry XMM
    movdqu xmm6, [rsp]
    movdqu xmm7, [rsp+16]
    movdqu xmm8, [rsp+32]
    
    mov rsp, rbp
    pop rbp
    ret
GenerateJuliaFractalASM endp
end