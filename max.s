
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30
RCC_APB1ENR     EQU RCC_BASE + 0x40
RCC_APB1RSTR    EQU RCC_BASE + 0x20      

GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOB_OTYPER    EQU GPIOB_BASE + 0x04
GPIOB_PUPDR     EQU GPIOB_BASE + 0x0C
GPIOB_AFRH      EQU GPIOB_BASE + 0x24    

I2C1_BASE       EQU 0x40005400
I2C1_CR1        EQU I2C1_BASE + 0x00
I2C1_CR2        EQU I2C1_BASE + 0x04
I2C1_DR         EQU I2C1_BASE + 0x10
I2C1_SR1        EQU I2C1_BASE + 0x14
I2C1_SR2        EQU I2C1_BASE + 0x18
I2C1_CCR        EQU I2C1_BASE + 0x1C
I2C1_TRISE      EQU I2C1_BASE + 0x20

WAKE_THRESHOLD  EQU 20000       
SLEEP_THRESHOLD EQU 25000      

MAX30102_ADDR   EQU 0x57
FINGER_THRESHOLD EQU 5000      

    AREA    MAX30102_DATA, DATA, READWRITE
    ALIGN
ir_value        SPACE   4
red_value       SPACE   4
temp_int        SPACE   1
temp_frac       SPACE   1
    ALIGN
final_temp_c    SPACE   4
final_bpm       SPACE   4
final_spo2      SPACE   4

dsp_sample_cnt  SPACE   4
dsp_last_beat   SPACE   4
dsp_ir_max      SPACE   4
dsp_ir_min      SPACE   4
dsp_red_max     SPACE   4
dsp_red_min     SPACE   4
dsp_window_cnt  SPACE   4
dsp_last_ir     SPACE   4


    ALIGN 4
bpm_hist_count  DCB 0           
    ALIGN 4
bpm_history     SPACE 24       

    ALIGN 4
spo2_hist_count DCB 0           
    ALIGN 4
spo2_history    SPACE 24       

    ALIGN 4
mtemp_hist_count DCB 0          
    ALIGN 4
mtemp_history    SPACE 24       
	ALIGN 4
led_state       SPACE 1         
    ALIGN 4



    AREA    MAX30102_CODE, CODE, READONLY
    EXPORT  MAX30102_Setup
    EXPORT  MAX30102_Update
    EXPORT  temp_int
    EXPORT  final_bpm
    EXPORT  final_spo2
	EXPORT ir_value
		
		
	EXPORT  bpm_hist_count
    EXPORT  bpm_history
    EXPORT  spo2_hist_count
    EXPORT  spo2_history
    EXPORT  mtemp_hist_count
    EXPORT  mtemp_history
		
	EXPORT  delay
		
    ALIGN


MAX30102_Setup
    PUSH {LR}
    BL DSP_Init
    BL I2C1_Hardware_Init
    LDR R0, =500000
    BL delay
    BL MAX30102_Init
    POP {PC}

MAX30102_Update
    PUSH {LR}
    BL I2C_Read_FIFO
    BL MAX30102_Read_Temp
    BL Process_Data
    POP {PC}



I2C1_Hardware_Init
    PUSH {R0, R1, LR}
    

    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 1)     
    STR R1, [R0]
    LDR R0, =RCC_APB1ENR
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 21)     
    STR R1, [R0]


    LDR R0, =I2C1_CR1
    LDR R1, =(1 :SHL: 15)         
    STR R1, [R0]                   
    MOVS R1, #0
    STR R1, [R0]                  


   


    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    BIC R1, R1, #(0xF :SHL: 16)
    ORR R1, R1, #(0xA :SHL: 16)
    STR R1, [R0]
    

    LDR R0, =GPIOB_OTYPER
    LDR R1, [R0]
    ORR R1, R1, #(3 :SHL: 8)
    STR R1, [R0]
    

    LDR R0, =GPIOB_PUPDR
    LDR R1, [R0]
    BIC R1, R1, #(0xF :SHL: 16)
    ORR R1, R1, #(0x5 :SHL: 16)
    STR R1, [R0]
    

    LDR R0, =GPIOB_AFRH
    LDR R1, [R0]
    BIC R1, R1, #0xFF             
    ORR R1, R1, #0x44            
    STR R1, [R0]
    

    LDR R0, =I2C1_CR1
    MOVS R1, #0
    STR R1, [R0]
    LDR R0, =I2C1_CR2
    MOVS R1, #16
    STR R1, [R0]
    LDR R0, =I2C1_CCR
    MOVS R1, #80
    STR R1, [R0]
    LDR R0, =I2C1_TRISE
    MOVS R1, #17
    STR R1, [R0]
    LDR R0, =I2C1_CR1
    MOVS R1, #1
    STR R1, [R0]
    POP {R0, R1, PC}


Process_Data
    PUSH {R4-R11, LR}


    LDR R0, =ir_value
    LDR R4, [R0]                

    LDR R0, =led_state
    LDRB R1, [R0]
    CMP R1, #1                 
    BEQ check_sleep

check_wake                   
    LDR R2, =WAKE_THRESHOLD
    CMP R4, R2
    BLO skip_calculations       
    B wake_up                  

check_sleep                   
    LDR R2, =SLEEP_THRESHOLD
    CMP R4, R2
    BHS continue_processing     

go_to_sleep
    BL Set_LED_Low              
    LDR R0, =led_state
    MOV R1, #0
    STRB R1, [R0]
    BL DSP_Init                 
    B skip_calculations

wake_up
    BL Set_LED_High             
    LDR R0, =led_state
    MOV R1, #1
    STRB R1, [R0]
    BL DSP_Init                 
    B skip_calculations         

skip_calculations

    MOVS R1, #0
    LDR R0, =final_bpm
    STR R1, [R0]
    LDR R0, =final_spo2
    STR R1, [R0]
    POP {R4-R11, PC}            
	LTORG
continue_processing

    LDR R0, =temp_int
    LDRB R4, [R0]
    STR R4, [R0]                

    
    LDR R0, =ir_value
    LDR R4, [R0]               
    LDR R0, =red_value
    LDR R5, [R0]                

             
    
    STR R4, [R0]                


    LDR R0, =ir_value
    LDR R4, [R0]                
    LDR R0, =red_value
    LDR R5, [R0]                
    LDR R0, =dsp_sample_cnt
    LDR R6, [R0]
    ADD R6, R6, #1              
    STR R6, [R0]

    LDR R0, =dsp_ir_max
    LDR R7, [R0]
    CMP R4, R7
    IT HI
    STRHI R4, [R0]              
    LDR R0, =dsp_ir_min
    LDR R8, [R0]
    CMP R4, R8
    IT CC
    STRCC R4, [R0]              

    LDR R0, =dsp_red_max
    LDR R9, [R0]
    CMP R5, R9
    IT HI
    STRHI R5, [R0]
    LDR R0, =dsp_red_min
    LDR R10, [R0]
    CMP R5, R10
    IT CC
    STRCC R5, [R0]


    ADD R11, R7, R8
    LSR R11, R11, #1            
    LDR R0, =dsp_last_ir
    LDR R1, [R0]
    STR R4, [R0]                
    
    CMP R1, R11
    BHS skip_beat
    CMP R4, R11
    BLO skip_beat
    
    LDR R0, =dsp_last_beat
    LDR R1, [R0]
    STR R6, [R0]                
    SUBS R2, R6, R1             
    CMP R2, #5                  
    BLS skip_beat
    
    LDR R0, =1200
    UDIV R0, R0, R2             
    CMP R0, #200
    BHI skip_beat
    CMP R0, #30
    BLO skip_beat
    LDR R1, =final_bpm
    STR R0, [R1]                

skip_beat

    LDR R0, =dsp_window_cnt
    LDR R1, [R0]
    ADD R1, R1, #1
    STR R1, [R0]
    CMP R1, #100                
    BLO dsp_done
    
    MOVS R1, #0
    STR R1, [R0]
    
    SUBS R9, R9, R10            
    SUBS R7, R7, R8             
    
    CMP R7, #0
    BEQ reset_minmax
    CMP R10, #0
    BEQ reset_minmax
    
    MUL R0, R9, R8
    MOV R1, #100
    MUL R0, R0, R1
    MUL R1, R7, R10
    UDIV R2, R0, R1
    
    MOV R0, #17
    MUL R2, R2, R0
    MOV R0, #100
    UDIV R2, R2, R0
    MOV R0, #104
    SUBS R0, R0, R2
    
    CMP R0, #100
    IT HI
    MOVHI R0, #100
    LDR R1, =final_spo2
    STR R0, [R1]                

reset_minmax
    BL DSP_Init

dsp_done
    POP {R4-R11, PC}


DSP_Init
    PUSH {R0, R1, LR}
    LDR R0, =dsp_ir_max
    MOVS R1, #0
    STR R1, [R0]
    LDR R0, =dsp_red_max
    STR R1, [R0]
    LDR R0, =dsp_ir_min
    LDR R1, =0x0003FFFF         
    STR R1, [R0]
    LDR R0, =dsp_red_min
    STR R1, [R0]
    POP {R0, R1, PC}



MAX30102_Init
    PUSH {R0, R1, R2, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x09
    MOVS R2, #0x40
    BL I2C_Write
    LDR R0, =100000
    BL delay
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x04
    MOVS R2, #0
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x05
    MOVS R2, #0
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x06
    MOVS R2, #0
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x09
    MOVS R2, #0x03
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x67              
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C
    MOVS R2, #0x24              
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0D
    MOVS R2, #0x24              
    BL I2C_Write
    POP {R0, R1, R2, PC}



I2C_Start
    PUSH {R0, R1, LR}
    LDR R0, =I2C1_CR1
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 8)
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_start
    LDR R1, [R0]
    TST R1, #(1 :SHL: 0)
    BEQ wait_start
    POP {R0, R1, PC}

I2C_Stop
    PUSH {R0, R1, LR}
    LDR R0, =I2C1_CR1
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 9)
    STR R1, [R0]
    POP {R0, R1, PC}

I2C_WriteByte
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_SR1
wait_txe
    LDR R2, [R1]
    TST R2, #(1 :SHL: 7)
    BEQ wait_txe
    LDR R1, =I2C1_DR
    STR R0, [R1]
    LDR R1, =I2C1_SR1
wait_btf
    LDR R2, [R1]
    TST R2, #(1 :SHL: 2)
    BEQ wait_btf
    POP {R1, R2, PC}

I2C_Read_ACK
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_CR1
    LDR R2, [R1]
    ORR R2, R2, #(1 :SHL: 10)
    STR R2, [R1]
    LDR R1, =I2C1_SR1
wait_rxne_ack
    LDR R2, [R1]
    TST R2, #(1 :SHL: 6)
    BEQ wait_rxne_ack
    LDR R1, =I2C1_DR
    LDR R0, [R1]
    AND R0, R0, #0xFF           
    POP {R1, R2, PC}

I2C_Read_NACK
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_CR1
    LDR R2, [R1]
    BIC R2, R2, #(1 :SHL: 10)
    ORR R2, R2, #(1 :SHL: 9)
    STR R2, [R1]
    LDR R1, =I2C1_SR1
wait_rxne_nack
    LDR R2, [R1]
    TST R2, #(1 :SHL: 6)
    BEQ wait_rxne_nack
    LDR R1, =I2C1_DR
    LDR R0, [R1]
    AND R0, R0, #0xFF           
    POP {R1, R2, PC}

I2C_Write
    PUSH {R3, LR}
    BL I2C_Start
    LDR R3, =I2C1_DR
    LSL R0, R0, #1
    STR R0, [R3]
    LDR R3, =I2C1_SR1
wait_addr_w
    LDR R0, [R3]
    TST R0, #(1 :SHL: 1)
    BEQ wait_addr_w
    LDR R3, =I2C1_SR2
    LDR R0, [R3]                
    MOV R0, R1                  
    BL I2C_WriteByte
    MOV R0, R2                  
    BL I2C_WriteByte
    BL I2C_Stop
    POP {R3, PC}


I2C_Read_FIFO
    PUSH {R4-R9, LR}
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAE              
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_fifo_w
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_fifo_w
    LDR R1, =I2C1_SR2
    LDR R1, [R1]
    MOVS R0, #0x07              
    BL I2C_WriteByte
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAF              
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_fifo_r
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_fifo_r
    LDR R1, =I2C1_SR2
    LDR R1, [R1]
    
    BL I2C_Read_ACK
    MOV R4, R0                 
    BL I2C_Read_ACK
    MOV R5, R0                  
    BL I2C_Read_ACK
    MOV R6, R0                  
    BL I2C_Read_ACK
    MOV R7, R0                  
    BL I2C_Read_ACK
    MOV R8, R0                  
    BL I2C_Read_NACK
    MOV R9, R0                 
    BL I2C_Stop
    
    AND R4, R4, #0x03
    LSL R4, R4, #16
    LSL R5, R5, #8
    ORR R4, R4, R5
    ORR R4, R4, R6
    LDR R0, =red_value
    STR R4, [R0]
    
    AND R7, R7, #0x03
    LSL R7, R7, #16
    LSL R8, R8, #8
    ORR R7, R7, R8
    ORR R7, R7, R9
    LDR R0, =ir_value
    STR R7, [R0]
    
    POP {R4-R9, PC}

MAX30102_Read_Temp
    PUSH {R4, R5, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x21
    MOVS R2, #0x01
    BL I2C_Write
    LDR R0, =500000 
    BL delay
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAE              
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_temp_w
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_temp_w
    LDR R1, =I2C1_SR2
    LDR R1, [R1]                
    MOVS R0, #0x1F              
    BL I2C_WriteByte
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAF              
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_temp_r
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_temp_r
    LDR R1, =I2C1_SR2
    LDR R1, [R1]                
    BL I2C_Read_ACK             
    MOV R4, R0
    BL I2C_Read_NACK            
    MOV R5, R0
    BL I2C_Stop
    LDR R0, =temp_int
    STRB R4, [R0]
    LDR R0, =temp_frac
    STRB R5, [R0]
    POP {R4, R5, PC}
Set_LED_High
    PUSH {R0-R3, LR}
  
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x67              
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C
    MOVS R2, #0x24              
    BL I2C_Write
    
    
    BL Flush_MAX_FIFO
    POP {R0-R3, PC}

Set_LED_Low
    PUSH {R0-R3, LR}

    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x02              
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C
    MOVS R2, #0x02              
    BL I2C_Write
    

    BL Flush_MAX_FIFO
    POP {R0-R3, PC}

Flush_MAX_FIFO
    PUSH {R0-R3, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x04             
    MOVS R2, #0x00
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x05             
    MOVS R2, #0x00
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x06              
    MOVS R2, #0x00
    BL I2C_Write
    POP {R0-R3, PC}
delay
    PUSH {R0, LR}
    CMP R0, #0
    BEQ delay_end
delay_loop
    NOP
    SUBS R0, R0, #1
    BNE delay_loop
delay_end
    POP {R0, PC}

    END