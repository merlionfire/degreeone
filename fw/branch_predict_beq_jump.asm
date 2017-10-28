main:    addi  r1,   r0,   0xf
         addi  r2,   r0,   1 
         addi  r3,   r0,   3
loop:    beq   r1,   r0,   end
         sub   r4,   r1,   r2
         sub   r1,   r1,   r2
         sub   r5,   r4,   r3
         lui   r4,   7
         j     loop
end:     srl   r4,   r4,   2
         srl   r5,   r5,   3
         srl   r1,   r1,   1

