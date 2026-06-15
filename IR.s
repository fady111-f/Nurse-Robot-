	AREA |.text|, CODE, READONLY, ALIGN=2
    THUMB

; Memory mapped registers for Clock and GPIO configuration
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x30 
RCC_APB1ENR     EQU 0x40 
RCC_APB2ENR     EQU 0x44 
    
GPIOA_BASE      EQU 0x40020000
GPIOB_BASE      EQU 0x40020400  
GPIO_MODER      EQU 0x00
GPIO_ODR        EQU 0x14
    
; Timer 4 registers for measuring pulse widths of the IR signal
TIM4_BASE       EQU 0x40000800  
TIM_CR1         EQU 0x00
TIM_EGR         EQU 0x14
TIM_CNT         EQU 0x24
TIM_PSC         EQU 0x28
TIM_ARR         EQU 0x2C

; SYSCFG to configure external interrupts (EXTI) to specific GPIO pins
SYSCFG_BASE     EQU 0x40013800
SYSCFG_EXTICR2  EQU 0x0C        
    
; EXTI registers to handle the IR sensor pin interrupt
EXTI_BASE       EQU 0x40013C00
EXTI_IMR        EQU 0x00
EXTI_FTSR       EQU 0x0C
EXTI_PR         EQU 0x14
    
; NVIC register to enable the EXTI interrupt in the core
NVIC_ISER0      EQU 0xE000E100

    EXPORT IR_Init
    EXPORT EXTI9_5_IRQHandler    
    
    IMPORT ir_command
    IMPORT ir_flag


    AREA IR_VARS, DATA, READWRITE, ALIGN=2
ir_data      DCD 0  ; Stores the 32-bit decoded NEC command from the remote
ir_bitcount  DCD 0  ; Counts how many bits of the NEC command have been received


    AREA |.text|, CODE, READONLY, ALIGN=2

; Initializes the IR receiver on PB5, configures TIM4 for timing, and sets up EXTI interrupts
IR_Init FUNCTION
    PUSH {R4, LR}                  

    ; Enable clocks for GPIOA, GPIOB, SYSCFG (APB2), and TIM4 (APB1)
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

    ; Configure GPIOA (likely used for other generic LEDs or outputs)
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0x000002A8             
    BIC R1, R1, R2             
    LDR R2, =0x00000154             
    ORR R1, R1, R2             
    STR R1, [R0, #GPIO_MODER]

    ; Configure PB5 as input for the IR receiver
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #(3 << 10)     
    STR R1, [R0, #GPIO_MODER]

    ; Setup TIM4 to count microseconds (Prescaler = 15 for 16MHz clock)
    LDR R0, =TIM4_BASE         
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =0xFFFFFFFF        ; Max auto-reload value
    STR R1, [R0, #TIM_ARR]
    MOV R1, #1
    STR R1, [R0, #TIM_EGR]     ; Trigger update to apply prescaler
    STR R1, [R0, #TIM_CR1]     ; Enable TIM4

    ; Route EXTI Line 5 to Port B (PB5)
    LDR R0, =SYSCFG_BASE
    LDR R1, [R0, #SYSCFG_EXTICR2]
    BIC R1, R1, #(0xF << 4)    
    ORR R1, R1, #(0x1 << 4)    
    STR R1, [R0, #SYSCFG_EXTICR2]

    ; Configure EXTI Line 5 to trigger on falling edges (since IR receiver pulls LOW on signal)
    LDR R0, =EXTI_BASE
    LDR R1, [R0, #EXTI_FTSR]
    ORR R1, R1, #(1 << 5)      
    STR R1, [R0, #EXTI_FTSR]
    LDR R1, [R0, #EXTI_IMR]    ; Unmask the interrupt
    ORR R1, R1, #(1 << 5)      
    STR R1, [R0, #EXTI_IMR]

    ; Enable EXTI9_5 interrupt in the NVIC (Position 23)
    LDR R0, =NVIC_ISER0
    LDR R1, [R0]
    ORR R1, R1, #(1 << 23)     
    STR R1, [R0]
    
    ; Clear initial state variables
    LDR R0, =ir_data
    MOV R1, #0
    STR R1, [R0]
    LDR R0, =ir_bitcount
    STR R1, [R0]

    POP {R4, PC}                  
    ENDFUNC

; Interrupt Service Routine for PB5 (IR Receiver)
; Uses NEC protocol timing to decode the incoming remote control signal
EXTI9_5_IRQHandler FUNCTION
    PUSH {R4-R7, R12, LR}            

    ; Clear the pending interrupt flag for Line 5
    LDR R0, =EXTI_BASE
    MOV R1, #(1 << 5)          
    STR R1, [R0, #EXTI_PR]

    ; Read the elapsed time since the last falling edge from TIM4, then reset the timer
    LDR R0, =TIM4_BASE        
    LDR R1, [R0, #TIM_CNT]     
    MOV R2, #0
    STR R2, [R0, #TIM_CNT]     

    ; Load current decoded data and bit count
    LDR R4, =ir_data
    LDR R5, [R4]               
    LDR R6, =ir_bitcount
    LDR R7, [R6]               

    ; Check for NEC Protocol Start Bit (~13.5 ms gap)
    LDR R2, =13000
    CMP R1, R2
    BLT Check_Bit              ; If gap is smaller, check if it's a regular data bit
    LDR R2, =14000
    CMP R1, R2
    BGT Reset_State            ; If gap is too large, reset
    ; If it falls within 13-14ms, it's a valid start pulse. Reset counters to receive 32 bits.
    MOV R5, #0                 
    MOV R7, #0                 
    B Save_State

Check_Bit
    ; Check if pulse represents Logic 0 (~1.125 ms gap)
    LDR R2, =900
    CMP R1, R2
    BLT Reset_State            ; Too short, error!
    LDR R2, =1400
    CMP R1, R2
    BLT Is_Logic_0

    ; Check if pulse represents Logic 1 (~2.25 ms gap)
    LDR R2, =2000
    CMP R1, R2
    BLT Reset_State            ; Error zone between Logic 0 and 1
    LDR R2, =2500
    CMP R1, R2
    BGT Reset_State            ; Too long for Logic 1

Is_Logic_1
    ; Logic 1 received: shift data right and insert a '1' bit at the top (MSB)
    LSR R5, R5, #1             
    LDR R2, =0x80000000
    ORR R5, R5, R2             
    ADD R7, R7, #1             ; Increment bit counter
    B Check_Done

Is_Logic_0
    ; Logic 0 received: shift data right and leave the top bit '0'
    LSR R5, R5, #1             
    ADD R7, R7, #1             ; Increment bit counter
    B Check_Done

Check_Done
    ; Check if we have received a full 32-bit NEC frame
    CMP R7, #32
    BNE Save_State             
    
    ; A full 32-bit frame is received. Verify the checksum.
    ; NEC format: [Address][~Address][Command][~Command]
    ; Extract the Command byte
    LSR R2, R5, #16
    AND R2, R2, #0xFF          
    
    ; Extract the inverted Command byte (~Command)
    LSR R3, R5, #24
    AND R3, R3, #0xFF          
    
    ; Adding them should equal 0xFF (since Command + ~Command = 0xFF)
    ADD R3, R3, R2
    CMP R3, #0xFF
    BNE Reset_State            ; Corrupted frame, ignore it

    ; Valid frame received! Store the command and flag it for the main loop
    LDR R0, =ir_command
    STRB R2, [R0]              
    
    LDR R0, =ir_flag
    MOV R1, #1
    STRB R1, [R0]              
    
    B Reset_State

Reset_State
    ; Reset the bit count and data buffer for the next transmission
    MOV R7, #0                 
    MOV R5, #0

Save_State
    ; Save the current state variables back to memory
    STR R5, [R4]               
    STR R7, [R6]               

    POP {R4-R7, R12, PC}            
    ENDFUNC

    ALIGN
    END