    AREA TFT_CODE, CODE, READONLY
    EXPORT TFT_Init
    EXPORT TFT_Fill
    EXPORT TFT_DrawChar
    
    EXPORT TFT_WriteCommand
    EXPORT TFT_WriteData
    EXPORT TFT_WriteData16
        
    IMPORT font8x8              ; Import the 8x8 bitmap font used to draw characters

; Memory mapped addresses for Clock and GPIO configuration
RCC_BASE     EQU 0x40023800
GPIOA_BASE   EQU 0x40020000
GPIOB_BASE   EQU 0x40020400

RCC_AHB1ENR  EQU 0x30
GPIO_MODER   EQU 0x00
GPIO_ODR     EQU 0x14
GPIO_BSRR    EQU 0x18
GPIO_OSPEEDR EQU 0x08

; Pin assignments for the ST7735 TFT Display
TFT_SCK_BIT  EQU 9      ; PA9  - SPI Clock
TFT_MOSI_BIT EQU 10     ; PA10 - SPI Master Out Slave In (Data line)

TFT_CS_BIT   EQU 12     ; PB12 - Chip Select (Active Low)
TFT_RST_BIT  EQU 13     ; PB13 - Reset
TFT_DC_BIT   EQU 15     ; PB15 - Data/Command selection (Low = Command, High = Data)


; Initializes the TFT display including GPIO pin setups and sending configuration commands to the ST7735 controller
TFT_Init FUNCTION
    PUSH {R0-R2, LR}
    
    ; Enable Clock for GPIOA and GPIOB
    LDR R0, =RCC_BASE + RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03
    STR R1, [R0]

    ; Configure GPIOA Pins (PA9, PA10) as outputs for bit-banged SPI
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0x003C0000       ; Clear mode bits for PA9, PA10
    BIC R1, R1, R2
    LDR R2, =0x00140000       ; Set mode bits to 01 (General purpose output)
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_MODER]

    ; Set GPIOA output speed to High for faster SPI updates
    LDR R1, [R0, #GPIO_OSPEEDR]
    LDR R2, =0x003C0000       
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_OSPEEDR]

    ; Configure GPIOB Pins (PB12, PB13, PB15) as outputs
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0xCF000000      ; Clear mode bits for 12, 13, 15
    BIC R1, R1, R2
    LDR R2, =0x45000000      ; Set mode bits to 01 (General purpose output)
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_MODER]

    ; Set GPIOB output speed to High
    LDR R1, [R0, #GPIO_OSPEEDR]
    LDR R2, =0xCF000000       
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_OSPEEDR]

    ; Initialize pins to default states
    ; Set Chip Select (CS) HIGH (Display not selected)
    LDR R0, =GPIOB_BASE
    LDR R1, =(1 << TFT_CS_BIT)
    STR R1, [R0, #GPIO_BSRR]
    
    ; Set SPI Clock (SCK) LOW
    LDR R0, =GPIOA_BASE
    LDR R1, =(1 << (TFT_SCK_BIT + 16)) 
    STR R1, [R0, #GPIO_BSRR]

    ; Hardware Reset sequence: Pull RST LOW, wait, pull RST HIGH, wait
    LDR R0, =GPIOB_BASE
    LDR R1, =(1 << (TFT_RST_BIT + 16)) ; Pull Reset LOW
    STR R1, [R0, #GPIO_BSRR]
    BL delay
    
    LDR R1, =(1 << TFT_RST_BIT)        ; Pull Reset HIGH
    STR R1, [R0, #GPIO_BSRR]
    BL delay

    ; Software Reset Command
    MOV R0, #0x11        
    BL TFT_WriteCommand
    BL delay

    ; Set Color Mode to 16-bit (RGB565)
    MOV R0, #0x3A        
    BL TFT_WriteCommand
    MOV R0, #0x55
    BL TFT_WriteData

    ; Memory Data Access Control (Set orientation and color format)
    MOV R0, #0x36        
    BL TFT_WriteCommand
    MOV R0, #0xE8        
    BL TFT_WriteData

    ; Display ON Command
    MOV R0, #0x29        
    BL TFT_WriteCommand

    POP {R0-R2, PC}
    ENDFUNC


; Fills the entire screen (128x160) with a single 16-bit color (passed in R0)
TFT_Fill FUNCTION
    PUSH {R1-R4, LR}
    MOV R4, R0           ; Save the 16-bit color in R4

    ; Define the drawing column window (0 to 127)
    MOV R0, #0x2A        ; Column Address Set command
    BL TFT_WriteCommand
    MOV R0, #0x00        ; Start Col High Byte
    BL TFT_WriteData
    MOV R0, #0x00        ; Start Col Low Byte
    BL TFT_WriteData
    MOV R0, #0x01        ; End Col High Byte
    BL TFT_WriteData
    MOV R0, #0xDF        ; End Col Low Byte
    BL TFT_WriteData

    ; Define the drawing row window (0 to 159)
    MOV R0, #0x2B        ; Row Address Set command
    BL TFT_WriteCommand
    MOV R0, #0x00        ; Start Row High Byte
    BL TFT_WriteData
    MOV R0, #0x00        ; Start Row Low Byte
    BL TFT_WriteData
    MOV R0, #0x01        ; End Row High Byte
    BL TFT_WriteData
    MOV R0, #0x3F        ; End Row Low Byte
    BL TFT_WriteData

    ; Start writing to RAM
    MOV R0, #0x2C        ; Memory Write command
    BL TFT_WriteCommand

    ; Loop to write the color to all pixels
    LDR R3, =153600      ; Total pixels * 2 (Wait, 128x160 = 20480. 153600 is used here maybe to cover different sizes?)
fill_pixels
    MOV R0, R4           
    BL TFT_WriteData16
    SUBS R3, R3, #1
    BNE fill_pixels

    POP {R1-R4, PC}
    ENDFUNC


; Draws a single 8x8 character on the screen
; Parameters: R0 = X coord, R1 = Y coord, R2 = ASCII Char, R3 = 16-bit Color
TFT_DrawChar FUNCTION
    PUSH {R4-R9, LR}
    
    MOV R4, R0          ; Save X coordinate
    MOV R5, R1          ; Save Y coordinate
    MOV R6, R2          ; Save Character
    MOV R7, R3          ; Save text color (Foreground)
    LDR R8, =0x0000     ; Save background color (Black)

    ; Validate Character is printable ASCII (32 to 126)
    CMP R6, #32
    BLT end_draw
    CMP R6, #126
    BGT end_draw

    ; Define the drawing window for the 8x8 character
    ; Columns: X to X+7
    ADD R9, R4, #7
    MOV R0, #0x2A       ; Column Address Set
    BL TFT_WriteCommand
    LSR R0, R4, #8
    BL TFT_WriteData
    AND R0, R4, #0xFF
    BL TFT_WriteData
    LSR R0, R9, #8
    BL TFT_WriteData
    AND R0, R9, #0xFF
    BL TFT_WriteData

    ; Rows: Y to Y+7
    ADD R9, R5, #7
    MOV R0, #0x2B       ; Row Address Set
    BL TFT_WriteCommand
    LSR R0, R5, #8
    BL TFT_WriteData
    AND R0, R5, #0xFF
    BL TFT_WriteData
    LSR R0, R9, #8
    BL TFT_WriteData
    AND R0, R9, #0xFF
    BL TFT_WriteData

    ; Start memory write
    MOV R0, #0x2C       ; Memory Write
    BL TFT_WriteCommand

    ; Find the font bitmap in memory
    SUB R6, R6, #32     ; Calculate character offset (Space is 0th index)
    LSL R6, R6, #3      ; Multiply by 8 (since each char is 8 bytes long)
    LDR R9, =font8x8
    ADD R9, R9, R6      ; R9 now points to the character's bitmap

    MOV R5, #8          ; Loop over 8 rows of the character
row_loop
    LDRB R6, [R9]       ; Load the byte representing the row
    ADD R9, R9, #1      
    
    MOV R4, #8          ; Loop over 8 bits (columns) in the row
bit_loop
    TST R6, #0x80       ; Test the leftmost bit
    BNE draw_fg         ; If 1, draw foreground color

draw_bg
    ; Bit is 0, draw background color
    MOV R0, R8          
    BL TFT_WriteData16
    B next_bit

draw_fg
    ; Bit is 1, draw text color
    MOV R0, R7          
    BL TFT_WriteData16

next_bit
    LSL R6, R6, #1      ; Shift byte left to check the next bit
    SUBS R4, R4, #1
    BNE bit_loop        
    
    SUBS R5, R5, #1
    BNE row_loop        

end_draw
    POP {R4-R9, PC}
    ENDFUNC


; Software Bit-Banged SPI implementation to send a single byte to the TFT
TFT_SPI_SendByte FUNCTION
    PUSH {R1-R3}
    LDR R1, =GPIOA_BASE + GPIO_BSRR
    MOV R3, #8             ; Loop 8 times for 8 bits
spi_loop
    ; Transmit MSB on MOSI pin
    TST R0, #0x80
    BNE set_mosi
    LDR R2, =(1 << (TFT_MOSI_BIT + 16)) ; Pull MOSI LOW
    STR R2, [R1]
    B clk_pulse
set_mosi
    LDR R2, =(1 << TFT_MOSI_BIT)        ; Pull MOSI HIGH
    STR R2, [R1]

clk_pulse
    ; Toggle Clock Pin
    LDR R2, =(1 << TFT_SCK_BIT)         ; Pull SCK HIGH
    STR R2, [R1]
    LSL R0, R0, #1                      ; Shift byte left
    LDR R2, =(1 << (TFT_SCK_BIT + 16))  ; Pull SCK LOW
    STR R2, [R1]

    SUBS R3, R3, #1
    BNE spi_loop
    
    POP {R1-R3}
    BX LR
    ENDFUNC

; Transmits a command byte to the TFT (Data/Command pin LOW)
TFT_WriteCommand FUNCTION
    PUSH {R1-R2, LR}
    LDR R1, =GPIOB_BASE + GPIO_BSRR
    
    ; Pull CS LOW (Select) and D/C LOW (Command)
    LDR R2, =(1 << (TFT_CS_BIT + 16)) | (1 << (TFT_DC_BIT + 16))
    STR R2, [R1]
    
    BL TFT_SPI_SendByte
    
    ; Pull CS HIGH (Deselect)
    LDR R2, =(1 << TFT_CS_BIT)
    STR R2, [R1]
    
    POP {R1-R2, PC}
    ENDFUNC

; Transmits a data byte to the TFT (Data/Command pin HIGH)
TFT_WriteData FUNCTION
    PUSH {R1-R2, LR}
    LDR R1, =GPIOB_BASE + GPIO_BSRR

    ; Pull CS LOW (Select) and D/C HIGH (Data)
    LDR R2, =(1 << (TFT_CS_BIT + 16)) | (1 << TFT_DC_BIT)
    STR R2, [R1]
    
    BL TFT_SPI_SendByte
    
    ; Pull CS HIGH (Deselect)
    LDR R2, =(1 << TFT_CS_BIT)
    STR R2, [R1]
    
    POP {R1-R2, PC}
    ENDFUNC

; Transmits a 16-bit word (e.g. RGB565 color) to the TFT by sending it as two bytes
TFT_WriteData16 FUNCTION
    PUSH {R0-R3, LR}
    MOV R3, R0              
    LSR R0, R3, #8          ; Send High byte first
    BL TFT_WriteData
    MOV R0, R3
    AND R0, R0, #0xFF       ; Send Low byte second
    BL TFT_WriteData
    POP {R0-R3, PC}
    ENDFUNC

; A simple software delay loop
delay FUNCTION
    PUSH {R0, LR}
    LDR R0, =0x20000        ; Arbitrary delay count
delay_loop
    SUBS R0, R0, #1
    BNE delay_loop
    POP {R0, PC}
    ENDFUNC

    ALIGN
    END