; ==============================================================================
; main.s - HC-SR04 Ultrasonic Sensor with Main Loop
; Target: STM32F411CEU6 (Black Pill)
; Clock: 16 MHz Default HSI
; Pins:  PB10 = TRIG (Output)
;        PB2  = ECHO (Input)
; ==============================================================================

    ; Define peripheral addresses

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
    
TIM3_BASE       EQU 0x40000400  ; Switched to TIM3 for PA6/PA7/PB0/PB1
TIM5_BASE       EQU 0x40000C00  ; Used for IR Timing
TIM_CR1         EQU 0x00
TIM_EGR         EQU 0x14
TIM_CCMR1       EQU 0x18
TIM_CCMR2       EQU 0x1C
TIM_CCER        EQU 0x20
TIM_CNT         EQU 0x24
TIM_PSC         EQU 0x28
TIM_ARR         EQU 0x2C
TIM_CCR1        EQU 0x34        ; PA6 - Shoulder
TIM_CCR2        EQU 0x38        ; PA7 - Base
TIM_CCR3        EQU 0x3C        ; PB0 - Elbow
TIM_CCR4        EQU 0x40        ; PB1 - Gripper
    
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


    ; ==========================================================================
    ; DATA MEMORY
    ; ==========================================================================
    AREA    HC_DATA, DATA, READWRITE
    ALIGN 4
    EXPORT  distance_cm
distance_cm SPACE   4   ; 32-bit variable for the calculated distance (cm)
    ; ==========================================================================
    ; EXPORTED FUNCTIONS
    ; ==========================================================================
    AREA    |.text|, CODE, READONLY  ; Required by Keil for main entry point
    ALIGN 4
    
	EXPORT HCSR04_Init
	EXPORT HCSR04_Measure
	EXPORT hc_delay_us
	EXPORT ARM_INIT
; ==============================================================================
; MAIN LOOP
; ==============================================================================

	
ARM_INIT
	LDR R0, =RCC_BASE  ;ARM init
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #0x03          ; Enable GPIOA (bit 0) AND GPIOB (bit 1)
    STR R1, [R0, #RCC_AHB1ENR]
    
    LDR R1, [R0, #RCC_APB2ENR]
    ORR R1, R1, #(1 << 14)     ; Enable SYSCFG
    STR R1, [R0, #RCC_APB2ENR]
    
    LDR R1, [R0, #RCC_APB1ENR]
    ORR R1, R1, #0x0A          ; Enable TIM3 (bit 1) AND TIM5 (bit 3)
    STR R1, [R0, #RCC_APB1ENR]

    ; 2. Configure GPIOA (PA6, PA7 to AF Mode for Servos)
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0xF000            ; Mask to clear PA6, PA7
    BIC R1, R1, R2             
    LDR R2, =0xA000            ; Set PA6, PA7 to AF (Binary: 1010 0000 0000 0000)
    ORR R1, R1, R2          
    STR R1, [R0, #GPIO_MODER]

    LDR R1, [R0, #GPIO_AFRL]
    LDR R2, =0xFF000000        ; Mask to clear PA6, PA7 AF
    BIC R1, R1, R2             
    LDR R2, =0x22000000        ; Set AF2 (TIM3) for PA6, PA7
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_AFRL]

    ; 3. Configure GPIOB (PB0, PB1 to AF Mode for Servos)
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #0x0F          ; Mask to clear PB0, PB1
    ORR R1, R1, #0x0A          ; Set PB0, PB1 to AF (Binary: 1010)
    STR R1, [R0, #GPIO_MODER]

    LDR R1, [R0, #GPIO_AFRL]
    BIC R1, R1, #0xFF          ; Mask to clear PB0, PB1 AF
    ORR R1, R1, #0x22          ; Set AF2 (TIM3) for PB0, PB1
    STR R1, [R0, #GPIO_AFRL]

    ; 4. Configure TIM5 (For IR Timing)
    LDR R0, =TIM5_BASE
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =0xFFFFFFFF        
    STR R1, [R0, #TIM_ARR]
    MOV R1, #1
    STR R1, [R0, #TIM_EGR]     
    STR R1, [R0, #TIM_CR1]     

    ; 5. Configure TIM3 (For Servos - 20ms PWM)
    LDR R0, =TIM3_BASE
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =19999             
    STR R1, [R0, #TIM_ARR]
    
    ; Setup PWM Mode 1 for Channels 1, 2, 3, 4
    LDR R1, =0x6868            ; CCMR1: CH1 & CH2 PWM Mode 1
    STR R1, [R0, #TIM_CCMR1]
    LDR R1, =0x6868            ; CCMR2: CH3 & CH4 PWM Mode 1
    STR R1, [R0, #TIM_CCMR2]
    
    LDR R1, =0x1111            ; CCER: Enable CH1, CH2, CH3, CH4 outputs
    STR R1, [R0, #TIM_CCER]

    ; 6. Set Initial Servo Positions
    LDR R1, =1600              
    STR R1, [R0, #TIM_CCR1]    ; PA6: Shoulder (Starts at 1600)
    LDR R1, =1500              
    STR R1, [R0, #TIM_CCR2]    ; PA7: Base (Starts at 1500)
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR3]    ; PB0: Elbow (Starts at 500)
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR4]    ; PB1: Gripper (Starts at 500 - Closed)
    
    MOV R1, #1                 ; Enable TIM3
    STR R1, [R0, #TIM_CR1]
	
	BX LR

; ==============================================================================
; HCSR04_Init: Configures PB10 (TRIG) and PB2 (ECHO), and enables clocks
; ==============================================================================
HCSR04_Init FUNCTION
    PUSH {R0, R1, LR}
    
    ; 1. Enable GPIOB Clock (Bit 1 in AHB1ENR)
	; --- 1. Enable Clock for GPIOA and GPIOB ---
    LDR R0, =0x40023830       ; Address of RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03         ; Set Bit 0 (GPIOA) and Bit 1 (GPIOB)
    STR R1, [R0]

    ; --- 2. Configure GPIOA (PA1, PA2, PA3, PA4 as Output) ---
    LDR R0, =0x40020000       ; Address of GPIOA_MODER
    LDR R1, [R0]
    ; Mask to clear bits [9:2] (PA1-PA4)
    LDR R2, =0xFFFFFC03       
    AND R1, R1, R2
    ; Set bits [9:2] to 01-01-01-01 (Output)
    LDR R2, =0x00000154       
    ORR R1, R1, R2
    STR R1, [R0]

	LDR R0, =0x40020014       ; Load the address of GPIOA_ODR (GPIOA_BASE + 0x14)
    LDR R1, [R0]              ; Read the current state of GPIOA
    BIC R1, R1, #0x1E         ; Clear bits 1, 2, 3, and 4
    STR R1, [R0]              ; Store the updated value back to ODR
    ; --- 3. Configure GPIOB (PB10 as Output, PB2 as Input) ---
    LDR R0, =0x40020400       ; Address of GPIOB_MODER
    LDR R1, [R0]
    ; Mask to clear bits [21:20] (PB10) and [5:4] (PB2)
    LDR R2, =0xFFCFFFCF       
    AND R1, R1, R2
    ; Set PB10 to Output (01), PB2 is already Input (00) from the AND mask
    LDR R2, =0x00100000       
    ORR R1, R1, R2
    STR R1, [R0]
    LDR R0, =RCC_BASE
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #(1 :SHL: 1)    ; Set Bit 1 for GPIOB
    STR R1, [R0]

    ; 2. Configure Pins in MODER
    ; PB10 as Output (Bits 21:20 = 01)
    ; PB2 as Input   (Bits 5:4 = 00)
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    
    ; Clear PB10 bits (21:20) and PB2 bits (5:4)
    BIC R1, R1, #(3 :SHL: 20)   
    BIC R1, R1, #(3 :SHL: 4)    
    
    ; Set PB10 to Output (01 at bit 20), PB2 remains 00 (Input)
    ORR R1, R1, #(1 :SHL: 20)   
    STR R1, [R0]

    ; 3. Ensure TRIG (PB10) is LOW initially
    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 26)       ; Reset PB10 (Bit 16 + 10 = 26)
    STR R1, [R0]

    POP {R0, R1, PC}
    ENDFUNC

; ==============================================================================
; HCSR04_Measure: Triggers sensor, measures echo width, and calculates distance
; ==============================================================================
HCSR04_Measure FUNCTION
    PUSH {R0-R5, LR}
    
    ; Phase 1: Send 10us HIGH pulse on TRIG (PB10)
    LDR R3, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 10)       ; Set PB10
    STR R1, [R3]
    
    MOVS R0, #10                ; 10us delay
    BL hc_delay_us
    
    MOV R1, #(1 :SHL: 26)       ; Reset PB10
    STR R1, [R3]
    
    ; Phase 2: Wait for ECHO (PB2) to go HIGH
    LDR R3, =GPIOB_IDR
    LDR R5, =60000              ; Timeout counter
wait_rise
    SUBS R5, R5, #1
    BEQ measure_error           
    LDR R0, [R3]
    TST R0, #(1 :SHL: 2)        ; Check PB2
    BEQ wait_rise               

    ; Phase 3: Measure ECHO HIGH time in microseconds
    MOVS R4, #0                 
    LDR R5, =30000              ; Max timeout (~500cm limit)
wait_fall
    ; --- 16-Cycle Loop for 1us accuracy at 16 MHz ---
    LDR R0, [R3]                
    TST R0, #(1 :SHL: 2)        ; Check PB2
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
    ; Phase 4: Calculate Distance (Pulse width / 58)
    MOVS R1, #58
    UDIV R4, R4, R1             ; Hardware division
    
save_dist
    LDR R1, =distance_cm
    STR R4, [R1]                ; Update variable in RAM
    B measure_end

measure_error
    MOVS R4, #0                 ; Write 0 on error/timeout
    LDR R1, =distance_cm
    STR R4, [R1]

measure_end
    POP {R0-R5, PC}
    ENDFUNC

; ==============================================================================
; INTERNAL HELPER FUNCTIONS
; ==============================================================================
hc_delay_us
    PUSH {R1, LR}
    MOVS R1, #4                 ; 4-cycle loop = 0.25us at 16MHz
    MUL R0, R1, R0              
    CMP R0, #0
    BEQ delay_us_end
delay_us_loop
    NOP                         
    SUBS R0, R0, #1             
    BNE delay_us_loop           
delay_us_end
    POP {R1, PC}

distance_state_logic
    ; 1. Trigger the sensor and get the distance
	BL FORWARD
    BL HCSR04_Measure
    
    ; 2. Load the calculated distance into R2
    LDR R1, =distance_cm
    LDR R2, [R1]
    
    ; 3. Compare distance to your threshold (e.g., 20 cm)
CHECK0
	CMP  R2, #0
    BEQ distance_too_close
	BGT COMPstop
CHECK1
	CMP  R2, #28
    BEQ distance_too_close
	BGT COMP2
	B   end_distance_check
COMP2
	CMP  R2, #35
	BLE  distance_too_close
	B    end_distance_check
COMPstop
	CMP  R2, #20
	BLE  distance_too_close2
	B     CHECK1
distance_too_close
    BL BREAK
distance_too_close2
	BL BREAK2
end_distance_check
    ; 4. Add a 60ms delay to prevent ultrasonic echo overlap (pinging too fast)
    LDR R0, =60000
    BL hc_delay_us
    
    ; Go back to the top of the main loop
    B distance_state_logic
	
FORWARD
	LDR R0, =GPIOA_ODR
    LDR R1, =0x0C
    STR R1, [R0]

	
Delay2
    LDR     R2, =0x200000       ; Counter value
DelayLoop2
    SUBS    R2, R2, #1
    BNE     DelayLoop2
	BX LR
BREAK
    LDR R0, =GPIOA_ODR
    LDR R1, =0x1E
    STR R1, [R0]
 ; Step 1: Base changes from 1500 to 1000
    LDR R0, =TIM3_BASE
    LDR R1, =1000
    STR R1, [R0, #TIM_CCR2]
    BL Delay_1s

    ; Step 2: Open the gripper (Assuming 750 is Open)
    LDR R1, =750
    STR R1, [R0, #TIM_CCR4]
    BL Delay_1s

    ; Step 3: Move the elbow full down (To 1500)
    LDR R1, =1500
    STR R1, [R0, #TIM_CCR3]
    BL Delay_1s
    
    ; Step 5: Shoulder to 600 
    ; (It started at 1600, moving to 600 lifts it)
    LDR R1, =600
    STR R1, [R0, #TIM_CCR1]
    BL Delay_1s

    ; Step 4: Close the gripper (To 500)
    LDR R1, =500
    STR R1, [R0, #TIM_CCR4]
    BL Delay_1s
    
    ; (It started at 1600, moving to 600 lifts it) -> Returning shoulder to 1400
    LDR R1, =1400
    STR R1, [R0, #TIM_CCR1]
    BL Delay_1s

    ; Step 6: Base to 1500
    LDR R1, =1500
    STR R1, [R0, #TIM_CCR2]
    BL Delay_1s

    ; Step 7: Open gripper
    LDR R1, =750
    STR R1, [R0, #TIM_CCR4]
    BL Delay_1s

    ; Step 8: Return to initial values
    LDR R1, =1600
    STR R1, [R0, #TIM_CCR1]    ; Shoulder Reset
    LDR R1, =1500
    STR R1, [R0, #TIM_CCR2]    ; Base Reset
    LDR R1, =500
    STR R1, [R0, #TIM_CCR3]    ; Elbow Reset
    LDR R1, =500
    STR R1, [R0, #TIM_CCR4]    ; Gripper Reset
    
    BL Delay_1s                ; Give them time to return to start

    B distance_state_logic
	
BREAK2
    LDR R0, =GPIOA_ODR
    LDR R1, =0x1E
    STR R1, [R0]
	
Delay_1s
    LDR R2, =4000000           ; Loop counter for rough 1s delay
Delay_Inner
    SUBS R2, R2, #1
    BNE Delay_Inner
    BX LR
EXIT
	B EXIT

    END