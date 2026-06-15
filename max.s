; Memory mapped registers for Clock and Reset control
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30
RCC_APB1ENR     EQU RCC_BASE + 0x40
RCC_APB1RSTR    EQU RCC_BASE + 0x20      

; Memory mapped registers for GPIOB (Used for I2C pins)
GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOB_OTYPER    EQU GPIOB_BASE + 0x04
GPIOB_PUPDR     EQU GPIOB_BASE + 0x0C
GPIOB_AFRH      EQU GPIOB_BASE + 0x24    

; Memory mapped registers for I2C1
I2C1_BASE       EQU 0x40005400
I2C1_CR1        EQU I2C1_BASE + 0x00
I2C1_CR2        EQU I2C1_BASE + 0x04
I2C1_DR         EQU I2C1_BASE + 0x10
I2C1_SR1        EQU I2C1_BASE + 0x14
I2C1_SR2        EQU I2C1_BASE + 0x18
I2C1_CCR        EQU I2C1_BASE + 0x1C
I2C1_TRISE      EQU I2C1_BASE + 0x20

; Thresholds for the DSP algorithm to detect when a finger is on the sensor
WAKE_THRESHOLD  EQU 20000       ; If IR value > 20000, consider finger present
SLEEP_THRESHOLD EQU 25000       ; Buffer threshold

; MAX30102 I2C Address (Shifted 1 bit for Write/Read later)
MAX30102_ADDR   EQU 0x57

    AREA    MAX30102_DATA, DATA, READWRITE
    ALIGN
ir_value        SPACE   4       ; Latest raw IR reading
red_value       SPACE   4       ; Latest raw Red LED reading
temp_int        SPACE   1       ; Internal Temperature (Integer part)
temp_frac       SPACE   1       ; Internal Temperature (Fractional part)
    ALIGN
final_temp_c    SPACE   4
final_bpm       SPACE   4       ; Calculated Heart Rate
final_spo2      SPACE   4       ; Calculated Blood Oxygen level

; DSP Algorithm state variables
dsp_sample_cnt  SPACE   4       ; Total samples read
dsp_last_beat   SPACE   4       ; Sample count of the last detected heartbeat
dsp_ir_max      SPACE   4       ; Maximum IR value in the current window
dsp_ir_min      SPACE   4       ; Minimum IR value
dsp_red_max     SPACE   4       ; Maximum Red value
dsp_red_min     SPACE   4       ; Minimum Red value
dsp_window_cnt  SPACE   4       ; Number of samples in the current calculation window
dsp_last_ir     SPACE   4       ; Previous IR value (used for finding peaks)

    ALIGN 4
bpm_hist_count  DCB 0           
    ALIGN 4
bpm_history     SPACE 24       
    ALIGN 4
spo2_hist_count DCB 0           
    ALIGN 4
spo2_history    SPACE 24       
    ALIGN 4
mtemp_hist_count DCB 0          
    ALIGN 4
mtemp_history    SPACE 24       
	ALIGN 4
led_state       SPACE 1         ; Tracks if the LEDs are high-power (finger present) or low-power
    ALIGN 4


    AREA    MAX30102_CODE, CODE, READONLY
    EXPORT  MAX30102_Setup
    EXPORT  MAX30102_Update
    EXPORT  temp_int
    EXPORT  final_bpm
    EXPORT  final_spo2
	EXPORT  ir_value
		
	EXPORT  bpm_hist_count
    EXPORT  bpm_history
    EXPORT  spo2_hist_count
    EXPORT  spo2_history
    EXPORT  mtemp_hist_count
    EXPORT  mtemp_history
		
	EXPORT  delay
    ALIGN

; High-level setup function: Initializes hardware, I2C, and the MAX30102 sensor
MAX30102_Setup
    PUSH {LR}
    BL DSP_Init                 ; Reset algorithm variables
    BL I2C1_Hardware_Init       ; Setup GPIO and I2C peripherals
    LDR R0, =500000
    BL delay                    ; Wait for sensor to power up
    BL MAX30102_Init            ; Send configuration commands to the sensor
    POP {PC}

; High-level update function: Reads FIFO, reads temp, and processes the signals
MAX30102_Update
    PUSH {LR}
    BL I2C_Read_FIFO            ; Pull raw RED and IR data from the sensor's FIFO
    BL MAX30102_Read_Temp       ; Read the sensor's internal die temperature
    BL Process_Data             ; Run the DSP algorithm to calculate HR and SpO2
    POP {PC}


; Configures the microcontroller's I2C1 peripheral on PB8 (SCL) and PB9 (SDA)
I2C1_Hardware_Init
    PUSH {R0, R1, LR}
    
    ; Enable Clock for GPIOB and I2C1
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 1)     
    STR R1, [R0]
    LDR R0, =RCC_APB1ENR
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 21)     
    STR R1, [R0]

    ; Reset I2C1 by setting and clearing the SWRST bit in CR1
    LDR R0, =I2C1_CR1
    LDR R1, =(1 :SHL: 15)         
    STR R1, [R0]                   
    MOVS R1, #0
    STR R1, [R0]                  

    ; Configure PB8 and PB9 as Alternate Function mode (10 in binary)
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    BIC R1, R1, #(0xF :SHL: 16)
    ORR R1, R1, #(0xA :SHL: 16)
    STR R1, [R0]
    
    ; Configure PB8 and PB9 as Open-Drain (required for I2C)
    LDR R0, =GPIOB_OTYPER
    LDR R1, [R0]
    ORR R1, R1, #(3 :SHL: 8)
    STR R1, [R0]
    
    ; Configure PB8 and PB9 with Pull-Up resistors
    LDR R0, =GPIOB_PUPDR
    LDR R1, [R0]
    BIC R1, R1, #(0xF :SHL: 16)
    ORR R1, R1, #(0x5 :SHL: 16)
    STR R1, [R0]
    
    ; Set Alternate Function to AF4 (I2C1) for pins 8 and 9
    LDR R0, =GPIOB_AFRH
    LDR R1, [R0]
    BIC R1, R1, #0xFF             
    ORR R1, R1, #0x44            
    STR R1, [R0]
    
    ; Setup I2C Clock speed (Standard Mode, 100kHz)
    LDR R0, =I2C1_CR1
    MOVS R1, #0
    STR R1, [R0]
    LDR R0, =I2C1_CR2
    MOVS R1, #16                 ; Peripheral clock is 16MHz
    STR R1, [R0]
    LDR R0, =I2C1_CCR
    MOVS R1, #80                 ; Clock control register calculation for 100kHz
    STR R1, [R0]
    LDR R0, =I2C1_TRISE
    MOVS R1, #17                 ; Maximum rise time
    STR R1, [R0]

    ; Enable I2C1
    LDR R0, =I2C1_CR1
    MOVS R1, #1                  ; Set PE (Peripheral Enable) bit
    STR R1, [R0]
    POP {R0, R1, PC}


; Digital Signal Processing (DSP) algorithm to detect heartbeats and calculate SpO2
Process_Data
    PUSH {R4-R11, LR}

    LDR R0, =ir_value
    LDR R4, [R0]                

    ; Power Management logic based on IR value (finger detection)
    LDR R0, =led_state
    LDRB R1, [R0]
    CMP R1, #1                 
    BEQ check_sleep

check_wake                   
    ; If LED is low-power, check if finger is detected (IR > Wake Threshold)
    LDR R2, =WAKE_THRESHOLD
    CMP R4, R2
    BLO skip_calculations       ; No finger, skip processing
    B wake_up                  

check_sleep                   
    ; If LED is high-power, check if finger was removed
    LDR R2, =SLEEP_THRESHOLD
    CMP R4, R2
    BHS continue_processing     

go_to_sleep
    ; Finger removed: lower LED power to save energy
    BL Set_LED_Low              
    LDR R0, =led_state
    MOV R1, #0
    STRB R1, [R0]
    BL DSP_Init                 ; Reset algorithm variables
    B skip_calculations

wake_up
    ; Finger detected: increase LED power to get good readings
    BL Set_LED_High             
    LDR R0, =led_state
    MOV R1, #1
    STRB R1, [R0]
    BL DSP_Init                 
    B skip_calculations         

skip_calculations
    ; When no valid finger is present, output 0 for BPM and SpO2
    MOVS R1, #0
    LDR R0, =final_bpm
    STR R1, [R0]
    LDR R0, =final_spo2
    STR R1, [R0]
    POP {R4-R11, PC}            
	LTORG

continue_processing
    LDR R0, =temp_int
    LDRB R4, [R0]
    STR R4, [R0]                

    ; Load current IR and RED values
    LDR R0, =ir_value
    LDR R4, [R0]               
    LDR R0, =red_value
    LDR R5, [R0]                
    
    ; Increment the total sample count
    LDR R0, =dsp_sample_cnt
    LDR R6, [R0]
    ADD R6, R6, #1              
    STR R6, [R0]

    ; Update Maximum and Minimum for IR in the current window
    LDR R0, =dsp_ir_max
    LDR R7, [R0]
    CMP R4, R7
    IT HI
    STRHI R4, [R0]              
    LDR R0, =dsp_ir_min
    LDR R8, [R0]
    CMP R4, R8
    IT CC
    STRCC R4, [R0]              

    ; Update Maximum and Minimum for RED in the current window
    LDR R0, =dsp_red_max
    LDR R9, [R0]
    CMP R5, R9
    IT HI
    STRHI R5, [R0]
    LDR R0, =dsp_red_min
    LDR R10, [R0]
    CMP R5, R10
    IT CC
    STRCC R5, [R0]

    ; Peak Detection (Heartbeat) logic
    ; Threshold = (Max + Min) / 2
    ADD R11, R7, R8
    LSR R11, R11, #1            
    
    ; Check if the signal just crossed the threshold downwards
    LDR R0, =dsp_last_ir
    LDR R1, [R0]
    STR R4, [R0]                
    
    CMP R1, R11
    BHS skip_beat               ; Previous was below threshold
    CMP R4, R11
    BLO skip_beat               ; Current is above threshold
    
    ; We detected a beat! Calculate Heart Rate
    LDR R0, =dsp_last_beat
    LDR R1, [R0]
    STR R6, [R0]                
    SUBS R2, R6, R1             ; R2 = samples since last beat
    CMP R2, #5                  ; Prevent division by zero or unrealistic rates
    BLS skip_beat
    
    ; BPM = 1200 / samples_since_last (assuming specific sampling rate)
    LDR R0, =1200
    UDIV R0, R0, R2             
    CMP R0, #200                ; Max realistic HR = 200
    BHI skip_beat
    CMP R0, #30                 ; Min realistic HR = 30
    BLO skip_beat
    LDR R1, =final_bpm
    STR R0, [R1]                

skip_beat
    ; SpO2 Calculation happens every 100 samples
    LDR R0, =dsp_window_cnt
    LDR R1, [R0]
    ADD R1, R1, #1
    STR R1, [R0]
    CMP R1, #100                
    BLO dsp_done
    
    ; 100 samples reached. Reset window counter.
    MOVS R1, #0
    STR R1, [R0]
    
    ; AC components: Max - Min
    SUBS R9, R9, R10            ; RED AC
    SUBS R7, R7, R8             ; IR AC
    
    ; Prevent division by zero
    CMP R7, #0
    BEQ reset_minmax
    CMP R10, #0
    BEQ reset_minmax
    
    ; R Ratio Calculation: R = (RED_AC * IR_DC) / (IR_AC * RED_DC)
    MUL R0, R9, R8
    MOV R1, #100                ; Scale by 100 to keep precision
    MUL R0, R0, R1
    MUL R1, R7, R10
    UDIV R2, R0, R1
    
    ; SpO2 = 104 - 0.17 * R
    MOV R0, #17
    MUL R2, R2, R0
    MOV R0, #100
    UDIV R2, R2, R0
    MOV R0, #104
    SUBS R0, R0, R2
    
    ; Cap SpO2 at 100%
    CMP R0, #100
    IT HI
    MOVHI R0, #100
    LDR R1, =final_spo2
    STR R0, [R1]                

reset_minmax
    ; Reset the algorithm values for the next 100-sample window
    BL DSP_Init

dsp_done
    POP {R4-R11, PC}


; Resets the DSP minimum and maximum tracking variables
DSP_Init
    PUSH {R0, R1, LR}
    LDR R0, =dsp_ir_max
    MOVS R1, #0
    STR R1, [R0]
    LDR R0, =dsp_red_max
    STR R1, [R0]
    LDR R0, =dsp_ir_min
    LDR R1, =0x0003FFFF         ; Large initial value for minimums
    STR R1, [R0]
    LDR R0, =dsp_red_min
    STR R1, [R0]
    POP {R0, R1, PC}


; Writes configuration settings to the MAX30102 registers
MAX30102_Init
    PUSH {R0, R1, R2, LR}
    
    ; Soft Reset the sensor
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x09
    MOVS R2, #0x40
    BL I2C_Write
    LDR R0, =100000
    BL delay
    
    ; Clear FIFO Pointers
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x04
    MOVS R2, #0
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x05
    MOVS R2, #0
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x06
    MOVS R2, #0
    BL I2C_Write
    
    ; Mode Configuration: SpO2 Mode (RED and IR LEDs active)
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x09
    MOVS R2, #0x03
    BL I2C_Write
    
    ; SpO2 Configuration: ADC Range 4096nA, 100 samples/s, 18-bit resolution
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x67              
    BL I2C_Write
    
    ; LED Pulse Amplitude Configuration (Drive current)
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C              ; RED LED
    MOVS R2, #0x24              ; ~7mA
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0D              ; IR LED
    MOVS R2, #0x24              ; ~7mA
    BL I2C_Write
    POP {R0, R1, R2, PC}

; Low-Level I2C Routines

I2C_Start
    PUSH {R0, R1, LR}
    LDR R0, =I2C1_CR1
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 8)    ; Set START bit
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_start
    LDR R1, [R0]
    TST R1, #(1 :SHL: 0)        ; Wait for SB (Start Bit) flag
    BEQ wait_start
    POP {R0, R1, PC}

I2C_Stop
    PUSH {R0, R1, LR}
    LDR R0, =I2C1_CR1
    LDR R1, [R0]
    ORR R1, R1, #(1 :SHL: 9)    ; Set STOP bit
    STR R1, [R0]
    POP {R0, R1, PC}

I2C_WriteByte
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_SR1
wait_txe
    LDR R2, [R1]
    TST R2, #(1 :SHL: 7)        ; Wait for TXE (Transmit Data Register Empty)
    BEQ wait_txe
    LDR R1, =I2C1_DR
    STR R0, [R1]                ; Write byte
    LDR R1, =I2C1_SR1
wait_btf
    LDR R2, [R1]
    TST R2, #(1 :SHL: 2)        ; Wait for BTF (Byte Transfer Finished)
    BEQ wait_btf
    POP {R1, R2, PC}

I2C_Read_ACK
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_CR1
    LDR R2, [R1]
    ORR R2, R2, #(1 :SHL: 10)   ; Enable ACK
    STR R2, [R1]
    LDR R1, =I2C1_SR1
wait_rxne_ack
    LDR R2, [R1]
    TST R2, #(1 :SHL: 6)        ; Wait for RXNE (Receive Data Register Not Empty)
    BEQ wait_rxne_ack
    LDR R1, =I2C1_DR
    LDR R0, [R1]                ; Read byte
    AND R0, R0, #0xFF           
    POP {R1, R2, PC}

I2C_Read_NACK
    PUSH {R1, R2, LR}
    LDR R1, =I2C1_CR1
    LDR R2, [R1]
    BIC R2, R2, #(1 :SHL: 10)   ; Disable ACK (NACK)
    ORR R2, R2, #(1 :SHL: 9)    ; Generate STOP condition after receiving
    STR R2, [R1]
    LDR R1, =I2C1_SR1
wait_rxne_nack
    LDR R2, [R1]
    TST R2, #(1 :SHL: 6)        ; Wait for RXNE
    BEQ wait_rxne_nack
    LDR R1, =I2C1_DR
    LDR R0, [R1]                ; Read final byte
    AND R0, R0, #0xFF           
    POP {R1, R2, PC}

I2C_Write
    PUSH {R3, LR}
    BL I2C_Start
    LDR R3, =I2C1_DR
    LSL R0, R0, #1              ; Shift Address 1 bit left for Write
    STR R0, [R3]
    LDR R3, =I2C1_SR1
wait_addr_w
    LDR R0, [R3]
    TST R0, #(1 :SHL: 1)        ; Wait for ADDR flag
    BEQ wait_addr_w
    LDR R3, =I2C1_SR2
    LDR R0, [R3]                ; Clear ADDR flag by reading SR2
    MOV R0, R1                  
    BL I2C_WriteByte            ; Write Register Address
    MOV R0, R2                  
    BL I2C_WriteByte            ; Write Data
    BL I2C_Stop
    POP {R3, PC}

; Reads 6 bytes from the MAX30102 FIFO Data Register (3 bytes RED, 3 bytes IR)
I2C_Read_FIFO
    PUSH {R4-R9, LR}
    
    ; Dummy write to set the register pointer to FIFO Data Register (0x07)
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAE              ; Slave address + Write
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_fifo_w
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_fifo_w
    LDR R1, =I2C1_SR2
    LDR R1, [R1]
    MOVS R0, #0x07              ; Register 0x07 (FIFO Data)
    BL I2C_WriteByte
    
    ; Repeated Start to begin reading
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAF              ; Slave address + Read
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_fifo_r
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_fifo_r
    LDR R1, =I2C1_SR2
    LDR R1, [R1]
    
    ; Sequential read of 6 bytes
    BL I2C_Read_ACK
    MOV R4, R0                 ; RED Byte 1 (MSB)
    BL I2C_Read_ACK
    MOV R5, R0                 ; RED Byte 2
    BL I2C_Read_ACK
    MOV R6, R0                 ; RED Byte 3 (LSB)
    BL I2C_Read_ACK
    MOV R7, R0                 ; IR Byte 1 (MSB)
    BL I2C_Read_ACK
    MOV R8, R0                 ; IR Byte 2
    BL I2C_Read_NACK
    MOV R9, R0                 ; IR Byte 3 (LSB)
    BL I2C_Stop
    
    ; Reconstruct the 18-bit RED value
    AND R4, R4, #0x03           ; Only lower 2 bits are valid in MSB
    LSL R4, R4, #16
    LSL R5, R5, #8
    ORR R4, R4, R5
    ORR R4, R4, R6
    LDR R0, =red_value
    STR R4, [R0]
    
    ; Reconstruct the 18-bit IR value
    AND R7, R7, #0x03
    LSL R7, R7, #16
    LSL R8, R8, #8
    ORR R7, R7, R8
    ORR R7, R7, R9
    LDR R0, =ir_value
    STR R7, [R0]
    
    POP {R4-R9, PC}

; Reads the internal die temperature of the MAX30102
MAX30102_Read_Temp
    PUSH {R4, R5, LR}
    
    ; Set TEMP_EN bit to initiate a single temperature reading
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x21
    MOVS R2, #0x01
    BL I2C_Write
    LDR R0, =500000 
    BL delay                    ; Wait for temperature conversion
    
    ; Read the Temperature Integer and Fraction Registers
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAE              
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_temp_w
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_temp_w
    LDR R1, =I2C1_SR2
    LDR R1, [R1]                
    MOVS R0, #0x1F              ; Temp Integer Register (0x1F)
    BL I2C_WriteByte
    
    BL I2C_Start
    LDR R0, =I2C1_DR
    MOVS R1, #0xAF              ; Read Mode
    STR R1, [R0]
    LDR R0, =I2C1_SR1
wait_temp_r
    LDR R1, [R0]
    TST R1, #(1 :SHL: 1)
    BEQ wait_temp_r
    LDR R1, =I2C1_SR2
    LDR R1, [R1]                
    
    BL I2C_Read_ACK             
    MOV R4, R0                  ; Integer part
    BL I2C_Read_NACK            
    MOV R5, R0                  ; Fractional part
    BL I2C_Stop
    
    ; Store the results
    LDR R0, =temp_int
    STRB R4, [R0]
    LDR R0, =temp_frac
    STRB R5, [R0]
    POP {R4, R5, PC}

; Increases the LED currents to normal levels (Used when finger is detected)
Set_LED_High
    PUSH {R0-R3, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x67              
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C
    MOVS R2, #0x24              ; Normal drive current
    BL I2C_Write
    BL Flush_MAX_FIFO           ; Clear stale data
    POP {R0-R3, PC}

; Decreases the LED currents to minimum levels (Used when no finger is present to save power)
Set_LED_Low
    PUSH {R0-R3, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0A
    MOVS R2, #0x02              ; Low sample rate/range
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x0C
    MOVS R2, #0x02              ; Minimum drive current
    BL I2C_Write
    BL Flush_MAX_FIFO
    POP {R0-R3, PC}

; Resets the Write, Overflow, and Read pointers of the MAX30102 FIFO
Flush_MAX_FIFO
    PUSH {R0-R3, LR}
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x04             ; Write Pointer
    MOVS R2, #0x00
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x05             ; Overflow Counter
    MOVS R2, #0x00
    BL I2C_Write
    MOVS R0, #MAX30102_ADDR
    MOVS R1, #0x06             ; Read Pointer 
    MOVS R2, #0x00
    BL I2C_Write
    POP {R0-R3, PC}

; Simple delay loop
delay
    PUSH {R0, LR}
    CMP R0, #0
    BEQ delay_end
delay_loop
    NOP
    SUBS R0, R0, #1
    BNE delay_loop
delay_end
    POP {R0, PC}

    END