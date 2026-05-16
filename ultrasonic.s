

GPIOB_BASE      EQU 0x40020400
GPIOA_BASE  	EQU  0x40020000
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOB_IDR       EQU GPIOB_BASE + 0x10
GPIOB_BSRR      EQU GPIOB_BASE + 0x18
GPIOA_BSRR 	    EQU   0x40020018
GPIOA_ODR 		EQU GPIOA_BASE + 0X14
GPIOB_ODR 		EQU GPIOB_BASE + 0X14	
BUTTON_0 EQU 0x19 
BUTTON_1 EQU 0x45
BUTTON_3 EQU 0x47
BUTTON_7 EQU 0x07
BUTTON_8 EQU 0x15
BUTTON_9 EQU 0x09
	
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x30 
RCC_APB1ENR     EQU 0x40 
RCC_APB2ENR     EQU 0x44 
    

GPIO_MODER      EQU 0x00
GPIO_AFRL       EQU 0x20
    
TIM3_BASE       EQU 0x40000400  


TIM_CR1         EQU 0x00
TIM_EGR         EQU 0x14
TIM_CCMR1       EQU 0x18
TIM_CCMR2       EQU 0x1C
TIM_CCER        EQU 0x20
TIM_CNT         EQU 0x24
TIM_PSC         EQU 0x28
TIM_ARR         EQU 0x2C
TIM_CCR1        EQU 0x34        
TIM_CCR2        EQU 0x38       
TIM_CCR3        EQU 0x3C       
TIM_CCR4        EQU 0x40        
    
SYSCFG_BASE     EQU 0x40013800
SYSCFG_EXTICR1  EQU 0x08
    
EXTI_BASE       EQU 0x40013C00
EXTI_IMR        EQU 0x00
EXTI_FTSR       EQU 0x0C
EXTI_PR         EQU 0x14
    
NVIC_ISER0      EQU 0xE000E100
    
IR_DATA_ADDR       EQU 0x20000000  
IR_BITCOUNT_ADDR   EQU 0x20000004  
GRIPPER_STATE_ADDR EQU 0x20000008  



    AREA    HC_DATA, DATA, READWRITE
    ALIGN 4
    EXPORT  distance_cm
distance_cm SPACE   4   


    AREA    |.text|, CODE, READONLY
    ALIGN 4
    
	EXPORT HCSR04_Init
	EXPORT HCSR04_Measure
	EXPORT hc_delay_us
	EXPORT ARM_INIT


	
ARM_INIT
	LDR R0, =RCC_BASE  
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #0x03          
    STR R1, [R0, #RCC_AHB1ENR]
    
    LDR R1, [R0, #RCC_APB2ENR]
    ORR R1, R1, #(1 << 14)     
    STR R1, [R0, #RCC_APB2ENR]
    
    LDR R1, [R0, #RCC_APB1ENR]
    ORR R1, R1, #0x02          
    
    STR R1, [R0, #RCC_APB1ENR]

   
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0xF000            
    BIC R1, R1, R2             
    LDR R2, =0xA000            
    ORR R1, R1, R2          
    STR R1, [R0, #GPIO_MODER]

    LDR R1, [R0, #GPIO_AFRL]
    LDR R2, =0xFF000000        
    BIC R1, R1, R2             
    LDR R2, =0x22000000        
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_AFRL]


    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #0x0F          
    ORR R1, R1, #0x0A          
    STR R1, [R0, #GPIO_MODER]

    LDR R1, [R0, #GPIO_AFRL]
    BIC R1, R1, #0xFF         
    ORR R1, R1, #0x22          
    STR R1, [R0, #GPIO_AFRL]

    
   



    

    LDR R0, =TIM3_BASE
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =19999             
    STR R1, [R0, #TIM_ARR]
    

    LDR R1, =0x6868           
    STR R1, [R0, #TIM_CCMR1]
    LDR R1, =0x6868            
    STR R1, [R0, #TIM_CCMR2]
    
    LDR R1, =0x1111            
    STR R1, [R0, #TIM_CCER]


    LDR R1, =1600              
    STR R1, [R0, #TIM_CCR1]    
    LDR R1, =1500              
    STR R1, [R0, #TIM_CCR2]   
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR3]    
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR4]    
    
    
    MOV R1, #1
    STR R1, [R0, #TIM_EGR]     
    STR R1, [R0, #TIM_CR1]     
	
	BX LR


HCSR04_Init FUNCTION
    PUSH {R0, R1, LR}
    
	
    LDR R0, =0x40023830      
    LDR R1, [R0]
    ORR R1, R1, #0x03        
    STR R1, [R0]


    LDR R0, =0x40020000      
    LDR R1, [R0]
    LDR R2, =0xFFFFFC03       
    AND R1, R1, R2
    LDR R2, =0x00000154       
    ORR R1, R1, R2
    STR R1, [R0]

	LDR R0, =0x40020014      
    LDR R1, [R0]
    BIC R1, R1, #0x1E        
    STR R1, [R0]


    LDR R0, =0x40020400      
    LDR R1, [R0]
    LDR R2, =0xFFCFFFCF       
    AND R1, R1, R2
    LDR R2, =0x00100000       
    ORR R1, R1, R2
    STR R1, [R0]

    LDR R0, =RCC_BASE
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #(1 :SHL: 1)   
    STR R1, [R0]


    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    
    BIC R1, R1, #(3 :SHL: 20)   
    BIC R1, R1, #(3 :SHL: 4)    
    ORR R1, R1, #(1 :SHL: 20)   
    STR R1, [R0]


    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 26)       
    STR R1, [R0]

    POP {R0, R1, PC}
    ENDFUNC


HCSR04_Measure FUNCTION
    PUSH {R0-R5, LR}
    
    
    LDR R3, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 10)       
    STR R1, [R3]
    
    MOVS R0, #10                
    BL hc_delay_us
    
    MOV R1, #(1 :SHL: 26)       
    STR R1, [R3]
    

    LDR R3, =GPIOB_IDR
    LDR R5, =60000             
wait_rise
    SUBS R5, R5, #1
    BEQ measure_error           
    LDR R0, [R3]
    TST R0, #(1 :SHL: 2)       
    BEQ wait_rise               


    MOVS R4, #0                 
    LDR R5, =30000              
wait_fall
    LDR R0, [R3]                
    TST R0, #(1 :SHL: 2)       
    BEQ calc_dist               
    ADD R4, R4, #1              
    CMP R4, R5                  
    BGE calc_dist               
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    B wait_fall                 

calc_dist
   
    MOVS R1, #58
    UDIV R4, R4, R1            
    
save_dist
    LDR R1, =distance_cm
    STR R4, [R1]
    B measure_end

measure_error
    MOVS R4, #0
    LDR R1, =distance_cm
    STR R4, [R1]

measure_end
    POP {R0-R5, PC}
    ENDFUNC


hc_delay_us
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

EXIT
	B EXIT

    END
