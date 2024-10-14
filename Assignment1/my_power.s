.data
      input_float_val:    .word 0x40B00000 # x = 5.5
      root_val:    .word 0x40400000 # n = 3
      root_result:    .word 0x00 # 166.375 0x43266000
.text
_start:
      j main
getbit:
    # prologue
    srl a0, a0, a1
    andi a0, a0, 0x1
    ret

fmul32:
    # prologue
    addi sp, sp, -12
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t2, 8(sp)
    
    seqz t0, a0
    seqz t1, a1
    or t0, t0, t1
    beqz t0, 2f
    li a0, 0
    j 3f

2:  li t2, 0x7FFFFF
    and t0, a0, t2
    and t1, a1, t2
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    or t1, t1, t2 # t1 = mb
imul24:
    li t3, 0 # t3 = m, r(in imul24)
1:  
    andi t4, t1, 0x1
    neg t4, t4
    and t4, t0, t4
    srli t3, t3, 1
    add t3, t3, t4
    srli t1, t1, 1
    bnez t1, 1b

    mv t0, a0 # t0 = a
    mv t1, a1 # t1 = b
    mv a0, t3
    li a1, 24
    jal getbit # a0 = mshift

# m(t3) value computed
    srl t3, t3, a0

    li t2, 0xFF800000
    and t0, t0, t2 # t0 = sea
    and t1, t1, t2 # t1 = seb

    li t2, 0x3f800000
    sub t4, t0, t2
    add t4, t4, t1
    li t2, 0xFF800000
    and t4, t4, t2 # t4 = ((sea - 0x3f800000 + seb) & 0xFF800000)
    
    li t2, 0x7fffff
    slli a0, a0, 23
    or a0, a0, t2
    and a0, a0, t3
    add a0, a0, t4 # a0 = r(in fmul32)

    # check overflow
    xor t3, t0, t1
    xor t3, t3, a0
    srli t3, t3, 31 # t3 = ovfl

    li t2, 0x7f800000
    xor t4, t2, a0
    and t4, t4, t3
    xor a0, a0, t4

3:  # epilogue
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 12
    ret
    
f2i32:
    li t2, 0x7FFFFF
    and t0, t2, a4
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    srli t1, a4, 23
    andi t1, t1, 0xff
    addi t1, t1, -127 # t1 = ea
    li t2, 23
    bge t2, t1, 1f # if t2 >= t1 then 1f
    bgez t1 2f
    li a4, 0
    ret
    
1: # ea <= 23
    neg t1, t1
    addi t1, t1, 23
    srl a4, t0, t1
    ret

2: # ea >= 0
    addi t1, t1, -23
    sll a4, t0, t1
    ret
 
my_power:
    # 保存返回地址
    addi sp, sp, -4         # 為暫存器和返回地址分配空間
    sw ra, 0(sp)            # 保存 ra 到堆棧

    # 參數寄存器 a0 = guess, a1 = n
    # 將 n 轉換為整數，n 在寄存器 a1 中
    # 將浮點數 n 強制轉換為整數 x = (int)n
    mv a4, a1                # 將 x 存入 t0，t0 現在是 n 的整數形式
    jal f2i32
    mv t0, a4

    # 初始化 temp = 1
    li t1, 0x3F800000      

    # 設置迴圈計數器 i = 0
    li t2, 0                 # 將 i 初始化為 0

loop_start:
    # 比較 i < x
    bge t2, t0, loop_end     # 如果 i >= x，則跳轉到 loop_end

    # temp = fmul32(temp, guess)
    mv a0, t1                # 將 temp 加載到 a0
    mv a1, s4                # 將 guess 加載到 a1
    jal ra, fmul32           # 調用 fmul32(temp, guess)，結果存放在 a0 中
    mv t1, a0                # 將結果存入 t1（temp）

    # i++
    addi t2, t2, 1           # 將 i 加 1
    j loop_start             # 跳回 loop_start

loop_end:
    # 返回 temp 結果
    mv s10, t1                # 將 temp 的值存入 s0 作為返回值

    # 恢復 ra 並返回
    lw ra, 0(sp)            # 恢復 ra 寄存器
    addi sp, sp, 4          # 恢復堆棧指針
    ret                    # 返回


main:
      la t0, input_float_val
      la t1, root_val
      lw s4, 0(t0)
      lw a1, 0(t1)

      jal my_power
      la t0, root_result
      sw s10, 0(t0)