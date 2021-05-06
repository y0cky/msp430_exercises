#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Übung 2: Programmieren Sie eine Funktion/Subroutine, die in einer Schleife ein Register immer um den Wert 2 erhöht, so lange bis das Register einen Wert größer gleich 80h hat.

MAIN
		  mov.w #0x000, R5			; Startwert
          mov.w #0x7F, R6                       ; Zielwert - 1
LOOP
		  CMP.w R5, R6                          ; Vergleiche Istwert mit Zielwert
		  JL GREATER                            ; Spring wenn Istwert > Zielwert
          
          incd.w R5                             ; Zielwert +2
		  JMP LOOP                              ; Vergleich Wiederholen
GREATER
          JMP MAIN

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