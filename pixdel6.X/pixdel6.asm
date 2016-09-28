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
;  est à 0 ou 1 sinon il décrémente le compteur et le transmet avec le reste du paquet
;  à la LED suivante. C'est donc la valeur initiale du compteur ainsi que la position 
;  dans la chaîne qui détermine quelle LED accepte le paquet.  Ce protocole permet
;  donc de réduire la quantité d'information qu'il est nécessaire d'envoyer dans la chaîne.
;  
;  Si la valeur du compteur à est zéro il s'agit un message de diffusion dans ce cas
;  Le pixdel reconnait la commande mais la retransmet aussi sans décrémenter le compteur.
;  ce protocole peut donc contrôler une chaîne de 255 pixdel.    
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
;==============================================================================    
;| valeur du compteur  |   action                                              |
;==============================================================================    
;|          0          |  diffusion: accepte le message et transmet au suivant |
;|          1          |  accepte le message mais ne transmet pas au suivant   |
;|        2-255        |  refuse le message, décrémente le compteur et         |
;|                     |  retransmet au suivant.                               |
;==============================================================================    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    include p12f1572.inc
    __config _CONFIG1, _FOSC_INTOSC&_WDTE_ON&_PWRTE_OFF&_MCLRE_ON&_CP_OFF&_BOREN_OFF&_CLKOUTEN_OFF
    __config _CONFIG2, _WRT_ALL&_PLLEN_ON&_STVREN_OFF&_LVP_OFF

    radix dec

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
#define VERROUGE_T_PWMPR PWM1PR    
#define VERT_PWMPH PWM1PH ; phase
#define VERTROUGE__PWMOF PWM1OF ; offset
#define VERT_PWMTMR PWM1TMR ; timer
#define VERT_PWMCON PWM1CON ; registre de contrôle
#define VERT_PWMCLKCON PWM1CLKCON    
#define VERT_PWMOFCON PWM1OFCON ; contrôle offset
#define VERT_PWMLDCON PWM1LDCON ; load control
#define VERT_PWMINTE PWM1INTE  ; activation interruption
#define VERT_PWMINTF PWM1INTF  ; indicateurs d'interruption    
#define BLEU_PIN RA0   ; PWM2
#define BLEU_PWMDCL PWM2DCL
#define BLEU_PWMDCH PWM2DCH
#define BLEU_PWMPR PWM2PR
#define BLEU_PWMPH PWM2PH ; phase
#define BLEU_PWMOF PWM2OF ; offset
#define BLEU_PWMTMR PWM2TMR ; timer
#define BLEU_PWMCON PWM2CON
#define BLEU_PWMCLKCON PWM2CLKCON    
#define BLEU_PWMOFCON PWM2OFCON ; contrôle offset
#define BLEU_PWMLDCON PWM2LDCON ; load control
#define BLEU_PWMINTE PWM2INTE  ; activation interruption
#define BLEU_PWMINTF PWM2INTF  ; indicateurs d'interruption    

#define PWM_BANK PWMEN

#define FOSC 32000000
#define BAUD 115200 ;  57600, 38400

#define DPTOS  INDF1  ; sommet de la pile des arguments

#define DIFFUSER  0   ; message de diffusion
#define ACCEPTER  1   ; message accepté
    
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
    movwi ++FSR1
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
 
    udata_shr 0x70
msec res 1 ; nombre de millisecondes depuis le reset    
a_recevoir res 1 ; nombre d'octets à recevoir
; sauvegarde octets nouvelle couleur
; RH:RL|GH:GL|BH:BL 
rouge res 2  
vert  res 2
bleu  res 2
 
    org 0
rst:    
    goto init
    
    org 4
isr:
    incf msec
    bcf INTCON,TMR0IF
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
; TIMER0 utilisé comme compteur millisecondes
    movlw 4
    movwf OPTION_REG
    clrf msec
    banksel TMR0
    clrf TMR0
    movlw (1<<GIE)|(1<<TMR0IE)
    movwf INTCON
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
    banksel PWM_BANK
; composante rouge
    clrf ROUGE_PWMDCH
    clrf ROUGE_PWMDCL
    clrf ROUGE_PWMPH
    clrf ROUGE_PWMPH+1
    clrf ROUGE_PWMLDCON
    movlw 255
    movwf ROUGE_PWMPR
    movwf ROUGE_PWMPR+1
    clrf ROUGE_PWMCLKCON
    movlw (3<<OE);|(1<<POL)
    movwf ROUGE_PWMCON
; composante verte
    clrf VERT_PWMDCH
    clrf VERT_PWMDCL
    clrf VERT_PWMPH
    clrf VERT_PWMPH+1
    clrf VERT_PWMLDCON
    movlw 255
    movwf VERT_PWMPR
    movwf VERT_PWMPR+1
    clrf VERT_PWMCLKCON
    movlw (3<<OE);|(1<<POL)
    movwf VERT_PWMCON
;  composante bleu
    clrf BLEU_PWMDCH
    clrf BLEU_PWMDCL
    clrf BLEU_PWMPH
    clrf BLEU_PWMPH+1
    clrf BLEU_PWMLDCON
    movlw 255
    movwf BLEU_PWMPR
    movwf BLEU_PWMPR+1
    clrf BLEU_PWMCLKCON
    movlw (3<<OE);|(1<<POL)
    movwf BLEU_PWMCON
    banksel TRISA
    movlw ~((1<<ROUGE_PIN)|(1<<VERT_PIN)|(1<<BLEU_PIN))
    andwf TRISA
;met à zéro les couleurs
    movlw rouge
    movwf FSR0L
    clrf FSR0H
    movlw 6
    pushw
    clrw
    movf DPTOS,F
    skpnz
    bra $+4
    movwi FSR0++
    decf DPTOS
    bra $-5
    drop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; attend la reception d'un octet
; les 7 octets doivent-être reçu et traité
; en moins de 16 msec sinon le WDT réinitialise le MCU
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
    call nouvelle_couleur
    movlw 7 ; 7 octets par commande
    movwf a_recevoir
    movlw low rouge
    movwf FSR0L
    movlw high rouge
    movwf FSR0H
    banksel PIR1
    clrwdt
    btfss PIR1,RCIF
    bra $-2
; reçu 1 octet doit-être le compteur
    banksel RCREG
    movfw RCREG
    pushw
    skpnz
    bra diffusion
    xorlw 1
    skpnz
    bra accepte
retransmet: ; au suivant
    decf DPTOS   ; décrémente le compteur
    call uart_tx ; et le retransmet
    decf a_recevoir ; compteur retransmis
retrans_loop:    ; retransmet les 6 octets suivants
    call uart_rx
    call uart_tx
    decfsz a_recevoir
    bra retrans_loop
    bra main
accepte: ; compteur à zéro accepte la commande
    drop
    decf a_recevoir
accept_loop:    
    call uart_rx
    popw
    movwi FSR0++
    decfsz a_recevoir
    bra accept_loop
    bra main
diffusion: ; message accepté par tous
    call uart_tx ; retransmet le compteur
    decf a_recevoir
diffus_loop:    
    call uart_rx 
    dup              ; garde une copie 
    call uart_tx     ; et retransmet
    popw
    movwi FSR0++
    decfsz a_recevoir
    bra diffus_loop
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
    btfss PIR1,TXIF
    bra $-1
    banksel TXREG
    popw
    movwf TXREG
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
    bsf ROUGE_PWMLDCON,7
    bsf VERT_PWMLDCON,7
    bsf BLEU_PWMLDCON,7
    return
    
    end
    
    
    
    