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


Port_4          bis.b   #BIT4,&P4DIR            ; Port P4.4 als Ausgang konfigurieren für UART TxD (zum Senden serieller Daten über diesen Pin)  
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
                 
                bic.b   #UCSWRST,&UCA1CTL1      ; Die UART in den normalen Betrieb versetzen nachdem zuvor alles Konfiguriert wurde, siehe UserGuide Seite 894
                
                bis.b   #UCRXIE, &UCA1IE        ; Interrupt für die UART aktivieren: wenn ein Byte empfangen wurde (RxD-Interrupt), diese Zeile MUSS zwingend nach dem Reset des UART Moduls erfolgen, da sonst die aktivierten Interrupts wieder deaktiviert werden (siehe Example auf Seite 894 im UserGuide)
                
               
Register_Init   ; 
                mov.w   #0x00, R5               ; ASCII 0
                mov.w   #0x00, R6               ; ASCII 1
                mov.w   #0x00, R7               ; ASCII 2
                mov.w   #0x00, R8               ; ASCII 3
                mov.w   #0x00, R10              ; Sum
                mov.w   #0x00, R13              ; Timer

                
                
                
main                                            ; Mainloop
                nop
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                
                jmp     main                    ; Endlosschleife
                nop                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...

;+++ UART_RxD_ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UART_RxD_ISR    nop
                
                
                ; Read 1-4 digits via UART in R5-R8
                ; read UART input buffer for 3 ASCII in R5 - R8

UARTRX          mov.b   &UCA1RXBUF, R5      ; Save ASCII 0 in R5

                CLRZ
                cmp.b   #0x0A,R5            ; Test if Rx=R5 is LF
                JZ      OVER                ; JMP if it was
                sub.b   #0x30,R5            ; if not, Convert ASCII in Number
               
WAITUART        bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 1
                JZ      WAITUART
               
                mov.b   &UCA1RXBUF,R6       ; Save ASCII 1 in R6
                CLRZ
                cmp.b   #0x0A,R6            ; Test if Rx=R6 is LF
                JZ      OVER                ; JMP if it was
                sub.b   #0x30,R6            ; if not, Convert ASCII in Number
  
WAITUART2       bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 2
                JZ      WAITUART2
               
                mov.b   &UCA1RXBUF, R7      ; Save ASCII 2 in R7
                CLRZ
                cmp.b   #0x0A,R7            ; Test if Rx=R7 is LF
                JZ      OVER                ; JMP if it was
                sub.b   #0x30,R7            ; if not, Convert ASCII in Number

WAITUART3       bit.b   #UCRXIFG, &UCA1IFG; Wait for ASCII 3
                JZ      WAITUART3
               
                mov.b   &UCA1RXBUF, R8      ; Save ASCII 3 in R8
                CLRZ
                cmp.b   #0x0A,R8            ; Test if Rx=R8 is LF
                JZ      OVER                ; JMP if it was
                sub.b   #0x30,R8            ; if not, Convert ASCII in Number
OVER


                mov.w   #TACLR+TASSEL1+MC1,&TA0CTL   ; Reset Timer and start to count ( SMCTL=1,048 Mhz, Continuous-Mode )
                CALL    #CALC                   ; Add the digits according to the decimal system and store the result in R10
                mov.w   TA0R, R13               ; store time count in R13

                mov.B   R10, R14
                CALL    #BINPRINT               ; output the binary number in R10 via UART in ASCII
          
                mov.b   #0x2B ,R4               ; send ASCII + via UART
                CALL    #SENDUART
                
                mov.B   R10, R14
                CALL    #ROMANPRINT
                
                mov.b   #0x2B ,R4               ; send ASCII + via UART
                CALL    #SENDUART

                CALL    #TIMER_PRINT            ; output the counted time [us] for calculation via UART in ASCII
                
                mov.b   #0x0A ,R4               ; send ASCII LF via UART
                CALL    #SENDUART
                
                JMP     Register_Init           ; Jump to initialization, reset program and repeat
                
                reti
                

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


; Calculation: add the input numbers to R10


CALC            nop
                ; Case distinction: how many digits? Choose register appropriately
                cmp.b   #0x0A,R8            ; Test if R8 is LF
                JZ      THREEDIGITS         ; 
                
                cmp.b   #0x0A,R7            ; Test if R7 is LF
                JZ      TWODIGITS
                
                cmp.b   #0x0A,R6            ; Test if R6 is LF
                JZ      ONEDIGIT
                
                
                cmp.b   #0x0A,R5            ; Test if R5 is LF
                RET                         ; no input, suspend calculation

THREEDIGITS                                 ; 3 digits input
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
                
                RET                         ; Calculation finished


TWODIGITS                                   ; 2 digits input
                add     R6, R10             ; add unit to R10

                CLRZ
                mov.B   #10, R15            ; repeat ten times
TEN2            add     R5, R10             ; add tens to R10
                dec     R15
                JNZ     TEN2
                
                RET                         ; Calculation finished
                
ONEDIGIT                                    ; 1 digit input
                add     R5, R10             ; add unit to R10

                RET
                

BINPRINT        mov.B   #17, R15            ; set count for the output of 16 bit
LOOP1           dec     R15
                JZ      FINISH              ; finish if bit counter is zero
                RLC.W   R14                 ; push the left bit into the carry 
                JNC     LOOP1
                
                mov.b   #0x31, R4
                CALL    #SENDUART
                
LOOP2           dec     R15                     ; decrease bit counter 
                JZ      FINISH                  ; finish if bit counter is zero
                RLC.W   R14
                JC      ONE
                
ZERO            mov.b   #0x30, R4
                CALL    #SENDUART
                JMP     LOOP2
                
ONE             mov.b   #0x31, R4
                CALL    #SENDUART
                JMP     LOOP2
                
FINISH          RET
           
                

; Print R14 in roman

ROMANPRINT      

LOOPC           sub     #100, R14
                JN      RXC
                
                mov.b   #0x43 ,R4
                CALL    #SENDUART
                JMP     LOOPC
                
RXC             add     #100, R14
LOOXC           sub     #90, R14
                JN      RL
                
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                mov.b   #0x43 ,R4
                CALL    #SENDUART
                JMP     LOOXC
                
RL              add     #90, R14
LOOPRL          sub     #50, R14
                JN      RXL
                
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                JMP     LOOPRL
                
RXL             add     #50, R14
LOOPXL          sub     #40, R14
                JN      RX
                
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                mov.b   #0x4C ,R4
                CALL    #SENDUART
                JMP     LOOPXL
                
RX              add     #40, R14
LOOPL           sub     #10, R14
                JN      RIX
                
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                JMP     LOOPL
                
RIX             add     #10, R14
LOOPIX          sub     #9, R14
                JN      RV
                
                mov.b   #0x49 ,R4
                CALL    #SENDUART
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                JMP     LOOPIX
                
RV              add     #9, R14
LOOPV           sub     #5, R14
                JN      RIV
                
                mov.b   #0x56 ,R4
                CALL    #SENDUART
                JMP     LOOPV
                
RIV             add     #5, R14
LOOPIV          sub     #4, R14
                JN      RI
                
                mov.b   #0x49 ,R4
                CALL    #SENDUART
                mov.b   #0x56 ,R4
                CALL    #SENDUART
                JMP     LOOPIV
                
RI              add     #4, R14
LOOPI           dec     R14
                JN      FINISH2
                
                mov.b   #0x49 ,R4
                CALL    #SENDUART
                JMP     LOOPI
                
FINISH2         RET
                

                
TIMER_PRINT     ; convert measured time value from binary to decimal and print it
                mov.w   #0x00, R15              ; Counter

CALCHUNDREDS    sub     #100, R13
                JN      SENDHUNDRED
                inc     R15
                JMP     CALCHUNDREDS
                
SENDHUNDRED     cmp     #0x00, R15              ; if zero, skip
                JZ      CALCTENS

                add     #0x30, R15
                mov.b   R15 ,R4
                CALL    #SENDUART
                
CALCTENS        mov.w   #0x00, R15              ; Counter
                add     #100, R13
LOOP_T          sub     #10, R13
                JN      SENDTENS
                inc     R15
                JMP     LOOP_T    
                
SENDTENS        cmp     #0x00, R15
                JZ      CALCONES
                
                add     #0x30, R15
                mov.b   R15 ,R4
                CALL    #SENDUART
                
CALCONES        mov.w   #0x00, R15
                add     #10, R13
LOOP_O          sub     #1, R13
                JN      SENDONES
                inc     R15
                JMP     LOOP_O 

SENDONES        add     #0x30, R15
                mov.b   R15 ,R4
                CALL    #SENDUART
                           
                
SENDUNIT        mov.b   #0x75 ,R4
                CALL    #SENDUART
                
                mov.b   #0x73 ,R4
                CALL    #SENDUART
                
                RET
         
         
SENDUART        ; TX R4 via uART
                mov.b   R4 ,&UCA1TXBUF          ; copy an ASCII into the UART send buffer
wait_for_byte   bit.b   #UCTXIFG,&UCA1IFG       ; test if TX interrupt flag is set. Wait until UCTXIFG = 1
                jz      wait_for_byte
                RET

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP430 RESET Vector
            DW      RESET                   
            
            
            ORG     0FFDCh                  ;Interrupt Vektor für die Flags UCA1RXIFG, UCA1TXIFG (USCI_A1 Receive or Transmit Interrupt)
            DW      UART_RxD_ISR            ;die Interrupt Vektor Adresse 0xFFDE steht im Datenblatt des MSP430F5529 auf Seite 21 in der Tabelle
            
            END