#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Übung 4: Programmieren Sie eine Funktion, die einen 32-bit Wert (R5 und R6) mit dem Faktor 4 multipliziert und den Überlauf überwacht. Bei einem Überlauf soll R7 zu 1 gesetzt werden.

	  mov #0x0000, R7						; R7 initialisieren
		
	  mov #0x10, R5							; Startwert festlegen
	  mov #0x00, R6
	  
LOOP
	  RLA R5								; R5 nach links Schieben (*2)
	  RLC R6								; R6 nach links schieben, Carry anhängen
	  JC OVERFLOW							; Prüfe ob Überlauf auftritt
	  RLA R5								; R5 nach links Schieben (*2)
	  RLC R6								; R6 nach links schieben, Carry anhängen
	  JC OVERFLOW							; Prüfe ob Überlauf auftritt
	  JMP LOOP
	  
OVERFLOW
	  MOV #0x1, R7							; Setze R7 = 1 wenn Überlauf auftritt
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