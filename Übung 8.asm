#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

LOOP
		  mov #0x79, R5							; Schreibe zu Vergleichenden Wert in R5
		  
		  cmp #0x80, R5							; Vergleiche R5 mit 0x80
		  JGE ONE								; Wenn R5 > 0x80 spring zu ONE
		  
		  cmp #0x20, R5							; Vergleiche R5 mit 0x80
		  JL ONE								; Wenn R5 < 0x20 spring zu ONE
		  
		  mov #0x00, R7							; Schreib 0 in R7 wenn R5 im zulässigen Bereich
		  
		  JMP LOOP
		  
ONE
		  mov #0x01, R7							; sonnst schreib 1 in R7
		  RET
	  

      NOP           ; diese Zeile hat keine Funktion, sie ist wegen dem Simulator nötig, bitte nicht daran stören    

;------- Interrupt Vektor Tabelle --------------------------------------------

          ORG   0xFFFE          ; RESET Vector
          DW    RESET           ; diese Zeile erwirkt einen automatischen Sprung an die Programmstelle mit dem Label "RESET" 
;-----------------------------------------------------------------------------
          END


      MOV #0xfffa, R8
 LOOP
      INC R8
      JMP LOOP