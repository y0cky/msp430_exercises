#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Übung 5:Programmieren Sie eine Funktion, die den Wert der Register R5, R6 und R7 addiert. Das Ergebnis soll in R8 und R9 stehen.


	  mov #0xFFFF, R5							; Zahlen die Addiert werden sollen
	  mov #0xFFFF, R6
	  mov #0xFFFF, R7
	  
	  mov #0x0000, R8							; Initialisierung Zielregister
	  mov #0x0000, R9
	  
	  ADD R5, R6								; Addiere R5 zu R6
	  ADC R9									; Überlauf in R9
	  ADD R6, R7								; Addiere R6 zu R7
	  ADC R9									; Überlauf in R9
	  MOV R7, R8								; Verschiebe R7 zu R8
	  
	  ; R5 + R6 + R7 = (R8, R9)		-> Ergebnis steht in Register R8 und R9 
	  
	  

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