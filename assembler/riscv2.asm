    .text            # Code section
    .globl _start
_start:
    # Base address for the buffer
    li t0, 0x10010004       # Load base address into t0

    # Initialize memory within the 4KB range
    li t1, 0x12               # Load immediate byte value
    sb t1, 0(t0)              # Store byte to address 0x00000100

    li t1, 0x3456             # Load immediate halfword value
    sh t1, 2(t0)              # Store halfword to address 0x00000102

    li t1, 0x789ABCDE         # Load immediate word value
    sw t1, 4(t0)              # Store word to address 0x00000104

    # Load data back for verification
    lb t2, 0(t0)              # Load byte from address 0x00000100
    lh t3, 2(t0)              # Load halfword from address 0x00000102
    lw t4, 4(t0)              # Load word from address 0x00000104
    sub a0, t4, t3

    # Exit
    li a7, 10                 # syscall for exit
    ecall
