	AREA    |.text|, CODE, READONLY
    ALIGN
    

    EXPORT  BT_Init
    EXPORT  BT_Get_Data


		
    IMPORT bpm_current
    IMPORT spo2_current
    IMPORT press_current
    IMPORT temp_int
    IMPORT Last_Rate
    IMPORT temp_data

    EXPORT BT_Send_Char
    EXPORT BT_Send_String
    EXPORT BT_Send_Number
    EXPORT BT_Send_Sensor_Data

    AREA BT_STRINGS, DATA, READONLY
    ALIGN 4
str_hr      DCB "HR:", 0
str_spo2    DCB " SpO2:", 0
str_press   DCB " Press:", 0
str_rtemp   DCB " RTemp:", 0
str_drop    DCB " Drop:", 0
str_nl      DCB "\r\n", 0
    ALIGN 4

    AREA |.text|, CODE, READONLY
    ALIGN 4


RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30

RCC_APB2ENR     EQU RCC_BASE + 0x44  

GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00

GPIOB_AFRL      EQU GPIOB_BASE + 0x20 


USART1_BASE     EQU 0x40011000
USART1_SR       EQU USART1_BASE + 0x00
USART1_DR       EQU USART1_BASE + 0x04
USART1_BRR      EQU USART1_BASE + 0x08
USART1_CR1      EQU USART1_BASE + 0x0C


BT_Init
    PUSH {R0-R2, LR}

    
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x02
    STR R1, [R0]

    
    LDR R0, =RCC_APB2ENR
    LDR R1, [R0]
    LDR R2, =0x00000010     
    ORR R1, R1, R2
    STR R1, [R0]


    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    LDR R2, =0xFFFF0FFF     
    AND R1, R1, R2
    LDR R2, =0x0000A000     
    ORR R1, R1, R2
    STR R1, [R0]


    LDR R0, =GPIOB_AFRL
    LDR R1, [R0]
    LDR R2, =0x00FFFFFF     
    AND R1, R1, R2
    LDR R2, =0x77000000     
    ORR R1, R1, R2
    STR R1, [R0]


    LDR R0, =USART1_BRR
    LDR R1, =0x0683
    STR R1, [R0]


    LDR R0, =USART1_CR1
    LDR R1, =0x200C
    STR R1, [R0]

    POP {R0-R2, PC}        



BT_Get_Data
    LDR R1, =USART1_SR
    LDR R2, [R1]
    TST R2, #0x20           
    BEQ no_bt_data          
    
    LDR R1, =USART1_DR
    LDR R0, [R1]            
    BX LR                  

no_bt_data
    MOV R0, #0              
    BX LR                   
	



BT_Send_Char
    PUSH {R1, R2, LR}
    LDR R1, =USART1_BASE    
wait_tx
    LDR R2, [R1, #0x00]      
    TST R2, #0x80            
    BEQ wait_tx              
    STR R0, [R1, #0x04]      
    POP {R1, R2, PC}


BT_Send_String
    PUSH {R0, R1, R2, LR}
    MOV R1, R0
send_str_loop
    LDRB R0, [R1], #1        
    CMP R0, #0               
    BEQ send_str_done
    BL BT_Send_Char
    B send_str_loop
send_str_done
    POP {R0, R1, R2, PC}


BT_Send_Number
    PUSH {R0-R5, LR}
    CMP R0, #0
    BNE btsn_start
    MOV R0, #'0'            
    BL BT_Send_Char
    B btsn_end

btsn_start
    MOV R1, #10              
    MOV R2, #0               
    SUB SP, SP, #16          
btsn_loop
    CMP R0, #0
    BEQ btsn_send
    UDIV R3, R0, R1          
    MLS R4, R3, R1, R0       
    ADD R4, R4, #'0'         
    STRB R4, [SP, R2]       
    ADD R2, R2, #1           
    MOV R0, R3               
    B btsn_loop
btsn_send
    SUB R2, R2, #1          
    LDRB R0, [SP, R2]
    BL BT_Send_Char
    CMP R2, #0
    BNE btsn_send
    ADD SP, SP, #16          
btsn_end
    POP {R0-R5, PC}


BT_Send_Sensor_Data
    PUSH {R0-R3, LR}

   
    LDR R0, =str_hr
    BL BT_Send_String
    LDR R0, =bpm_current
    LDR R0, [R0]
    BL BT_Send_Number

    
    LDR R0, =str_spo2
    BL BT_Send_String
    LDR R0, =spo2_current
    LDR R0, [R0]
    BL BT_Send_Number

    
    LDR R0, =str_press
    BL BT_Send_String
    LDR R0, =press_current
    LDR R0, [R0]
    BL BT_Send_Number

    
    LDR R0, =str_rtemp
    BL BT_Send_String
    LDR R0, =temp_data
    LDRSH R0, [R0]           
    ASRS R0, R0, #4          
    BL BT_Send_Number


    LDR R0, =str_drop
    BL BT_Send_String
    LDR R0, =Last_Rate
    LDR R0, [R0]
    BL BT_Send_Number


    LDR R0, =str_nl
    
    END