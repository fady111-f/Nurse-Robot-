
    AREA VARS, DATA, READWRITE
myVar DCD 0


RCC_BASE        EQU 0x40023800
RCC_AHB1ENR     EQU 0x40023830


GPIOA_BASE      EQU 0x40020000
GPIOB_BASE      EQU 0x40020400


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

	
RFID_Init FUNCTION
    PUSH {LR}
    
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x03         
    STR R1, [R0]

    
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #0x00]   
    LDR R2, =0x00030000       
    BIC R1, R1, R2
    LDR R2, =0x00010000       
    ORR R1, R1, R2
    STR R1, [R0, #0x00]       
    
   
    LDR R1, =(1<<8)
    STR R1, [R0, #0x18]       

    
    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #0x00]       
    LDR R2, =0x30000000       
    BIC R1, R1, R2            
    STR R1, [R0, #0x00]      

    
    MOV R0, #CommandReg
    MOV R1, #0x0F            
    BL RC522_WriteReg
    LDR R2, =0x000FFFFF      
Reset_Wait
    SUBS R2, R2, #1
    BNE Reset_Wait


    MOV R0, #TModeReg
    MOV R1, #0x80            
    BL RC522_WriteReg
    MOV R0, #TPrescalerReg
    MOV R1, #0xA9            
    BL RC522_WriteReg
    MOV R0, #TReloadRegH
    MOV R1, #0x03
    BL RC522_WriteReg
    MOV R0, #TReloadRegL
    MOV R1, #0xE8
    BL RC522_WriteReg
    
    
    MOV R0, #TxASKReg
    MOV R1, #0x40            
    BL RC522_WriteReg
    MOV R0, #ModeReg
    MOV R1, #0x3D            
    BL RC522_WriteReg
    
    
    MOV R0, #TxControlReg
    BL RC522_ReadReg
    ORR R1, R0, #0x03        
    MOV R0, #TxControlReg
    BL RC522_WriteReg

    POP {PC}
    ENDFUNC


RFID_Process FUNCTION
    PUSH {LR}
    BL Poll_Card
    CMP R4, #0
    BEQ Process_End           
    BL Check_UID
Process_End
    POP {PC}
    ENDFUNC


Poll_Card
    PUSH {LR, R5, R6, R7}
    MOV R4, #0                

    MOV R0, #CommandReg
    MOV R1, #0x00             
    BL RC522_WriteReg
    MOV R0, #ComIrqReg
    MOV R1, #0x7F             
    BL RC522_WriteReg
    MOV R0, #FIFOLevelReg
    MOV R1, #0x80             
    BL RC522_WriteReg
    
    MOV R0, #FIFODataReg
    MOV R1, #0x26             
    BL RC522_WriteReg
    
    MOV R0, #CommandReg
    MOV R1, #0x0C             
    BL RC522_WriteReg
    MOV R0, #BitFramingReg
    MOV R1, #0x87             
    BL RC522_WriteReg
    
    LDR R6, =0x1000
Wait_REQA
    SUBS R6, R6, #1
    BEQ Poll_Fail             
    MOV R0, #ComIrqReg
    BL RC522_ReadReg
    ANDS R7, R0, #0x20        
    BEQ Wait_REQA

    MOV R0, #CommandReg
    MOV R1, #0x00             
    BL RC522_WriteReg
    MOV R0, #ComIrqReg
    MOV R1, #0x7F             
    BL RC522_WriteReg
    MOV R0, #FIFOLevelReg
    MOV R1, #0x80             
    BL RC522_WriteReg
    
    MOV R0, #FIFODataReg
    MOV R1, #0x93             
    BL RC522_WriteReg
    MOV R0, #FIFODataReg
    MOV R1, #0x20             
    BL RC522_WriteReg
    
    MOV R0, #CommandReg
    MOV R1, #0x0C             
    BL RC522_WriteReg
    MOV R0, #BitFramingReg
    MOV R1, #0x80             
    BL RC522_WriteReg
    
    LDR R6, =0x1000
Wait_Anti
    SUBS R6, R6, #1
    BEQ Poll_Fail
    MOV R0, #ComIrqReg
    BL RC522_ReadReg
    ANDS R7, R0, #0x20
    BEQ Wait_Anti

    MOV R0, #BitFramingReg
    MOV R1, #0x00
    BL RC522_WriteReg

    MOV R0, #FIFOLevelReg
    BL RC522_ReadReg
    CMP R0, #5
    BNE Poll_Fail

    MOV R4, #0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          
    LSL R0, R0, #8
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          
    LSL R0, R0, #16
    ORR R4, R4, R0
    
    MOV R0, #FIFODataReg
    BL RC522_ReadReg          
    LSL R0, R0, #24
    ORR R4, R4, R0
    
Poll_Fail
    POP {LR, R5, R6, R7}
    BX LR


SPI_TxRx FUNCTION
    PUSH {R1-R6, LR}
    MOV R4, #8               
    MOV R5, #0               
    LDR R1, =GPIOA_BASE      
    LDR R6, =GPIOB_BASE      
    LDR R2, =(1<<9)        
    LDR R3, =(1<<10)         

spi_loop

    TST R0, #0x80            
    BNE set_mosi
    LDR R12, =(1<<26)        
    STR R12, [R1, #0x18]     
    B clk_pulse
set_mosi
    STR R3, [R1, #0x18]      

clk_pulse

    STR R2, [R1, #0x18]      


    LSL R5, R5, #1           
    LDR R12, [R6, #0x10]    
    TST R12, #(1 << 14)      
    BEQ clk_low
    ORR R5, R5, #1           

clk_low
   
    LDR R12, =(1<<25)        
    STR R12, [R1, #0x18]     

    
    LSL R0, R0, #1           

    SUBS R4, R4, #1          
    BNE spi_loop             

    MOV R0, R5               
    POP {R1-R6, PC}
    ENDFUNC


RC522_WriteReg
    PUSH {LR, R4, R5}
    MOV R4, R0                
    MOV R5, R1                
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<24)       
    STR R2, [R1]
    
    LSL R0, R4, #1
    AND R0, R0, #0x7E         
    BL SPI_TxRx               
    MOV R0, R5
    BL SPI_TxRx               
    
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<8)        
    STR R2, [R1]
    
    POP {LR, R4, R5}
    BX LR


RC522_ReadReg
    PUSH {LR, R4}
    MOV R4, R0                
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<24)       
    STR R2, [R1]
    
    LSL R0, R4, #1
    AND R0, R0, #0x7E
    ORR R0, R0, #0x80         
    BL SPI_TxRx               
    MOV R0, #0x00             
    BL SPI_TxRx               
    
    LDR R1, =GPIOA_BASE + 0x18
    LDR R2, =(1<<8)        
    STR R2, [R1]
    
    POP {LR, R4}
    BX LR


    LTORG
Check_UID FUNCTION
    PUSH {LR}                 
    
    LDR R5, =0x031F39CA       
    LDR R0, =myVar
    STR R4, [R0]
    CMP R4, R5
    BEQ.W Show_1      

    LDR R5, =0x023338e6       
    CMP R4, R5
    BEQ.W Show_2 

    B Check_UID_End

Show_1
    LDR R0, =0x0000           
    BL TFT_Fill
    BL DS18B20_UpdateTemp
    MOV R0, #5                
    MOV R1, #5               
    LDR R2, =str_NAME        
    LDR R3, =0xFFFF           
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

    MOV R0, #5                
    MOV R1, #55               
    LDR R2, =str_ROOM_LBL     
    LDR R3, =0x07E0           
    BL TFT_DrawString

    LDR R0, =temp_data        
    LDRSH R2, [R0]
    ASRS R2, R2, #4           
    MOV R0, #95               
    MOV R1, #55               
    LDR R3, =0xFFFF           
    BL TFT_DrawNumber

    BL MAX30102_Update
    MOV R0, #5                
    MOV R1, #70               
    LDR R2, =str_SPO2_LBL     
    LDR R3, =0x07FF           
    BL TFT_DrawString

    LDR R0, =final_spo2
    LDR R2, [R0]              
    MOV R0, #95
    MOV R1, #70
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    MOV R0, #5                
    MOV R1, #85               
    LDR R2, =str_HR_LBL     
    LDR R3, =0xF800           
    BL TFT_DrawString

    LDR R0, =final_bpm
    LDR R2, [R0]              
    MOV R0, #95
    MOV R1, #85
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    MOV R0, #5                
    MOV R1, #100               
    LDR R2, =str_PRESS_LBL     
    LDR R3, =0xFFE0           
    BL TFT_DrawString

    BL read_velostat          
    MOV R2, R0                
    MOV R0, #95
    MOV R1, #100
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

    MOV R0, #5                
    MOV R1, #115               
    LDR R2, =str_USE_TEMP_LBL     
    LDR R3, =0xF81F           
    BL TFT_DrawString

    LDR R0, =temp_int
    LDRB R2, [R0]             
    MOV R0, #95
    MOV R1, #115
    LDR R3, =0xFFFF
    BL TFT_DrawNumber

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