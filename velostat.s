; Memory mapped registers for Clock, GPIO, and ADC1
RCC_AHB1ENR  EQU 0x40023830  ; Advanced High-performance Bus 1 Enable Register (for GPIO)
RCC_APB2ENR  EQU 0x40023844  ; Advanced Peripheral Bus 2 Enable Register (for ADC1)
GPIOA_MODER  EQU 0x40020000  ; GPIO Port A Mode Register
ADC1_SR      EQU 0x40012000  ; ADC1 Status Register
ADC1_CR1     EQU 0x40012004  ; ADC1 Control Register 1
ADC1_CR2     EQU 0x40012008  ; ADC1 Control Register 2
ADC1_SQR3    EQU 0x40012034  ; ADC1 Regular Sequence Register 3
ADC1_DR      EQU 0x4001204C  ; ADC1 Data Register

            AREA    |.text|, CODE, READONLY
            
            EXPORT  init_velostat
            EXPORT  read_velostat

; Initializes the ADC1 to read analog values from the Velostat sensor on PA0
init_velostat
            PUSH {R0-R2, LR}         

            ; Enable the clock for GPIOA
            LDR R0, =RCC_AHB1ENR
            LDR R1, [R0]
            ORR R1, R1, #0x01        
            STR R1, [R0]

            ; Enable the clock for ADC1
            LDR R0, =RCC_APB2ENR
            LDR R1, [R0]
            ORR R1, R1, #0x0100      ; Set bit 8 to enable ADC1 clock
            STR R1, [R0]

            ; Configure PA0 as Analog Input Mode
            LDR R0, =GPIOA_MODER
            LDR R1, [R0]
            ORR R1, R1, #0x03        ; Set bits 0 and 1 to 11 (Analog mode) for Pin 0
            STR R1, [R0]

            ; Configure ADC1 to read from Channel 0 (PA0) as the first conversion in the regular sequence
            LDR R0, =ADC1_SQR3
            LDR R1, [R0]
            BIC R1, R1, #0x1F        ; Clear the first 5 bits (SQ1) to select Channel 0
            STR R1, [R0]

            ; Turn on the ADC
            LDR R0, =ADC1_CR2
            LDR R1, [R0]
            ORR R1, R1, #0x01        ; Set ADON bit to power up the ADC
            STR R1, [R0]

            ; Wait for the ADC to stabilize after powering up
            LDR R2, =10000
Delay_Init
            SUBS R2, R2, #1
            BNE Delay_Init

            POP {R0-R2, PC}         


; Triggers a new conversion and returns the analog reading in R0
read_velostat
            PUSH {R1, LR}           
            
            ; Start the ADC conversion
            LDR R0, =ADC1_CR2
            LDR R1, [R0]
            ORR R1, R1, #0x40000000  ; Set SWSTART bit to begin conversion of regular channels
            STR R1, [R0]

Wait_EOC
            ; Polling loop: Wait for End Of Conversion (EOC) flag to be set
            LDR R0, =ADC1_SR
            LDR R1, [R0]
            ANDS R1, R1, #0x02       ; Check the EOC bit (bit 1)
            BEQ Wait_EOC             ; If not set, keep waiting

            ; Read the 12-bit converted value from the Data Register
            LDR R0, =ADC1_DR
            LDR R0, [R0]             ; The result is stored in R0 to be returned to the caller

            POP {R1, PC}             
            
            ALIGN
            END