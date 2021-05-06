#include "msp430f5529.h"                        ; Einbinden der Definitionen


;--- Initialisierung des Mikrocontrollers -------------------------------------

main      ORG 4400h                             ; Programmstart im Flash (Adresse 4400h aus dem Datenblatt entnehmen)
RESET                                           ; das Label "RESET" ist hier identisch mit der Adresse 4400h und entspricht dem Programmanfang        

          mov.w  #0x03100,SP                     ; Init Stackpointer-Register (SP)
StopWDT   mov.w  #WDTPW+WDTHOLD,&WDTCTL          ; Watchdog anhalten (ist standardmäßig nach dem Reset sonst aktiv!)



;--- ab hier Programmierung der eigentlichen Aufgabenstellung -----------------

; Programmieren Sie in einer Endlosschleife ein „Lauflicht“ mit Register R5. Der Startwert von R5 soll 0x0001 sein. Die anfängliche „1“ ganz rechts soll nach links wandern bis zum 15. Bit. Dann soll die Richtung umkehren und die „1“ soll wieder
; nach rechts wandern bis zum 0. Bit. Es soll immer nur ein Bit in R5 logisch „1“ sein, alle anderen Bits sollen „0“ sein.

		  mov #0x01, R5
		  
LOOP
                  
		  RLA R5								; Schieb 15x Null von rechts
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
		  RLA R5
                  
          CLRC									; Lösche das Carry Bit
		  
		  RRC R5								; Schieb 15x Null von links
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  RRC R5
		  
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