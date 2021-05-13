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
Button_S1       SET     0x02
Button_S2       SET     0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)

;-------------------------------------------------------------------------------
            ORG     04400h                  ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           mov.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !
StopWDT         mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++

Port_1
                mov.b #0x00, &P1IFG     ; Alle P1-IFG's löschen, falls zufällig gesetzt         
                mov.b #BIT0, &P1DIR     ; nur P1.0 für rote LED als Ausgang konfigurieren (1=Out, 0=In), der Rest des Ports sind Eingänge (der Taster Button_S2 hängt an P1.1)
                mov.b #BIT1, &P1OUT     ; LED an Port 1.0 ist aus (P1.0=0), PullUp an Port 1.1 für den Button_S2 (P1.1=1)  
                mov.b #0x00, &P1SEL     ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
                mov.b #BIT1, &P1REN     ; aktiviere PullUp an P1.1 für Button_S2
                mov.b #0xff, &P1IES     ; alle Port 1 Interrupts werden auf negative Flanke getriggert (das ist so, weil die Taster auf dem LaunchPad nach Masse gehen)
                mov.b #Button_S2, &P1IE ; Nur Taster "Button_S2" für Interrupt freigeben, alle anderen Interruptflags von Port 1 unterdrücken

PORT_2
                mov.b #0x00, &P2IFG     ; Alle P2-IFG's löschen, falls zufällig gesetzt         
                mov.b #0x00, &P2DIR     ; alle Ports sind Eingänge
                mov.b #BIT1, &P2OUT     ; PullUp an Port 1.1 für den Button_S1 (P2.1=1)  
                mov.b #0x00, &P2SEL     ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
                mov.b #BIT1, &P2REN     ; aktiviere PullUp an P1.1 für Button_S1
                mov.b #0xff, &P2IES     ; alle Port 1 Interrupts werden auf negative Flanke getriggert (das ist so, weil die Taster auf dem LaunchPad nach Masse gehen)
                mov.b #Button_S1, &P2IE ; Nur Taster "Button_S1" für Interrupt freigeben, alle anderen Interruptflags von Port 1 unterdrücken

Port_4          bis.b   #BIT7,&P4DIR            ; Port P4.7 als Ausgang konfigurieren für grüne LED                    
                bis.b   #BIT7,&P4OUT            ; LED an Port 4.7 einschalten zu Programmbeginn (1 = "an")


                MOV     #0x00, R5               ; Initialisierung  erster Summand
                MOV     #0x00, R6               ; Initialisierung  zweiter Summand
                
                MOV     #0x00, R8               ; Initialisierung Programmstatusregister (0: Eingebe erste Summand, 1: Eingabe zweiter Summand)
          
Main        
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                
                jmp     Main                    ; Endlosschleife
                nop                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...
                                          
;+++ ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                         

; Button_S2
PORT1_ISR

                mov.w   #50000,R15  
Entprellen2     dec.w   R15                     ; Decrement R15
                jnz     Entprellen2             ; Springe zu Entprellen wenn R15 noch nicht 0 ist
                
                bic.b   #BIT1, &P1IFG           ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden
               
                cmp     #0x01, R8               ; Vergleiche ob der zweite Summand schon eingegeben wurde
                jz AUSGABE                      ; Wenn ja, springe zur Ausgabe

                mov     #0x01, R8               ; Wenn nein, änder Programmstatus für Eingabe des zweiten Summanden 
                reti


; Ausgabe der Summe durch Blinken der roten LED
AUSGABE         add     R5, R6                  ; Addiere die zwei Summanten n+m
                bic.b   #BIT7,&P4OUT            ; keine Eingebebereitschaft, Grüne LED AUS

BLINK           cmp     #0x00, R6               ; Vergleiche ob das Ergebnis in R6 Null ist
                jz RESTART                      ; wenn Null: Neustart

                bis.b   #BIT0,&P1OUT            ; LED Rot AN

                mov.w   #50000,R15              ; Dauer der Verzögerung
                CALL #DelayLoop                 ; Verzögerungsschleife aufrufen

                bic.b   #BIT0,&P1OUT            ; LED Rot AUS

                mov.w   #50000,R15              ; Dauer der Verzögerung
                CALL #DelayLoop                 ; Verzögerungsschleife aufrufen

                dec     R6                      ; Ergebnis runterzählen (wie oft noch zu blinken)
                jmp BLINK                       ; Wiederhole das Blinken

DelayLoop       dec     R15                     ; Verzögerungsschleife
                jnz DelayLoop
                RET

; Neustart des Programm nach Ausgabe
RESTART         MOV     #0x00, R5                    ; Erste Summand
                MOV     #0x00, R6                    ; Zweiter Summand
                
                MOV     #0x00, R8                    ; Programmstatusregister

                bis.b   #BIT7,&P4OUT                 ; Eingebebereitschaft, LED Grün AN
                reti


; Button_S1
PORT2_ISR

                mov.w   #50000,R15  
Entprellen      dec.w   R15                     ; Decrement R15
                jnz     Entprellen              ; Springe zu Entprellen wenn R15 noch nicht 0 ist

                bic.b   #BIT1, &P2IFG           ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden

                cmp     #0x01, R8               ; Vergleiche den aktuellen Programmstatus
                jz      NEXT                    ; Springe wenn der zweite Summand eingegeben wird

                inc     R5                      ; sonnst erhöhe den ersten Summand um eins
                reti

NEXT            inc     R6                      ; erhöhe den zweiten Summand um eins
                reti                            ; eine Interruptroutine muss immer mit dem Befehl reti abgeschlossen werden





;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET                   
            
            ORG     0FFDEh                  ;Interrupt Vektor für die Flags in Register P1IFG
            DW      PORT1_ISR               ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle

            ORG     0FFD4h                  ;Interrupt Vektor für die Flags in Register P2IFG
            DW      PORT2_ISR
            END
