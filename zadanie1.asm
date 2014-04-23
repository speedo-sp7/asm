; Zadanie1 c.21                                                                      
; Roman Ro�t�r
;
; TEXT ZADANIA
;	Nap�te program (v JSI), ktor� umo�n� pou��vatelovi pomocou menu nasleduj�ce akcie: zadat meno s�boru, vyp�sat obsah s�boru, vyp�sat dl�ku s�boru
;	(v desiatkovej s�stave, v bajtoch), vykonat pridelen� �lohu, ukoncit program. Program nac�ta volbu pou��vatela z kl�vesnice. Program sa mus� ukoncit aj po stlacen� kl�vesu "ESCAPE".
;	V programe vhodne pou�ite makro s parametrom, ako aj vhodn� volania OS (resp. BIOS) pre nac�tanie znaku, nastavenie kurzora, v�pis retazca, zmazanie obrazovky a pod. Na spracovanie pola
;	znakov musia byt vhodne pou�it� retazcov� in�trukcie. Pridelen� �loha mus� byt realizovan� ako extern� proced�ra (kompilovan� samostatne a prilinkovan� k v�sledn�mu programu).
;	Defin�cie makier musia byt v samostatnom s�bore. Program mus� korektne spracovat s�bory s dl�kou aspon do 128 kB. Pri c�tan� vyu�ite pole vhodnej velkosti (buffer), pricom zo s�boru do
;	pam�te sa bude pres�vat v�dy (a� na posledn� c�tanie) cel� velkost pola. O�etrite chybov� stavy.
;
; DOPLNKOVA ULOHA
; POVODNE: 14. Na��ta� re�azec a vyp�sa� po�et jeho v�skytov (ako podre�azca) v s�bore.
; ZMENENE NA: 21. N�js� znak s maxim�lnou hodnotou a vyp�sa� jeho poz�ciu.
;PREKLAD:         [cesta]\tasm /l/zi/c subor.asm
;LINKOVANIE:      [cesta]\tlink /l/i/v subor.obj
;POMOCNE PROGRAMY:[cesta]\thelp\help.exe, abshelp.exe
;                 [cesta]\tasm\thelp.com
;                 [cesta]\ng\ng.exe


ZAS   segment stack 'stack'												        ;zaciatok zasobnikoveho segmentu
      dw 64 dup(?)																	      ;definicia 64-och slov v pamati
ZAS   ENDS                                                ;koniec zasobnikoveho segmentu

DATA	SEGMENT
    ;zaciatok datoveho segmentu

    ;misc
    NEWL EQU 13,10
    TAB EQU 9
    NEWLINE   DB NEWL,'$'
    TESTFILE  DB 'ahoj.txt',0,'$'

    ;menu
    MENU  	  DB NEWL,'ASM Zadanie 1. -- Autor: Roman Rostar (c)',NEWL,'MENU :',NEWL
		    	    DB TAB,'1. Nacitat subor',NEWL
		    		  DB TAB,'2. Vypisat obsah suboru',NEWL
        		  DB TAB,'3. Pozicia maximalneho znaku v subore',NEWL
        		  DB TAB,'4. Zmazat obrazovku a vypisat menu',NEWL
              DB TAB,'[ESC,ENTER] pre vypnutie programu',NEWL,'$'
    UNKNWN    DB 'Neznamy prikaz',NEWL,'$'

    ;messages
    MSG_BACK            DB 'Stlacte ENTER pre navrat do menu',NEWL,'$'
    MSG_RETURN_ENTER		DB	NEWL,'Stlacte ENTER pre navrat do hlavneho menu.$'
    MSG_FILE_NAME       DB  'Zadajte meno suboru',NEWL,'$'
    MSG_LEN             DB 'Pocet znako v subore je: ','$'
    MSG_CHR             DB 'Najvacsi znak je: ','$'
    MSG_POS             DB 'na pozicii: ','$' 

    ;error messages
    ERROR     DB 'Error: Not yet implemented!',NEWL,'$'
    ERROR_FL  DB 'Nastala chyba pri otvarani suboru',NEWL,'$'
    ERR_NO_HANDLE  DB 'Najprv nacitajte subor',NEWL,'$'
    ;
    ;File handle suboru
    HANDLE    DW 0
    FILENAME  DB 100 dup (?)
    FN_LEN    DB 0
    BUFFER    DB 100 dup (?)
    READ      DW 0
    D         DW 0
    POS       DW 0
    MAX_VAL   DB 0
    MAX_POS   DW 0
    dec_length		db	0  
DATA ENDS

include makra.asm

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:ZAS  ;makro na vycistenie obrazovky aka clrscr
  
  CHARS proc				; prevod z bytov do dekadickeho cisla
		mov dec_length, 0	;dlzka decimalneho cisla = pocet cifier zatial 0
	DEC_DIVISION:
		xor dx, dx			;uvodny xor
		mov cx, 10
		
		mov ax, bx 		;do ax nacitame nase cislo, ktore chceme vypisovat, vzdy v programe ho umiesnujem to bx
		div cx			;predelime desiatmi
		mov bx, ax		;do bx skopirujeme obsah ax, tj predelene cislo
		push dx			;do dx hodime cifru
		inc dec_length		;pridame jednu cifru
		cmp bx, 0			;skontrolujeme ci este mame cifry v bx
		jz DEC_PRINT
		jmp DEC_DIVISION
		
	DEC_PRINT:		;vypisanie dekadickeho cisla
		pop dx		;cifru vytiahneme z dx
		add dx, 30h			;posun na zaciatok cisel
		mov ah, 02h			;funkcia na print cisla
		int 21h
		dec dec_length		; posun o cifru dalej
		cmp dec_length, 0
		jz navrat ;uz sme vypisali cele cislo
		jmp DEC_PRINT
	navrat:
		ret	
	endp CHARS

  OCC proc   ;procedura na zistenie miesta max znaku
    mov D,0
    mov POS,0        ;init
    mov MAX_VAL, 0
    mov MAX_POS, 0
  
    PRINT NEWLINE
    mov AX,HANDLE   ;ak nemam handle, treba ho najprv nacitat
    cmp AX,0
    jnz go_on1
    PRINT ERR_NO_HANDLE
    ret             ;ak bola chyba koncim
    
go_on1:
    mov ah, 42h ;nastavim sa na zaciatok suboru
    mov BX, HANDLE
    mov al, 0 
    mov dx, 0
    mov cx, 0
    int 21h
cont1:         ;pokracujem citanie
    mov AH, 3Fh
    mov BX, HANDLE
    mov CX, 99
    lea DX, BUFFER
    int 21h        ;precitam 99bajtov do bufferu
    
    cmp ax,cx ;porovnam kolko ancital
    jne end_read1; ak sa nerovnaju uz som docital
    push ax   ;schovam si hodnoty a po porovnavani max znakov to popnem
    push bx
    push dx

    mov D,0   ;v nacitanom bufferi ideme od 1
loo:
    ;prejdi buffer
    lea di, buffer
    add di,D
    MOV AL, [DI]
    cmp AL, MAX_VAL
    jng next
    MOV MAX_VAL,AL ;ak je tak prepis maxhodnotu
		MOV AX,POS
		MOV MAX_POS, AX
next:
    inc D
    inc POS
    MOV BX, D			;zistujem ci uz som na konci obsahu suboru
		CMP BX,99
		JNG loo
    pop dx       ;popnem hodnoty a pokracujem v cykle citania
    pop bx
    pop ax
    jmp cont1
       
end_read1:  ;ak som nacital menej ako 99B tak idem sem (koniec suboru)
    push ax ;schovam hodnoty a idem citat posledny usek 
    push bx
    push dx

    mov D,0   ;to iste ako v cykle loo
loo2:
    ;prejdi buffer
    lea di, buffer
    add di,D
    MOV AL, [DI]
    cmp AL, MAX_VAL
    jng next2
    MOV MAX_VAL,AL ;ak je tak prepis maxhodnotu
		MOV AX,POS
		MOV MAX_POS, AX
next2:
    inc D
    inc POS
    MOV BX, D			;zistujem ci uz som na konci obsahu suboru
		CMP BX,CX
		JNG loo2
    pop dx  ;hodnoty popnem aby som mohol ist dalej
    pop bx
    pop ax
    ret
  endp

  WAIT_FOR proc
    waiting:
		PRINT MSG_RETURN_ENTER
      mov AH, 8		; nacitanie znaku
			int 21H
			cmp AL, 13		;Porovnaj ci bol stlaceny enter
		loopne waiting
		ret
	endp
  
  
  
  READNAME proc
    ;PRINT MSG_FILE_NAME
    lea BX, FILENAME
    reading:      
      mov AH, 1		; nacitanie znaku
			int 21H
			cmp AL, 13		;Porovnaj ci bol stlaceny enter
      jz  return    ;ak hej skoncili sme 
      mov [BX],AL   ;
      inc BX
      inc FN_LEN
      jmp reading
    return:
      mov AL,'$'
      mov [BX],AL
      ;PRINT FILE
      mov AH, FN_LEN  ;necham v AH dlzku mena
		  ret
  endp
    
  START:
    ;nacitanie programu
    MOV AX, SEG DATA
		MOV DS, AX
clear:      
vyp_menu:
    CLRSCR
    PRINT MENU
select:
		mov  ah,1
		int  21h
		cmp al,'1'			;nacitaj subor
		jz load_inter
		cmp al, '2' 		;vypis subor
		jz output_file
		cmp al, '3'     ;pocet vyskytov v subore
		jz occur
    cmp al,'4'			;zmaz obrazovku,vypis menu
		jz clear
		cmp al, 27 ; esc na ukoncenie
		jz quit_inter1
		cmp al, 13 ;enter na ukoncenie
		jz quit_inter1
    PRINT NEWLINE
    PRINT UNKNWN  ;ak stlatcil nieco ine
    ;PRINT NEWL
    jmp select
load_inter:
    jmp load_file
quit_inter1:
    jmp quit_inter2
         
occur:
    call OCC
    PRINT MSG_CHR
    MOV AH, 02h
		MOV DL, MAX_VAL
		INT 21h
    PRINT NEWLINE
    PRINT MSG_POS
    mov BX, MAX_POS
    call chars   
    call wait_for  
    jmp vyp_menu
         
output_file:
    PRINT NEWLINE
    mov READ, 0
    mov AX,HANDLE
    cmp AX,0
    jnz go_on
    PRINT ERR_NO_HANDLE
    call wait_for
    jmp vyp_menu
 
go_on:
    mov ah, 42h ;nastavim sa na zaciatok suboru
    mov BX, HANDLE
    mov al, 0 
    mov dx, 0
    mov cx, 0
    int 21h
cont:         ;pokracujem citanie
    mov AH, 3Fh
    mov BX, HANDLE
    mov CX, 99
    lea DX, BUFFER
    int 21h        ;precitam 99bajtov do bufferu
    add READ,AX    
    cmp ax,cx ;porovnam kolko ancital
    jne end_read; ak sa nerovnaju uz som docital
    mov bx,ax
    mov BUFFER[bx],'$' ;vypisem co zatial mam
    PRINT BUFFER
    mov ah, 42h        ;posuniem sa o 99 B dalej
    mov al, 1 ;idem od current
    mov dx, 99
    mov cx, 0
    jmp cont    
end_read:
    mov bx,ax
    mov BUFFER[bx],'$' 
    PRINT BUFFER
    PRINT NEWLINE
    PRINT MSG_LEN
    mov bx,read
    call CHARS
    call WAIT_FOR
    jmp vyp_menu  
    
quit_inter2:
    jmp quit

load_file:
    PRINT NEWLINE
    mov ax,handle
    cmp ax, 0
    jz empty_handle ;ak mam handle trea ho zavriet, ak nemam tak idem rovno nacitavat
    mov bx, ax  ;nacitam filehandle
    mov ah, 3Eh ;fcia na zavretie handle
    int 21h
empty_handle:
    PRINT MSG_FILE_NAME   
    call READNAME
    cmp AH,0
    jz  nenacitane
    mov AH, 3DH ; FCIA NA OTVORENIE SUBORU
    mov AL, 0   ; 0= READ-ONLY ACCESS
    mov DX, OFFSET FILENAME
    int 21H
    ;ak bola chyba tak ideme prec
    jc file_err   
    
    mov handle,ax ;nebola chyba
    PRINT handle
    jmp vyp_menu
     
nenacitane:
    PRINT NEWLINE
    PRINT ERROR
    call WAIT_FOR
    jmp vyp_menu
    
file_err:
    PRINT NEWLINE
    PRINT ERROR_FL
    call WAIT_FOR
    jmp vyp_menu



quit:
    ;ukoncenie programu
    mov ax,handle
    cmp ax, 0
    jz final
    mov bx, ax  ;nacitam filehandle
    mov ah, 3Eh ;fcia na zavretie handle
    int 21h
final:
    mov AH, 4CH
		int 21H

  CODE ENDS
  END START