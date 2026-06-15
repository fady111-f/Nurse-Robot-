	AREA    |.text|, CODE, READONLY
    ALIGN
    
    EXPORT  BT_Init
    EXPORT  BT_Get_Data

; Import global sensor variables to send them over Bluetooth
    IMPORT bpm_current
    IMPORT spo2_current
    IMPORT press_current
    IMPORT temp_int
    IMPORT Last_Rate
    IMPORT temp_data

    EXPORT BT_Send_Char
    EXPORT BT_Send_String
    EXPORT BT_Send_Number
    EXPORT BT_Send_Sensor_Data

; String constants for formatting the telemetry output
    AREA BT_STRINGS, DATA, READONLY
    ALIGN 4
str_hr      DCB "HR:", 0
str_spo2    DCB " SpO2:", 0
str_press   DCB " Press:", 0
str_rtemp   DCB " RTemp:", 0
str_drop    DCB " Drop:", 0
str_nl      DCB "\r\n", 0
    ALIGN 4

    AREA |.text|, CODE, READONLY
    ALIGN 4

; Memory mapped registers for Clock and GPIO
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU RCC_BASE + 0x30
RCC_APB2ENR     EQU RCC_BASE + 0x44  

GPIOB_BASE      EQU 0x40020400
GPIOB_MODER     EQU GPIOB_BASE + 0x00
GPIOB_AFRL      EQU GPIOB_BASE + 0x20 

; USART1 Registers for Bluetooth communication
USART1_BASE     EQU 0x40011000
USART1_SR       EQU USART1_BASE + 0x00
USART1_DR       EQU USART1_BASE + 0x04
USART1_BRR      EQU USART1_BASE + 0x08
USART1_CR1      EQU USART1_BASE + 0x0C

; Initializes USART1 on pins PB6 (TX) and PB7 (RX) to communicate with HC-05 Bluetooth module
BT_Init
    PUSH {R0-R2, LR}

    ; Enable clock for GPIOB (AHB1 Bus)
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x02
    STR R1, [R0]

    ; Enable clock for USART1 (APB2 Bus)
    LDR R0, =RCC_APB2ENR
    LDR R1, [R0]
    LDR R2, =0x00000010     
    ORR R1, R1, R2
    STR R1, [R0]

    ; Configure PB6 and PB7 as Alternate Function mode (10 in binary)
    LDR R0, =GPIOB_MODER
    LDR R1, [R0]
    LDR R2, =0xFFFF0FFF     ; Clear mode bits for PB6 and PB7
    AND R1, R1, R2
    LDR R2, =0x0000A000     ; Set mode bits to 10 for PB6 and PB7
    ORR R1, R1, R2
    STR R1, [R0]

    ; Assign Alternate Function 7 (USART1) to PB6 and PB7
    LDR R0, =GPIOB_AFRL
    LDR R1, [R0]
    LDR R2, =0x00FFFFFF     ; Clear AF bits for pins 6 and 7
    AND R1, R1, R2
    LDR R2, =0x77000000     ; Set AF7 for pins 6 and 7
    ORR R1, R1, R2
    STR R1, [R0]

    ; Configure Baud Rate: 9600 bps
    ; Assuming 16 MHz APB2 clock, the BRR value is calculated as:
    ; 16,000,000 / (16 * 9600) = 104.166 -> 0x68 (Mantissa) and 0x03 (Fraction)
    LDR R0, =USART1_BRR
    LDR R1, =0x0683
    STR R1, [R0]

    ; Enable USART1, Enable Transmitter (TE), Enable Receiver (RE)
    LDR R0, =USART1_CR1
    LDR R1, =0x200C         ; Bit 13 (UE), Bit 3 (TE), Bit 2 (RE)
    STR R1, [R0]

    POP {R0-R2, PC}        

; Polls the USART1 receiver to check if data is available
; Returns the received byte in R0. If no data, returns 0.
BT_Get_Data
    LDR R1, =USART1_SR
    LDR R2, [R1]
    TST R2, #0x20           ; Test RXNE flag (Read Data Register Not Empty)
    BEQ no_bt_data          ; If 0, no data received
    
    LDR R1, =USART1_DR
    LDR R0, [R1]            ; Read the received byte
    BX LR                  

no_bt_data
    MOV R0, #0              ; Return 0 to indicate no data
    BX LR                   
	
; Transmits a single character (passed in R0) via Bluetooth
BT_Send_Char
    PUSH {R1, R2, LR}
    LDR R1, =USART1_BASE    
wait_tx
    LDR R2, [R1, #0x00]      ; Read USART1_SR
    TST R2, #0x80            ; Test TXE flag (Transmit Data Register Empty)
    BEQ wait_tx              ; If 0, buffer is full, keep waiting
    STR R0, [R1, #0x04]      ; Write character to USART1_DR
    POP {R1, R2, PC}

; Transmits a null-terminated string (pointer passed in R0) via Bluetooth
BT_Send_String
    PUSH {R0, R1, R2, LR}
    MOV R1, R0
send_str_loop
    LDRB R0, [R1], #1        ; Load a byte and increment pointer
    CMP R0, #0               ; Check for null terminator
    BEQ send_str_done
    BL BT_Send_Char          ; Send the character
    B send_str_loop
send_str_done
    POP {R0, R1, R2, PC}

; Converts an integer (passed in R0) to its ASCII string representation and sends it
BT_Send_Number
    PUSH {R0-R5, LR}
    CMP R0, #0               ; Handle 0 explicitly
    BNE btsn_start
    MOV R0, #'0'            
    BL BT_Send_Char
    B btsn_end

btsn_start
    MOV R1, #10              ; Base 10 divisor
    MOV R2, #0               ; Digit count
    SUB SP, SP, #16          ; Allocate 16 bytes on stack for digits
btsn_loop
    CMP R0, #0               ; Loop until quotient is 0
    BEQ btsn_send
    UDIV R3, R0, R1          ; R3 = R0 / 10
    MLS R4, R3, R1, R0       ; R4 = R0 - (R3 * 10) [This is R0 % 10]
    ADD R4, R4, #'0'         ; Convert remainder to ASCII char
    STRB R4, [SP, R2]        ; Store char on stack
    ADD R2, R2, #1           ; Increment digit count
    MOV R0, R3               ; Move quotient to R0 for next loop
    B btsn_loop
btsn_send
    SUB R2, R2, #1           ; Decrement index to pop digits in reverse order
    LDRB R0, [SP, R2]
    BL BT_Send_Char          ; Send character
    CMP R2, #0
    BNE btsn_send
    ADD SP, SP, #16          ; Clean up stack
btsn_end
    POP {R0-R5, PC}

; Compiles all current sensor data into a single string line and sends it over Bluetooth
BT_Send_Sensor_Data
    PUSH {R0-R3, LR}

    ; Send Heart Rate
    LDR R0, =str_hr
    BL BT_Send_String
    LDR R0, =bpm_current
    LDR R0, [R0]
    BL BT_Send_Number

    ; Send Blood Oxygen (SpO2)
    LDR R0, =str_spo2
    BL BT_Send_String
    LDR R0, =spo2_current
    LDR R0, [R0]
    BL BT_Send_Number

    ; Send Pressure (Velostat)
    LDR R0, =str_press
    BL BT_Send_String
    LDR R0, =press_current
    LDR R0, [R0]
    BL BT_Send_Number

    ; Send Room Temperature (DS18B20)
    LDR R0, =str_rtemp
    BL BT_Send_String
    LDR R0, =temp_data
    LDRSH R0, [R0]           ; Load 16-bit temp
    ASRS R0, R0, #4          ; Shift right by 4 to get integer part (DS18B20 12-bit format)
    BL BT_Send_Number

    ; Send Drop Rate
    LDR R0, =str_drop
    BL BT_Send_String
    LDR R0, =Last_Rate
    LDR R0, [R0]
    BL BT_Send_Number

    ; Send Newline characters (\r\n)
    LDR R0, =str_nl
    BL BT_Send_String
    
    POP {R0-R3, PC}
    
    END