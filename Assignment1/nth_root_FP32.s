.data
    input_float_val:    .word 0x4613B514 # 9453.27
    root_val:    .word 0x00000003  # n = 3  integer
    root_result:    .word 0x00  # expect 21.14433 0x41A92787 
    epsilon:    .word 0x38D1B717 # close to 0.0001
    n_One:      .word 0xBF800000
    str1:    .string " - th root of "    # n(input_float_val)-th root of x(root_val) is value(root_result)
    str2:    .string " is "            
               

.text

_start:
    j main

getbit:
    # prologue
    srl a0, a0, a1
    andi a0, a0, 0x1
    ret


count_leading_zeros:
    # prologue
    addi sp, sp, -12
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)

    # a0 = x
    srli s0, a0, 1
    or a0, a0, s0
    srli s0, a0, 2
    or a0, a0, s0
    srli s0, a0, 4
    or a0, a0, s0
    srli s0, a0, 8
    or a0, a0, s0
    srli s0, a0, 16
    or a0, a0, s0

    srli s0, a0, 1
    li s2, 0x55555555
    and s0, s0, s2
    sub a0, a0, s0
    srli s0, a0, 2
    li s2, 0x33333333
    and s0, s2, s0
    and s1, a0, s2
    add a0, s0, s1
    srli s0, a0, 4
    add s0, s0, a0
    li s2, 0x0f0f0f0f
    and a0, s0, s2
    srli s0, a0, 8
    add a0, a0, s0
    srli s0, a0, 16
    add a0, a0, s0

    li s2, 32
    andi a0, a0, 0x7f
    sub a0, s2, a0

    # epilogue
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    addi sp, sp, 12
    ret

fabsf:
    li t2, 0x7fffffff
    and t0, a0, t2


fadd32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li t2, 0x7fffffff
    and t0, a0, t2 # t0 = cmp_a
    and t1, a1, t2 # t1 = cmp_b
    bge t0, t1, 1f
    mv t2, a0 # swap a0 = ia, a1 = ib
    mv a0, a1
    mv a1, t2
1:  
    srli t0, a0, 23
    srli t1, a1, 23
    andi t0, t0, 0xff # t0 = ea
    andi t1, t1, 0xff # t1 = eb

    li t2, 0x7fffff
    and t3, a0, t2
    and t4, a1, t2
    addi t2, t2, 1
    or t3, t3, t2 # t3 = ma
    or t4, t4, t2 # t4 = mb
    
    sub t2, t0, t1 # t2 = align
    li t5, 24
    bge t5, t2, 2f
    li t2, 24
2:
    srl t4, t4, t2 # mb >>= align
    xor t2, a0, a1
    srli t2, t2, 31
    beqz t2, 3f
    neg t4, t4
3:
    add t3, t3, t4 # t3 = result of ma
    # t1(eb) and t4(mb) are free to use
    mv t4, a0 # t4 = ia
    mv a0, t3
    jal count_leading_zeros # a0 = clz
    li t2, 8
    blt t2, a0, 4f
    sub t5, t2, a0
    srl t3, t3, t5
    add t0, t0, t5
    j 5f
4: 
    sub t5, a0, t2 # t5 = shift
    sll t3, t3, t5
    sub t0, t0, t5
5:
    li t2, 0x80000000
    and a0, t2, t4
    slli t0, t0, 23
    or a0, a0, t0
    li t2, 0x7fffff
    and t3, t3, t2
    or a0, a0, t3
    
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
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

fdiv32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)

    beqz a0, 3f
    bnez a1, 1f
    li a0, 0x7f800000
    j 3f
1:
    li t2, 0x7FFFFF
    and t0, t2, a0
    and t1, t2, a1
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    or t1, t1, t2 # t1 = mb
idiv24:
    li t3, 0 # t3 = m, r(in idiv24)
    li t4, 32 # t4 = end condition
2:
    sub t0, t0, t1
    sltz t2, t0
    seqz t2, t2
    slli t3, t3, 1
    or t3, t3, t2
    seqz t2, t2
    neg t2, t2
    and t5, t2, t1 # t5 = b & -(a < 0)
    add t0, t0, t5
    slli t0, t0, 1
    
    addi t4, t4, -1
    bnez t4, 2b 

    li t2, 0xFF800000
    and t0, a0, t2 # t0 = sea
    and t1, a1, t2 # t1 = seb
    mv a0, t3
    li a1, 31
    jal getbit
    seqz a0, a0 # a0 = mshift
    sll t3, t3, a0 # t3 = m

    li t2, 0x3f800000
    sub t4, t0, t1
    add t4, t4, t2 # t4 = sea - seb + 0x3f800000
    neg a0, a0
    li t2, 0x800000
    and a0, a0, t2 # a0 = 0x800000 & -mshift
    srli t3, t3, 8
    addi t2, t2, -1
    and t3, t3, t2 # t3 = m
    sub a0, t4, a0
    or a0, a0, t3

    # check overflow
    xor t3, t1, t0
    xor t3, t3, a0
    srli t3, t3, 31

    li t2, 0x7f800000
    xor t4, t2, a0
    and t4, t4, t3
    xor a0, a0, t4
3:
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
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

i2f32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)

    beqz a0, 4f

    li t0, 0x80000000
    and t0, t0, a0 # t0 = s
    beqz t0, 1f
    neg a0, a0
1: 
    mv t1, a0 # t1 = x
    jal count_leading_zeros
    mv t2, a0 # t2 = clz
    li t3, 31
    sub t3, t3, t2
    addi t3, t3, 127 # t3 = e
    slli t3, t3, 23 # e << 23
    or a0, t0, t3 # s | e << 23

    li t4, 8
    blt t2, t4, 2f # if clz < 8, then 2f
    sub t4, t2, t4
    sll t1, t1, t4
    li t4, 0x7fffff
    and t1, t1, t4 # x & 0x7fffff
    or a0, a0, t1
    j 4f
2: 
    sub t4, t4, t2
    srl t1, t1, t4
    li t4, 0x7fffff
    and t1, t1, t4
    or a0, a0, t1
    j 4f

4:
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
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

fcomparison:
    li t2, 0x7F800000
    and t0, a0, t2 # t0, t1 is ea
    and t1, s3, t2 # s3 is epsilon
    li t2, 0x7FFFFF
    and t3, a0, t2 
    and t4, s3, t2

    li t5, 0x800000        # 0x800000 掩碼 (隱含的1)
    or t3, t3, t5          # t3 = ma = (ia & 0x7FFFFF) | 0x800000
    or t4, t4, t5          # t4 = mb = (ib & 0x7FFFFF) | 0x800000

    # 比較指數 ea 和 eb
    bgt t0, t1, return_one # 如果 ea > eb，返回 1
    blt t0, t1, return_zero # 如果 ea < eb，返回 0

    # 指數相等時，比較尾數 ma 和 mb
    bgt t3, t4, return_one # 如果 ma > mb，返回 1
    j return_zero          # 否則返回 0

return_one:
    li a0, 1               # 設置返回值為 1
    ret                    # 返回

return_zero:
    li a0, 0               # 設置返回值為 0
    ret                    # 返回


nth_root:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, input_float_val
    lw s0, 0(t0) # s0 is input_float_val
    la t1,  root_val
    lw s1, 0(t1) # s1 is root_val
    mv a0, s1 # int move to a0
    jal i2f32 # a0 convert to FP32
    mv s2, a0 # s2 is root_val_f
    la t0, epsilon
    lw s3, 0(t0) # s3 is epsilon
    li s4, 0 # s4 is result of the root
    mv a0, s0
    mv a1, s2
    jal fdiv32 # initial guess
    mv s4, a0 # put 1st guess into s4
    li s11, 0xBF800000

check_condition:
    mv a1, s2
    # mv s10, s4 # the number to check store in s10
    jal my_power
    li t1, 0x80000000
    mv a0, s10
    or a1, s0, t1 # x to -x, x is always positive
    jal fadd32 # result store in a0
    jal fabsf # result store in a0
    jal fcomparison  # a0 = 0 or 1

    beqz a0,  while_end
    j loop_while


    
loop_while:
    mv a0, s2
    mv a1, s11
    jal fadd32 # result store in a0
    mv a3, a0 # copy fadd32(f_n, n_One) result in a3
    mv a1, s4
    jal fmul32 # result store in a0
    mv s9, a0 # s9 is fmul32(fadd32(f_n, n_One), guess)

    mv a1, a3
    jal my_power # my_power(guess, fadd32(f_n, n_One)), result in s10
    mv a0, s0
    mv a1, s10
    jal fdiv32 # result in a0
    mv a1, s9
    jal fadd32 # result in a0
    mv a1, s2
    jal fdiv32 # result in a0
    
    mv s10, a0
    beq s4, s10, while_end
    mv s4, s10
    j check_condition
    

while_end:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print:
    mv t0, s2
    mv t1, s0
    mv t2, s4

    #  n-th root of
    mv a0, t0
    li a7 2
    ecall
    la a0, str1          # 加載字串地址
    li a7, 4             # 系統調用號 4 (write string)
    ecall
    mv a0, t1
    li a7, 2
    ecall
    la a0, str2
    li a7, 4
    ecall
    mv a0, t2
    li a7, 2
    ecall
    ret



main:
    jal nth_root
    li s5, 1
    li s5, 1
    jal print
    li s5, 1
    li s5, 1

