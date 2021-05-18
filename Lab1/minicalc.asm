;***************************************************************************************************************
;   Mini Taschenrechner 
;
;   Über den Button S1 werden zwei Zahlen eingegeben, welche anschließend summiert und durch Blinken ausgegeben werden.  
;
;   Johannes Wilhelm
;   Hochschule Mannheim
;   Built with IAR Embedded Workbench
;****************************************************************************************************************

#include "msp430f5529.h"

;hier ein paar Definitonen, so dass das Programm unten besser lesbar wird
;
Button_S1       SET     0x02                         ; Taster an Port P2.1
Button_S2       SET     0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)

;-------------------------------------------------------------------------------
            ORG     04400h                  ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           MOV.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !
StopWDT         MOV.w   #WDTPW+WDTHOLD,&WDTCTL  ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++

Port_1
                MOV.b #0x00, &P1IFG     ; Alle P1-IFG's löschen, falls zufällig gesetzt         
                MOV.b #BIT0, &P1DIR     ; nur P1.0 für rote LED als Ausgang konfigurieren (1=Out, 0=In), der Rest des Ports sind Eingänge (der Taster Button_S2 hängt an P1.1)
                MOV.b #BIT1, &P1OUT     ; LED an Port 1.0 ist aus (P1.0=0), PullUp an Port 1.1 für den Button_S2 (P1.1=1)  
                MOV.b #0x00, &P1SEL     ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
                MOV.b #BIT1, &P1REN     ; aktiviere PullUp an P1.1 für Button_S2
                MOV.b #0xff, &P1IES     ; alle Port 1 Interrupts werden auf negative Flanke getriggert (das ist so, weil die Taster auf dem LaunchPad nach Masse gehen)
                MOV.b #Button_S2, &P1IE ; Nur Taster "Button_S2" für Interrupt freigeben, alle anderen Interruptflags von Port 1 unterdrücken

PORT_2
                MOV.b #0x00, &P2IFG     ; Alle P2-IFG's löschen, falls zufällig gesetzt         
                MOV.b #0x00, &P2DIR     ; alle Ports sind Eingänge
                MOV.b #BIT1, &P2OUT     ; PullUp an Port 2.1 für den Button_S1 (P2.1=1)  
                MOV.b #0x00, &P2SEL     ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
                MOV.b #BIT1, &P2REN     ; aktiviere PullUp an P1.1 für Button_S1
                MOV.b #0xff, &P2IES     ; alle Port 1 Interrupts werden auf negative Flanke getriggert (das ist so, weil die Taster auf dem LaunchPad nach Masse gehen)
                MOV.b #Button_S1, &P2IE ; Nur Taster "Button_S1" für Interrupt freigeben, alle anderen Interruptflags von Port 1 unterdrücken

Port_4          BIS.b   #BIT7,&P4DIR            ; Port P4.7 als Ausgang konfigurieren für grüne LED                    
                BIS.b   #BIT7,&P4OUT            ; LED an Port 4.7 einschalten zu Programmbeginn (1 = "an")


                MOV     #0x00, R5               ; Initialisierung  erster Summand
                MOV     #0x00, R6               ; Initialisierung  zweiter Summand
                MOV     #0x00, R8               ; Initialisierung Programmstatusregister (0: Eingebe erste Summand, 1: Eingabe zweiter Summand)
          
Main        
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                NOP
                
                JMP     Main                    ; Endlosschleife
                NOP                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...
                                          
;+++ ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                         

; Button_S2
PORT1_ISR

                MOV.w   #50000,R15  
Entprellen2     DEC.w   R15                     ; Decrement R15
                JNZ     Entprellen2             ; Springe zu Entprellen wenn R15 noch nicht 0 ist
                
                BIC.b   #BIT1, &P1IFG           ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden
               
                CMP     #0x01, R8               ; Vergleiche ob der zweite Summand schon eingegeben wurde
                JZ AUSGABE                      ; Wenn ja, springe zur Ausgabe

                MOV     #0x01, R8               ; Wenn nein, änder Programmstatus für Eingabe des zweiten Summanden 
                RETI


; Ausgabe der Summe durch Blinken der roten LED
AUSGABE         ADD     R5, R6                  ; Addiere die zwei Summanten n+m
                BIC.b   #BIT7,&P4OUT            ; keine Eingebebereitschaft, Grüne LED AUS

BLINK           CMP     #0x00, R6               ; Vergleiche ob das Ergebnis in R6 Null ist
                JZ RESTART                      ; wenn Null: Neustart

                BIS.b   #BIT0,&P1OUT            ; LED Rot AN

                MOV.w   #50000,R15              ; Dauer der Verzögerung
                CALL #DelayLoop                 ; Verzögerungsschleife aufrufen

                BIC.b   #BIT0,&P1OUT            ; LED Rot AUS

                MOV.w   #50000,R15              ; Dauer der Verzögerung
                CALL #DelayLoop                 ; Verzögerungsschleife aufrufen

                DEC     R6                      ; Ergebnis runterzählen (so oft wird noch geblinkt)
                JMP BLINK                       ; Wiederhole das Blinken

DelayLoop       DEC     R15                     ; Verzögerungsschleife
                JNZ DelayLoop
                RET

; Neustart des Programm nach Ausgabe
RESTART         MOV     #0x00, R5                    ; Erste Summand auf null
                MOV     #0x00, R6                    ; Zweiter Summand auf null
                
                MOV     #0x00, R8                    ; Programmstatusregister auf null

                BIS.b   #BIT7,&P4OUT                 ; Eingebebereitschaft, LED Grün AN
                RETI


; Button_S1
PORT2_ISR

                MOV.w   #50000,R15
Entprellen      DEC.w   R15                     ; Decrement R15
                JNZ     Entprellen              ; Springe zu Entprellen wenn R15 noch nicht 0 ist

                BIC.b   #BIT1, &P2IFG           ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden

                CMP     #0x01, R8               ; Vergleiche den aktuellen Programmstatus
                JZ      NEXT                    ; Springe zu next wenn der zweite Summand eingegeben wird

                INC     R5                      ; sonnst erhöhe den ersten Summand um eins
                RETI

NEXT            INC     R6                      ; erhöhe den zweiten Summand um eins
                RETI                            ; eine Interruptroutine muss immer mit dem Befehl RETI abgeschlossen werden





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
