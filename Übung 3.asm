#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Übung 3: Programmieren Sie eine Funktion, die den Wert in R5 mit dem Faktor 8 multipliziert. Die Funktion soll weiterhin prüfen, ob ein Überlauf auftritt und in diesem Fall den Wert in R8 auf 50h setzen.
		  
		  mov.w #0x2, R5                        ; Startwert
LOOP       
		  RLA R5                                ; x2
          JC OVERFLOW                           ; Prüfen ob Überlauf
		  RLA R5
          JC OVERFLOW
		  RLA R5
          JC OVERFLOW
          JMP LOOP                              ; Springe zum Anfang
OVERFLOW
	  mov.w #0x50, R5
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