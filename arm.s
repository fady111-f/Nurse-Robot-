    AREA    |.text|, CODE, READONLY
    ALIGN 4
    
    EXPORT ARM_INIT

; Memory mapped registers for Clock and GPIO configuration
GPIOB_BASE      EQU 0x40020400
GPIOA_BASE      EQU 0x40020000
GPIO_MODER      EQU 0x00
GPIO_AFRL       EQU 0x20
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x30 
RCC_APB1ENR     EQU 0x40 
RCC_APB2ENR     EQU 0x44 

; TIM3 Registers for multi-channel PWM control (to move 4 servos)
TIM3_BASE       EQU 0x40000400  
TIM_CR1         EQU 0x00
TIM_EGR         EQU 0x14
TIM_CCMR1       EQU 0x18
TIM_CCMR2       EQU 0x1C
TIM_CCER        EQU 0x20
TIM_PSC         EQU 0x28
TIM_ARR         EQU 0x2C
TIM_CCR1        EQU 0x34        
TIM_CCR2        EQU 0x38       
TIM_CCR3        EQU 0x3C       
TIM_CCR4        EQU 0x40

; Initializes TIM3 and its corresponding GPIO pins to output PWM signals for the Robotic Arm
ARM_INIT
	LDR R0, =RCC_BASE  
    
    ; Enable Clock for GPIOA and GPIOB (AHB1 Bus)
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #0x03          
    STR R1, [R0, #RCC_AHB1ENR]
    
    ; Enable Clock for SYSCFG and potentially other APB2 peripherals
    LDR R1, [R0, #RCC_APB2ENR]
    ORR R1, R1, #(1 << 14)     
    STR R1, [R0, #RCC_APB2ENR]
    
    ; Enable Clock for TIM3 (APB1 Bus, bit 1)
    LDR R1, [R0, #RCC_APB1ENR]
    ORR R1, R1, #0x02          
    STR R1, [R0, #RCC_APB1ENR]

    ; Configure GPIOA pins (PA6, PA7) for Alternate Function mode (AF)
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0xF000            ; Clear mode bits for PA6, PA7
    BIC R1, R1, R2             
    LDR R2, =0xA000            ; Set mode bits to 10 (Alternate Function)
    ORR R1, R1, R2          
    STR R1, [R0, #GPIO_MODER]

    ; Assign Alternate Function 2 (TIM3) to PA6 and PA7
    LDR R1, [R0, #GPIO_AFRL]
    LDR R2, =0xFF000000        ; Clear AF bits for pins 6 and 7
    BIC R1, R1, R2             
    LDR R2, =0x22000000        ; Set AF2 for pins 6 and 7
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_AFRL]


    ; Configure GPIOB pins (PB0, PB1) for Alternate Function mode (AF)
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #0x0F          ; Clear mode bits for PB0, PB1
    ORR R1, R1, #0x0A          ; Set mode bits to 10 (Alternate Function)
    STR R1, [R0, #GPIO_MODER]

    ; Assign Alternate Function 2 (TIM3) to PB0 and PB1
    LDR R1, [R0, #GPIO_AFRL]
    BIC R1, R1, #0xFF         ; Clear AF bits for pins 0 and 1
    ORR R1, R1, #0x22          ; Set AF2 for pins 0 and 1
    STR R1, [R0, #GPIO_AFRL]

    ; Setup TIM3 to generate a 50Hz PWM signal (standard for servo motors)
    ; Assuming 16MHz clock, prescaler = 15 -> 1MHz timer clock (1 tick = 1us)
    LDR R0, =TIM3_BASE
    LDR R1, =15                
    STR R1, [R0, #TIM_PSC]
    LDR R1, =19999             ; Auto-Reload Register: 20000 ticks = 20ms period (50Hz)
    STR R1, [R0, #TIM_ARR]
    
    ; Configure TIM3 Channels 1-4 for PWM Mode 1 (Toggle output on compare match)
    LDR R1, =0x6868           
    STR R1, [R0, #TIM_CCMR1]   ; CH1 and CH2
    LDR R1, =0x6868            
    STR R1, [R0, #TIM_CCMR2]   ; CH3 and CH4
    
    ; Enable outputs for all 4 channels
    LDR R1, =0x1111            
    STR R1, [R0, #TIM_CCER]

    ; Set initial servo positions (Pulse width in microseconds)
    ; Usually, 1500us is center (90 deg), 500us is 0 deg, 2500us is 180 deg.
    LDR R1, =1600              
    STR R1, [R0, #TIM_CCR1]    ; Servo 1 pulse width
    LDR R1, =1500              
    STR R1, [R0, #TIM_CCR2]    ; Servo 2 pulse width
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR3]    ; Servo 3 pulse width
    LDR R1, =500               
    STR R1, [R0, #TIM_CCR4]    ; Servo 4 pulse width
    
    ; Generate an update event to load the prescaler and start the timer
    MOV R1, #1
    STR R1, [R0, #TIM_EGR]     
    STR R1, [R0, #TIM_CR1]     
	
	BX LR

    END
