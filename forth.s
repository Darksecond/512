ORG 0x7C00

jmp 0x0:start

; push onto return stack
%macro pushr 1
	xchg sp, bp
	push %1
	xchg sp, bp
%endmacro

; pop from return stack
%macro popr 1
	xchg sp, bp
	pop %1
	xchg sp, bp
%endmacro

; lodsw loads SI into AX and increases SI
%macro NEXT 0
	lodsw
	jmp [eax] ;using EAX here, because 'jmp [ax]' is not valid.
%endmacro

; inner interpreter
; ax contains codeword because of previous NEXT
DOCOL:
pushr si   ; save current si on return stack
add ax, 4  ; ax points to codeword
mov si, ax ; make si point to first data word
NEXT

start:
cli
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
sti
; early set up is done, work starts here

; parameter stack starts at 0x7C00
; return stack starts at 0x0000 (rolls over to top of segment)
mov sp, 0x7C00
mov bp, 0x0000

mov si, cold_start
NEXT

cold_start:
	dw TEST ;TODO replace with 'QUIT'

;TEST forth 'word'
;hangs as part of it, so it's really really 'broken', but it works as a test-thing
TEST:
	dw CODE_TEST
CODE_TEST:
mov si, msg
ch_loop:
lodsb      ; copy from SI into AL
or al, al  ; zero=end of string
jz hang    ; get out
mov ah, 0x0E ;Write Character in TTY Mode
int 0x10 ;Video Services
jmp ch_loop

msg   db 'Welcome to Macintosh', 13, 10, 0

hang:
jmp hang

times 510-($-$$) db 0
db 0x55
db 0xAA
