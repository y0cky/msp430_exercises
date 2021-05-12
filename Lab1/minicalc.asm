;***************************************************************************************************************
;   Mini Taschenrechner 
;
;   Johannes Wilhelm
;   Hochschule Mannheim
;   Built with IAR Embedded Workbench
;****************************************************************************************************************

#include "msp430f5529.h"

;hier ein paar Definitonen, so dass das Programm unten besser lesbar wird
;
Button_S1       SET     BIT1
Button_S2       SET     0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)

;-------------------------------------------------------------------------------
            ORG     04400h                  ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           mov.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !
StopWDT         mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++

; LED Rot
                bis.b	#BIT0, &P1DIR           ; P1.0 -> output
                bic.b	#BIT0, &P1OUT           ; LED Rot AN

; LED grün
                bis.b	#BIT7, &P4DIR           ; P4.7 -> output
                bic.b	#BIT7, &P4OUT           ; LED grün AN

; Button_S1
                bic.b	#BIT1, &P2DIR			; P2.1 -> input
			    bis.b	#BIT1, &P2REN			; enable pull-up/down
			    bis.b	#BIT1, &P2OUT			; P2.1 -> pull-up

; Button_S2
                bic.b	#BIT1, &P1DIR			; P1.1 -> input
			    bis.b	#BIT1, &P1REN			; enable pull-up/down
			    bis.b	#BIT1, &P1OUT			; P1.1 -> pull-up
          
Main        
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                
                jmp     Main                    ; Endlosschleife
                nop                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...
                                          
;+++ ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                         
PORT1_ISR
                mov.w   #50000,R15  
Entprellen      dec.w   R15                     ; Decrement R15
                jnz     Entprellen              ; Springe zu Entprellen wenn R15 noch nicht 0 ist
                
                bic.b   #Button_S2, &P1IFG      ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden
               
                xor.b   #BIT7,&P4OUT            ; Toggle P4.7 --> die grüne LED wird also nach einem Tastendruck abwechselnd an und aus geschaltet
                xor.b   #BIT0,&P1OUT            ; Toggle P1.0 --> die rote LED wird also nach einem Tastendruck abwechselnd an und aus geschaltet
                
                reti  ; eine Interruptroutine muss immer mit dem Befehl reti abgeschlossen werden
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET                   
            
            ORG     0FFDEh                  ;Interrupt Vektor für die Flags in Register P1IFG
            DW      PORT1_ISR               ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            END
