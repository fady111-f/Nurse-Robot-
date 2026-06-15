; Memory mapped registers for Clock and GPIO configuration
GPIOB_BASE      EQU 0x40020400
GPIOA_BASE  	EQU 0x40020000
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOB_IDR       EQU GPIOB_BASE + 0x10
GPIOB_BSRR      EQU GPIOB_BASE + 0x18
GPIOA_BSRR 	    EQU 0x40020018
GPIOA_ODR 		EQU GPIOA_BASE + 0X14
GPIOB_ODR 		EQU GPIOB_BASE + 0X14	

; Clock Enable Registers
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x30 
RCC_APB1ENR     EQU 0x40 
RCC_APB2ENR     EQU 0x44 
    
GPIO_MODER      EQU 0x00
GPIO_AFRL       EQU 0x20

; Shared data memory holding the distance in cm
    AREA    HC_DATA, DATA, READWRITE
    ALIGN 4
    EXPORT  distance_cm
distance_cm SPACE   4   ; Stores the calculated distance from the ultrasonic sensor in centimeters

    AREA    |.text|, CODE, READONLY
    ALIGN 4
    
	EXPORT HCSR04_Init
	EXPORT HCSR04_Measure
	EXPORT hc_delay_us

; Initializes the GPIO pins used for the HC-SR04 Ultrasonic Sensor
; PB10 is configured as Output (Trigger pin)
; PB2 is configured as Input (Echo pin)
HCSR04_Init FUNCTION
    PUSH {R0, R1, LR}
    
	; Enable clock for GPIOA and GPIOB
    LDR R0, =0x40023830      ; RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03        
    STR R1, [R0]

    ; Configure GPIOA (likely generic setups for motors/other components)
    LDR R0, =0x40020000      ; GPIOA_MODER
    LDR R1, [R0]
    LDR R2, =0xFFFFFC03       
    AND R1, R1, R2
    LDR R2, =0x00000154       
    ORR R1, R1, R2
    STR R1, [R0]

    ; Clear outputs on GPIOA
	LDR R0, =0x40020014      ; GPIOA_ODR
    LDR R1, [R0]
    BIC R1, R1, #0x1E        
    STR R1, [R0]

    ; Configure GPIOB
    LDR R0, =0x40020400      ; GPIOB_MODER
    LDR R1, [R0]
    LDR R2, =0xFFCFFFCF       
    AND R1, R1, R2
    LDR R2, =0x00100000       
    ORR R1, R1, R2
    STR R1, [R0]

    ; Configure PB10 as Output (Trigger) and PB2 as Input (Echo)
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    BIC R1, R1, #(3 :SHL: 20)   ; Clear mode bits for PB10
    BIC R1, R1, #(3 :SHL: 4)    ; Clear mode bits for PB2
    ORR R1, R1, #(1 :SHL: 20)   ; Set PB10 to Output mode
    STR R1, [R0]

    ; Set Trigger pin (PB10) LOW initially
    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 26)       ; 10 + 16 = 26 (Reset bit)
    STR R1, [R0]

    POP {R0, R1, PC}
    ENDFUNC


; Triggers the ultrasonic sensor and measures the echo duration to calculate distance
HCSR04_Measure FUNCTION
    PUSH {R0-R5, LR}
    
    ; 1. Send a 10 microsecond HIGH pulse to the Trigger pin (PB10)
    LDR R3, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 10)       ; Set PB10 HIGH
    STR R1, [R3]
    
    MOVS R0, #10                
    BL hc_delay_us              ; Wait 10 us
    
    MOV R1, #(1 :SHL: 26)       ; Set PB10 LOW
    STR R1, [R3]
    
    ; 2. Wait for the Echo pin (PB2) to go HIGH
    LDR R3, =GPIOB_IDR
    LDR R5, =60000             ; Timeout counter to prevent infinite loop
wait_rise
    SUBS R5, R5, #1
    BEQ measure_error           ; If timeout is reached before Echo goes HIGH, jump to error
    LDR R0, [R3]
    TST R0, #(1 :SHL: 2)       ; Test PB2
    BEQ wait_rise               ; If still LOW, keep waiting

    ; 3. Echo is HIGH. Start counting how long it stays HIGH.
    MOVS R4, #0                 ; Initialize pulse width counter
    LDR R5, =30000              ; Maximum measurable distance timeout
wait_fall
    LDR R0, [R3]                
    TST R0, #(1 :SHL: 2)       ; Test PB2
    BEQ calc_dist               ; If Echo goes LOW, pulse has ended. Jump to calculate.
    ADD R4, R4, #1              ; Increment pulse width counter
    CMP R4, R5                  
    BGE calc_dist               ; If timeout reached, jump to calculate anyway
    
    ; NOPs used to tune the loop time to precisely match microsecond scale
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    NOP                         
    B wait_fall                 

calc_dist
    ; 4. Calculate Distance
    ; The speed of sound is approx 340 m/s or 29 us/cm.
    ; Since the pulse travels back and forth, we divide by 58 (29 * 2) to get distance in cm.
    MOVS R1, #58
    UDIV R4, R4, R1            
    
save_dist
    ; Store the calculated distance in memory
    LDR R1, =distance_cm
    STR R4, [R1]
    B measure_end

measure_error
    ; If sensor didn't respond, store 0 cm
    MOVS R4, #0
    LDR R1, =distance_cm
    STR R4, [R1]

measure_end
    POP {R0-R5, PC}
    ENDFUNC


; General purpose microsecond delay loop
; Tuned for 16MHz clock
hc_delay_us
    PUSH {R1, LR}
    MOVS R1, #4
    MUL R0, R1, R0              ; Multiply requested microseconds by 4 loops per us
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
