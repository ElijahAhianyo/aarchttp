    .section .text
    .p2align 4
    .type sbrk, %function
    .global sbrk
    
sbrk:
    .Lfunc_sbrk_begin
    .cfi_startproc
    stp x29, x30, [sp, #-16]!
    .cfi_def_cfa_offset 16
    .cfi_offset 29, -16
    .cfi_offset 30, -8
    mov x29, sp
    //x0-> size to incr

    mov x1, x0

    // get the current break
    mov x0, #0
    mov x8, SYS_BRK
    svc #0

    mov x2, x0
validate_size:
    cmp x1, xzr
    beq success
    blt error

    // compute new break
    mov x3, x2
    add x3, x3, x1
    
    //set the new brk
    mov x0, x3
    mov x8, SYS_BRK
    svc #0

    cmp x0, x2 
    // if the old break == new break, something went wrong.
    b error

success:
    // return the current brk
    mov x0, x2
    b done

error:
    mov x0, #-1

done:
    
    ldp x29, x30, [sp], #16
    .cfi_restore 29
    .cfi_restore 30
    .cfi_def_cfa_offset 0
    ret
    .size sbrk, (. - sbrk)
    .cfi_endproc
    .Lfunc_sbrk_end

