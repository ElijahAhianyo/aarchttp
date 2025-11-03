    /*
    Block has the structure:
    Block{
        size_t size -> 8bytes
        Block *next -> 8
        Block *prev -> 8
        int free -> 4 bytes
        padding -> 4bytes
        ptr -> 8bytes
        char data[1]
    }

    */
    .include "constants.s"

    .section .data
    .include "data.s"

    .section .text
    .p2align 4
    .type malloc, %function
    .global malloc
malloc:
.Lfunc_main_begin:
.cfi_startproc:
stp x29, x30 [sp #-16]!
.cfi_def_cfa_offset 16
.cfi_offset 29, -16
.cfi_offset 30, -8




    .section .text
    .p2align 4
    .type find_block, %function
find_block:
    .Lfunc_find_block_begin:
    .cfi_startproc:
    // x0-> last block
    // x1-> size we want
    mox x3, xzr
    adrp x3, base;
    add x3, x3, :lo12:base
while:
    cbz x3, end_while
    mov x4, [x3, #24] // get the free block
    cbz x4, end_while
    mov x0, x3
    mov x3, [x3, #8] // get the next block
    b while


end_while:
    mov x0, x3
    ret 
    .Lfunc_find_block_end
    .cfi_endproc

    .section text
    .type extend_heap, %function
    .global extend_heap
extend_heap:
    .Lfunc_extend_heap_begin
    .cfi_startproc
    stp x29, x30 [sp, #-32]!
    .cfi_def_cfa_offset 32
    .cfi_offset 29, -32
    .cfi_offset 30, -24
    mov x29, sp
    str x19, [sp, #16]
    .cfi_offset 19, -16
    // x0 -> last block
    // x1 -> size to extend by

    mov x2, x0 //last block
    mov x3, x1 // size

    //get the heap end/break
    mov x0, #0
    bl sbrk
    mov x19, x0

    mov x0, x3
    add x0, x0, BLOCK_SIZE
    bl sbrk
    
    cmp x0, #-1
    beq error

    str x3, [x19]
    str x2, [x19, #16]
    str #1, [x19, #24]
    add x4, x19, BLOCK_SIZE
    str x4, [x19, #32] 

    // if the last node is not null, we update its 
    // next node
    cmp x2, xzr
    beq done
    str x19, [x2, #8]

done:
    mov x0, x19
    b epilogue

error:
    mov x0, NULL
    b epilogue


epilogue:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #16
    .cfi_restore 19
    .cfi_restore 29
    .cfi_restore 30
    ret
    .cfi_endproc
    .Lfunc_extend_heap_end



    .section .text
    .p2align 4
    .type split_block, %function
split_block:
    .Lfunc_split_block_begin
    .cfi_startproc
    // x0 -> block
    // x1 -> size

    /*
    create a new block whose size is old_block->size - size - BLOCK_SIZE
    then link the old block to it
    */

    // mov x2, x0 // block
    mov x2, x1 // size

    sub x2, [x0], x2 //new size
    // new block
    //TODO: check this logic 
    add x3, x0, x2 
    add x3, x3, BLOCK_SIZE

    // fill in the details of the new block
    str x2, [x3] // size (should we move an extra byte here?)
    str #1, [x3, #24]
    // newblock->next should point to block->next
    ldr x4, [x0, #8]
    str x4, [x3, #8]

    // new_block->prev = block
    str x0, [x3, #16] 

    // new_block->ptr = new_block->data
    add x5, x0, BLOCK_SIZE
    str x5, [x3, #32]

    str x2, [x0]
    str x3, [x0, #8]

    //if the new_block has a next node, we should update that.
    ldr x4, [x3, #8]
    cmp x4, xzr
    beq split_block_done

update_new_block_next:
    ldr x4, [x4]
    str x3, [x4, #16]
    b split_block_done

split_block_done:
    mov x0, xzr

    ret
    .cfi_endproc
    .Lfunc_split_block_end

    //To validate an address or a pointer, it must meet the ff conditions:
    // 1. It should be within the acceptable heap range. i.e higher than the base and 
    // lower than sbrk(0).
    // 2. The pointer should be the same as its ptr/data member.

    .section .text
    .p2align 4
    .type valid_addr, %function
valid_addr:
    .Lfunc_valid_addr_begin
    .cfi_startproc
    //x0->block
    stp x29, x30, [sp, #-16]!
    .cfi_def_cfa_offset 16
    .cfi_offset 29, -16
    .cfi_offset 30, -16
    mov x29, sp

    mov x1, xzr
    adrp x1, base
    add x1, x1, :lo12:base

    mov x2, x0 // block

    cmp x2, xzr
    beq valid_addr_zero

    cmp x2, x1
    blt valid_addr_zero

    bl sbrk

    cmp x2, x0 
    bgt valid_addr_zero

    // very skeptical about this(get_block).
    sub x3, x2, BLOCK_SIZE
    cmp x2, [x3, #32]

    bne valid_addr_zero

    mov x1, #1
    b done

valid_addr_zero:
    mov x0, #0


done:
    ldp x29, x30, [sp], #16
    .cfi_restore 29
    .cfi_restore 30
    .cfi_def_cfa_offset 0
    ret
    .cfi_endproc
    .Lfunc_valid_addr_end


    .section .text 
    .p2align 4
    .type copy_block, %function
copy_block:
    .Lfunc_copy_block_begin
    .cfi_startproc
    // xo -> destination
    // x1-> src

    // get the data/ptr start
    add x2, x0, #32 // dst
    add x3, x1, #32 // src

    //obtain sizes
    ldr x4, [x2]
    ldr x5, [x3]
    lsr x4, x4, #8
    lsr x5, x5, #8

    cmp x4, x5
    csel x4, x4, x5, lt

    mov x5, #0
loop:
    cmp x4, x5
    beq copy_block_done
    ldr x6, [x3, x5]
    str x6, [x2, x5]
    incr x5
    b loop

copy_block_done:
    mov x0, xzr
    ret
    .cfi_endproc
    .Lfunc_copy_block_end
    


    .section .text
    .p2align 4
    .type coallesce, %function
coallesce:
    .Lfunc_coallesce_begin
    .cfi_startproc

    // x0 -> block
    ldr x1, [x0, #8] // block->next(next block)
    cmp x1, xzr
    beq return_block
    ldr x2, [x1, #24]
    cmp x2, #1
    bne return_block
    mov x3, #0
    add x3, [x0], BLOCK_SIZE
    add x3, [x1], x3
    str x3, [x0]

    //block->next = block->next->next
    ldr x4, [x1, #8] // block->next->next
    str x4, [x1, #8]

    // if the new block->next, we should update its prev too
    cmp x1, xzr
    beq return_block
    str x0, [x1, #16]

return_block:
    ret 
    .cfi_endproc
    .Lfunc_coallesce_end


    .section .text
    .p2align 4
    .type malloc, %function
    .global malloc
malloc
    .cfi_startproc
    .Lfunc_malloc_begin
    



    




    

