
   
    
    
    include p12f1572.inc
    __config _CONFIG1, _FOSC_INTOSC&_WDTE_OFF&_PWRTE_OFF&_MCLRE_ON&_CP_OFF&_BOREN_OFF&_CLKOUTEN_OFF
    __config _CONFIG2, _WRT_ALL&_PLLEN_ON&_STVREN_OFF&_LVP_OFF


    org 0
rst:    
    goto init
    
    org 4
isr:
    
    
    retfie
    
init:
    
main:
    
    
    end
    
    
    
    