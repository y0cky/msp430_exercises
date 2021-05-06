#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Programmieren Sie eine Funktion, welche den Wert der Register R8 und R9 vertauscht. Benutzen Sie hier kein weiteres Register zum Zwischenspeichern, sondern verwenden Sie den Stack!

LOOP
	  mov #0xFFFF, R8							; Initialisierung
	  mov #0x0000, R9
	  
	  push R8									; Schiebe R8 in Stack
	  push R9									; Schiebe R9 in Stack
	  pop R8									; Erste Wert aus Steck (R9) in R8
	  pop R9									; Zweiter Wert aus Steck (R8) in R8
	  
	  JMP LOOP

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