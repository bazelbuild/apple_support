.globl _main
_main:
#if defined(__arm64__) || defined(__aarch64__)
    mov w0, #0
#else
    xorl %eax, %eax
#endif
    ret
