# pixdel6

Nouvelle version de PIXDEL  utilisant un MCU PIC12F1572 et un protocol de communication diff�rent.
 
# protocole de communication
============================

chaque commande comprend 7 octets envoy�s dans l'ordre suivant:

COUNTER|RED_HEIGH|RED_LOW|GREEN_HEIGH|GREEN_LOW|BLUE_HEIGH|BLUE_LOW

* COUNTER; compteur 8 bits
** 0 message pour diffusion accepter et retransmis tel quel.
** 1 message accept� mais non retransmis.
** 2-255  compteur d�cr�ment� et message retransmis.
*  RED_HEIGH 8 bits fort valeur couleur rouge.
*  RED_LOW   8 bits faible valeur couleur rouge.
*  GREEN_HEIGH 8 bits fort valeur couleur verte.
*  GREEN_LOW   8 bits faible valeur couleur verte.
*  BLUE_HEIGH 8 bits fort valeur couleur bleu.
*  BLUE_LOW   8 bits faible valeur couleur bleu.

La cha�ne peut comprendre un maximum de 255 pixdel. La communication se
fait par RS-232 � 115200BAUD.





