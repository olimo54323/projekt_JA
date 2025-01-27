.data
    four dq 4.0, 4.0, 4.0, 4.0
    two dq 2.0, 2.0, 2.0, 2.0
    scaleX dq 0.00375, 0.00375, 0.00375, 0.00375  ; 3.0 / 800
    scaleY dq 0.00333, 0.00333, 0.00333, 0.00333  ; 2.0 / 600
    centerX dq 400.0, 400.0, 400.0, 400.0
    centerY dq 300.0, 300.0, 300.0, 300.0
    x_offsets dq 0.0, 1.0, 2.0, 3.0
    one dq 1.0, 1.0, 1.0, 1.0
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
    sub rsp, 96
    
    test rcx, rcx
    jz done
    
    ; Save XMM registers we'll use
    movdqu [rsp], xmm6
    movdqu [rsp+16], xmm7
    movdqu [rsp+32], xmm8
    movdqu [rsp+48], xmm9
    movdqu [rsp+64], xmm10
    movdqu [rsp+80], xmm11
    
    ; Load constants into YMM registers
    vbroadcastsd ymm6, xmm1    ; re parameter
    vbroadcastsd ymm7, xmm2    ; im parameter
    
    mov rdx, [sizeX]           ; sizeX
    mov r8, [height]           ; height
    
    mov r10, [rbp+48]          ; startY
    mov r11, [rbp+56]          ; endY
    
    ; Validate Y range
    cmp r10, r8
    jge done
    cmp r11, r8
    jle size_ok
    mov r11, r8
size_ok:
    
process_rows:
    cmp r10, r11
    jge done
    
    xor rax, rax               ; x = 0
    
process_pixels:
    lea r14, [rax+4]           ; Look ahead 4 pixels
    cmp r14, rdx
    jg next_row
    
    ; Calculate x coordinates for 4 pixels
    vcvtsi2sd xmm3, xmm3, rax
    vbroadcastsd ymm3, xmm3
    vaddpd ymm3, ymm3, ymmword ptr [x_offsets]
    vsubpd ymm3, ymm3, ymmword ptr [centerX]
    vmulpd ymm3, ymm3, ymmword ptr [scaleX]
    
    ; Calculate y coordinate
    vcvtsi2sd xmm4, xmm4, r10
    vbroadcastsd ymm4, xmm4
    vsubpd ymm4, ymm4, ymmword ptr [centerY]
    vmulpd ymm4, ymm4, ymmword ptr [scaleY]
    
    ; Initialize iteration counters for 4 pixels
    vxorpd ymm10, ymm10, ymm10  ; Clear iteration counts
    xor r12, r12               ; iteration counter
    
    ; Save initial x, y values
    vmovapd ymm8, ymm3        ; zx = x
    vmovapd ymm9, ymm4        ; zy = y
    
iterate:
    ; Calculate z^2
    vmulpd ymm3, ymm8, ymm8   ; zx^2
    vmulpd ymm4, ymm9, ymm9   ; zy^2
    
    ; Check |z|^2 < 4
    vaddpd ymm5, ymm3, ymm4   ; |z|^2
    vcmppd ymm5, ymm5, ymmword ptr [four], 1  ; Compare < 4
    vmovmskpd r13, ymm5
    test r13, r13
    jz done_iterating
    
    cmp r12, r9               ; check iteration count
    jge done_iterating
    
    ; Add one to iteration counts for points still in set
    vandpd ymm11, ymm5, ymmword ptr [one]  ; Convert mask to 0.0 or 1.0
    vaddpd ymm10, ymm10, ymm11            ; Add to iteration counts
    
    ; z = z^2 + c
    vsubpd ymm3, ymm3, ymm4   ; zx^2 - zy^2
    vaddpd ymm3, ymm3, ymm6   ; + re
    
    vmulpd ymm4, ymm8, ymm9   ; zx * zy
    vmulpd ymm4, ymm4, ymmword ptr [two]  ; * 2
    vaddpd ymm4, ymm4, ymm7   ; + im
    
    vmovapd ymm8, ymm3        ; new zx
    vmovapd ymm9, ymm4        ; new zy
    
    inc r12
    jmp iterate
    
done_iterating:
    ; Calculate array offset
    mov r14, r10
    imul r14, rdx             ; y * sizeX
    add r14, rax
    
    ; Convert iteration counts (ymm10) to colors
    vcvtsi2sd xmm5, xmm5, r9            ; max iterations to double
    vbroadcastsd ymm5, xmm5             ; broadcast max iterations
    vbroadcastsd ymm4, iteration_scale   ; broadcast 255.0
    
    vmulpd ymm10, ymm10, ymm4           ; mno¿enie przez 255.0
    vdivpd ymm10, ymm10, ymm5           ; dzielenie przez max iteracje
    
    ; Store results
    vextractf128 xmm11, ymm10, 0   ; Extract lower 2 doubles
    vcvttsd2si r13, xmm11          ; Convert first value
    mov byte ptr [rcx+r14], r13b   ; Store first pixel
    
    vshufpd xmm11, xmm11, xmm11, 1 ; Get second value
    vcvttsd2si r13, xmm11          ; Convert second value
    mov byte ptr [rcx+r14+1], r13b ; Store second pixel
    
    vextractf128 xmm11, ymm10, 1   ; Extract upper 2 doubles
    vcvttsd2si r13, xmm11          ; Convert third value
    mov byte ptr [rcx+r14+2], r13b ; Store third pixel
    
    vshufpd xmm11, xmm11, xmm11, 1 ; Get fourth value
    vcvttsd2si r13, xmm11          ; Convert fourth value
    mov byte ptr [rcx+r14+3], r13b ; Store fourth pixel
    
    add rax, 4
    jmp process_pixels
    
next_row:
    inc r10
    jmp process_rows
    
done:
    ; Restore XMM registers
    movdqu xmm6, [rsp]
    movdqu xmm7, [rsp+16]
    movdqu xmm8, [rsp+32]
    movdqu xmm9, [rsp+48]
    movdqu xmm10, [rsp+64]
    movdqu xmm11, [rsp+80]
    
    mov rsp, rbp
    pop rbp
    ret
GenerateJuliaFractalASM endp
end