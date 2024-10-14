.data
    input_float_val:    .word 0x3f9e0419   # 這是 1.23456 的單精度浮點數的十六進位表示
    #input_float_val:    .word 0x7FC00000    #NaN in FP32
    output_float_val:    .word 0x00

.text
.global main
 
main: 
    la    t0, input_float_val
    la    s10, output_float_val
    lw    t1, 0(t0) 

# 1. 檢查是否為 NaN
    li    s1, 0x7fffffff      # 常數 0x7fffffff
    and    s2, s1, t1        # u.i & 0x7fffffff
    li    s3, 0x7f800000    # 常數 0x7f800000
    bgtu    s2, s3, NaN    # if (u.i & 0x7fffffff) > 0x7f800000, 跳轉到 NaN 處理
# 2. 進行操作
    srli    s1, t1, 16
    andi    s1, s1, 1
    li    s2, 0x7fff
    add    s1, s1, s2
    add    s1, s1, t1
    srli    s1, s1, 16
    sw    s1, 0(s10)
    ret
    
    
NaN:
    li    a6, 15
    srli    s4, t1, 16
    ori    s4, s4, 64
    sw    s4, 0(t0)
    ret
