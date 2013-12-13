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
;
; WORD memory layout
; 
; Link - 2 bytes
; Flags + Length - 1 byte
; Name - Length bytes
; Codeword - 2 bytes
; Parameter list - Unknown bytes

;TODO Macro's (pushr, popr, colon, variable, constant)
; Various macro's
; 
; Various variables required by macro's.
; Link, this is the 'top' of the linked list of WORDs.
%define link 0

; Immediate flag, FORTH will execute an immediate WORD even when in compiling mode.
%define immediate 0x80

; Head macro, this creates the header of a WORD. It is fairly complex because of the linked-list.
; This macro will re-set the link macro-variable to point to this word.
; This macro will also create a label pointing to the codeword.
; The label starts with xt_
; head <name>, <label>, <flags>, <codeword>
%macro head 4
; Local label called %%link, which has the value of 'link'.
%%link dw link
; Redefine 'link' to point to local %%link
%define link %%link
; Put the length of the name into %%count
%strlen %%count %1
; write out length byte, add in any flags.
db %3 + %%count, %1
; xt_<name> label pointing towards the codeword
xt_ %+ %2 dw %4
%endmacro

; Primitive macro
; primitive <name>, <label>, <flags>=0
%macro primitive 2-3 0
; Call head, %3 will be 0 if not supplied. $+2 is the next statement, meaning it's the start of the actual code.
head %1,%2,%3,$+2
%endmacro

; Next macro
; This is part of the FORTH system. It will go to the next forth word in a chain.
%macro next 0
; read whatever SI points to into AX, and increase SI by 2
lodsw
; We need it in DI, as specified, also we can't jmp indirectly to AX.
xchg di, ax
jmp word [di]
%endmacro

; Jump to Start to set CS.
ORG 0x7C00
jmp 0x0:Start

;TODO Put this into the 'ABORT' word.
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
; 
; Start of the forth system.
; Temporarily we start with the 'halt' word.
push 'C'
push 'B'
push 'A'

; Start in cold start
mov si, cold_start
next

; Cold start 'word'
;TODO we might wanna refactor this a bit
cold_start:
dw xt_emit
dw xt_emit
dw xt_emit
dw xt_halt

; This is here temporarily.
; HALT word, will halt the system.
primitive 'HALT',halt
.halt:
hlt
jmp .halt

; EMIT primitive
; EMIT - ( char -- ) display a character on the screen.
primitive 'EMIT',emit
pop ax
mov ah, 0x0E ;Write Character in TTY Mode
int 0x10 ;Video Services
next

; This is required to fill up the file to 512 bytes.
; The last two bytes are an identifier to mark the disk as bootable.
times 510-($-$$) db 0
db 0x55
db 0xAA
