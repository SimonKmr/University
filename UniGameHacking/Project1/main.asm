.686
.model flat,stdcall
option casemap:none

; import library for kernel32.dll (contained in windows sdk)
includelib kernel32.lib

; api declarations, later substituted by linker 
ExitProcess PROTO STDCALL, :DWORD
MessageBoxA PROTO STDCALL, :DWORD,:DWORD,:DWORD,:DWORD
ExitProcess PROTO STDCALL, :DWORD
GetStdHandle PROTO STDCALL, :DWORD
WriteConsoleA PROTO STDCALL, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

.data
CpuidSupportedMsg       db "CPUID supported!",0
CpuidUnsupportedMsg     db "CPUID unsupported!",0
NewLine					dw 0A0Dh,0

cpuCounter				dd 80000002h,0
consoleOutHandle		dd 0,0
cpuIdentifier			dd 0,0			  

cpuStr					dd 0,0 

.code
start:

; preparation for console.Write cw
; consoleOutHandle = getStdHandle(-11)
push -11
call GetStdHandle
mov consoleOutHandle, eax

; Check if cpuid is supported
pushfd                               ;Save EFLAGS
pushfd                               ;Store EFLAGS
xor dword ptr[esp],00200000h         ;Invert the ID bit in stored EFLAGS
popfd                                ;Load stored EFLAGS (with ID bit inverted)
pushfd                               ;Store EFLAGS again (ID bit may or may not be inverted)
pop eax                              ;eax = modified EFLAGS (ID bit may or may not be inverted)
xor eax,[esp]                        ;eax = whichever bits were changed
popfd                                ;Restore original EFLAGS
and eax,00200000h

;if(cpuid.isSupported) goto CpuIdSupported; 
cmp eax, 0
jne CpuIdSupported


; write "CPU is not supported"
; WriteConsoleA(consoleOutHandle, CpuidUnsupportedMsg, 18, 0, 0)
push 0 
push 0 
push 18
push OFFSET CpuidUnsupportedMsg
push consoleOutHandle
call WriteConsoleA

;ExitProcess(0)
push 0
call ExitProcess



CpuIdSupported:
; write "CPU supported"
; WriteConsoleA(StdoutHandle, CpuidSupportedMsg, 16, 0, 0)
push 0 
push 0 
push 16
push OFFSET CpuidSupportedMsg
push consoleOutHandle
call WriteConsoleA

; /n (creates a new line)
; WriteConsoleA(StdoutHandle, "\n", 2, 0, 0)
push 0 
push 0 
push 2
push OFFSET NewLine
push consoleOutHandle
call WriteConsoleA

; while{
PrintLoop:

;eax,ebx,ecx,edx = cpuid(cpuCounter)
mov eax, cpuCounter
cpuid

;returns manufacturer ID
;cpuStr = eax + ebx + ecx + edx
mov dword ptr[cpuStr]	, eax
mov dword ptr[cpuStr+4]	, ebx
mov dword ptr[cpuStr+8]	, ecx
mov dword ptr[cpuStr+12], edx

; Write(cpuStr)
; WriteConsoleA(StdoutHandle, cpuStr, 16, 0, 0)
push 0 
push 0 
push 16
push OFFSET cpuStr
push consoleOutHandle
call WriteConsoleA

;cpuCounter++
mov ecx,cpuCounter
add ecx, 1
mov cpuCounter, ecx


;} do(cpuCounter < 80000005h) 
cmp ecx, 80000005h
jl PrintLoop



;ExitProcess(0)
push 0
call ExitProcess

end start ; entrypoint = start