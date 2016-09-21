;
; * pixdel6
; * Copyright 2016, Jacques Deschenes
; * 
; * This file is part of pixdel6 project.
; * 
; * ***  LICENCE ****
; * This program is free software; you can redistribute it and/or modify
; * it under the terms of the GNU General Public License as published by
; * the Free Software Foundation; either version 3 of the License, or
; * (at your option) any later version.
; * 
; * This program is distributed in the hope that it will be useful,
; * but WITHOUT ANY WARRANTY; without even the implied warranty of
; * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; * GNU General Public License for more details.
; * 
; * You should have received a copy of the GNU General Public License
; * along with this program; See 'copying.txt' in root directory of source.
; * If not, write to the Free Software Foundation,
; * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
; *  
; * to contact the author:  jd_temp@yahoo.fr
; * 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  pixdel6 est la sixième version de pixdel.
;  Cette version utilise le MCU PIC12F1572.
;  Le protocole de communication est différent. Il s'agit d'un protocole pour
;  dispositif attachés en chaîne que j'ai mis au point.
;  Contrairement au produit commercial WS8212b, chaque LED de la chaîne peut-être
;  contrôlée individuellement quelque soit sa position dans la chaîne sans qu'il
;  soit nécessaire d'envoyer une commande à chaque LED qui la précède.
;  L'idée est basée sur un compteur décrémenté. Chaque paquet de données envoyé
;  dans la chaîne débute par un compteur. Une LED accepte le paquet si le compteur
;  est à zéro sinon il décrémente le compteur et le transmet avec le reste du paquet
;  à la LED suivante. C'est donc la valeur initiale du compteur ainsi que la position 
;  dans la chaîne qui détermine quel LED accepte le paquet.  Ce protocole permet
;  donc de réduire la quantité d'information qu'il est nécessaire d'envoyer dans la chaîne.
;
;   Le PIC12F1572 possède 3 canaux PWM 16 bits et un périphérique EUSART.
;   Le EUSART est utilisé pour la communication et les 3 PWM pour le contrôle des
;   composantes RGB de la LED. Le paquet transmis est donc constitué de 7 octets
;	1 compteur 8 bits permettant de contrôler 255 pixdel6.
;       6 octets de contrôle de la couleur, 2 octets par composantes.
;   FORMAT DU PAQUET:
;   ------------------	    
;   COMPTEUR|Rh|Rl|Gh|Gl|Bh|Bl    
;   >>>> COMPTEUR=255 pour message de diffusion <<<<
;   Puisque le paquet est de taille fixe et qu'en plus le compteur détermine la cible,
;   il n'est pas nécessaire de faire une pose entre chaque commande comme c'est le cas
;   pour les WS8212b.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    include p12f1572.inc
    __config _CONFIG1, _FOSC_INTOSC&_WDTE_NSLEEP&_PWRTE_OFF&_MCLRE_ON&_CP_OFF&_BOREN_OFF&_CLKOUTEN_OFF
    __config _CONFIG2, _WRT_ALL&_PLLEN_ON&_STVREN_OFF&_LVP_OFF

    radix decimal

#define TX  RA4
#define RX  RA5
#define ROUGE_PIN RA2    ; PWM3
#define ROUGE_PWMDCL PWM3DCL ; rapport cyclique
#define ROUGE_PWMDCH PWM3DCH ; octet fort    
#define ROUGE_PWMPR PWM3PR ;période
#define ROUGE_PWMPH PWM3PH ; phase
#define ROUGE_PWMOF PWM3OF ; offset
#define ROUGE_PWMTMR PWM3TMR ; timer
#define ROUGE_PWMCON PWM3CON ; registre de contrôle
#define ROUGE_PWMCLKCON PWM3CLKCON  ; contrôle clock
#define ROUGE_PWMOFCON PWM3OFCON ; contrôle offset
#define ROUGE_PWMLDCON PWM3LDCON ; load control
#define ROUGE_PWMINTE PWM3INTE  ; activation interruption
#define ROUGE_PWMINTF PWM3INTF  ; indicateurs d'interruption    
#define VERT_PIN RA1  ; PWM1
#define VERT_PWMDCL PWM1DCL
#define VERT_PWMDCH PWM1DCH
#define VERT_PWMPR PWM1PR    
#define VERT_PWMPH PWM1PH ; phase
#define VERT_PWMOF PWM1OF ; offset
#define VERT_PWMTMR PWM1TMR ; timer
#define VERT_PWMCON PWM1CON ; registre de contrôle
#define VERT_PWMCLKCON PWM1CLKCON    
#define BLEU_PIN RA0   ; PWM2
#define BLEU_PWMDCL PWM2DCL
#define BLEU_PWMDCH PWM2DCH
#define BLEU_PWMPR PWM2PR
#define BLEU_PWMPH PWM2PH ; phase
#define BLEU_PWMOF PWM2OF ; offset
#define BLEU_PWMTMR PWM2TMR ; timer
#define BLEU_PWMCON PWM2CON
#define BLEU_PWMCLKCON PWM2CLKCON    
#define PWM_BANK PWMEN

#define FOSC 32000000
#define BAUD 115200 ;  57600, 38400

;;;;;;;;;;;;;;;;;;;;;;;;;
;   macros
;;;;;;;;;;;;;;;;;;;;;;;;;
    
popw  macro
    moviw FSR1--
    endm
 
pushw macro
    movwi ++FSR1
    endm

dup macro
    movfw INDF1
    pushw
    endm
    
drop macro
    addfsr FSR1,-1
    endm

case macro valeur, cible
    xorlw valeur
    skpnz
    bra cible
    xorlw valeur
    endm
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    udata
stack res 16
 
    udata_shr
data_cntr res 1
rouge res 2  ; high:low
vert  res 2
bleu  res 2
 
    org 0
rst:    
    goto init
    
    org 4
isr:
    retfie
    
init:
; clock à 32Mhz
    banksel OSCCON
    movlw (0xE<<IRCF0)
    movwf OSCCON
; Watch dog timer expire à 16 msec.
    banksel WDTCON
    clrf WDTCON
    bsf WDTCON,WDTPS2
;initialisation pointeur de pile
    movlw high stack
    movwf FSR1H
    movlw low stack
    movwf FSR1L
;désactivation entrées analogique
    banksel ANSELA
    clrf ANSELA
;réglage APFCON pour TX sur RA4 et RX sur RA5   
    banksel APFCON
    bsf APFCON, TXCKSEL
    bsf APFCON, RXDTSEL
; réglage UART   BAUD, 8 bits, 1 stop, pas de parité
; configuration transmission
    banksel TXSTA
    movlw (1<<TXEN)|(1<<BRGH)
    movwf TXSTA
    movlw FOSC/16/BAUD-1
    movwf SPBRGL
; configuration réception  UART
    movlw (1<<SPEN)|(1<<CREN)
    movwf RCSTA
; configuraion PWM
    banksel PWMEN
; composante rouge
    clrf ROUGE_PWMPH
    movlw 255
    movwf ROUGE_PWMPR
    movwf ROUGE_PWMPR+1
    clrf ROUGE_PWMCLKCON
    movlw (3<<6)|(1<<4)
    movwf ROUGE_PWMCON
; composante verte
    clrf VERT_PWMPH
    movlw 255
    movwf VERT_PWMPR
    movwf VERT_PWMPR+1
    clrf VERT_PWMCLKCON
    movlw (3<<6)|(1<<4)
    movwf VERT_PWMCON
;  composante bleu
    clrf BLEU_PWMPH
    movlw 255
    movwf BLEU_PWMPR
    movwf BLEU_PWMPR+1
    clrf BLEU_PWMCLKCON
    movlw (3<<6)|(1<<4)
    movwf BLEU_PWMCON
    banksel TRISA
    movlw ~((1<<ROUGE_PIN)|(1<<VERT_PIN)|(1<<BLEU_PIN))
    andwf TRISA
    clrf data_cntr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; attend la reception d'un octet
; les 7 octets doivent-être reçu et traité
; en moins de 16 msec sinon le WDT réinitialise le MCU
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
    banksel PIR1
    clrwdt
    btfss PIR1,RCIF
    bra $-2
; reçu 1 octet doit-être le compteur
    banksel RCREG
    movfw RCREG
    pushw
    skpnz
    bra accepte
    xorlw 255
    skpnz
    bra diffusion
    call uart_tx
retransmet: ; au suivant
    decf INDF1   ; décrémente le compteur
    call uart_tx ; et le retransmet
retrans_loop:    ; retransmet les 6 octets suivants
    call uart_rx
    call uart_tx
    decfsz data_cntr
    bra retrans_loop
    bra main
accepte: ; compteur à zéro accepte la commande
    drop
accept_loop:    
    call uart_rx
    call sauvegarde
    decfsz data_cntr
    bra accept_loop
    call nouvelle_couleur
    bra main
diffusion: ; message accepté par tous
    call uart_tx ; retransmet le compteur
diffus_loop:    
    call uart_rx 
    dup              ; garde une copie 
    call uart_tx     ; et retransmet
    call sauvegarde
    decfsz data_cntr
    bra diffus_loop
    call nouvelle_couleur
    bra main
    
; attend un octet du uart
; l'octet reçu est empilé    
uart_rx:
    banksel PIR1
    btfss PIR1,RCIF
    bra $-1
    banksel RCREG
    movfw RCREG
    pushw
    return

; transmet un octet
; octet à transmettre au sommet de la pile    
uart_tx:
    banksel PIR1
    btfsc PIR1,TXIF
    bra $-1
    banksel TXREG
    popw
    movwf TXREG
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mais en file d'attente les valeurs reçues
; la valeur de data_cntr détermine
; la variable    
; le sommet de la pile contient la valeur 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
sauvegarde:
    movfw data_cntr
    case 6, store_red
    case 5, store_red
    case 4, store_green
    case 3, store_green
    case 2, store_blue
    case 1, store_blue
    reset ; erreur ne devrait pas arrivé ici.
store_red:
    popw
    btfss data_cntr,0
    movwf rouge ; octet fort
    btfsc data_cntr,0
    movwf rouge+1 ; octet faible
    bra store_exit
store_green:
    popw
    btfss data_cntr,0
    movwf vert
    btfsc data_cntr,0
    movwf vert+1
    bra store_exit
store_blue:
    popw
    btfss data_cntr,0
    movwf bleu
    btfsc data_cntr,0
    movwf bleu+1
store_exit:    
    return

nouvelle_couleur:
    banksel PWM_BANK
    movfw rouge
    movwf ROUGE_PWMDCH
    movfw rouge+1
    movwf ROUGE_PWMDCL
    movfw vert
    movwf VERT_PWMDCH
    movfw vert+1
    movwf VERT_PWMDCL
    movfw bleu
    movwf BLEU_PWMDCH
    movfw bleu+1
    movwf BLEU_PWMDCL
    return
    
    end
    
    
    
    