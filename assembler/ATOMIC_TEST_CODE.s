# Load Addresses
addi 5, 0, 0
addi 6, 0, 4
addi 7, 0, 8
addi 28, 0, 12
addi 29, 0, 16


# Load immediate values for tests
lui 30, -283732
addi 30, 30, -1350
lui 31, -349525
addi 31, 31, -1366
addi 10, 0, 1
lui 11, 61681
addi 11, 11, -241
lui 12, 1
addi 12, 12, -1


# AMOSWAP.W:
amoswap.w 12, 5, 30

# AMOXOR.W:
amoxor.w 13, 6, 31

# AMOADD.W
amoadd.w 14, 7, 10


# AMOOR.W
amoor.w 15, 28, 11


# AMOAND.W
amoand.w 16, 29, 12


nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
