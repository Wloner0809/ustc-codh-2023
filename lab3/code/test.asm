.data

data1: .word 0x00000023
data2: .word 0x00000210
data3: .word 0x00000233
data4: .word 0xffff00ff
data6: .word 0x00002100
data7: .word 0xfffff00f
data8: .word 0x00023000
data9: .word 0x0000118c
data5: .word 0x00002100

str:   .string "the test is successful !"

.text

.macro fail
li a7, 10
ecall
.end_macro

beq x0, x0, next1               #测试beq

fail

next1:
    lw  t1, 0x00002500          #测试lw，让0x00002500中的值为0
    beq t1, x0, next2
    fail

next2:
    lw  t1, data1               #测试add
    lw  t2, data2
    lw  t3, data3
    add t2, t2, t1
    beq t2, t3, next3
    fail

next3:
    lw  t1, data2               #测试addi
    addi t1, t1, 0x23
    beq t1, t3, next4
    fail

next4:
    sub t1, t1, t3              #测试sub
    beq t1, x0, next5
    fail

next5:
    lw  t1, data4               #测试blt
    lw  t2, data1
    blt t1, t2, next6
    fail

next6:
    lw  t1, data1               #测试bltu
    lw  t2, data4
    bltu t1, t2, next7
    fail

next7:
    lw  t1, data1               #测试and
    lw  t2, data2
    mv  t3, x0
    and t1, t1, t2
    beq t1, t3, next8
    fail

next8:
    lw  t1, data2               #测试or
    lw  t2, data3
    or  t1, t1, t2
    beq t1, t2, next9
    fail

next9:
    lw  t1, data1               #测试xor
    lw  t2, data2
    lw  t3, data3
    xor t2, t2, t3
    beq t2, t1, next10
    fail

next10:
    lw  t1, data2               #测试slli
    lw  t2, data6
    slli t1, t1, 4
    beq t1, t2, next11
    fail

next11:
    lw  t1, data3               #测试srli
    lw  t2, data1
    srli t1, t1, 4
    beq t1, t2, next12
    fail

next12:
    lw  t1, data4               #测试srai
    lw  t2, data7
    srai t1, t1, 4
    beq t1, t2, next13
    fail

next13:
    lw  t1, data8               #测试lui
    lui t2, 0x00023
    beq t1, t2, next14
    fail

next14:
    auipc t1, 0x00001           #测试auipc
    lw  t2, data9
    beq t1, t2, next15
    fail

next15:
    lw t1, 0x00002020           #测试sw
    lw t2, data3
    sw t2, 0(t1)
    lw t3, 0(t1)
    beq t2, t3, next16
    fail

next16:
    addi ra, x0, 0              #测试jal
    jal ra, next17
    fail

next17:
    addi  t1, ra, 0x18          #测试jalr
    jalr ra, 0(t1)
    fail
    la  a0, str
    li, a7, 4
    ecall

