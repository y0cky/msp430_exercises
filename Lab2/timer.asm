#include "msp430f5529.h"

Button_S1       SET     0x02                         ; Taster an Port P2.1
Button_S2       SET     0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)

;-------------------------------------------------------------------------------
            ORG     04400h                  ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           MOV.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !
StopWDT         MOV.w   #WDTPW+WDTHOLD,&WDTCTL  ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++


                MOV     #0x00, R5               ; Initialisierung Timer
          
Main            mov.w   #TASSEL_2+MC0,&TA0CTL   ; SMCTL=1,048 Mhz, Up-Mode 
                mov.w   #CCIE,&TA0CCTL0         ; aktiviere TA0CCR0-Capture/Compare Interrupt (wird immer ausgelöst, wenn der Timer_A bis zu dem Wert in Register TA0CCR0 hochgezählt hat)        
                mov.w   #1 ,&TA0CCR0            ; bis zu diesem Wert wird hochgezählt, dann gibt es einen ersten Interrupt und der Timer beginnt automatisch wieder bei Null zu zählen (32768 entsprechen 1s bei 32,768 kHz Zählfrequenz)
                mov.b   #0x00,&UCA1IFG          ; alle Interruptflags löschen, falls zufällig gesetzt
                BIS.W   #GIE, SR                ; global Interruptsystem aktivieren
                NOP
                
                JMP     Main                    ; Endlosschleife
                NOP                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...
                                          
;+++ ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                         

;+++ TIMER_A0_CCR0ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TIMER_A0_CCR0ISR
                ;Hinweis: das InterruptFlag CCIFG in Register TA0CCTL0 wird automatisch gelöscht und muss nicht per Software gelöscht werden --> steht auf Seite 471 im FamilyUserGuide!
                
                ;xor.b   #LED_2, &P4OUT          ;Test ob Interrupt funktioniert
                inc     R5                      ;R5 um pro Sekunde erhöhen
               
        

ENDE_ISR_TIMER_A0
                reti
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET                   
            
            ORG     0FFEAh                  ;Interrupt Vektor für das Flag CCIFG0 im Register TA0CCTL0 (dieses Flag wird gesetzt, wenn der Timer_A0 bis zu TA0CCR0 hochgezählt hat)
            DW      TIMER_A0_CCR0ISR        ;die Interrupt Vektor Adresse 0xFFEA steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            END