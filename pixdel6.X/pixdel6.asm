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
;  pixdel6 est la sixi�me version de pixdel.
;  Cette version utilise le MCU PIC12F1572.
;  Le protocole de communication est diff�rent. Il s'agit d'un protocole pour
;  dispositif attach�s en cha�ne que j'ai mis au point.
;  Contrairement au produit commercial WS8212b, chaque LED de la cha�ne peut-�tre
;  contr�l�e individuellement quelque soit sa position dans la cha�ne sans qu'il
;  soit n�cessaire d'envoyer une commande � chaque LED qui la pr�c�de.
;  L'id�e est bas�e sur un compteur d�cr�ment�. Chaque paquet de donn�es envoy�
;  dans la cha�ne d�bute par un compteur. Une LED accepte le paquet si le compteur
;  est � z�ro sinon il d�cr�mente le compteur et le transmet avec le reste du paquet
;  � la LED suivante. C'est donc la valeur initiale du compteur ainsi que la position 
;  dans la cha�ne qui d�termine quel LED accepte le paquet.  Ce protocole permet
;  donc de r�duire la quantit� d'information qu'il est n�cessaire d'envoyer dans la cha�ne.
;
;   Le PIC12F1572 poss�de 3 canaux PWM 16 bits et un p�riph�rique EUSART.
;   Le EUSART est utilis� pour la communication et les 3 PWM pour le contr�le des
;   composantes RGB de la LED. Le paquet transmis est donc constitu� de 7 octets
;	1 compteur 8 bits permettant de contr�ler 256 pixdel6.
;       6 octets de contr�le de la couleur, 2 octets par composantes.
;   FORMAT DU PAQUET:
;   ------------------	    
;   COMPTEUR|Rh|Rl|Gh|Gl|Bh|Bl    
;
;   Puisque le paquet est de taille fixe et qu'en plus le compteur d�termine la cible,
;   il n'est pas n�cessaire de faire une pose entre chaque commande comme c'est le cas
;   pour les WS8212b.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    include p12f1572.inc
    __config _CONFIG1, _FOSC_INTOSC&_WDTE_OFF&_PWRTE_OFF&_MCLRE_ON&_CP_OFF&_BOREN_OFF&_CLKOUTEN_OFF
    __config _CONFIG2, _WRT_ALL&_PLLEN_ON&_STVREN_OFF&_LVP_OFF

    radix decimal

#define LOW 0
#define HIGH 1    
#define TX  RA4
#define RX  RA5
#define RED_PIN RA2    ; PWM3
#define RED_PWMDC PWM3DC ; rapport cyclique
#define RED_PWMPR PWM3PR ;p�riode
#define RED_PWMPH PWM3PH ; phase
#define RED_PWMOF PWM3OF ; offset
#define RED_PWMTMR PWM3TMR ; timer
#define RED_PWMCON PWM3CON ; registre de contr�le
#define RED_PWMCLKCON PWM3CLKCON  ; contr�le clock
#define RED_PWMOFCON PWM3OFCON ; contr�le offset
#define RED_PWMLDCON PWM3LDCON ; load control
#define RED_PWMINTE PWM3INTE  ; activation interruption
#define RED_PWMINTF PWM3INTF  ; indicateurs d'interruption    
#define GREEN_PIN RA1  ; PWM1
#define GREEN_PWMDC PWM1DC
#define GREEN_PWMPR PWM1PR    
#define BLUE_PIN RA0   ; PWM2
#define BLUE_PWMDC PWM2DC
#define BLUE_PWMPR PWM2PR
    
#define FOSC 32000000
#define BAUD 38400

    
    org 0
rst:    
    goto init
    
    org 4
isr:
    
    
    retfie
    
init:
; clock � 32Mhz
    banksel OSCCON
    movlw (0xE<<IRCF0)
    movwf OSCCON
;d�sactivation entr�es analogique
    banksel ANSELA
    clrf ANSELA
;r�glage APFCON pour TX sur RA4 et RX sur RA5   
    banksel APFCON
    bsf APFCON, TXCKSEL
    bsf APFCON, RXDTSEL
; r�glage EUSART   38400 BAUD, 8 bits, 1 stop, pas de parit�
; configuration transmission
    banksel TXSTA
    movlw (1<<TXEN)|(1<<BRGH)
    movwf TXSTA
    movlw FOSC/16/BAUD-1
    movwf SPBRGL
; configuration r�ception
    movlw (1<<SPEN)|(1<<CREN)
    movwf RCSTA
; configuraion PWM
    banksel PWMEN
    
main:
    
    
    end
    
    
    
    