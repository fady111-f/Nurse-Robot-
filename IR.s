	AREA |.text|, CODE, READONLY, ALIGN=2
    THUMB


RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x30 
RCC_APB1ENR     EQU 0x40 
RCC_APB2ENR     EQU 0x44 
    
GPIOA_BASE      EQU 0x40020000
GPIOB_BASE      EQU 0x40020400  
GPIO_MODER      EQU 0x00
GPIO_ODR        EQU 0x14
    
TIM4_BASE       EQU 0x40000800  
TIM_CR1         EQU 0x00
TIM_EGR         EQU 0x14
TIM_CNT         EQU 0x24
TIM_PSC         EQU 0x28
TIM_ARR         EQU 0x2C

SYSCFG_BASE     EQU 0x40013800
SYSCFG_EXTICR2  EQU 0x0C        
    
EXTI_BASE       EQU 0x40013C00
EXTI_IMR        EQU 0x00
EXTI_FTSR       EQU 0x0C
EXTI_PR         EQU 0x14
    
NVIC_ISER0      EQU 0xE000E100

    EXPORT IR_Init
    EXPORT EXTI9_5_IRQHandler    
    
    IMPORT ir_command
    IMPORT ir_flag


    AREA IR_VARS, DATA, READWRITE, ALIGN=2
ir_data      DCD 0  
ir_bitcount  DCD 0  


    AREA |.text|, CODE, READONLY, ALIGN=2

IR_Init FUNCTION
    PUSH {R4, LR}                  

    LDR R0, =RCC_BASE
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #0x03          
    STR R1, [R0, #RCC_AHB1ENR]
    
    LDR R1, [R0, #RCC_APB2ENR]
    ORR R1, R1, #(1 << 14)     
    STR R1, [R0, #RCC_APB2ENR]
    
    LDR R1, [R0, #RCC_APB1ENR]
    ORR R1, R1, #(1 << 2)      
    STR R1, [R0, #RCC_APB1ENR]


    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0x000002A8             
    BIC R1, R1, R2             
    LDR R2, =0x00000154             
    ORR R1, R1, R2             
    STR R1, [R0, #GPIO_MODER]

    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #(3 << 10)     
    STR R1, [R0, #GPIO_MODER]


    LDR R0, =TIM4_BASE         
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =0xFFFFFFFF        
    STR R1, [R0, #TIM_ARR]
    MOV R1, #1
    STR R1, [R0, #TIM_EGR]     
    STR R1, [R0, #TIM_CR1]     

    
    LDR R0, =SYSCFG_BASE
    LDR R1, [R0, #SYSCFG_EXTICR2]
    BIC R1, R1, #(0xF << 4)    
    ORR R1, R1, #(0x1 << 4)    
    STR R1, [R0, #SYSCFG_EXTICR2]


    LDR R0, =EXTI_BASE
    LDR R1, [R0, #EXTI_FTSR]
    ORR R1, R1, #(1 << 5)      
    STR R1, [R0, #EXTI_FTSR]
    LDR R1, [R0, #EXTI_IMR]
    ORR R1, R1, #(1 << 5)      
    STR R1, [R0, #EXTI_IMR]

    
    LDR R0, =NVIC_ISER0
    LDR R1, [R0]
    ORR R1, R1, #(1 << 23)     
    STR R1, [R0]
    
    
    LDR R0, =ir_data
    MOV R1, #0
    STR R1, [R0]
    LDR R0, =ir_bitcount
    STR R1, [R0]

    POP {R4, PC}                  
    ENDFUNC

EXTI9_5_IRQHandler FUNCTION
    PUSH {R4-R7, R12, LR}            

    
    LDR R0, =EXTI_BASE
    MOV R1, #(1 << 5)          
    STR R1, [R0, #EXTI_PR]

    
    LDR R0, =TIM4_BASE        
    LDR R1, [R0, #TIM_CNT]     
    MOV R2, #0
    STR R2, [R0, #TIM_CNT]     

    
    LDR R4, =ir_data
    LDR R5, [R4]               
    LDR R6, =ir_bitcount
    LDR R7, [R6]               

    
    LDR R2, =13000
    CMP R1, R2
    BLT Check_Bit
    LDR R2, =14000
    CMP R1, R2
    BGT Reset_State
    MOV R5, #0                 
    MOV R7, #0                 
    B Save_State

Check_Bit
    LDR R2, =900
    CMP R1, R2
    BLT Reset_State            
    LDR R2, =1400
    CMP R1, R2
    BLT Is_Logic_0

    LDR R2, =2000
    CMP R1, R2
    BLT Reset_State            
    LDR R2, =2500
    CMP R1, R2
    BGT Reset_State            

Is_Logic_1
    LSR R5, R5, #1             
    LDR R2, =0x80000000
    ORR R5, R5, R2             
    ADD R7, R7, #1             
    B Check_Done

Is_Logic_0
    LSR R5, R5, #1             
    ADD R7, R7, #1             
    B Check_Done

Check_Done
    CMP R7, #32
    BNE Save_State             
    

    LSR R2, R5, #16
    AND R2, R2, #0xFF          
    
    LSR R3, R5, #24
    AND R3, R3, #0xFF          
    
    ADD R3, R3, R2
    CMP R3, #0xFF
    BNE Reset_State            


    LDR R0, =ir_command
    STRB R2, [R0]              
    
    LDR R0, =ir_flag
    MOV R1, #1
    STRB R1, [R0]              
    
    B Reset_State

Reset_State
    MOV R7, #0                 
    MOV R5, #0

Save_State
    STR R5, [R4]               
    STR R7, [R6]               

    POP {R4-R7, R12, PC}            
    ENDFUNC

    ALIGN
    END