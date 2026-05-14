;Clock 16 MHZ
;Pin A5 + 4.7 pull up
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30
GPIOA_BASE      EQU 0x40020000
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOA_OTYPER    EQU GPIOA_BASE + 0x04
GPIOA_IDR       EQU GPIOA_BASE + 0x10
GPIOA_BSRR      EQU GPIOA_BASE + 0x18

;data 
    AREA    DS_DATA, DATA, READWRITE
    ALIGN 4
    EXPORT  temp_data
temp_data   SPACE   2  

;code 
    AREA    DS_CODE, CODE, READONLY
    ALIGN 4
    
    EXPORT DS18B20_Init
    EXPORT DS18B20_UpdateTemp
;inti GPIOA + PA5
DS18B20_Init FUNCTION
    PUSH {R0, R1, LR}
    
    ; enable clock
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #1
    STR R1, [R0]

    ;A5 output mode
    LDR R0, =GPIOA_MODER
    LDR R1, [R0]
    BIC R1, R1, #(3 :SHL: 22)   
    ORR R1, R1, #(1 :SHL: 22)   
    STR R1, [R0]

    ;open drain mode
    LDR R0, =GPIOA_OTYPER
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 11)
    STR R1, [R0]

    BL pin_high
    POP {R0, R1, PC}
    ENDFUNC

;read and store the temp
DS18B20_UpdateTemp FUNCTION
    PUSH {R0, R1, R4, LR}
    
    
    BL ds18b20_reset            
    MOVS R0, #0xCC              
    BL ds18b20_write_byte
    MOVS R0, #0x44              
    BL ds18b20_write_byte
    

    LDR R0, =750
    BL ds_delay_ms


    BL ds18b20_reset            
    MOVS R0, #0xCC             
    BL ds18b20_write_byte
    MOVS R0, #0xBE              
    BL ds18b20_write_byte
    
    
    BL ds18b20_read_byte
    MOV R4, R0                  
    
    
    BL ds18b20_read_byte
    LSL R0, R0, #8              
    ORR R4, R4, R0              
    
   
    LDR R1, =temp_data
    STRH R4, [R1]               
    
    POP {R0, R1, R4, PC}
    ENDFUNC

; pull line low 
pin_low
    PUSH {R0, R1, LR}
    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 27)    
    STR R1, [R0]
    POP {R0, R1, PC}

; pull line high
pin_high
    PUSH {R0, R1, LR}
    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 11)       
    STR R1, [R0]
    POP {R0, R1, PC}

;reset pulse
ds18b20_reset
    PUSH {R0, LR}
    BL pin_low                  
    LDR R0, =480                
    BL ds_delay_us                 
    BL pin_high                 
    LDR R0, =60                 
    BL ds_delay_us                 
    LDR R0, =420                
    BL ds_delay_us                 
    POP {R0, PC}

ds18b20_write_byte
    PUSH {R1, R2, LR}
    MOVS R1, #8                 
    MOV R2, R0                  
w_loop
    LSRS R2, R2, #1             
    BCC write_0_bit             
    
    
    CPSID i                     
    BL pin_low
    MOVS R0, #2
    BL ds_delay_us                 
    BL pin_high
    CPSIE i                     
    
    MOVS R0, #60
    BL ds_delay_us                 
    B w_next
    
write_0_bit

    CPSID i                    
    BL pin_low
    MOVS R0, #60
    BL ds_delay_us                 
    BL pin_high
    CPSIE i                     
    
    MOVS R0, #2
    BL ds_delay_us                 
    
w_next
    SUBS R1, R1, #1
    BNE w_loop
    POP {R1, R2, PC}

ds18b20_read_byte
    PUSH {R1, R2, R3, LR}
    MOVS R1, #8                 
    MOVS R2, #0                 
    LDR R3, =GPIOA_IDR          
r_loop
    LSRS R2, R2, #1             
    
    
    CPSID i                   
    BL pin_low                  
    MOVS R0, #2
    BL ds_delay_us                 
    BL pin_high                 
    MOVS R0, #10
    BL ds_delay_us                 
    
    LDR R0, [R3]               
    TST R0, #(1 :SHL: 11)        
    BEQ r_zero                  
    ORR R2, R2, #0x80           
r_zero
    CPSIE i                    
    
    MOVS R0, #50
    BL ds_delay_us                 
    SUBS R1, R1, #1
    BNE r_loop
    
    MOV R0, R2                  
    POP {R1, R2, R3, PC}


ds_delay_us
    PUSH {R1, LR}
    MOVS R1, #4                 
    MUL R0, R1, R0              
    CMP R0, #0
    BEQ delay_us_end
delay_us_loop
    NOP                         
    SUBS R0, R0, #1             
    BNE delay_us_loop           
delay_us_end
    POP {R1, PC}

ds_delay_ms
    PUSH {R0, R1, LR}
ms_loop
    CMP R0, #0
    BEQ ms_end
    PUSH {R0}                   
    LDR R0, =1000               
    BL ds_delay_us                 
    POP {R0}                    
    SUBS R0, R0, #1             
    B ms_loop
ms_end
    POP {R0, R1, PC}
    
    END