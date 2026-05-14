
RCC_AHB1ENR     EQU 0x40023830

GPIOA_BASE      EQU 0x40020000
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOA_BSRR      EQU GPIOA_BASE + 0x18

GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOB_IDR       EQU GPIOB_BASE + 0x10
GPIOB_BSRR      EQU GPIOB_BASE + 0x18

SYSTICK_CTRL    EQU 0xE000E010
SYSTICK_LOAD    EQU 0xE000E014
SYSTICK_VAL     EQU 0xE000E018


    AREA    |.data|, DATA, READWRITE
    ALIGN 4
Last_Rate       DCD 0       
Total_Drops     DCD 0      
Current_Count   DCD 0       
Sec_Count       DCD 0      
Prev_State      DCD 1      
Prev_Time       DCD 0


    AREA    |.text|, CODE, READONLY
    EXPORT  IR_Drop_Init
    EXPORT  IR_Drop_Update
    EXPORT  Last_Rate
    EXPORT  Current_Count
    EXPORT  Total_Drops
    EXPORT  Sec_Count
    ALIGN 4


IR_Drop_Init FUNCTION
    PUSH {R0-R2, LR}

    
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #3             
    STR R1, [R0]


    LDR R0, =GPIOA_MODER
    LDR R1, [R0]
    LDR R2, =0x03000000         
    BIC R1, R1, R2
    LDR R2, =0x01000000         
    ORR R1, R1, R2
    STR R1, [R0]

    
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    LDR R2, =0x000003C0         
    BIC R1, R1, R2
    LDR R2, =0x00000100        
    ORR R1, R1, R2
    STR R1, [R0]


    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 12)
    STR R1, [R0]

    
    LDR R0, =SYSTICK_LOAD
    LDR R1, =15999999           
    STR R1, [R0]
    LDR R0, =SYSTICK_VAL
    MOV R1, #0                  
    STR R1, [R0]
    LDR R0, =SYSTICK_CTRL
    MOV R1, #5                 
    STR R1, [R0]

    POP {R0-R2, PC}
    ENDFUNC


IR_Drop_Update FUNCTION
    PUSH {R4-R7, LR}           


    LDR R0, =SYSTICK_CTRL
    LDR R1, [R0]
    TST R1, #(1 :SHL: 16)      
    BEQ check_ir               


    LDR R0, =Sec_Count
    LDR R5, [R0]
    ADD R5, R5, #1              
    STR R5, [R0]
    
    CMP R5, #10                 
    BLT check_ir


    LDR R0, =Current_Count
    LDR R4, [R0]              
    MOV R2, #6                  
    MUL R3, R4, R2              
    
    LDR R0, =Last_Rate          
    STR R3, [R0]               
    

    MOV R5, #0                  
    LDR R0, =Sec_Count
    STR R5, [R0]
    MOV R4, #0                  
    LDR R0, =Current_Count
    STR R4, [R0]

check_ir

    LDR R0, =GPIOB_IDR
    LDR R1, [R0]
    TST R1, #(1 :SHL: 3)       
    BEQ ir_is_blocked           
    B ir_is_clear               

ir_is_blocked
    LDR R0, =Prev_State
    LDR R6, [R0]
    CMP R6, #1                 
    BNE end_update             


    LDR R0, =Current_Count
    LDR R4, [R0]
    ADD R4, R4, #1              
    STR R4, [R0]               

    LDR R0, =Total_Drops
    LDR R7, [R0]
    ADD R7, R7, #1              
    STR R7, [R0]                
    
    LDR R0, =Prev_State
    MOV R6, #0                  
    STR R6, [R0]


    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 20)      
    STR R1, [R0]
    B end_update

ir_is_clear
    LDR R0, =Prev_State
    MOV R6, #1                 
    STR R6, [R0]


    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 4)        
    STR R1, [R0]

end_update
    POP {R4-R7, PC}            
    ENDFUNC

    END