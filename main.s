    .include "constants.s"

    .section .data
    .include "data.s"

    .section .text
    .type main, %function
    .global main
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x0, STDOUT
    ldr x1, =output_text
    mov x2,  #len
    mov x8, SYS_WRITE
    svc #0

    mov x0, xzr
    ldp x29, x30, [sp], #16

    ret

    .size main, (. - main)


