;***************************************************************************************************************
;   Dieses Beispielprogramm setzt zum Verständnis voraus, dass Sie das erste kleine Beispielprogramm
;   mit den beiden blinkenden LEDs sowie den darin enthaltenen kleinen Programmieraufgaben gut beherrschen.
;
;   Als Erweiterung zum ersten Programm wird nun der Taster S2 (Taster unten rechts auf dem LaunchPad neben 
;   der grünen LED) zum Steuern der LEDs verwendet. Da wir nur vernünftig programmieren wollen, setzen wir
;   hierzu einen Interrupt ein. Beim Drücken des Tasters wird ein Port-Interrupt über Port 1.1 ausgelöst. In
;   der zugehörigen Interrupt Service Routine (ISR) wird dann direkt oder indirekt das Leuchten der LEDs 
;   beeinflusst.
;  
;   Da ein mechanischer Taster immer prellt, ist eine kleine Delay-Loop zum Entprellen des Tasters vorhanden.
;   Erst nach einer kurzen Wartezeit nach dem Drücken des Tasters wird sein Zustand als stabil angenommen und
;   die Programmabarbeitung fortgesetzt. Das Interruptflag wird natürlich auch erst NACH der Delay-Schleife 
;   wieder zurückgesetzt, denn sonst würde es durch das Prellen sofort wieder neu gesetzt werden und die ISR würde 
;   mehrfach abgearbeitet.
;
;   Hinweis: Der interne Takt beträgt hier standardmäßig 1,048 MHz
;   (ACLK = n/a, MCLK = SMCLK = default DCO = 1,048 MHz)     
;
;   Dennis Trebbels
;   Hochschule Mannheim
;   Built with IAR Embedded Workbench
;****************************************************************************************************************
;
;   Aufgaben zum Einstieg in die Programmierung mit Port-Interrupts mit dem LaunchPad:   

;   1) Ändern/Erweitern Sie den Programmcode, so dass die S2 3x drücken müssen, um beide LEDs zu toggeln (das Programm muss also 3x den Tastendruck zählen bevor es die LEDs ansteuert)
;
;   2) Ändern/Erweitern Sie den Programmcode, so dass die LEDs auch mit dem Taster S1 angesteuert werden können (an P2.1). Die Taster S1 und S2 sind dann sozusagen gleichwertig und es wäre egal, wo der Benutzer drückt
;
;   3) Ändern/Erweitern Sie den Programmcode, so dass Sie mit S1 beide LEDs nur einschalten können und mit S2 beide LEDs nur Ausschalten können
;
;   4) Ändern/Erweitern Sie den Programmcode, so dass sie die grüne LED nur dann mit S2 toggeln können, wenn gleichzeitig S1 dauerhaft gedrückt ist
;
;   5) Ändern/Erweitern Sie den Programmcode, so dass beide LEDs langsam blinken wenn sie S2 drücken bzw. aus sind wenn sie S2 nochmal drücken etc...
;
;****************************************************************************************************************

#include "msp430f5529.h"

;hier ein paar Definitonen, so dass das Programm unten besser lesbar wird
;
Button_S2    SET   0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)

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

Port_4          bis.b   #BIT7,&P4DIR            ; Port P4.7 als Ausgang konfigurieren für grüne LED                    
                bis.b   #BIT7,&P4OUT            ; LED an Port 4.7 einschalten zu Programmbeginn (1 = "an")
                ;mehr ist bei Port 4 nicht nötig da sonst der Port nicht benutzt wird in diesem Programm
          
Mainloop        
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                
                jmp     Mainloop                ; Endlosschleife
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
