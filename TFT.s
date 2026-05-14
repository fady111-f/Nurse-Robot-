

    AREA TFT_CODE, CODE, READONLY
    EXPORT TFT_Init
    EXPORT TFT_Fill
    EXPORT TFT_DrawChar
    
    EXPORT TFT_WriteCommand
    EXPORT TFT_WriteData
    EXPORT TFT_WriteData16
        
    IMPORT font8x8


RCC_BASE     EQU 0x40023800
GPIOA_BASE   EQU 0x40020000
GPIOB_BASE   EQU 0x40020400

RCC_AHB1ENR  EQU 0x30
GPIO_MODER   EQU 0x00
GPIO_ODR     EQU 0x14
GPIO_BSRR    EQU 0x18
GPIO_OSPEEDR EQU 0x08


TFT_SCK_BIT  EQU 9     
TFT_MOSI_BIT EQU 10     

TFT_CS_BIT   EQU 12     
TFT_RST_BIT  EQU 13    
TFT_DC_BIT   EQU 15    


TFT_Init FUNCTION
    PUSH {R0-R2, LR}

    
    LDR R0, =RCC_BASE + RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03
    STR R1, [R0]

    
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0x003C0000       
    BIC R1, R1, R2
    LDR R2, =0x00140000      
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_MODER]

    
    LDR R1, [R0, #GPIO_OSPEEDR]
    LDR R2, =0x003C0000       
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_OSPEEDR]

   
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
    LDR R2, =0xCF000000      
    BIC R1, R1, R2
    LDR R2, =0x45000000       
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_MODER]

   
    LDR R1, [R0, #GPIO_OSPEEDR]
    LDR R2, =0xCF000000       
    ORR R1, R1, R2
    STR R1, [R0, #GPIO_OSPEEDR]

    
    LDR R0, =GPIOB_BASE
    LDR R1, =(1 << TFT_CS_BIT)
    STR R1, [R0, #GPIO_BSRR]
    
    LDR R0, =GPIOA_BASE
    LDR R1, =(1 << (TFT_SCK_BIT + 16)) 
    STR R1, [R0, #GPIO_BSRR]

   
    LDR R0, =GPIOB_BASE
    LDR R1, =(1 << (TFT_RST_BIT + 16)) 
    STR R1, [R0, #GPIO_BSRR]
    BL delay
    
    LDR R1, =(1 << TFT_RST_BIT)       
    STR R1, [R0, #GPIO_BSRR]
    BL delay

   
    MOV R0, #0x11        
    BL TFT_WriteCommand
    BL delay

    MOV R0, #0x3A        
    BL TFT_WriteCommand
    MOV R0, #0x55
    BL TFT_WriteData

    MOV R0, #0x36        
    BL TFT_WriteCommand
    MOV R0, #0xE8        
    BL TFT_WriteData

    MOV R0, #0x29        
    BL TFT_WriteCommand

    POP {R0-R2, PC}
    ENDFUNC


TFT_Fill FUNCTION
    PUSH {R1-R4, LR}
    MOV R4, R0           

    MOV R0, #0x2A
    BL TFT_WriteCommand
    MOV R0, #0x00
    BL TFT_WriteData
    MOV R0, #0x00
    BL TFT_WriteData
    MOV R0, #0x01
    BL TFT_WriteData
    MOV R0, #0xDF
    BL TFT_WriteData

    MOV R0, #0x2B
    BL TFT_WriteCommand
    MOV R0, #0x00
    BL TFT_WriteData
    MOV R0, #0x00
    BL TFT_WriteData
    MOV R0, #0x01
    BL TFT_WriteData
    MOV R0, #0x3F
    BL TFT_WriteData

    MOV R0, #0x2C
    BL TFT_WriteCommand

    LDR R3, =153600
fill_pixels
    MOV R0, R4           
    BL TFT_WriteData16
    SUBS R3, R3, #1
    BNE fill_pixels

    POP {R1-R4, PC}
    ENDFUNC


TFT_DrawChar FUNCTION
    PUSH {R4-R9, LR}
    
    MOV R4, R0          
    MOV R5, R1          
    MOV R6, R2          
    MOV R7, R3          
    LDR R8, =0x0000     

    CMP R6, #32
    BLT end_draw
    CMP R6, #126
    BGT end_draw

    ADD R9, R4, #7
    MOV R0, #0x2A
    BL TFT_WriteCommand
    LSR R0, R4, #8
    BL TFT_WriteData
    AND R0, R4, #0xFF
    BL TFT_WriteData
    LSR R0, R9, #8
    BL TFT_WriteData
    AND R0, R9, #0xFF
    BL TFT_WriteData

    ADD R9, R5, #7
    MOV R0, #0x2B
    BL TFT_WriteCommand
    LSR R0, R5, #8
    BL TFT_WriteData
    AND R0, R5, #0xFF
    BL TFT_WriteData
    LSR R0, R9, #8
    BL TFT_WriteData
    AND R0, R9, #0xFF
    BL TFT_WriteData

    MOV R0, #0x2C
    BL TFT_WriteCommand

    SUB R6, R6, #32
    LSL R6, R6, #3      
    LDR R9, =font8x8
    ADD R9, R9, R6      

    MOV R5, #8          
row_loop
    LDRB R6, [R9]       
    ADD R9, R9, #1      
    
    MOV R4, #8          
bit_loop
    TST R6, #0x80       
    BNE draw_fg

draw_bg
    MOV R0, R8          
    BL TFT_WriteData16
    B next_bit

draw_fg
    MOV R0, R7          
    BL TFT_WriteData16

next_bit
    LSL R6, R6, #1      
    SUBS R4, R4, #1
    BNE bit_loop        
    
    SUBS R5, R5, #1
    BNE row_loop        

end_draw
    POP {R4-R9, PC}
    ENDFUNC


TFT_SPI_SendByte FUNCTION
    PUSH {R1-R3}
    LDR R1, =GPIOA_BASE + GPIO_BSRR
    MOV R3, #8             
spi_loop
    TST R0, #0x80
    BNE set_mosi
    LDR R2, =(1 << (TFT_MOSI_BIT + 16)) 
    STR R2, [R1]
    B clk_pulse
set_mosi
    LDR R2, =(1 << TFT_MOSI_BIT)        
    STR R2, [R1]

clk_pulse
    LDR R2, =(1 << TFT_SCK_BIT)         
    STR R2, [R1]
    LSL R0, R0, #1                      
    LDR R2, =(1 << (TFT_SCK_BIT + 16))  
    STR R2, [R1]

    SUBS R3, R3, #1
    BNE spi_loop
    
    POP {R1-R3}
    BX LR
    ENDFUNC

TFT_WriteCommand FUNCTION
    PUSH {R1-R2, LR}
    LDR R1, =GPIOB_BASE + GPIO_BSRR
    
    LDR R2, =(1 << (TFT_CS_BIT + 16)) | (1 << (TFT_DC_BIT + 16))
    STR R2, [R1]
    
    BL TFT_SPI_SendByte
    
   
    LDR R2, =(1 << TFT_CS_BIT)
    STR R2, [R1]
    
    POP {R1-R2, PC}
    ENDFUNC

TFT_WriteData FUNCTION
    PUSH {R1-R2, LR}
    LDR R1, =GPIOB_BASE + GPIO_BSRR

    LDR R2, =(1 << (TFT_CS_BIT + 16)) | (1 << TFT_DC_BIT)
    STR R2, [R1]
    
    BL TFT_SPI_SendByte
    
    
    LDR R2, =(1 << TFT_CS_BIT)
    STR R2, [R1]
    
    POP {R1-R2, PC}
    ENDFUNC

TFT_WriteData16 FUNCTION
    PUSH {R0-R3, LR}
    MOV R3, R0              
    LSR R0, R3, #8          
    BL TFT_WriteData
    MOV R0, R3
    AND R0, R0, #0xFF       
    BL TFT_WriteData
    POP {R0-R3, PC}
    ENDFUNC

delay FUNCTION
    PUSH {R0, LR}
    LDR R0, =0x20000        
delay_loop
    SUBS R0, R0, #1
    BNE delay_loop
    POP {R0, PC}
    ENDFUNC

    ALIGN
    END