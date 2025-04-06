; codigo que detecta linha quando nivel logico é 1
    
#include <p16f628a.inc>
list p=p16f628a
    
org 0x00
GOTO inicio
    
org 0x04
RETFIE
    
#define sensor_dir	PORTA,6
#define sensor_esq	PORTA,7
#define sensor_obst	PORTA,4
#define motor_esq_A	PORTA,0
#define motor_esq_B	PORTA,1
#define motor_dir_A	PORTA,2
#define motor_dir_B	PORTA,3
#define led_00		PORTB,0
#define led_01		PORTB,1
#define led_10		PORTB,2
#define led_11		PORTB,4
#define led_final	PORTB,5
    
delay_val1  EQU	 43
delay_val2  EQU  30
	
CBLOCK 0X20
    ;variaveis
    leitura
    estagio_atual
    aux
    aux1
    aux2
    porta_copia
ENDC
    
setup:
    ;desativa comparadores
    BANKSEL CMCON
    MOVLW   0x07              
    MOVWF   CMCON
    
    ;configura portas I/O
    BANKSEL TRISA
    MOVLW   b'11010000'
    MOVWF   TRISA
    MOVLW   b'00000000'	
    MOVWF   TRISB
    
    ;limpa pinos de saída
    BANKSEL PORTB
    CLRF    PORTB
    CLRF    PORTA
    
    ;inicializa estadio_atual em 0
    CLRF    estagio_atual
    
    ;configura pwm
    ; ...
    
    RETURN
    
ler_sensores:
    ;captura a leitura dos dois sensores na variável "leitura"
    CLRF    leitura
    BTFSC   sensor_esq
    BSF	    leitura,1
    BTFSC   sensor_dir
    BSF	    leitura,0
    
    BCF     PORTB,6
    BCF     PORTB,7
    BTFSC   leitura,1
    BSF	    PORTB, 6
    BTFSC   leitura,0
    BSF	    PORTB, 7
    RETURN
        
inicio:
    CALL setup 
loop: 
    CALL ler_sensores
        
    ;testa leitura dos sensores
    MOVLW   0x00	;para frente quando leitura=0
    XORWF   leitura,W
    BTFSC   STATUS,Z
    CALL    para_frente
    
    MOVLW   0x01	;para direita quando leitura=1
    XORWF   leitura,W
    BTFSC   STATUS,Z
    CALL    para_direita
    
    MOVLW   0x02	;para esquerda quando leitura=2
    XORWF   leitura,W
    BTFSC   STATUS,Z
    CALL    para_esquerda
    
    MOVLW   0x03	;novo estágio quando leitura=3
    XORWF   leitura,W
    BTFSC   STATUS,Z
    CALL    novo_estagio
    
    GOTO loop
 
;;;;;;;;;;;;;;;; ROTINAS DE CONTROLE DO CARRINHO ;;;;;;;;;;;;;;;;;;;;;
para_frente:
    BANKSEL PORTB
    BSF	    motor_esq_A
    BCF     motor_esq_B
    BSF     motor_dir_A
    BCF     motor_dir_B
    RETURN
    
para_direita:
    BANKSEL PORTB
    BSF	    motor_esq_A
    BCF     motor_esq_B
    BCF     motor_dir_A
    BCF     motor_dir_B
    RETURN
    
para_esquerda:
    BANKSEL PORTB
    BCF	    motor_esq_A
    BCF     motor_esq_B
    BSF     motor_dir_A
    BCF     motor_dir_B   
    RETURN
    
parar:
    BANKSEL PORTB
    BCF	    motor_esq_A
    BCF     motor_esq_B
    BCF     motor_dir_A
    BCF     motor_dir_B
    RETURN
    
meia_volta:
    BANKSEL PORTB
    BSF	    motor_esq_A
    BCF     motor_esq_B
    BCF     motor_dir_A
    BSF     motor_dir_B
    RETURN
    
checa_obstaculo:
    ; estágios 3, 5, 9 ou 11
    BANKSEL PORTB
    BTFSC   sensor_obst
    CALL    acende_leds
    RETURN
    
;;;;;;;;;;;;;;;;; ATUALIZAÇÃO DE ESTÁGIO ;;;;;;;;;;;;;;;;;;;;   
novo_estagio:
    CALL    ler_sensores	;faz uma nova leitura dos sensores
    MOVLW   0x03	
    XORWF   leitura,W
    BTFSC   STATUS,Z		;testa se a leitura é consistente
    CALL    atualiza_estagio	;se for, atualiza estágio
    RETURN			;senao, alarme falso e retorna
    
atualiza_estagio:
    ;legenda
    ; 1) para_esquerda	    2) para_esquerda	    3) para, checa obstáculo e dá meia-volta
    ; 4) para_frente	    5) para, checa obstáculo e dá meia_volta	    6) para_esquerda
    ; 7) para_frente	    8) para_esquerda	    9) para, checa obstáculo e dá meia-volta
    ; 10) para_frente	    11) para, checa obstáculo e acende led_final 
    INCF estagio_atual
    MOVF estagio_atual, W
    
    ADDWF PCL, F
    GOTO  loop
    GOTO  estagio_1_2_6_8   ;estagio 1
    GOTO  estagio_1_2_6_8   ;estagio 2
    GOTO  estagio_3_5_9	    ;estagio 3
    GOTO  estagio_4_7_10    ;estagio 4
    GOTO  estagio_3_5_9	    ;estagio 5
    GOTO  estagio_1_2_6_8   ;estagio 6
    GOTO  estagio_4_7_10    ;estagio 7
    GOTO  estagio_1_2_6_8   ;estagio 8
    GOTO  estagio_3_5_9	    ;estagio 9
    GOTO  estagio_4_7_10    ;estagio 10
    GOTO  estagio_11	    ;estagio 11
    RETURN
    
;;;;;;;;;;;;;;;;;;;;;;; ESTÁGIOS DO CIRCUITO ;;;;;;;;;;;;;;
    
estagio_1_2_6_8:
    CALL para_esquerda
    CALL delay_50ms
    RETURN
 
estagio_4_7_10:
    CALL para_frente
    CALL delay_50ms
    RETURN

estagio_3_5_9:
    CALL parar
    CALL checa_obstaculo
    CALL meia_volta
    CALL delay_50ms
    RETURN
    
estagio_11:
    CALL    parar
    CALL    checa_obstaculo
    CALL    acende_led_final
    CALL    delay_50ms
    RETURN
    
;;;;;;;;;;;;;;;;;;;;;;; ROTINAS DE ACENDER LED ;;;;;;;;;;;;;;;;;;;;
    
 acende_leds:
    ; estágio 3
    MOVLW   0x03
    XORWF   estagio_atual,W
    BTFSC   STATUS,Z
    CALL    acende_led_00
    ; estágio 5
    MOVLW   0x05
    XORWF   estagio_atual,W
    BTFSC   STATUS,Z
    CALL    acende_led_01
    ; estágio 9
    MOVLW   0x09
    XORWF   estagio_atual,W
    BTFSC   STATUS,Z
    CALL    acende_led_10
    ; estágio 11
    MOVLW   0x0B
    XORWF   estagio_atual,W
    BTFSC   STATUS,Z
    CALL    acende_led_11
    RETURN
    
acende_led_00:
    BANKSEL PORTB
    BSF	    led_00
    RETURN
    
acende_led_01:
    BANKSEL PORTB
    BSF	    led_01
    RETURN
    
acende_led_10:
    BANKSEL PORTB
    BSF	    led_10
    RETURN
    
acende_led_11:
    BANKSEL PORTB
    BSF	    led_11
    RETURN 
    
acende_led_final:
    BANKSEL PORTB
    BSF	    led_final
    RETURN 

;;;;;;;;;;;;;;;;;;;;;; ROTINA DE DELAY ;;;;;;;;;;;;;;;;;;;;
    
;delay de 10ms
delay_10ms:
    MOVLW   delay_val1        
    MOVWF   aux1
L0:
    MOVLW   delay_val2         
    MOVWF   aux2   
L1:    
    NOP       
    NOP      
    NOP    
    NOP               
    
    DECFSZ   aux2, F      
    GOTO    L1       
    DECFSZ   aux1, F       
    GOTO    L0       
    RETURN             

delay_50ms:
    CALL delay_10ms
    CALL delay_10ms
    CALL delay_10ms
    CALL delay_10ms
    CALL delay_10ms
    RETURN
    
END


