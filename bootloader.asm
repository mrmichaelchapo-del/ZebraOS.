; ZEBRA BOOTLOADER v2 🦓 - bugs fixed edition
; 16-bit real mode, loads ZEBRA.FNT + KERNEL, jumps to kernel
; nasm -f bin bootloader.asm -o boot.bin
; must be exactly 512 bytes, ends with 0xAA55

bits 16
org 0x7C00

FONT_SEG   equ 0x1000      ; font loads at 0x1000:0000 (linear 0x10000)
FONT_SECT  equ 2           ; font starts at sector 2
FONT_COUNT equ 2           ; 2 sectors = 1024 bytes, covers 772 byte font

KERNEL_SEG   equ 0x2000    ; kernel at 0x2000:0000 (linear 0x20000) - FIXED, no overlap!
KERNEL_SECT  equ 4         ; kernel starts at sector 4 (after 2 font sectors)
KERNEL_COUNT equ 8         ; 8 sectors = 4KB, plenty for kernel start

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl   ; SAVE the BIOS drive number, dl gets clobbered otherwise

    mov si, msg_boot
    call print

    ; --- load ZEBRA.FNT ---
    mov ax, FONT_SEG
    mov es, ax
    xor bx, bx             ; es:bx = 0x1000:0000
    mov ah, 0x02
    mov al, FONT_COUNT
    mov ch, 0
    mov cl, FONT_SECT
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    mov si, msg_font
    call print

    ; --- load KERNEL ---
    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx             ; es:bx = 0x2000:0000
    mov ah, 0x02
    mov al, KERNEL_COUNT
    mov ch, 0
    mov cl, KERNEL_SECT
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    mov si, msg_kernel
    call print

    ; --- hand off to kernel, tell it where the font is ---
    mov ax, FONT_SEG
    mov [boot_info_font], ax   ; boot info struct at 0x0500 for now

    jmp KERNEL_SEG:0x0000      ; FIXED: jumps to 0x2000:0000, font is safe at 0x1000

disk_error:
    mov si, msg_err
    call print
    jmp $

print:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

; --- data ---
boot_drive    db 0
boot_info_font dw 0
msg_boot   db "ZebraOS booting...", 13, 10, 0
msg_font   db "ZEBRA.FNT loaded!", 13, 10, 0
msg_kernel db "Kernel loaded, handing off...", 13, 10, 0
msg_err    db "DISK ERROR. no zebra today.", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55