    AREA VARS, DATA, READWRITE
    ALIGN 4
myVar DCD 0     ; Stores the decoded 32-bit RFID UID

; Memory mapped registers for Clock and GPIO configuration
RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x40023830

GPIOA_BASE      EQU 0x40020000
GPIOB_BASE      EQU 0x40020400

; RC522 RFID Module Register Addresses
CommandReg      EQU 0x01
ComIrqReg       EQU 0x04
DivIrqReg       EQU 0x05
ErrorReg        EQU 0x06
FIFODataReg     EQU 0x09
FIFOLevelReg    EQU 0x0A
ControlReg      EQU 0x0C
BitFramingReg   EQU 0x0D
ModeReg         EQU 0x11
TxControlReg    EQU 0x14
TxASKReg        EQU 0x15
TModeReg        EQU 0x2A
TPrescalerReg   EQU 0x2B
TReloadRegH     EQU 0x2C
TReloadRegL     EQU 0x2D

    AREA    |.text|, CODE, READONLY, ALIGN=2
    
    EXPORT  RFID_Init
    EXPORT  RFID_Process
    EXPORT  myVar

    IMPORT  TFT_Fill
    IMPORT  TFT_DrawChar
    IMPORT  TFT_DrawString
    IMPORT  TFT_DrawNumber
    IMPORT  temp_data
    IMPORT  final_spo2
    IMPORT  final_bpm
    IMPORT  read_velostat
    IMPORT  temp_int
    IMPORT  Last_Rate
    IMPORT  DS18B20_UpdateTemp
    IMPORT  MAX30102_Update

; Initializes the SPI interface on GPIOA (Pins 5,6,7) and the RC522 RFID module
RFID_Init FUNCTION
    PUSH {LR}
    
    ; Enable Clock for GPIOA and GPIOB
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03         
    STR R1, [R0]

    ; Configure GPIOA Pins for SPI
    ; PA8 (RST), PA9 (CS) configured as Outputs. PA5, PA6, PA7 configured as Outputs for bit-bang SPI.
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #0x00]   
    LDR R2, =0x00030000       
    BIC R1, R1, R2
    LDR R2, =0x00010000       
    ORR R1, R1, R2
    STR R1, [R0, #0x00]       
    
    ; Set PA8 (RST) HIGH to enable the RFID module
    LDR R1, =(1<<8)
    STR R1, [R0, #0x18]       

    ; Configure GPIOB Pins (likely unused or generic)
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #0x00]       
    LDR R2, =0x30000000       
    BIC R1, R1, R2            
    STR R1, [R0, #0x00]      

    ; 1. Soft Reset the RC522 Module
    MOV R0, #CommandReg
    MOV R1, #0x0F            ; 0x0F = SoftReset command
    BL RC522_WriteReg
    LDR R2, =0x000FFFFF      ; Delay loop to wait for reset to finish
Reset_Wait
    SUBS R2, R2, #1
    BNE Reset_Wait

    ; 2. Configure Timer for RC522
    MOV R0, #TModeReg
    MOV R1, #0x80            ; TAuto=1 (timer starts automatically)
    BL RC522_WriteReg
    MOV R0, #TPrescalerReg
    MOV R1, #0xA9            ; Set Prescaler to configure timer frequency
    BL RC522_WriteReg
    MOV R0, #TReloadRegH
    MOV R1, #0x03            ; Timer reload value High
    BL RC522_WriteReg
    MOV R0, #TReloadRegL
    MOV R1, #0xE8            ; Timer reload value Low (30 milliseconds timeout)
    BL RC522_WriteReg
    
    ; 3. Configure Modulation (100% ASK)
    MOV R0, #TxASKReg
    MOV R1, #0x40            ; Force 100% ASK modulation
    BL RC522_WriteReg
    MOV R0, #ModeReg
    MOV R1, #0x3D            ; Set CRC preset value to 0x6363
    BL RC522_WriteReg
    
    ; 4. Turn Antenna ON
    MOV R0, #TxControlReg
    BL RC522_ReadReg
    ORR R1, R0, #0x03        ; Set Tx1RFEn and Tx2RFEn bits
    MOV R0, #TxControlReg
    BL RC522_WriteReg

    POP {PC}
    ENDFUNC

; High-level routine called repeatedly to check if a card is present and read its ID
RFID_Process FUNCTION
    PUSH {LR}
    BL Poll_Card              ; Try to read a card
    CMP R4, #0                ; If R4 == 0, no card was read
    BEQ Process_End           
    BL Check_UID              ; Card detected! Check its UID and display info
Process_End
    POP {PC}
    ENDFUNC

; Lower-level routine to ask the RC522 if any card is in the antenna field
Poll_Card
    PUSH {LR, R5, R6, R7}
    MOV R4, #0                ; Default return value: 0 (No card)

    ; Step 1: Send Request Command (REQA) to find cards in the area
    MOV R0, #CommandReg
    MOV R1, #0x00             ; Idle command
    BL RC522_WriteReg
    MOV R0, #ComIrqReg
    MOV R1, #0x7F             ; Clear all interrupt flags
    BL RC522_WriteReg
    MOV R0, #FIFOLevelReg
    MOV R1, #0x80             ; Flush the FIFO buffer
    BL RC522_WriteReg
    
    MOV R0, #FIFODataReg
    MOV R1, #0x26             ; 0x26 = REQA command byte
    BL RC522_WriteReg
    
    MOV R0, #CommandReg
    MOV R1, #0x0C             ; Transceive command (Transmit and Receive)
    BL RC522_WriteReg
    MOV R0, #BitFramingReg
    MOV R1, #0x87             ; Start sending (StartSend=1), and transmit 7 bits (for REQA)
    BL RC522_WriteReg
    
    ; Wait for the card to reply
    LDR R6, =0x1000
Wait_REQA
    SUBS R6, R6, #1
    BEQ Poll_Fail             ; Timeout: No card replied
    MOV R0, #ComIrqReg
    BL RC522_ReadReg
    ANDS R7, R0, #0x20        ; Check RxIRq bit (Receiver Interrupt)
    BEQ Wait_REQA

    ; Step 2: Send Anti-Collision Command to get the Card UID
    MOV R0, #CommandReg
    MOV R1, #0x00             ; Idle command
    BL RC522_WriteReg
    MOV R0, #ComIrqReg
    MOV R1, #0x7F             ; Clear interrupt flags
    BL RC522_WriteReg
    MOV R0, #FIFOLevelReg
    MOV R1, #0x80             ; Flush FIFO buffer
    BL RC522_WriteReg
    
    MOV R0, #FIFODataReg
    MOV R1, #0x93             ; 0x93 = Anti-Collision Cascade Level 1
    BL RC522_WriteReg
    MOV R0, #FIFODataReg
    MOV R1, #0x20             ; 0x20 = Valid Bits count
    BL RC522_WriteReg
    
    MOV R0, #CommandReg
    MOV R1, #0x0C             ; Transceive command
    BL RC522_WriteReg
    MOV R0, #BitFramingReg
    MOV R1, #0x80             ; Start sending (StartSend=1), transmit all 8 bits
    BL RC522_WriteReg
    
    ; Wait for the UID reply
    LDR R6, =0x1000
Wait_Anti
    SUBS R6, R6, #1
    BEQ Poll_Fail
    MOV R0, #ComIrqReg
    BL RC522_ReadReg
    ANDS R7, R0, #0x20        ; Check RxIRq bit
    BEQ Wait_Anti

    MOV R0, #BitFramingReg
    MOV R1, #0x00             ; Clear StartSend
    BL RC522_WriteReg

    ; Verify we received 5 bytes (4 bytes UID + 1 byte BCC Checksum)
    MOV R0, #FIFOLevelReg
    BL RC522_ReadReg
    CMP R0, #5
    BNE Poll_Fail

    ; Read the 4-byte UID from the FIFO
    MOV R4, #0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          ; Read Byte 1
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          ; Read Byte 2
    LSL R0, R0, #8
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          ; Read Byte 3
    LSL R0, R0, #16
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          ; Read Byte 4
    LSL R0, R0, #24
    ORR R4, R4, R0
    
Poll_Fail
    POP {LR, R5, R6, R7}
    BX LR

; Software implementation of SPI Protocol (Bit-Banging)
; Transmits byte in R0, returns received byte in R0
SPI_TxRx FUNCTION
    PUSH {R1-R6, LR}
    MOV R4, #8               ; Loop 8 times for 8 bits
    MOV R5, #0               ; Accumulator for received byte
    LDR R1, =GPIOA_BASE      
    LDR R6, =GPIOB_BASE      
    LDR R2, =(1<<9)          ; SCK Set Bit
    LDR R3, =(1<<10)         ; MOSI Set Bit

spi_loop
    ; Transmit MSB
    TST R0, #0x80            
    BNE set_mosi
    LDR R12, =(1<<26)        ; 10 + 16 = 26 (MOSI Reset bit)
    STR R12, [R1, #0x18]     ; Pull MOSI LOW
    B clk_pulse
set_mosi
    STR R3, [R1, #0x18]      ; Pull MOSI HIGH

clk_pulse
    STR R2, [R1, #0x18]      ; Pull SCK HIGH (Clock rising edge)

    ; Read MISO on rising edge
    LSL R5, R5, #1           
    LDR R12, [R6, #0x10]     ; Read GPIOB IDR (MISO is apparently on GPIOB Pin 14 here)
    TST R12, #(1 << 14)      
    BEQ clk_low
    ORR R5, R5, #1           ; Add 1 to accumulator if MISO is HIGH

clk_low
    LDR R12, =(1<<25)        ; 9 + 16 = 25 (SCK Reset bit)
    STR R12, [R1, #0x18]     ; Pull SCK LOW (Clock falling edge)

    ; Shift transmission byte left to prepare next bit
    LSL R0, R0, #1           
    SUBS R4, R4, #1          
    BNE spi_loop             

    MOV R0, R5               ; Return received byte
    POP {R1-R6, PC}
    ENDFUNC

; Writes a byte (R1) to an RC522 Register (R0)
RC522_WriteReg
    PUSH {LR, R4, R5}
    MOV R4, R0                
    MOV R5, R1                
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<24)       ; 8 + 16 = 24 (CS Reset bit)
    STR R2, [R1]           ; Pull CS LOW to start SPI transaction
    
    ; Format the Address byte (0XXXXXX0) for Write
    LSL R0, R4, #1
    AND R0, R0, #0x7E         
    BL SPI_TxRx               ; Send Address
    MOV R0, R5
    BL SPI_TxRx               ; Send Data
    
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<8)        
    STR R2, [R1]           ; Pull CS HIGH to end SPI transaction
    
    POP {LR, R4, R5}
    BX LR

; Reads a byte from an RC522 Register (R0), returns value in R0
RC522_ReadReg
    PUSH {LR, R4}
    MOV R4, R0                
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<24)       ; CS Reset bit
    STR R2, [R1]           ; Pull CS LOW
    
    ; Format the Address byte (1XXXXXX0) for Read
    LSL R0, R4, #1
    AND R0, R0, #0x7E
    ORR R0, R0, #0x80         
    BL SPI_TxRx               ; Send Address
    MOV R0, #0x00             
    BL SPI_TxRx               ; Send Dummy byte to receive Data
    
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<8)        
    STR R2, [R1]           ; Pull CS HIGH
    
    POP {LR, R4}
    BX LR


    LTORG

; Checks the scanned UID against known users and displays patient info on the TFT Screen
Check_UID FUNCTION
    PUSH {LR}                 
    
    ; Patient 1: Safwat
    LDR R5, =0x031F39CA       ; Known UID 1
    LDR R0, =myVar
    STR R4, [R0]              ; Save the scanned UID
    CMP R4, R5
    BEQ.W Show_1              ; If match, go to Show_1

    ; Patient 2: Omar
    LDR R5, =0x023338e6       ; Known UID 2
    CMP R4, R5
    BEQ.W Show_2              ; If match, go to Show_2

    B Check_UID_End           ; If unknown, do nothing

Show_1
    LDR R0, =0x0000           ; Black color
    BL TFT_Fill               ; Clear screen
    
    ; Update sensors before showing info
    BL DS18B20_UpdateTemp
    
    ; Print Patient Info Strings
    MOV R0, #5                
    MOV R1, #5               
    LDR R2, =str_NAME        
    LDR R3, =0xFFFF           ; White color
    BL TFT_DrawString
    
    MOV R0, #5                
    MOV R1, #20               
    LDR R2, =str_AGE       
    LDR R3, =0xFFFF           
    BL TFT_DrawString
    
    MOV R0, #5                
    MOV R1, #35               
    LDR R2, =str_COND        
    LDR R3, =0xFFFF           
    BL TFT_DrawString

    ; Print Room Temperature
    MOV R0, #5                
    MOV R1, #55               
    LDR R2, =str_ROOM_LBL     
    LDR R3, =0x07E0           ; Green color
    BL TFT_DrawString

    LDR R0, =temp_data        
    LDRSH R2, [R0]
    ASRS R2, R2, #4           ; Convert 12-bit temp to integer
    MOV R0, #95               
    MOV R1, #55               
    LDR R3, =0xFFFF           
    BL TFT_DrawNumber

    ; Update and Print SpO2
    BL MAX30102_Update
    MOV R0, #5                
    MOV R1, #70               
    LDR R2, =str_SPO2_LBL     
    LDR R3, =0x07FF           ; Cyan color
    BL TFT_DrawString

    LDR R0, =final_spo2
    LDR R2, [R0]              
    MOV R0, #95
    MOV R1, #70
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    ; Print Heart Rate
    MOV R0, #5                
    MOV R1, #85               
    LDR R2, =str_HR_LBL     
    LDR R3, =0xF800           ; Red color
    BL TFT_DrawString

    LDR R0, =final_bpm
    LDR R2, [R0]              
    MOV R0, #95
    MOV R1, #85
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    ; Update and Print Bed Pressure (Velostat)
    MOV R0, #5                
    MOV R1, #100               
    LDR R2, =str_PRESS_LBL     
    LDR R3, =0xFFE0           ; Yellow color
    BL TFT_DrawString

    BL read_velostat          
    MOV R2, R0                
    MOV R0, #95
    MOV R1, #100
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    ; Print Max Temperature
    MOV R0, #5                
    MOV R1, #115               
    LDR R2, =str_USE_TEMP_LBL     
    LDR R3, =0xF81F           ; Magenta color
    BL TFT_DrawString

    LDR R0, =temp_int
    LDRB R2, [R0]             
    MOV R0, #95
    MOV R1, #115
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    ; Print IV Drop Rate
    MOV R0, #5                
    MOV R1, #130               
    LDR R2, =str_RATE_LBL     
    LDR R3, =0xFFFF           
    BL TFT_DrawString

    LDR R0, =Last_Rate
    LDR R2, [R0]              
    MOV R0, #95
    MOV R1, #130
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    B Check_UID_End
    LTORG

Show_2
    ; Simplified screen for second patient
    LDR R0, =0x0000           
    BL TFT_Fill
    MOV R0, #5              
    MOV R1, #5             
    LDR R2, =str_NAME2        
    LDR R3, =0xFFFF           
    BL TFT_DrawString
    MOV R0, #5              
    MOV R1, #20             
    LDR R2, =str_AGE2      
    LDR R3, =0xFFFF           
    BL TFT_DrawString
    MOV R0, #5              
    MOV R1, #35             
    LDR R2, =str_COND2        
    LDR R3, =0xFFFF           
    BL TFT_DrawString
    B Check_UID_End

Check_UID_End
    POP {PC}
    ENDFUNC


    AREA RFID_STRINGS, DATA, READONLY
    ALIGN 4
        
str_ROOM_LBL     DCB "Room Temp: ", 0
str_SPO2_LBL     DCB "SpO2: ", 0
str_HR_LBL       DCB "HR: ", 0
str_PRESS_LBL    DCB "Pressure: ", 0
str_USE_TEMP_LBL DCB "Max Temp: ", 0
str_RATE_LBL     DCB "Last Rate: ", 0
        
str_NAME   DCB "Name: SAFWAT", 0
str_AGE    DCB "Age: 19", 0
str_COND   DCB "Condition: ???", 0

str_NAME2  DCB "Name: omar", 0
str_AGE2   DCB "Age: 21", 0
str_COND2  DCB "???", 0

    ALIGN 4
    END