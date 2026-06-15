; Memory mapped addresses for RCC (Reset and Clock Control) and GPIO peripherals
RCC_AHB1ENR     EQU 0x40023830

GPIOA_BASE      EQU 0x40020000
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOA_BSRR      EQU GPIOA_BASE + 0x18

GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOB_IDR       EQU GPIOB_BASE + 0x10
GPIOB_BSRR      EQU GPIOB_BASE + 0x18

; SysTick Timer registers for precise 1-second delays
SYSTICK_CTRL    EQU 0xE000E010
SYSTICK_LOAD    EQU 0xE000E014
SYSTICK_VAL     EQU 0xE000E018


    AREA    |.data|, DATA, READWRITE
    ALIGN 4
Last_Rate       DCD 0       ; Holds the calculated drop rate in drops/min
Total_Drops     DCD 0       ; Total number of drops counted since startup
Current_Count   DCD 0       ; Number of drops in the current 10-second window
Sec_Count       DCD 0       ; Tracks the number of seconds elapsed (0 to 10)
Prev_State      DCD 1       ; Stores the previous state of the IR sensor to detect state changes (edge detection)
Prev_Time       DCD 0       ; Store the previous time (unused here but reserved for future)


    AREA    |.text|, CODE, READONLY
    EXPORT  IR_Drop_Init
    EXPORT  IR_Drop_Update
    EXPORT  Last_Rate
    EXPORT  Current_Count
    EXPORT  Total_Drops
    EXPORT  Sec_Count
    ALIGN 4


; Initializes the IR Drop Rate Sensor and the SysTick Timer
IR_Drop_Init FUNCTION
    PUSH {R0-R2, LR}

    ; Enable clock for GPIOA and GPIOB
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #3             
    STR R1, [R0]

    ; Configure GPIOA Pin 12 as Output (to power the IR LED transmitter)
    LDR R0, =GPIOA_MODER
    LDR R1, [R0]
    LDR R2, =0x03000000         
    BIC R1, R1, R2
    LDR R2, =0x01000000         
    ORR R1, R1, R2
    STR R1, [R0]

    ; Configure GPIOB Pin 3 as Input (from the IR receiver) and PB4 as Output (Buzzer/LED alert)
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    LDR R2, =0x000003C0         
    BIC R1, R1, R2
    LDR R2, =0x00000100        
    ORR R1, R1, R2
    STR R1, [R0]

    ; Turn on the IR transmitter by setting PA12 HIGH
    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 12)
    STR R1, [R0]

    ; Setup SysTick Timer to count 1 second (16 MHz clock, so 16,000,000 ticks)
    LDR R0, =SYSTICK_LOAD
    LDR R1, =15999999           ; 16M ticks - 1
    STR R1, [R0]
    LDR R0, =SYSTICK_VAL
    MOV R1, #0                  ; Reset current timer value
    STR R1, [R0]
    LDR R0, =SYSTICK_CTRL
    MOV R1, #5                  ; Enable SysTick using processor clock
    STR R1, [R0]

    POP {R0-R2, PC}
    ENDFUNC


; Updates the drop count by polling the IR receiver, and calculates drops/min every 10 seconds
IR_Drop_Update FUNCTION
    PUSH {R4-R7, LR}           

    ; Check if SysTick has rolled over (1 second has passed)
    LDR R0, =SYSTICK_CTRL
    LDR R1, [R0]
    TST R1, #(1 :SHL: 16)      ; Test the COUNTFLAG bit (bit 16)
    BEQ check_ir               ; If 1 second has not passed yet, jump to check the IR sensor

    ; 1 second has passed. Increment our second counter
    LDR R0, =Sec_Count
    LDR R5, [R0]
    ADD R5, R5, #1              
    STR R5, [R0]
    
    ; Have 10 seconds passed?
    CMP R5, #10                 
    BLT check_ir                ; If less than 10 seconds, just check the sensor

    ; 10 seconds have passed. Calculate the Drop Rate (drops per minute)
    LDR R0, =Current_Count
    LDR R4, [R0]              
    MOV R2, #6                  ; Multiply by 6 (since 10 seconds * 6 = 60 seconds = 1 minute)
    MUL R3, R4, R2              
    
    ; Store the calculated rate
    LDR R0, =Last_Rate          
    STR R3, [R0]               
    
    ; Reset the second counter and the current drop counter for the next 10-second window
    MOV R5, #0                  
    LDR R0, =Sec_Count
    STR R5, [R0]
    MOV R4, #0                  
    LDR R0, =Current_Count
    STR R4, [R0]

check_ir
    ; Read the input from the IR sensor (GPIOB Pin 3)
    LDR R0, =GPIOB_IDR
    LDR R1, [R0]
    TST R1, #(1 :SHL: 3)       
    BEQ ir_is_blocked          ; If the pin is LOW, a drop is blocking the light 
    B ir_is_clear              ; Otherwise, the path is clear

ir_is_blocked
    ; We see a drop! Check if we already counted this drop (Prev_State == 1 means it was clear before)
    LDR R0, =Prev_State
    LDR R6, [R0]
    CMP R6, #1                 
    BNE end_update             ; If it was already blocked, don't count it twice

    ; It's a new drop. Increment our counters.
    LDR R0, =Current_Count
    LDR R4, [R0]
    ADD R4, R4, #1              
    STR R4, [R0]               

    LDR R0, =Total_Drops
    LDR R7, [R0]
    ADD R7, R7, #1              
    STR R7, [R0]                
    
    ; Update state to 'blocked' (0)
    LDR R0, =Prev_State
    MOV R6, #0                  
    STR R6, [R0]

    ; Turn off the LED indicator/Buzzer on PB4 (reset bit)
    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 20)      ; Write 1 to upper 16 bits to reset pin 4
    STR R1, [R0]
    B end_update

ir_is_clear
    ; No drop is blocking the path. Update state to 'clear' (1)
    LDR R0, =Prev_State
    MOV R6, #1                 
    STR R6, [R0]

    ; Turn on the LED indicator/Buzzer on PB4 (set bit)
    LDR R0, =GPIOB_BSRR
    MOV R1, #(1 :SHL: 4)        
    STR R1, [R0]

end_update
    POP {R4-R7, PC}            
    ENDFUNC

    END