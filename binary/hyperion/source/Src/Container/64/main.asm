; Hyperion 64-Bit container.exe

include 'image_base.inc'
format PE64 GUI 5.0 at IMAGE_BASE
entry start

include '..\..\..\Fasm\INCLUDE\win64a.inc'
include 'createstrings.inc'
include 'pe.inc'
;automatically generated by hyperion cpp stub
include 'key_size.inc'
include 'infile_size.inc'
include 'image_size.inc'
;---

SIZE_DATA_SECTION_NAME	equ 5
SIZE_CHECKSUM		equ 4

;this contains the decrypted and loaded executable
section '.bss' data readable writeable

	 decrypted_infile: db IMAGE_SIZE dup (?)

;--------------------------------------------------

;this contains the encrypted exe
section '.data' data readable writeable

	 encrypted_infile: include 'infile_array.inc'

;--------------------------------------------------

section '.text' code readable executable

;include necessary functions
include 'logfile_select.asm'
include 'loadexecutable.asm'
;automatically generated by hyperion cpp stub
include 'decryption_payload.asm'
;---

start:
	 sub rsp,8
	 fastcall MainMethod
	 test rax,rax
	 jz the_end_my_friend
	 ;file was loaded, execute it
	 add rsp,8
	 jmp rax
the_end_my_friend:
	 invoke ExitProcess,0

proc MainMethod
	 local str1[256]:BYTE,\
	 RetVal:QWORD

	 ;create logfile and write initial message into it
	 initLogFile
	 test rax,rax
	 jz main_exiterrornolog

	 ;decrypt exe in data section
	 fastcall decryptExecutable, encrypted_infile
	 test rax,rax
	 jz main_exiterror

	 ;load the executable at its image base
	 ;(this will overwrite current MZ header and bss section)
	 fastcall loadExecutable, encrypted_infile
	 test rax,rax
	 jz main_exiterror

	 ;start program execution
	 mov rdx,IMAGE_BASE
	 xor rax,rax
	 mov eax,[rdx+IMAGE_DOS_HEADER.e_lfanew]
	 add rax,rdx
	 add rax,4
	 ;image file header now in eax
	 add rax,sizeof.IMAGE_FILE_HEADER
	 xor rdx,rdx
	 mov edx,[rax+IMAGE_OPTIONAL_HEADER64.AddressOfEntryPoint]
	 mov rax,IMAGE_BASE
	 add rdx,rax
	 ;entry point of original exe is now in rdx
	 mov [RetVal],rdx

;finished without errors
main_exitsuccess:
	 writeNewLineToLog
	 createStringDone str1
	 lea rax,[str1]
	 writeLog rax
	 mov rax,[RetVal]
	 jmp main_exit

;finished with errors after logfile API loading
main_exiterror:
	 writeNewLineToLog
	 createStringError str1
	 lea rax,[str1]
	 writeLog rax
	 sub rax,rax

main_exit:
	 ret

;finished with errors before logfile API loading
main_exiterrornolog:
	 ret

endp

;import table
section '.idata' import data readable writeable

	 library kernel,'KERNEL32.DLL'

	 import kernel,\
	    LoadLibrary,'LoadLibraryA',\
	    GetProcAddress,'GetProcAddress',\
	    GetFileSize,'GetFileSize',\
	    CreateFileMapping,'CreateFileMappingA',\
	    MapViewOfFile,'MapViewOfFile',\
	    UnmapViewOfFile,'UnmapViewOfFile',\
	    CreateFile,'CreateFileA',\
	    CloseHandle,'CloseHandle',\
	    DeleteFile,'DeleteFileA',\
	    GetModuleHandle,'GetModuleHandle',\
	    VirtualAlloc,'VirtualAlloc',\
	    VirtualProtect,'VirtualProtect',\
	    VirtualFree,'VirtualFree',\
	    ExitProcess,'ExitProcess'