; System configured for a 16 MHz Clock
; The DS18B20 data line is connected to GPIO Pin A11 (needs a 4.7k external pull-up resistor)
; Memory mapped registers for Clock and GPIO configuration
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30
GPIOA_BASE      EQU 0x40020000
GPIOA_MODER     EQU GPIOA_BASE + 0x00
GPIOA_OTYPER    EQU GPIOA_BASE + 0x04
GPIOA_IDR       EQU GPIOA_BASE + 0x10
GPIOA_BSRR      EQU GPIOA_BASE + 0x18

; Shared data memory holding the raw temperature reading
    AREA    DS_DATA, DATA, READWRITE
    ALIGN 4
    EXPORT  temp_data
temp_data   SPACE   2  ; 16-bit space to store the raw temperature from the DS18B20 sensor

; Code memory area
    AREA    DS_CODE, CODE, READONLY
    ALIGN 4
    
    EXPORT DS18B20_Init
    EXPORT DS18B20_UpdateTemp

; Initializes the GPIOA Port and configures Pin A11 for 1-Wire communication
DS18B20_Init FUNCTION
    PUSH {R0, R1, LR}
    
    ; Enable the clock for GPIO Port A
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #1
    STR R1, [R0]

    ; Configure Pin A11 as a General Purpose Output
    LDR R0, =GPIOA_MODER
    LDR R1, [R0]
    BIC R1, R1, #(3 :SHL: 22)   ; Clear bits 22 and 23 for Pin 11
    ORR R1, R1, #(1 :SHL: 22)   ; Set bits to 01 (Output mode)
    STR R1, [R0]

    ; Configure Pin A11 as Open-Drain
    ; Open-drain is required for 1-Wire, allowing both master and slave to pull the line low safely
    LDR R0, =GPIOA_OTYPER
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 11)   ; Set bit 11 to enable Open-Drain mode
    STR R1, [R0]

    ; Set the line HIGH (idle state for 1-Wire)
    BL pin_high
    POP {R0, R1, PC}
    ENDFUNC

; High-level routine to ask the sensor to convert temperature, then read and store it
DS18B20_UpdateTemp FUNCTION
    PUSH {R0, R1, R4, LR}
    
    ; Phase 1: Issue a "Convert T" command
    BL ds18b20_reset            ; Reset the 1-Wire bus and check for presence pulse
    MOVS R0, #0xCC              ; Send "Skip ROM" command (0xCC) since we only have one sensor on the bus
    BL ds18b20_write_byte
    MOVS R0, #0x44              ; Send "Convert T" command (0x44) to start temperature conversion
    BL ds18b20_write_byte
    
    ; Wait 750 milliseconds for the DS18B20 to finish the 12-bit conversion
    LDR R0, =750
    BL ds_delay_ms

    ; Phase 2: Read the temperature from the Scratchpad
    BL ds18b20_reset            ; Reset bus again to begin a new transaction
    MOVS R0, #0xCC              ; Skip ROM command (0xCC)
    BL ds18b20_write_byte
    MOVS R0, #0xBE              ; Send "Read Scratchpad" command (0xBE) to get the data
    BL ds18b20_write_byte
    
    ; Read the Least Significant Byte (LSB) of the temperature
    BL ds18b20_read_byte
    MOV R4, R0                  
    
    ; Read the Most Significant Byte (MSB) of the temperature
    BL ds18b20_read_byte
    LSL R0, R0, #8              ; Shift MSB left by 8 bits
    ORR R4, R4, R0              ; Combine LSB and MSB into a single 16-bit value in R4
    
    ; Store the final raw 16-bit temperature into memory
    LDR R1, =temp_data
    STRH R4, [R1]               
    
    POP {R0, R1, R4, PC}
    ENDFUNC

; Pull the 1-Wire line (Pin A11) LOW by writing to the upper half of BSRR (reset bits)
pin_low
    PUSH {R0, R1, LR}
    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 27)    ; 11 + 16 = 27 (Reset bit for Pin 11)
    STR R1, [R0]
    POP {R0, R1, PC}

; Release the 1-Wire line (Pin A11) allowing it to float HIGH via the pull-up resistor
pin_high
    PUSH {R0, R1, LR}
    LDR R0, =GPIOA_BSRR
    MOV R1, #(1 :SHL: 11)    ; Set bit for Pin 11
    STR R1, [R0]
    POP {R0, R1, PC}

; Generates the 1-Wire initialization sequence (Reset Pulse)
ds18b20_reset
    PUSH {R0, LR}
    BL pin_low                  ; Pull line LOW
    LDR R0, =480                ; Wait for 480 microseconds (Reset Pulse)
    BL ds_delay_us                 
    BL pin_high                 ; Release line to HIGH
    LDR R0, =60                 ; Wait 60 microseconds for the sensor to respond
    BL ds_delay_us                 
    ; Usually we would read the pin here to check for the Presence Pulse (LOW), but we skip checking it here
    LDR R0, =420                ; Wait the remainder of the 480 microsecond response window
    BL ds_delay_us                 
    POP {R0, PC}

; Writes a single byte over the 1-Wire bus (LSB first)
ds18b20_write_byte
    PUSH {R1, R2, LR}
    MOVS R1, #8                 ; Loop counter for 8 bits
    MOV R2, R0                  ; R2 holds the byte to write
w_loop
    LSRS R2, R2, #1             ; Shift right by 1. Carry flag contains the bit to transmit
    BCC write_0_bit             ; If carry is 0, branch to write a '0' bit
    
    ; Transmit a '1' bit
    CPSID i                     ; Disable interrupts globally to prevent timing jitter
    BL pin_low                  ; Pull line LOW to start the time slot
    MOVS R0, #2
    BL ds_delay_us              ; Hold LOW for ~2us
    BL pin_high                 ; Release line HIGH
    CPSIE i                     ; Re-enable interrupts
    
    MOVS R0, #60
    BL ds_delay_us              ; Wait 60us for the time slot to finish
    B w_next
    
write_0_bit
    ; Transmit a '0' bit
    CPSID i                     ; Disable interrupts
    BL pin_low                  ; Pull line LOW
    MOVS R0, #60
    BL ds_delay_us              ; Hold LOW for the entire 60us time slot
    BL pin_high                 ; Release line HIGH
    CPSIE i                     ; Re-enable interrupts
    
    MOVS R0, #2
    BL ds_delay_us              ; Short recovery delay between bits
    
w_next
    SUBS R1, R1, #1
    BNE w_loop
    POP {R1, R2, PC}

; Reads a single byte from the 1-Wire bus (LSB first)
ds18b20_read_byte
    PUSH {R1, R2, R3, LR}
    MOVS R1, #8                 ; Loop counter for 8 bits
    MOVS R2, #0                 ; Accumulator for the received byte
    LDR R3, =GPIOA_IDR          ; Address of the GPIOA Input Data Register
r_loop
    LSRS R2, R2, #1             ; Shift accumulator right to make room for the new bit at MSB
    
    CPSID i                     ; Disable interrupts to ensure strict reading timing
    BL pin_low                  ; Pull line LOW to initiate the read time slot
    MOVS R0, #2
    BL ds_delay_us              ; Hold LOW for ~2us
    BL pin_high                 ; Release line HIGH
    MOVS R0, #10
    BL ds_delay_us              ; Wait ~10us before sampling the line (DS18B20 will hold it LOW if bit is '0')
    
    LDR R0, [R3]                ; Read GPIOA inputs
    TST R0, #(1 :SHL: 11)       ; Test Pin A11
    BEQ r_zero                  ; If it's LOW, the bit is a '0'
    ORR R2, R2, #0x80           ; If it's HIGH, the bit is a '1', so set the MSB of the accumulator
r_zero
    CPSIE i                     ; Re-enable interrupts
    
    MOVS R0, #50
    BL ds_delay_us              ; Wait 50us to complete the read time slot
    SUBS R1, R1, #1
    BNE r_loop                  ; Repeat for all 8 bits
    
    MOV R0, R2                  ; Move the complete byte to R0 to return it
    POP {R1, R2, R3, PC}


; Microsecond delay routine (Software loop)
; Assuming 16 MHz clock, ~4 cycles per loop iteration
ds_delay_us
    PUSH {R1, LR}
    MOVS R1, #4                 ; Tuning multiplier for us delay
    MUL R0, R1, R0              
    CMP R0, #0
    BEQ delay_us_end
delay_us_loop
    NOP                         
    SUBS R0, R0, #1             
    BNE delay_us_loop           
delay_us_end
    POP {R1, PC}

; Millisecond delay routine (Calls the microsecond delay 1000 times)
ds_delay_ms
    PUSH {R0, R1, LR}
ms_loop
    CMP R0, #0
    BEQ ms_end
    PUSH {R0}                   
    LDR R0, =1000               
    BL ds_delay_us                 
    POP {R0}                    
    SUBS R0, R0, #1             
    B ms_loop
ms_end
    POP {R0, R1, PC}
    
    END