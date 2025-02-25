#Compressed Instructions
#ADDI, SW, LW, LI, LUI, ADDI4SPN, ADDI16SP, SRLI, SRAI, SLLI, ANDI 

#ADDI pt1
c.addi x8, 1 #0p
c.nop
c.nop
c.addi x9, -1 #0n

#SW
sw x8, 0(x15)
c.nop
c.nop
sw x9, 4(x15)

#ADDI pt2
c.addi x8, 20 #pp
c.nop
c.nop
c.addi x9, -20 #nn
sw x8, 8(x15)
c.nop
c.nop
sw x9, 12(x15)
c.addi, x8, -12 #pn
c.nop
c.nop
c.addi x9, 12 #np
sw x8, 16(x15)
c.nop
c.nop
sw x9, 20(x15)

#LW
c.lw x11, 0(x15)
c.lw x12, 1(x15)
c.lw x13, 2(x15)
c.lw x14, 3(x15)
c.sw x11, 6(x15)
c.sw x12, 7(x15)
c.sw x13, 8(x15)
c.sw x14, 9(x15)

#LI
c.li x11, 31
c.li x12, 0
c.li x13, 1
c.li x14, -1
c.sw x11, 10(x15)
c.sw x12, 11(x15)
c.sw x13, 12(x15)
c.sw x14, 13(x15)

#LUI
c.lui x11, 2
c.lui x12, 1
c.lui x13, -5
c.nop
sw x11, 56(x15)
sw x12, 60(x15)
sw x13, 64(x15)

#ADDI4SPN
c.addi4spn x8, 1
c.addi4spn x9, 25
c.nop
c.nop
sw x8, 68(x15)
sw x9, 72(x15)

#ADDI16SP
c.addi16sp 1
c.nop
c.nop
c.nop
sw x2, 76(x15)
c.nop
c.nop
c.nop
c.addi16sp -1
c.nop
c.nop
c.nop
sw x2, 80(x15)

#SRLI
c.li x8, 8
c.li x9, -16
c.li x10, 0
c.nop
c.srli x8, 3  #pos
c.srli x9, 4  #neg
c.srli x10, 5 #zero
c.nop
c.nop
sw x8, 84(x15)
sw x9, 88(x15)
sw x10, 92(x15)

#SRAI
c.nop
c.li x8, 8
c.li x9, -16
c.nop
c.srai x8, 4  #pos
c.srai x9, 5  #neg
c.srai x10, 3 #zero
c.nop
sw x8, 96(x15)
sw x9, 100(x15)
sw x10, 104(x15)

#SLLI
c.li x1, 16
c.li x2, -5
c.li x3, 0
c.nop
c.nop
c.slli x1, 4 #shift positive
c.slli x2, 4 #shift negative
c.slli x3, 8 #shift zero
c.nop
sw x1, 108(x15)
sw x2, 112(x15)
sw x3, 116(x15)

#ANDI
c.nop
c.li x8, 21
c.li x9, 14
c.li x10, 7
c.nop
c.andi x8, 63
c.andi x9, 0
c.andi x10, -1
c.nop
sw x8, 120(x15)
sw x9, 124(x15)
sw x10, 128(x15)
c.nop