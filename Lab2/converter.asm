;***************************************************************************************************************
;   UART Converter
;
;   Über UART wird eine Zahl zwischen 1 und 999 eingelesen und in Binär sowie in römischen Zahlen wieder ausgegeben. 
;   Dabei wird außerdem die Zeit zum umrechnen in Binär gemessen.
;
;   Johannes Wilhelm
;   Hochschule Mannheim
;   Built with IAR Embedded Workbench
;****************************************************************************************************************


#include "msp430f5529.h"

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
                mov.w   #0x00, R4               ; UART TX
                mov.w   #0x00, R5               ; UART RX hundres
                mov.w   #0x00, R6               ; UART RX tens
                mov.w   #0x00, R7               ; UART RX ones
                mov.w   #0x00, R8               ; UART RX LF
                mov.w   #0x00, R10              ; sum
                mov.w   #0x00, R14              ; working memory
                mov.w   #0x00, R15              ; counter

main                                            ; Mainloop
                nop
                BIS.W #GIE, SR                  ; global Interruptsystem aktivieren
                nop
                jmp     main                    
                nop                             ; sinnloser letzter Befehl, damit der IAR Simulator nicht meckert...

;+++ UART_RxD_ISR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UART_RxD_ISR    nop
                
                
                ; Read 1-3 digits via UART in R5-R7

UARTRX          mov.b   &UCA1RXBUF, R5     ; Save ASCII 0 in R5

                CLRZ
                cmp.b   #0x0A,R5            ; Test if Rx=R5 is LF
                JZ      OVER                ; Finish RX if it was
                sub.b   #0x30,R5            ; if not, Convert ASCII in Number
               
WAITUART        bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 1
                JZ      WAITUART
               
                mov.b   &UCA1RXBUF,R6       ; Save ASCII 1 in R6
                CLRZ
                cmp.b   #0x0A,R6            ; Test if Rx=R6 is LF
                JZ      OVERONE             ; Finish RX if it was
                sub.b   #0x30,R6            ; if not, Convert ASCII in Number
  
WAITUART2       bit.b   #UCRXIFG, &UCA1IFG  ; Wait for ASCII 2
                JZ      WAITUART2
               
                mov.b   &UCA1RXBUF, R7      ; Save ASCII 2 in R7
                CLRZ
                cmp.b   #0x0A,R7            ; Test if Rx=R7 is LF
                JZ      OVERTWO             ; JMP if it was
                sub.b   #0x30,R7            ; if not, Convert ASCII in Number

WAITUART3       bit.b   #UCRXIFG, &UCA1IFG; Wait for ASCII 3
                JZ      WAITUART3
               
                mov.b   &UCA1RXBUF, R8      ; Save ASCII 3 in R8
                CLRZ
                cmp.b   #0x0A,R8            ; Test if Rx=R8 is LF
                JZ      OVERTHREE           ; JMP if it was
                reti                        ; too many characters, exit interrupt


OVERONE         mov.b   #0x00,R6            ; Remove LF
                mov.b   R5,R7               ; write ones in right register R7
                mov.b   #0x00, R5           ; delete hunreds
                JMP     OVER

OVERTWO         mov.b   #0x00,R7            ; Remove LF
                mov.b   R6,R7               ; write ones in right register R7
                mov.b   R5,R6               ; write tens in right register R6

                mov.b   #0x00, R5           ; delete hunreds
                JMP     OVER

OVERTHREE       mov.b   #0x00,R8            ; Remove LF
                JMP     OVER

OVER                                        ; end of UART RX


                mov.w   #TACLR+TASSEL1+MC1,&TA0CTL  ; Reset Timer and start to count ( SMCTL=1,048 Mhz, Continuous-Mode )
                CALL    #CALC                       ; Add the digits according to the decimal system and store the result in R10
                bic     #BIT5, &TA0CTL              ; stop Timer (Continuous-Mode -> Stop-mode)

                mov.w   R10, R14
                CALL    #BINPRINT                   ; output the binary number in R14 via UART in ASCII

                mov.b   #0x2B ,R4                   ; send ASCII + via UART
                CALL    #SENDUART

                mov.w   R10, R14                
                CALL    #ROMANPRINT                 ; output R14 in roman numbers

                mov.b   #0x2B ,R4                   ; send ASCII + via UART
                CALL    #SENDUART

                CALL    #TIMER_PRINT                ; output the counted time [us] for calculation via UART in ASCII

                mov.b   #0x0A ,R4                   ; send ASCII LF via UART
                CALL    #SENDUART

                JMP     Register_Init               ; Jump to initialization, reset program and repeat

                reti

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;+++ Functions +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


; calculation: add the entered number according to the decimal number system to R10
CALC            nop

ONES            add     R7, R10                     ; add ones to R10

TENS            cmp     #0x00, R6                   ; check if tens exist
                JZ      HUNDREDS                    ; Jump if tens in R8 are zero 
                mov.B   #10, R15                    ; repeat ten times
LOOPTENS        add     R6, R10                     ; add tens to R10
                dec     R15
                JNZ     LOOPTENS

HUNDREDS        cmp     #0x00, R5                   ; check if tens exist
                JZ      FINISH                      ; Jump if tens in R8 are zero 
                mov.B   #100, R15                   ; repeat ten times
LOOPHUNDREDS    add     R5, R10                     ; add tens to R10
                dec     R15
                JNZ     LOOPHUNDREDS

FINISH          RET


 ; binary print: Sends the bits in R14 one after the other via UART in ASCII
BINPRINT        nop
                mov.B   #17, R15                ; set count for the output of 16 bit
LOOP1           dec     R15
                JZ      FINISH                  ; finish if bit counter is zero
                RLC.W   R14                     ; push the left bit into the carry 
                JNC     LOOP1
                
                mov.b   #0x31, R4               ; print the first 1 in ASCII via UART
                CALL    #SENDUART

LOOP2           dec     R15                     ; decrease bit counter 
                JZ      FINISH1                 ; finish if bit counter is zero
                RLC.W   R14                     ; Slide the left bit into the carry
                JC      ONE                     ; Case distinction: Carry = 0 or 1
                
ZERO            mov.b   #0x30, R4               ; if zero, print 0
                CALL    #SENDUART
                JMP     LOOP2
                
ONE             mov.b   #0x31, R4               ; if one, print 1
                CALL    #SENDUART
                JMP     LOOP2
                
FINISH1         RET


TIMER_PRINT                                     ; convert measured time value from binary to decimal and print it
                mov.w   TA0R, R14               ; copy time value in R14
                mov.w   #0x00, R15              ; initialization counter

CALCHUNDREDS    sub     #100, R14               ; divide Number in R14 by 100
                JN      SENDHUNDRED
                inc     R15                     ; Store the result in R15 
                JMP     CALCHUNDREDS
                
SENDHUNDRED     cmp     #0x00, R15              ; if zero, skip print
                JZ      CALCTENS

                add     #0x30, R15              ; convert Number in ASCII
                mov.b   R15 ,R4                 ; Print result
                CALL    #SENDUART
                
CALCTENS        mov.w   #0x00, R15              ; reset counter
                add     #100, R14
LOOP_T          sub     #10, R14                ; divide rest of the last division in R14 by 10
                JN      SENDTENS
                inc     R15                     ; store the result in R15 
                JMP     LOOP_T    
                
SENDTENS        cmp     #0x00, R15              ; if zero, skip print
                JZ      CALCONES
                
                add     #0x30, R15              ; convert Number in ASCII
                mov.b   R15 ,R4                 ; Print result
                CALL    #SENDUART
                
CALCONES        add     #10, R14                ; rest of the last division

SENDONES        add     #0x30, R14              ; convert Number in ASCII
                mov.b   R14 ,R4                 ; Print ones
                CALL    #SENDUART
                           
                
SENDUNIT        mov.b   #0x75 ,R4               ; print Unit (u)
                CALL    #SENDUART
                
                mov.b   #0x73 ,R4               ; print Unit (s)
                CALL    #SENDUART
                
                RET


; Print R14 in roman

ROMANPRINT      

PCM             nop                     
LOOPM           sub     #900, R14       ; Divide the number in R14 by 900
                JN      RD              
                
                mov.b   #0x43 ,R4       ; Print a "CM" as many times as 900 fits in the number R14
                CALL    #SENDUART
                mov.b   #0x4D ,R4
                CALL    #SENDUART
                JMP     LOOPM           

RD              add     #900, R14       ; Add 900 from the last value so that the number is not negative.
LOOPD           sub     #500, R14       ; Divide the number in R14 by 500
                JN      RCD
                
                mov.b   #0x44 ,R4       ; Print a "D" as many times as 500 fits in the number R14
                CALL    #SENDUART
                JMP     LOOPD

RCD             add     #500, R14       ; Repeat the process to the smallest unit in the roman number system
LOOPCD          sub     #400, R14
                JN      RC
                
                mov.b   #0x43 ,R4
                CALL    #SENDUART
                mov.b   #0x44 ,R4
                CALL    #SENDUART
                JMP     LOOPCD

RC              add     #400, R14
LOOPC           sub     #100, R14
                JN      RXC
                
                mov.b   #0x43 ,R4
                CALL    #SENDUART
                JMP     LOOPC
                
RXC             add     #100, R14
LOOPXC          sub     #90, R14
                JN      RL
                
                mov.b   #0x58 ,R4
                CALL    #SENDUART
                mov.b   #0x43 ,R4
                CALL    #SENDUART
                JMP     LOOPXC
                
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