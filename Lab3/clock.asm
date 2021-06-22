
#include "msp430f5529.h"

;-------------------------------------------------------------------------------
main            ORG     04400h                   ; Progam Start, Adresse aus Tabelle im Datenblatt Seite 22, rechte Spalte (für MSP430F5529)
;-------------------------------------------------------------------------------
RESET           mov.w   #04400h,SP               ; Stackpointer initialisieren, der Stack wächst von oben nach unten !

StopWDT         mov.w   #WDTPW+WDTHOLD,&WDTCTL   ; Watchdog Timer anhalten

; +++ Konfiguration der IO-Ports und der Port-Interrupts +++

Port_1
                mov.b #0x00, &P1IFG   ; Alle P1-IFG's löschen, falls zufällig gesetzt         
                mov.b #BIT0, &P1DIR   ; nur P1.0 für rote LED als Ausgang konfigurieren (1=Out, 0=In), der Rest des Ports sind Eingänge (der Taster Button_S2 hängt an P1.1)
                mov.b #BIT1, &P1OUT   ; LED an Port 1.0 ist aus (P1.0=0), PullUp an Port 1.1 für den Button_S2 (P1.1=1)  
                mov.b #0x00, &P1SEL   ; kompletter Port P1 als normaler IO-Port verfügbar, nichts wird an andere Peripherie abgegeben
            

Port_4          bis.b   #BIT7,&P4DIR            ; Port P4.7 als Ausgang konfigurieren für grüne LED 
                bis.b   #BIT4,&P4DIR            ; Port P4.4 als Ausgang konfigurieren für UART TxD (zum Senden serieller Daten über diesen Pin)  
                bis.b   #BIT7,&P4OUT            ; LED an Port 4.7 einschalten zu Programmbeginn (1 = "an")
                bis.b   #BIT4,&P4OUT            ; 1 = High = UART Idle State
                bis.b   #BIT4,&P4SEL            ; P4.4 nicht als normalen Port verwenden sondern an USCI-Modul (=UART) abgeben zum Senden (TxD)   
                bis.b   #BIT5,&P4SEL            ; P4.5 nicht als normalen Port verwenden sondern an USCI-Modul (=UART) abgeben zum Empfangen von Daten (RxD)

UART_A1_config  
                bis.b   #UCSWRST,&UCA1CTL1      ; Die UART in den Reset-Mode bringen um sie nachfolgend Konfigurieren zu können, siehe UserGuide Seite 894
                
                mov.b   #0x00, &UCA1CTL0        ; Betriebsart des UART: Asynchron, 8 Datenbits, 1 Stopbit, kein Paritybit, LSB zuerst senden/empfangen 
                bis.b   #UCSSEL1,&UCA1CTL1      ; SMCLK als Taktquelle auswählen
                mov.b   #109, &UCA1BR0          ; Lowbyte, Baudrate einstellen entsprechend Tabelle aus dem UserGuide    
                mov.b   #0, &UCA1BR1            ; Highbyte, Baudrate einstellen entsprechend Tabelle aus dem UserGuide    
                bis.b   #UCBRS1,&UCA1MCTL       ; Modulator einstellen entsprechend Tabelle aus dem UserGuide
                mov.b   #0x00, &UCA1STAT        ; alle möglichen Flags löschen
                mov.b   #0x00, &UCA1ABCTL       ; keine Auto-Baudrate-Detektion
                 
                bic.b   #UCSWRST,&UCA1CTL1      ;Die UART in den normalen Betrieb versetzen nachdem zuvor alles Konfiguriert wurde, siehe UserGuide Seite 894
                
                bis.b   #UCRXIE, &UCA1IE        ; Interrupt für die UART aktivieren: wenn ein Byte empfangen wurde (RxD-Interrupt), diese Zeile MUSS zwingend nach dem Reset des UART Moduls erfolgen, da sonst die aktivierten Interrupts wieder deaktiviert werden (siehe Example auf Seite 894 im UserGuide)

                mov.b   #0x00,R15             ; bereits eigegebene Ziffern
                mov.b   #0x30, R10              ; Stunde Ziffer 1
                mov.b   #0x30, R9               ; Stunde Ziffer 2
                mov.b   #0x30, R8               ; Minute Ziffer 1        
                mov.b   #0x30, R7               ; Minute Ziffer 2  
                mov.b   #0x30, R6               ; Sekunde Ziffer 1
                mov.b   #0x30, R5               ; Sekunde Ziffer 2

               
                
             
; +++ Mainloop +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Mainloop        
                nop
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                mov.b   #0x00,&UCA1IFG          ; alle Interruptflags löschen, falls zufällig gesetzt

                cmp #0x04,R15                   ; wenn alle Zahlen eingegeben wurden
                jz  taktaktiv                   ; stell  den Timer ein
                jmp Mainloop

taktaktiv
                mov.w   #TASSEL0+MC0,&TA0CTL    ; ACLK=32,768 kHz als Taktquelle, Up-Mode (zählt von 0x0000 bis TA0CCR0), hier keinen Interrupt aktivieren --> es wird NICHT der TAIFG genutzt in diesem Beispiel, sondern der TA0CCRO-Interrupt !!! 
                mov.w   #CCIE,&TA0CCTL0         ; aktiviere TA0CCR0-Capture/Compare Interrupt (wird immer ausgelöst, wenn der Timer_A bis zu dem Wert in Register TA0CCR0 hochgezählt hat)        
                mov.w   #32768,&TA0CCR0         ; bis zu diesem Wert wird hochgezählt, dann gibt es einen ersten Interrupt und der Timer beginnt automatisch wieder bei Null zu zählen (32768 entsprechen 1s bei 32,768 kHz Zählfrequenz)

                jmp Mainloop
                
**********************************************************************************************************************************************
;+++ UART_RxD_ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UART_RxD_ISR    mov.w   #TACLR, &TA0CTL          ; Timer stoppen

                cmp     #0x0000,R15             ; Fallunterscheidung
                jz      Std1                    ; Welche Ziffer soll eingegeben werden?
                cmp     #0x0001,R15
                jz      Std2
                cmp     #0x0002,R15
                jz      Min1
                cmp     #0x0003,R15
                jz      Min2
                cmp     #0x0004,R15
                jz      NEU
                reti


NEU             mov     #0x00, R15              ; Counter zurücksetzten wenn mehr als 4 Zeichen eingegeben wurden
                JMP     UART_RxD_ISR
                
Std1             
                mov.b   &UCA1RXBUF, R10         ;Empfangspuffer auslesen --> diese Aktion setzt das Interrupt Flag automatisch zurück
                inc R15
                

                cmp.b   #0x30,R10               ; empfangenes Zeichen im Erlaubten bereich?
                jl RESETStd1                    ; Zeichen ist kleiner als "0"
             
                cmp.b   #0x33,R10               ; empfangenes Zeichen im Erlaubten bereich?
                jge RESETStd1                   ; Zeichen ist größer als "2"
                
                reti   

RESETStd1       mov.b   '0', R10                ; Eingabe rückgängig machen
                dec R15
                reti
                
Std2             
                mov.b   &UCA1RXBUF, R9          ;Empfangspuffer auslesen --> diese Aktion setzt das Interrupt Flag automatisch zurück
                inc R15
                

                cmp.b   #0x30,R9                ; empfangenes Zeichen im Erlaubten bereich?
                jl RESETStd2                    ; Zeichen ist kleiner als "0"
             
                cmp.b   #0x34,R9                ; empfangenes Zeichen im Erlaubten bereich?
                jge RESETStd2                   ; Zeichen ist größer als "3"

                reti   

RESETStd2       mov.b   '0', R9                 ; Eingabe rückgängig machen
                dec R15
                reti
                
Min1             
                mov.b   &UCA1RXBUF, R8          ;Empfangspuffer auslesen --> diese Aktion setzt das Interrupt Flag automatisch zurück
                inc R15
                

                cmp.b   #0x30,R8                ; empfangenes Zeichen im Erlaubten bereich?
                jl RESETMin1                    ; Zeichen ist kleiner als "0"
             
                cmp.b   #0x36,R8                ; empfangenes Zeichen im Erlaubten bereich?
                jge RESETMin1                   ; Zeichen ist größer als "5"

                reti   

RESETMin1       mov.b   '0', R8                 ; Eingabe rückgängig machen
                dec R15
                reti
                
                
Min2             
                mov.b   &UCA1RXBUF, R7          ;Empfangspuffer auslesen --> diese Aktion setzt das Interrupt Flag automatisch zurück
                inc R15
                

                cmp.b   #0x30,R7                ; empfangenes Zeichen im Erlaubten bereich?
                jl RESETMin2                    ; Zeichen ist kleiner als "0"
             
                cmp.b   #0x3A,R7                ; empfangenes Zeichen im Erlaubten bereich?
                jge RESETMin2                   ; Zeichen ist größer als "9"

                reti   

RESETMin2       mov.b   '0', R7                 ; Eingabe rückgängig machen
                dec R15
                reti
                
WEITER
                reti
                
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



***********************************************************************************************************************************************
;+++ TIMER_A0_CCR0ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TIMER_A0_CCR0ISR

                inc     R5                      ; R5 um 1 pro Sekunde erhöhen
                
ersteSekZiffer  
                cmp     #0x3A,R5                ; Wenn erste Sekundenziffer über 9 zählt
                jge     zweiteSekZiffer         ; spring zur nächsten Ziffer
                jmp     Senden
                
zweiteSekZiffer
                mov.b   #0x30,R5                ; erste Ziffer auf Null
                inc     R6                      ; zweite Ziffer hochzählen
                cmp     #0x36,R6                ; Wenn zweite Ziffer über 6 zählt
                jz      ersteMinZiff            ; spring zur Minutenziffer
                jmp     Senden
                
ersteMinZiff
                mov.b   #0x30,R6                ; Sekunden auf Null
                inc     R7                      ; erste Minutenziffer hochzählen
                cmp     #0x3A,R7                ; Vergleiche ob erste Ziffer über 9
                jz      zweiteMinZiff           ; spring zur zweiten Ziffer
                jmp     Senden
                
zweiteMinZiff
                mov.b   #0x30,R7                ; erste Minutenziffer auf Null
                inc     R8                      ; zweite Minutenziffer erhöhen
                cmp     #0x36,R8                ; Wenn 60min erreicht
                jz      ersteStdZiff            ; spring zur Stundenziffer
                jmp     Senden

ersteStdZiff
                mov.b   #0x30,R8                ; Minuten auf Null
                inc     R9                      ; erste Stundenziffer hochzählen
                cmp     #0x3A,R9                ; Wenn erste Ziffer über 9
                jz      zweiteStdZiff           ; spring zur zweiten Ziffer
                jmp     midnightcheck

zweiteStdZiff
                mov.b   #0x30,R9                ; erste Ziffer auf Null
                inc     R10                     ; zweite Ziffer erhöhen
                cmp     #0x32,R10               ; prüfe ob >20 Stunden
                jz      midnightcheck
                
                jmp     Senden
                
                
midnightcheck   cmp     #0x32,R10               ; prüfe ob 2X Uhr
                jz      midnight1               ; >20h
                jmp     Senden                  ; sonnst Senden

midnight1       cmp     #0x34,R9                ; prüfe ob 24 Uhr
                jz      midnight2               ; 24h erreicht 
                jmp     Senden                  ; sonnst Senden

midnight2       mov.b   #0x30,R10               ; Stunden zurücksetzen
                mov.b   #0x30,R9
                jmp     Senden
                
                
Senden          call    #uhrzeitsenden          ; Sende aktuelle Zeit via UART
      
                reti

;+++++++Funktionen++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
uhrzeitsenden   bit     #TAIFG, &TA0CTL         ; teste ob TimeA interrupt flag gesetzt ist
                jz      uhrzeitsenden           ; so lange warten bis das Timer interrupt beendet wurde
                
                mov.b   R10, &UCA1TXBUF           ; Sende Stunde (2. Stelle)
                call    #warten_tx                ; warten, bis es gesendet wurde
                mov.b   R9, &UCA1TXBUF            ; Sende Stunde (1. Stelle)
                call    #warten_tx
                mov.b   #0x3A, &UCA1TXBUF         ; Sende ein : 
                call    #warten_tx
                mov.b   R8, &UCA1TXBUF            ; Sende Minute (2. Stelle)
                call    #warten_tx
                mov.b   R7, &UCA1TXBUF            ; Sende Minute (1. Stelle)
                call    #warten_tx
                mov.b   #0x3A, &UCA1TXBUF         ; Sende ein : 
                call    #warten_tx
                mov.b   R6, &UCA1TXBUF            ; Sende Sekunde (2. Stelle)
                call    #warten_tx
                mov.b   R5, &UCA1TXBUF            ; Sende Sekunde (1. Stelle)
                call    #warten_tx
                mov.b   #0x0A,&UCA1TXBUF          ; sende ein "LF"
                call    #warten_tx
                RET                               ; raus aus der unterfunktion


warten_tx
wait_for_byte1  bit.b   #UCTXIFG,&UCA1IFG       ; teste ob das Bit UCTXIFG (= Interruptflag für TxD) gesetzt ist --> dann wäre die UART bereit für das nächste zu sendende Byte!
                jz      wait_for_byte1          ; so lange warten (in Schleife "wait_for_byte1") bis das erste Byte komplett gesendet wurde, dann erst das nächste Byte in den Sendepuffer kopieren
                RET


;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET
            
            ORG     0FFDCh                  ;Interrupt Vektor für die Flags UCA1RXIFG, UCA1TXIFG (USCI_A1 Receive or Transmit Interrupt)
            DW      UART_RxD_ISR            ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            ORG     0FFEAh                  ;Interrupt Vektor für das Flag CCIFG0 im Register TA0CCTL0 (dieses Flag wird gesetzt, wenn der Timer_A0 bis zu TA0CCR0 hochgezählt hat)
            DW      TIMER_A0_CCR0ISR        ;die Interrupt Vektor Adresse 0xFFEA steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            END