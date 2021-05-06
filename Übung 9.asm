#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Übung 9: Programmieren Sie eine Funktion, die bei jedem Aufruf das Register R5 um den Wert
; des Registers R6 erhöht. Das Register R6 soll einen Startwert von 0x0000 haben und bei jedem Funktionsaufruf selbst um +1 erhöht werden.

		  MOV 0x00, R5							; Initialisierung der Anfangswerte
		  MOV 0x00, R6

LOOP
		  CALL #increase						; Funktion aufrufen
		  JMP LOOP
	  
increase
		  ADD R6, R5							; Addiere R6 zu R5
		  INC R6								; R6 +1
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