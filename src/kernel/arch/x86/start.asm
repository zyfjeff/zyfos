global _start, _kmain
extern kmain, start_ctors, end_ctors, start_dtors, end_dtors

;一些宏定义,定义多启动标准的魔数和标志,具体细节可参见Multiboot Specification
%define MULTIBOOT_HEADER_MAGIC  0x1BADB002
%define MULTIBOOT_HEADER_FLAGS	0x00000003
%define CHECKSUM -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

;-- Entry point
_start:
	jmp start

;-- Multiboot header --
align 4

;多启动标准的头部定义
multiboot_header:
dd MULTIBOOT_HEADER_MAGIC
dd MULTIBOOT_HEADER_FLAGS
dd CHECKSUM     
;--/Multiboot header --

start:
	push ebx
	 
static_ctors_loop:
   mov ebx, start_ctors
   jmp .test
.body:
   call [ebx]
   add ebx,4
.test:
   cmp ebx, end_ctors
   jb .body
 
   call kmain                      ; call kernel proper
 
static_dtors_loop:
   mov ebx, start_dtors
   jmp .test
.body:
   call [ebx]
   add ebx,4
.test:
   cmp ebx, end_dtors
   jb .body
	
	cli ; stop interrupts
	hlt ; halt the CPU
