#include "msp430f5529.h"

;hier ein paar Definitonen, so dass das Programm unten besser lesbar wird
;
Button_S2    SET   0x02                         ; Taster an Port P1.1 (der Name S2 stammt aus dem Schaltplan des LaunchPad, siehe LaunchPad-Userguide "slau533b" auf Seite 57)
LED_2        SET   0x80                         ; grüne LED ist an Port 4.7 angeschlossen (7.Bit ==> 0x80)                
;-------------------------------------------------------------------------------
            ORG     04400h                      ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           mov.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !
StopWDT         mov.w   #WDTPW+WDTHOLD,&WDTCTL   ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++

Port_1
                mov.b #0x00, &P1IFG   ; Alle P1-IFG's löschen, falls zufällig gesetzt         
                mov.b #BIT0, &P1DIR   ; nur P1.0 für rote LED als Ausgang konfigurieren (1=Out, 0=In), der Rest des Ports sind Eingänge (der Taster Button_S2 hängt an P1.1)
                mov.b #BIT1, &P1OUT   ; LED an Port 1.0 ist aus (P1.0=0), PullUp an Port 1.1 für den Button_S2 (P1.1=1)  
                mov.b #0x00, &P1SEL   ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
                mov.b #BIT1, &P1REN   ; aktiviere PullUp an P1.1 für Button_S2
                mov.b #0xff, &P1IES   ; alle Port 1 Interrupts werden auf negative Flanke getriggert (das ist so, weil die Taster auf dem LaunchPad nach Masse gehen)
                mov.b #Button_S2, &P1IE    ; Nur Taster "Button_S2" für Interrupt freigeben, alle anderen Interruptflags von Port 1 unterdrücken

Port_4          bis.b   #BIT7,&P4DIR            ; Port P4.7 als Ausgang konfigurieren für grüne LED 
                bis.b   #BIT4,&P4DIR            ; Port P4.4 als Ausgang konfigurieren für UART TxD (zum Senden serieller Daten über diesen Pin)  
                bis.b   #BIT7,&P4OUT            ; LED an Port 4.7 einschalten zu Programmbeginn (1 = "an")
                bis.b   #BIT4,&P4OUT            ; 1 = High = UART Idle State
                bis.b   #BIT4,&P4SEL            ; P4.4 nicht als normalen Port verwenden sondern an USCI-Modul (=UART) abgeben zum Senden (TxD)   
                bis.b   #BIT5,&P4SEL            ; P4.5 nicht als normalen Port verwenden sondern an USCI-Modul (=UART) abgeben zum Empfangen von Daten (RxD)        
                
                ;mehr ist bei Port 4 nicht nötig da sonst der Port nicht benutzt wird in diesem Programm
UART_A1_config  
                bis.b   #UCSWRST,&UCA1CTL1      ; Die UART in den Reset-Mode bringen um sie nachfolgend Konfigurieren zu können, siehe UserGuide Seite 894
                
                mov.b   #0x00, &UCA1CTL0        ; Betriebsart des UART: Asynchron, 8 Datenbits, 1 Stopbit, kein Paritybit, LSB zuerst senden/empfangen 
                bis.b   #UCSSEL1,&UCA1CTL1      ; SMCLK als Taktquelle auswählen
                mov.b   #109, &UCA1BR0          ; Lowbyte, Baudrate einstellen entsprechend Tabelle aus dem UserGuide    
                mov.b   #0, &UCA1BR1            ; Highbyte, Baudrate einstellen entsprechend Tabelle aus dem UserGuide    
                bis.b   #UCBRS1,&UCA1MCTL       ; Modulator einstellen entsprechend Tabelle aus dem UserGuide
                mov.b   #0x00, &UCA1STAT        ; alle möglichen Flags löschen
                mov.b   #0x00, &UCA1ABCTL       ; keine Auto-Baudrate-Detektion
                 
                bic.b   #UCSWRST,&UCA1CTL1      ; Die UART in den normalen Betrieb versetzen nachdem zuvor alles Konfiguriert wurde, siehe UserGuide Seite 894
                
                bis.b   #UCRXIE, &UCA1IE        ; Interrupt für die UART aktivieren: wenn ein Byte empfangen wurde (RxD-Interrupt), diese Zeile MUSS zwingend nach dem Reset des UART Moduls erfolgen, da sonst die aktivierten Interrupts wieder deaktiviert werden (siehe Example auf Seite 894 im UserGuide)
                
               
Register_Init   ; 
                mov.w   #0x00, R5               ; ASCII 0
                mov.w   #0x00, R6               ; ASCII 1
                mov.w   #0x00, R7               ; ASCII 2
                mov.w   #0x00, R8               ; ASCII 3
                mov.w   #0x00, R10              ; Sum
                
main                                            ; Mainloop
                nop
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                
                jmp     main                    ; Endlosschleife
                nop                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...

;+++ PORT1_ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                         
PORT1_ISR
                mov.w   #50000,R15  
Entprellen      dec.w   R15                     ; Decrement R15
                jnz     Entprellen              ; Springe zu Entprellen wenn R15 noch nicht 0 ist
                
                ; Senden eines Bytes
                mov.b   R5,&UCA1TXBUF           ; hier ein ASCII Zeichen senden per UART bei jedem Tastendruck, indem das zu sendende Byte in den Sendepuffer kopiert wird
                
                ; auf nächstes ASCII-Zeichen weiterzählen für nächsten Tastendruck
                inc R5                          ; R5 um 1 erhöhen = nächstes Zeichen aus der ASCII Tabelle in R5 laden, welches beim nächsten Tastendruck gesendet wir
                cmp.w   #0x3a, R5               ; prüfen ob maximaler Zählerstand für R5 erreicht wurde (es sollen ja nur die Zeichen 0...9 gesendet werden)        
                jnz Nicht_zu_Null_ruecksetzen   ; falls maximaler Zählerstand nicht erreicht wurde: R5 nicht zurücksetzen auf 0x30 = ASCII-"0"
                mov.w   #0x30, R5               ; falls maximaler Zählerstand erreicht wurde: R5 auf 0x30 rücksetzen, dann wird beim nächsten Tastendruck wieder die ASCII-"0" gesendet        
Nicht_zu_Null_ruecksetzen                
                
                
                bic.b   #Button_S2, &P1IFG      ; das gesetzte Interruptflag löschen, sonst würde ISR sofort wieder neu ausgelöst werden
               
                reti    ; eine Interruptroutine muss immer mit dem Befehl reti abgeschlossen werden
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;+++ UART_RxD_ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UART_RxD_ISR    nop
                mov.b   &UCA1RXBUF, R5      ; Save ASCII 0 in R5

                CLRZ
                cmp.b   #0x0A,R5            ; Test if Rx=R5 is LF
                JZ      CALC                ; JMP if it was LF
                sub.b   #0x30,R5            ; if not, Convert ASCII in Number
               
WAITUART        bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 1
                JZ      WAITUART
               
                mov.b   &UCA1RXBUF,R6       ; Save ASCII 1 in R6
                CLRZ
                cmp.b   #0x0A,R6            ; Test if Rx=R6 is LF
                JZ      CALC                ; JMP if it was
                sub.b   #0x30,R6            ; if not, Convert ASCII in Number
  
WAITUART2       bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 2
                JZ      WAITUART2
               
                mov.b   &UCA1RXBUF, R7      ; Save ASCII 2 in R7
                CLRZ
                cmp.b   #0x0A,R7            ; Test if Rx=R7 is LF
                JZ      CALC                ; JMP if it was
                sub.b   #0x30,R7            ; if not, Convert ASCII in Number

WAITUART3       bit.b   #UCRXIFG, &UCA1IFG; Wait for ASCII 3
                JZ      WAITUART3
               
                mov.b   &UCA1RXBUF, R8      ; Save ASCII 3 in R8
                CLRZ
                cmp.b   #0x0A,R8            ; Test if Rx=R8 is LF
                JZ      CALC                ; JMP if it was
                sub.b   #0x30,R8            ; if not, Convert ASCII in Number


; Calculation: add the input numbers to R10

; Case distinction: how many digits? Choose register appropriately
CALC            nop
                cmp.b   #0x0A,R8            ; Test if R8 is LF
                JZ      THREEDIGITS         ; 
                
                cmp.b   #0x0A,R7            ; Test if R7 is LF
                JZ      TWODIGITS
                
                cmp.b   #0x0A,R6            ; Test if R6 is LF
                JZ      ONEDIGIT
                
                cmp.b   #0x0A,R5            ; Test if R5 is LF
                JZ      OUTPUT              ; no input, suspend calculation




THREEDIGITS     ; 3 digits input
                add     R7, R10             ; add unit to R10

                CLRZ
                mov.B   #10, R15            ; repeat ten times
TEN1            add     R6, R10             ; add tens to R10    
                dec     R15
                JNZ     TEN1
                
                CLRZ
                mov.B   #100, R15           ; repeat hundred times
HUNDERTER       add     R5, R10             ; add hundred  to R10
                dec     R15
                JNZ     HUNDERTER 
                
                JMP     OUTPUT              ; Calculation finished


TWODIGITS       ; 2 digits input
                add     R6, R10             ; add unit to R10

                CLRZ
                mov.B   #10, R15            ; repeat ten times
TEN2            add     R5, R10             ; add tens to R10
                dec     R15
                JNZ     TEN2
                
                JMP     OUTPUT              ; Calculation finished
                
ONEDIGIT        ; 1 digit input
                add     R5, R10             ; add unit to R10

                JMP     OUTPUT


; output the entered number in bits by shifting the register R10

OUTPUT          mov.B   #0, R14             ; as long as zero until the first one has been output
                CLRZ
                mov.B   #16, R15            ; set count for the output of 16 bit
LOOP            
                RLC.W   R10                 ; push the left bit into the carry 

                ; case distinction: Carry bit = 0 or 1
                JC      ONE                     
                JMP     ZERO
                reti
                
; Carry bit is zero
ZERO            CLRZ
                cmp.b   #0, R14                 ; check if ever entered a one
                JZ      wait_for_byte1          ; in not, no output. Jump to next bit

                mov.b   #0x30,&UCA1TXBUF        ; copy an ASCII 0 into the UART send buffer
wait_for_byte1  bit.b   #UCTXIFG,&UCA1IFG       ; test if TX interrupt flag is set. Wait until UCTXIFG = 1
                jz      wait_for_byte1
                
                CLRZ
                dec     R15                     ; decrease bit counter 
                JZ      LF                      ; Output LF if bit counter is zero
                JMP     LOOP                    ; if not, repeat

; Carry bit is one
ONE             
                mov.b   #0x31,&UCA1TXBUF        ; copy an ASCII 1 into the UART send buffer
wait_for_byte2  bit.b   #UCTXIFG,&UCA1IFG       ; test if TX interrupt flag is set. Wait until UCTXIFG = 1
                jz      wait_for_byte2
                
                mov.B   #1, R14                 ; a one was entered, print next zeros
                CLRZ
                dec     R15                     ; decrease bit counter 
                JZ      LF                      ; Output LF if bit counter is zero
                JMP     LOOP                    ; if not, repeat
                
; output ends, send LF
LF              
                mov.b   #0x0A,&UCA1TXBUF        ; copy an ASCII "LF" into the UART send buffer
wait_for_byte3  bit.b   #UCTXIFG,&UCA1IFG       ; test if TX interrupt flag is set. Wait until UCTXIFG = 1
                jz      wait_for_byte3
                JMP     Register_Init           ; Jump to initialization, reset program and repeat
                
                reti
                

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET                   
            
            ORG     0FFDEh                  ;Interrupt Vektor für die Flags in Register P1IFG
            DW      PORT1_ISR               ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            ORG     0FFDCh                  ;Interrupt Vektor für die Flags UCA1RXIFG, UCA1TXIFG (USCI_A1 Receive or Transmit Interrupt)
            DW      UART_RxD_ISR            ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            END