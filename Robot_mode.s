
GPIOA_BASE_RM   EQU 0x40020000
GPIOA_ODR_RM    EQU GPIOA_BASE_RM + 0x14

TIM3_BASE_RM    EQU 0x40000400
TIM5_BASE_RM    EQU 0x40000C00

TIM_CR1_RM      EQU 0x00
TIM_CNT_RM      EQU 0x24
TIM_PSC_RM      EQU 0x28
TIM_ARR_RM      EQU 0x2C
TIM_CCR1_RM     EQU 0x34
TIM_CCR2_RM     EQU 0x38
TIM_CCR3_RM     EQU 0x3C
TIM_CCR4_RM     EQU 0x40


DIST_ARM_LOW1    EQU 85      
DIST_ARM_HIGH1   EQU 100      
DIST_ARM_LOW2    EQU 155      
DIST_ARM_HIGH2   EQU 170      
DIST_STOP       EQU 30    


    IMPORT  HCSR04_Measure      
    IMPORT  hc_delay_us         
    IMPORT  distance_cm        
    IMPORT  ir_flag            
    IMPORT  ir_command         


    AREA    ROBOT_CODE, CODE, READONLY
    ALIGN   4

    EXPORT  Enter_Robot_Mode    


Enter_Robot_Mode FUNCTION
    PUSH    {R4-R11, LR}


    BL      RM_StopMotors


robot_main_loop


    LDR     R0, =ir_flag
    LDRB    R1, [R0]
    CMP     R1, #0
    BNE     robot_exit         


    BL      RM_Forward


    BL      HCSR04_Measure


    LDR     R0, =distance_cm
    LDR     R4, [R0]          



    CMP     R4, #0
    BEQ     rm_too_close        

    CMP     R4, #DIST_STOP
    BLE     rm_too_close        
CHECK1
    CMP     R4, #DIST_ARM_LOW1
    BLT     rm_continue        
    CMP     R4, #DIST_ARM_HIGH1
    BGT     CHECK2   	
	B 		TRIGGER_ARM
CHECK2	
    CMP     R4, #DIST_ARM_LOW2
    BLT     rm_continue         
    CMP     R4, #DIST_ARM_HIGH2
    BGT     rm_continue         

TRIGGER_ARM

    BL      RM_Brake
    BL      RM_ArmSequence      

    B       rm_ping_delay

rm_too_close
 
    BL      RM_Brake
    B       robot_exit

rm_continue

    B       rm_ping_delay

rm_ping_delay

    LDR     R0, =60000         
    BL      hc_delay_us
    B       robot_main_loop

robot_exit

    LDR     R0, =ir_flag
    MOV     R1, #0
    STRB    R1, [R0]


    BL      RM_StopMotors

    POP     {R4-R11, PC}
    ENDFUNC


RM_Forward
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E       
    ORR     R1, R1, #0x0C       
    STR     R1, [R0]
    POP     {R0, R1, PC}


RM_StopMotors
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E       
    STR     R1, [R0]
    POP     {R0, R1, PC}


RM_Brake
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E
    ORR     R1, R1, #0x1E      
    STR     R1, [R0]
    POP     {R0, R1, PC}


RM_ArmSequence FUNCTION
    PUSH    {R0-R2, LR}
    LDR     R0, =TIM3_BASE_RM


    LDR     R1, =1000
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s


    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s


    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s


    LDR     R1, =600
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s
	

    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s
	

    LDR     R1, =1600
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s


    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s
	

    LDR     R1, =700
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s


    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s
	

    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s
	

    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s


    LDR     R1, =1400
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s

 
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s

 
    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s

  
    LDR     R1, =1600
    STR     R1, [R0, #TIM_CCR1_RM]    
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR2_RM]    
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR3_RM]    
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]    
    BL      RM_Delay_1s

    POP     {R0-R2, PC}
    ENDFUNC


RM_Delay_1s
    PUSH    {R2, LR}
    LDR     R2, =4000000
rm_delay_loop
    SUBS    R2, R2, #1
    BNE     rm_delay_loop
    POP     {R2, PC}

    END