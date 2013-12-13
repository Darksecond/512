; Forth in 512 bytes.
; This code is designed to be placed as the bootsector (MBR) of a disk. It does not need any other kind of operating system running.
; It runs in real mode and is fully 16-bit.
; Because it needs to fit in 512 bytes, not all standard FORTH words might be available.
; 
; Overview of memory layout
; -------------------------
;
; FORTH requires a number of memory sections to exist, which include:
; Parameter stack,
; Return stack,
; PAD,
; Text Input Buffer,
; HEAP
; Code
; 
; Memory is laid out as follows:
; 
; |-----|---------|------------|------|----------|------------|
; | TIB | PAD --> | <-- RSTACK | CODE | HEAP --> | <-- PSTACK |
; |-----|---------|------------|------|----------|------------|
; 
; TIB needs to be a mininum of 80 characters, it will start right after the BIOS, starting at 0x500.
; PAD starts right after the TIB and grows upwards.
; RSTACK starts from 0x7C00 downwards.
; CODE start from 0x7C00 upwards, for 512 bytes.
; HEAP starts after the code upwards
; PSTACK starts from 0x0000 downwards
; 
; Register allocations
; --------------------
;
; AX General purpose
; BX General purpose
; CX General purpose
; DX General purpose
; SI Forth instruction Pointer
; DI Pointer to current CFA of word currently being executed
; SP Parameter stack pointer
; BP Return stack pointer
; Segments are all set to zero by default.

; Jump to Start to set CS.
ORG 0x7C00
jmp 0x0:Start

; Initialization of segments and registers.
; Afterwards we jump straight into FORTH.
Start:
; Initialize segments
cli
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
sti
; Initialize parameter and return stack
mov sp, 0x0000
mov bp, 0x7C00

; This is here temporarily.
; We should, and will, move this to it's own word.
.halt:
hlt
jmp .halt

; This is required to fill up the file to 512 bytes.
; The last two bytes are an identifier to mark the disk as bootable.
times 510-($-$$) db 0
db 0x55
db 0xAA
