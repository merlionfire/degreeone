// This code tests 2-layer nested loop with beq and bne
main:       addi  r1,   r0,   0x10
            addi  r4,   r0,   1
loop_ex:    beq   r1,   r0,   end
            addi  r2,   r0,   0x80 
            addi  r3,   r0,   0xabcd 
            lui   r3,   0x984C
loop_in:    bne   r2,   r0,   shift            
            j     in_done 
shift:      sra   r3,   r3,   1
            sub   r2,   r2,   r4
            j     loop_in
in_done:    sub   r1,   r1,   r4
            j     loop_ex
end:        srl   r4,   r4,   2
            srl   r5,   r5,   3
            srl   r1,   r1,   1
            j     main
