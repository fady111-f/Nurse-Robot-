

    AREA MAIN_VARS, DATA, READWRITE
    ALIGN 4
    EXPORT ir_command
    EXPORT ir_flag

ir_command        DCB 0
ir_flag           DCB 0
current_selection DCB 0
screen_state      DCB 0
active_btn        DCB 0
servo_state       DCB 0      
num_buffer    SPACE 12  

    ALIGN 4
hist_count        DCB 0      
    ALIGN 4
temp_history      SPACE 12   
	
	
    ALIGN 4
spo2_current  DCD 0    
spo2_past1    DCD 0    
spo2_past2    DCD 0
spo2_past3    DCD 0
spo2_past4    DCD 0
spo2_past5    DCD 0    
spo2_idx      DCB 0    

bpm_hist_count  DCB 0
spo2_hist_count DCB 0
    ALIGN 4

    ALIGN 4
bpm_current   DCD 0
bpm_past1     DCD 0
bpm_past2     DCD 0
bpm_past3     DCD 0
bpm_past4     DCD 0
bpm_past5     DCD 0
	
	ALIGN 4
press_hist_count DCB 0
    ALIGN 4
press_current    DCD 0
press_past1      DCD 0
press_past2      DCD 0
press_past3      DCD 0
press_past4      DCD 0
press_past5      DCD 0
	

desired_drop_rate DCD 0      	

    ALIGN 4
	IMPORT MAX30102_Setup
    IMPORT MAX30102_Update
    IMPORT final_bpm
    IMPORT final_spo2
    IMPORT temp_int
	IMPORT IR_Drop_Init
    IMPORT IR_Drop_Update
	IMPORT Last_Rate
	IMPORT  Current_Count
	IMPORT  Total_Drops
	IMPORT 	Sec_Count
	IMPORT HCSR04_Init
    IMPORT HCSR04_Measure
    IMPORT hc_delay_us      
	IMPORT BT_Init
    IMPORT BT_Get_Data
	IMPORT ARM_INIT
    IMPORT Enter_Robot_Mode     
	
    IMPORT bpm_history
    
    IMPORT spo2_history
    IMPORT mtemp_hist_count
    IMPORT mtemp_history
		
	EXPORT spo2_current
	EXPORT press_current
	EXPORT spo2_current
	EXPORT bpm_current
	IMPORT BT_Send_Sensor_Data
	IMPORT distance_cm
	
    IMPORT RFID_Init
    IMPORT RFID_Process
		
	IMPORT init_velostat
    IMPORT read_velostat

    ALIGN 4	
    ALIGN 4


    AREA MAIN_CODE, CODE, READONLY
    ALIGN 4

    EXPORT __main
    EXPORT font8x8
	EXPORT TFT_DrawString
	EXPORT TFT_DrawNumber
    IMPORT IR_Init
    IMPORT TFT_Init
    IMPORT TFT_WriteCommand
    IMPORT TFT_WriteData
    IMPORT TFT_WriteData16
    IMPORT TFT_Fill
    IMPORT TFT_DrawChar
    IMPORT temp_data
    IMPORT DS18B20_Init
    IMPORT DS18B20_UpdateTemp
	EXPORT active_btn
		
	IMPORT delay


COLOR_BLACK   EQU 0x0000
COLOR_WHITE   EQU 0xFFFF
COLOR_CYAN    EQU 0x07FF
COLOR_GREEN   EQU 0x07E0
COLOR_RED     EQU 0xF800
COLOR_YELLOW  EQU 0xFFE0
COLOR_MAGENTA EQU 0xF81F
COLOR_BLUE    EQU 0x001F
GPIOB_BASE    EQU 0x40020400
GPIOB_BSRR    EQU GPIOB_BASE + 0x18
GPIOA_BSRR 	  EQU 0x40020018
BUTTON_UP     EQU 0x18
BUTTON_DOWN   EQU 0x52
BUTTON_LEFT   EQU 0x08
BUTTON_RIGHT  EQU 0x5A
BUTTON_OK     EQU 0x1C  
BUTTON_2      EQU 0x46
BUTTON_4      EQU 0x44
BUTTON_5      EQU 0x40
BUTTON_6      EQU 0x43
	
TIM2_BASE   EQU   0x40000000
TIM_CCMR2       EQU 0x1C
TIM_CNT         EQU 0x24
TIM_ARR         EQU 0x2C
TIM_CCR1        EQU 0x34        
TIM_CCR2        EQU 0x38        
TIM_CCR3        EQU 0x3C        
TIM_CCR4        EQU 0x40        
	

BUTTON_0 EQU 0x19 
BUTTON_1 EQU 0x45
BUTTON_3 EQU 0x47
BUTTON_7 EQU 0x07
BUTTON_8 EQU 0x15
BUTTON_9 EQU 0x09

RCC_AHB1ENR   EQU 0x40023830
RCC_APB1ENR   EQU 0x40023840
GPIOA_BASE    EQU 0x40020000
GPIOA_MODER   EQU 0x00
GPIOA_ODR     EQU 0x14
GPIOA_AFRL    EQU 0x20
TIM4_BASE     EQU 0x40000800 
TIM3_BASE     EQU 0x40000400 
TIM5_BASE     EQU 0x40000C00 
TIM_CR1       EQU 0x00
TIM_PSC       EQU 0x28
TIM_CCMR1     EQU 0x18
TIM_CCER      EQU 0x20
TIM_EGR       EQU 0x14

SERVO_0_DEG   EQU 1200      
SERVO_90_DEG  EQU 500      
	
DROP_TOLERANCE    EQU 2   
STATE_MAIN_MENU   EQU 0
STATE_SUISEI_MENU EQU 1
STATE_WA_MENU     EQU 2
STATE_KYO_MENU    EQU 3
STATE_MO_MENU     EQU 4
STATE_KAWAII_MENU EQU 5
STATE_HOSHIYOME_MENU EQU 6



str_sep   DCB "==============================", 0
str_title DCB "smart control dashboard", 0
str_1     DCB "[1] room temp", 0
str_2     DCB "[2] heart rate", 0
str_3     DCB "[3] SpO2", 0
str_4     DCB "[4] temperature", 0
str_5     DCB "[5] pressure", 0
str_temp  DCB "Temperature is: ", 0

str_temp_curr DCB "Current: ", 0
str_temp_past DCB "Past: ", 0
str_bp        DCB "blood pressure: ", 0
str_glucose   DCB "glucose level: ", 0
str_slash     DCB "/", 0
str_mgdl      DCB " mg/dL", 0
str_bpm   DCB "heart rate: ", 0
str_spo2  DCB "blood oxygen: ", 0
str_unit1 DCB " bpm", 0
str_unit2 DCB " %", 0

str_bpm_curr  DCB "Current: ", 0    
str_bpm_past  DCB "Past: ", 0      
str_spo2_curr DCB "Current: ", 0    
str_spo2_past DCB "Past: ", 0       
str_mt_curr   DCB "Current: ", 0    
str_mt_past   DCB "Past: ", 0       

str_spo2_c    DCB "Current: ", 0
str_spo2_p1   DCB "Past:  ", 0
str_spo2_p2   DCB "Past:  ", 0
str_spo2_p3   DCB "Past:  ", 0
str_spo2_p4   DCB "Past:  ", 0
str_spo2_p5   DCB "Past:  ", 0


str_bpm_c     DCB "Current: ", 0
str_bpm_p1    DCB "Past:  ", 0
str_bpm_p2    DCB "Past:  ", 0
str_bpm_p3    DCB "Past:  ", 0
str_bpm_p4    DCB "Past:  ", 0
str_bpm_p5    DCB "Past:  ", 0
str_dr_label DCB "drop rate: ", 0
str_dr_unit  DCB " d/min", 0

str_press_c DCB "Current: ", 0
str_press_p DCB "Past:  ", 0

str_6        DCB "[6] drop rate", 0
str_target   DCB "Target: ", 0
str_actual   DCB "Actual: ", 0
str_status   DCB "Status: ", 0
str_ok       DCB "OK", 0
str_high     DCB "HIGH", 0
str_low      DCB "LOW", 0
str_not_set  DCB "---", 0
    ALIGN 4
    ALIGN 4
		
		

dummy_sys     DCD 120
dummy_dia     DCD 80
dummy_gluc    DCD 95
    ALIGN 4



TFT_SetWindow FUNCTION
    PUSH {R4-R7, LR}
    MOV R4, R0 
    MOV R5, R1 
    MOV R6, R2 
    MOV R7, R3 
    MOV R0, #0x2A
    BL TFT_WriteCommand
    LSR R0, R4, #8
    BL TFT_WriteData
    AND R0, R4, #0xFF
    BL TFT_WriteData
    LSR R0, R6, #8
    BL TFT_WriteData
    AND R0, R6, #0xFF
    BL TFT_WriteData
    MOV R0, #0x2B
    BL TFT_WriteCommand
    LSR R0, R5, #8
    BL TFT_WriteData
    AND R0, R5, #0xFF
    BL TFT_WriteData
    LSR R0, R7, #8
    BL TFT_WriteData
    AND R0, R7, #0xFF
    BL TFT_WriteData
    MOV R0, #0x2C
    BL TFT_WriteCommand
    POP {R4-R7, PC}
    ENDFUNC

TFT_DrawHLine FUNCTION
    PUSH {R4-R6, LR}
    MOV R4, R2      
    MOV R5, R3      
    ADD R2, R0, R2  
    SUB R2, R2, #1  
    MOV R3, R1      
    BL TFT_SetWindow
hl_loop
    CMP R4, #0
    BEQ hl_end
    MOV R0, R5
    BL TFT_WriteData16
    SUB R4, R4, #1
    B hl_loop
hl_end
    POP {R4-R6, PC}
    ENDFUNC

TFT_DrawVLine FUNCTION
    PUSH {R4-R6, LR}
    MOV R4, R2      
    MOV R5, R3      
    MOV R3, R1
    ADD R3, R3, R2  
    SUB R3, R3, #1  
    MOV R2, R0      
    BL TFT_SetWindow
vl_loop
    CMP R4, #0
    BEQ vl_end
    MOV R0, R5
    BL TFT_WriteData16
    SUB R4, R4, #1
    B vl_loop
vl_end
    POP {R4-R6, PC}
    ENDFUNC

TFT_DrawRect FUNCTION
    PUSH {R4-R10, LR}
    MOV R4, R0 
    MOV R5, R1 
    MOV R6, R2 
    MOV R7, R3 
    LDR R8, [SP, #32] 
    MOV R0, R4
    MOV R1, R5
    MOV R2, R6
    MOV R3, R8
    BL TFT_DrawHLine
    MOV R0, R4
    ADD R1, R5, R7
    SUB R1, R1, #1
    MOV R2, R6
    MOV R3, R8
    BL TFT_DrawHLine
    MOV R0, R4
    MOV R1, R5
    MOV R2, R7
    MOV R3, R8
    BL TFT_DrawVLine
    ADD R0, R4, R6
    SUB R0, R0, #1
    MOV R1, R5
    MOV R2, R7
    MOV R3, R8
    BL TFT_DrawVLine
    POP {R4-R10, PC}
    ENDFUNC

TFT_DrawString FUNCTION
    PUSH {R4-R7, LR}
    MOV R4, R0 
    MOV R5, R1 
    MOV R6, R2 
    MOV R7, R3 
ds_loop
    LDRB R2, [R6]
    CMP R2, #0
    BEQ ds_end
    MOV R0, R4
    MOV R1, R5
    MOV R3, R7
    BL TFT_DrawChar
    ADD R6, R6, #1
    ADD R4, R4, #8
    B ds_loop
ds_end
    POP {R4-R7, PC}
    ENDFUNC
	
TFT_DrawNumber FUNCTION
    PUSH {R4-R8, LR}    
    MOV R4, R0          
    MOV R5, R1          
    MOV R6, R3          
    LDR R7, =num_buffer 
    ADD R7, R7, #11     
    MOV R0, #0
    STRB R0, [R7]       
    MOV R0, R2          
    MOV R8, #10         
    CMP R0, #0          
    BNE num_loop
num_zero
    SUB R7, R7, #1      
    MOV R2, #'0'        
    STRB R2, [R7]       
    B num_draw          
num_loop
    CMP R0, #0          
    BEQ num_draw
    UDIV R2, R0, R8     
    MLS  R3, R2, R8, R0 
    ADD R3, R3, #'0'    
    SUB R7, R7, #1      
    STRB R3, [R7]       
    MOV R0, R2          
    B num_loop
num_draw
    MOV R0, R4          
    MOV R1, R5          
    MOV R2, R7          
    MOV R3, R6          
    BL TFT_DrawString   
    POP {R4-R8, PC}
    ENDFUNC

Convert_IR_To_Digit_BT
	push{LR}
    MOV R7, #0xFF
	
	CMP R0, #0xB2             
    BEQ bt_0
    CMP R0, #0x96            
    BEQ bt_1
    CMP R0, #0x99             
    BEQ bt_2
    CMP R0, #0x8D             
    BEQ bt_3
	CMP R0, #0x8C             
    BEQ bt_4
    CMP R0, #0x98             
    BEQ bt_5
    CMP R0, #0xBE             
    BEQ bt_6
    CMP R0, #0x88             
    BEQ bt_7
	CMP R0, #0x9C             
    BEQ bt_8
    CMP R0, #0xBA             
    BEQ bt_9

bt_0
    MOV R4, #BUTTON_0
    BL Convert_IR_To_Digit 
	B END_BT_CONVERT
bt_1
    MOV R4, #BUTTON_1
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_2
    MOV R4, #BUTTON_2
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_3
    MOV R4, #BUTTON_3
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_4
    MOV R4, #BUTTON_4   
    BL Convert_IR_To_Digit          
	B END_BT_CONVERT
bt_5
    MOV R4, #BUTTON_5
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_6
    MOV R4, #BUTTON_6
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_7
    MOV R4, #BUTTON_7
    BL Convert_IR_To_Digit
	B END_BT_CONVERT
bt_8
    MOV R4, #BUTTON_8     
    BL Convert_IR_To_Digit          
	B END_BT_CONVERT
bt_9
    MOV R4, #BUTTON_9
    BL Convert_IR_To_Digit
	
END_BT_CONVERT
	POP{PC}

Convert_IR_To_Digit FUNCTION
    
    MOV R7, #0xFF
    
    CMP R4, #BUTTON_0
    BEQ is_0
    CMP R4, #BUTTON_1
    BEQ is_1
    CMP R4, #BUTTON_2
    BEQ is_2
    CMP R4, #BUTTON_3
    BEQ is_3
    CMP R4, #BUTTON_4
    BEQ is_4
    CMP R4, #BUTTON_5
    BEQ is_5
    CMP R4, #BUTTON_6
    BEQ is_6
    CMP R4, #BUTTON_7
    BEQ is_7
    CMP R4, #BUTTON_8
    BEQ is_8
    CMP R4, #BUTTON_9
    BEQ is_9
    B end_convert

is_0  MOV R7, #0 
      B end_convert
is_1  MOV R7, #1 
      B end_convert
is_2  MOV R7, #2 
      B end_convert
is_3  MOV R7, #3 
      B end_convert
is_4  MOV R7, #4 
      B end_convert
is_5  MOV R7, #5 
      B end_convert
is_6  MOV R7, #6 
      B end_convert
is_7  MOV R7, #7 
      B end_convert
is_8  MOV R7, #8 
      B end_convert
is_9  MOV R7, #9 
      B end_convert

end_convert
    BX LR
    ENDFUNC

UpdateMenuHighlight FUNCTION
    PUSH {R4-R6, LR}
    MOV R4, R0        
    MOV R5, R1        

    
    MOV R0, #30       
    MUL R1, R4, R0    
    ADD R1, R1, #3    
    MOV R0, #5        
    MOV R2, #140      
    MOV R3, #16       
    LDR R12, =COLOR_BLACK
    SUB SP, SP, #8
    STR R12, [SP, #0]
    BL TFT_DrawRect
    ADD SP, SP, #8

    
    MOV R0, #30
    MUL R1, R5, R0
    ADD R1, R1, #3
    MOV R0, #5
    MOV R2, #140
    MOV R3, #16
    LDR R12, =COLOR_RED
    SUB SP, SP, #8
    STR R12, [SP, #0]
    BL TFT_DrawRect
    ADD SP, SP, #8

    POP {R4-R6, PC}
    ENDFUNC

DrawMainMenu FUNCTION
    PUSH {R4-R6, LR}
    MOV R4, R0          

    LDR R0, =COLOR_BLACK
    BL TFT_Fill

    
    MOV R0, #10
    MOV R1, #7          
    LDR R2, =str_1
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString

    
    MOV R0, #10
    MOV R1, #37         
    LDR R2, =str_2
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString

    
    MOV R0, #10
    MOV R1, #67         
    LDR R2, =str_3
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString

    
    MOV R0, #10
    MOV R1, #97         
    LDR R2, =str_4
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString

    
    MOV R0, #10
    MOV R1, #127        
    LDR R2, =str_5
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString


    MOV R0, #10
    MOV R1, #157        
    LDR R2, =str_6
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString

    
    MOV R0, #30         
    MUL R1, R4, R0      
    ADD R1, R1, #3      
    MOV R0, #5          
    MOV R2, #140        
    MOV R3, #16         
    LDR R12, =COLOR_RED
    SUB SP, SP, #8
    STR R12, [SP, #0]
    BL TFT_DrawRect
    ADD SP, SP, #8

    POP {R4-R6, PC}
    ENDFUNC



__main FUNCTION
    
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x01       
    STR R1, [R0]

    LDR R0, =RCC_APB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x0D       
    STR R1, [R0]

    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIOA_MODER]
    LDR R2, =0x00000FFC     
    BIC R1, R1, R2
    LDR R2, =0x00000954     
    ORR R1, R1, R2
    STR R1, [R0, #GPIOA_MODER]

    
    LDR R1, [R0, #GPIOA_AFRL]
    BIC R1, R1, #(0xF << 20) 
    ORR R1, R1, #(0x1 << 20) 
    STR R1, [R0, #GPIOA_AFRL]

    
    LDR R0, =TIM2_BASE
    MOV R1, #15          
    STR R1, [R0, #TIM_PSC]
    MOV R1, #19999          
    STR R1, [R0, #TIM_ARR]
    MOV R1, #SERVO_0_DEG
    STR R1, [R0, #TIM_CCR1]
    MOV R1, #0x68          
    STR R1, [R0, #TIM_CCMR1]
    MOV R1, #0x01          
    STR R1, [R0, #TIM_CCER]
    MOV R1, #0x01          
    STR R1, [R0, #TIM_CR1]	
	
    LDR R0, =TIM5_BASE
    LDR R1, =15999         
    STR R1, [R0, #TIM_PSC]
    LDR R1, =0xFFFFFFFF
    STR R1, [R0, #TIM_ARR]
    
    MOV R1, #0x01
    STR R1, [R0, #TIM_EGR]
    
    MOV R1, #0x01
    STR R1, [R0, #TIM_CR1]

    MOV R0, #0
    LDR R1, =servo_state
    STRB R0, [R1]
    BL  ARM_INIT
	
    
    BL  HCSR04_Init

    BL IR_Init
    BL TFT_Init
	BL IR_Drop_Init
	BL DS18B20_Init
	BL MAX30102_Setup
	BL RFID_Init
	BL BT_Init
	BL init_velostat
    CPSIE i
    
    MOV R0, #0
    LDR R1, =current_selection
    STRB R0, [R1]
    LDR R1, =screen_state
    STRB R0, [R1]
    LDR R1, =ir_flag
    STRB R0, [R1]
    LDR R1, =active_btn
    STRB R0, [R1]
    LDR R1, =servo_state
    STRB R0, [R1]
	
	

	LDR R1, =Last_Rate
    STR R0, [R1]
	LDR R1, =Current_Count
    STR R0, [R1]
	LDR R1, =Total_Drops
    STR R0, [R1]
	LDR R1, =Sec_Count
    STR R0, [R1]
    
	
    LDR R1, =bpm_current
    STR R0, [R1]
    LDR R1, =bpm_past1
    STR R0, [R1]
    LDR R1, =bpm_past2
    STR R0, [R1]
    LDR R1, =bpm_past3
    STR R0, [R1]
    LDR R1, =bpm_past4
    STR R0, [R1]
    LDR R1, =bpm_past5
    STR R0, [R1]

    
    LDR R1, =spo2_current
    STR R0, [R1]
    LDR R1, =spo2_past1
    STR R0, [R1]
    LDR R1, =spo2_past2
    STR R0, [R1]
    LDR R1, =spo2_past3
    STR R0, [R1]
    LDR R1, =spo2_past4
    STR R0, [R1]
    LDR R1, =spo2_past5
    STR R0, [R1]
    LDR R1, =spo2_idx
    STRB R0, [R1]    
	
	

    LDR R1, =press_current
    STR R0, [R1]
    LDR R1, =press_past1
    STR R0, [R1]
    LDR R1, =press_past2
    STR R0, [R1]
    LDR R1, =press_past3
    STR R0, [R1]
    LDR R1, =press_past4
    STR R0, [R1]
    LDR R1, =press_past5
    STR R0, [R1]
    LDR R1, =press_hist_count
    STRB R0, [R1]    
	
	

    LDR R1, =final_bpm
    STR R0, [R1]
    LDR R1, =final_spo2
    STR R0, [R1]
	
	
    LDR R1, =hist_count
    STRB R0, [R1]           
    LDR R1, =temp_data
    STRH R0, [R1]           

    
    LDR R1, =temp_history
    STR R0, [R1, #0]        
    STR R0, [R1, #4]        
    STR R0, [R1, #8]        

   
    LDR R1, =mtemp_hist_count
    STRB R0, [R1]           
    LDR R1, =temp_int
    STRB R0, [R1]           

 
    LDR R1, =mtemp_history
    STR R0, [R1, #0]       
    STR R0, [R1, #4]        
    STR R0, [R1, #8]        
    STR R0, [R1, #12]       
    STR R0, [R1, #16]       
    STR R0, [R1, #20]       
	
	
	LDR R1, =bpm_hist_count
    STRB R0, [R1]
    LDR R1, =spo2_hist_count
    STRB R0, [R1]

	
	
    BL DrawMainMenu
    
	LTORG
main_loop

	BL MAX30102_Update

	BL RFID_Process

	BL IR_Drop_Update
	

    LDR R0, =TIM5_BASE
    LDR R1, [R0, #TIM_CNT]
   
    LDR R2, =servo_state
    LDRB R3, [R2]
    CMP R3, #0           
    BEQ wait_10_sec      

wait_5_sec

    LDR R10, =5000      
    B check_time
wait_10_sec
    LDR R10, =10000      
check_time

    CMP R1, R10         
    BLT check_events 
    
	MOV R1, #0
	STR R1, [R0, #TIM_CNT]
	MOV R1, #0x01
	STR R1, [R0, #TIM_EGR] 
    LDR R4, =TIM2_BASE
    CMP R3, #0
    BEQ move_to_90

    

    MOV R5, #SERVO_0_DEG
    STR R5, [R4, #TIM_CCR1]

    MOV R3, #0

    STRB R3, [R2]

    B check_events

move_to_90

    MOV R5, #SERVO_90_DEG

    STR R5, [R4, #TIM_CCR1]

    MOV R3, #1
    STRB R3, [R2]
    B check_events

check_events
    BL BT_Get_Data
    CMP R0, #0               
    BEQ check_ir_events     
    
    
    CMP R0, #0x9A            
    BNE skip_bt_send          
    BL BT_Send_Sensor_Data    
    B main_loop               
skip_bt_send                
    

    
    CMP R0, #0x95             
    BEQ bt_down
    CMP R0, #0xA6             
    BEQ bt_up
    CMP R0, #0xA4             
    BEQ bt_left
    CMP R0, #0xA0            
    BEQ bt_ok

   
    CMP R0, #0x96
    BNE bt_not_1
    BL  Enter_Robot_Mode
    MOV R11, #STATE_MAIN_MENU
    LDR R0, =screen_state
    STRB R11, [R0]
    MOV R0, #0
    LDR R1, =current_selection
    STRB R0, [R1]
    BL  DrawMainMenu
    B   main_loop
bt_not_1
	
	
	CMP R0, #0x99            
    MOVEQ R4, #BUTTON_2
    CMP R0, #0x8C            
    MOVEQ R4, #BUTTON_4
    CMP R0, #0x98             
    MOVEQ R4, #BUTTON_5
    CMP R0, #0xBE             
    MOVEQ R4, #BUTTON_6
	
	
	LDR R5, =active_btn
    LDRB R6, [R5]
    CMP R4, R6
    BEQ gpio_off
	CMP R0, #0x99            
    BEQ check_b2
    CMP R0, #0x8C             
    BEQ check_b4
    CMP R0, #0x98             
    BEQ check_b5
    CMP R0, #0xBE             
    BEQ check_b6
    B check_ir_events        
	

bt_left
    MOV R4, #BUTTON_LEFT     
    B continue_logic         
bt_up
    MOV R4, #BUTTON_UP
    B continue_logic
bt_down
    MOV R4, #BUTTON_DOWN
    B continue_logic
bt_ok
    MOV R4, #BUTTON_OK
    B continue_logic
check_ir_events
    LDR R0, =ir_flag
    LDRB R1, [R0]
    CMP R1, #0            
    BEQ main_loop         
    
    MOV R1, #0
    STRB R1, [R0]
    
    LDR R0, =ir_command
    LDRB R4, [R0]         

    
    CMP     R4, #BUTTON_1
    BNE     after_robot_check
    
    BL      Enter_Robot_Mode
    
    MOV     R11, #STATE_MAIN_MENU
    LDR     R0, =screen_state
    STRB    R11, [R0]
    MOV     R0, #0
    LDR     R1, =current_selection
    STRB    R0, [R1]
    BL      DrawMainMenu
    B       main_loop
after_robot_check

	
    LDR R5, =active_btn
    LDRB R6, [R5]
    CMP R4, R6
    BEQ gpio_off



check_b2
    CMP R4, #BUTTON_2
    BNE check_b4
    MOV R3, #0x0C
    B gpio_apply
check_b4
    CMP R4, #BUTTON_4
    BNE check_b5
    MOV R3, #0x14
    B gpio_apply
check_b5
    CMP R4, #BUTTON_5
    BNE check_b6
    MOV R3, #0x12
    B gpio_apply
check_b6
    CMP R4, #BUTTON_6
    BNE continue_logic
    MOV R3, #0x0A
    B gpio_apply

gpio_off
    MOV R3, #0
    MOV R4, #0
gpio_apply
	LDR R5, =active_btn
    STRB R4, [R5]
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIOA_ODR]
    BIC R1, R1, #0x1E
    ORR R1, R1, R3
    STR R1, [R0, #GPIOA_ODR]
    B main_loop
	LTORG
   
continue_logic
    LDR R0, =screen_state
    LDRB R11, [R0]        
    
    LDR R0, =current_selection
    LDRB R10, [R0]        
    
    CMP R11, #STATE_MAIN_MENU
    BNE check_submenu
    
    MOV R5, R10  
check_submenu
    CMP R4, #BUTTON_LEFT
    BNE check_up
    MOV R11, #STATE_MAIN_MENU
    MOV R0, R10
    BL DrawMainMenu

check_up
    CMP R4, #BUTTON_UP
    BNE check_down
    CMP R10, #0
    BEQ wrap_up
    SUB R10, R10, #1
    B do_update
wrap_up
    MOV R10, #5               
    B do_update
check_down
    CMP R4, #BUTTON_DOWN
    BNE check_ok
    CMP R10, #5               
    BGE wrap_down
    ADD R10, R10, #1
    B do_update
wrap_down
    MOV R10, #0
    B do_update
do_update
    MOV R0, R5    
    MOV R1, R10   
    BL UpdateMenuHighlight
    B save_and_end
check_ok
    CMP R4, #BUTTON_OK
    BNE save_and_end
    CMP R10, #0
    BNE ok_1
    MOV R11, #STATE_SUISEI_MENU
    B save_and_end
ok_1
    CMP R10, #1
    BNE ok_2
    MOV R11, #STATE_WA_MENU
    B save_and_end
ok_2
    CMP R10, #2
    BNE ok_3
    MOV R11, #STATE_KYO_MENU
    B save_and_end
ok_3
    CMP R10, #3
    BNE ok_4
    MOV R11, #STATE_MO_MENU
    B save_and_end
ok_4
    CMP R10, #4
    BNE ok_5                 
    MOV R11, #STATE_KAWAII_MENU
    B save_and_end
ok_5
    CMP R10, #5             
    BNE save_and_end
    MOV R11, #STATE_HOSHIYOME_MENU
    B save_and_end

save_and_end
    LDR R0, =current_selection
    STRB R10, [R0]
    LDR R0, =screen_state
    STRB R11, [R0]
    B main_screen_render

main_screen_render

    CMP R11, #STATE_SUISEI_MENU
    BEQ draw_suisei_menu
    CMP R11, #STATE_WA_MENU
    BEQ draw_wa_menu
    CMP R11, #STATE_KYO_MENU
    BEQ.W draw_kyo_menu
    CMP R11, #STATE_MO_MENU
    BEQ.W draw_mo_menu
    CMP R11, #STATE_KAWAII_MENU
    BEQ.W draw_kawaii_menu
	CMP R11, #STATE_HOSHIYOME_MENU
    BEQ.W draw_hoshiyome_menu   
    B main_loop
	LTORG

draw_suisei_menu

    BL DS18B20_UpdateTemp
    
    LDR R0, =temp_data
    LDRSH R2, [R0]
    ASRS R2, R2, #4    

   
    LDR R0, =COLOR_BLACK
    BL TFT_Fill

   
    LDR R0, =temp_history
    LDRH R1, [R0, #8]   
    STRH R1, [R0, #10]   
    LDRH R1, [R0, #6]    
    STRH R1, [R0, #8]    
    LDRH R1, [R0, #4]    
    STRH R1, [R0, #6]    
    LDRH R1, [R0, #2]    
    STRH R1, [R0, #4]    
    LDRH R1, [R0, #0]    
    STRH R1, [R0, #2]    

   
    STRH R2, [R0, #0]

   
    LDR R1, =hist_count
    LDRB R3, [R1]
    CMP R3, #6
    BEQ draw_history_list
    ADD R3, R3, #1
    STRB R3, [R1]

draw_history_list
    MOV R4, #0           
history_loop
    LDR R1, =hist_count
    LDRB R3, [R1]
    CMP R4, R3          
    BGE end_suisei_draw

  
    MOV R5, #35
    MUL R5, R4, R5
    ADD R5, R5, #30    
    
    CMP R4, #0
    BNE draw_past_temp
    LDR R2, =str_temp_curr
    LDR R3, =COLOR_RED
    B print_label
draw_past_temp
    LDR R2, =str_temp_past
    LDR R3, =COLOR_CYAN

print_label
    MOV R0, #60         
    MOV R1, R5           
    BL TFT_DrawString

    
    LDR R0, =temp_history
    LSL R6, R4, #1       
    LDRSH R2, [R0, R6]   

 
    MOV R0, #180        
    MOV R1, R5           
    LDR R3, =COLOR_RED   
    BL TFT_DrawNumber

    ADD R4, R4, #1       
    B history_loop
end_suisei_draw
    B main_loop
	LTORG

draw_wa_menu
    
    LDR R0, =bpm_past4
    LDR R1, [R0]
    LDR R0, =bpm_past5
    STR R1, [R0]

    LDR R0, =bpm_past3
    LDR R1, [R0]
    LDR R0, =bpm_past4
    STR R1, [R0]

    LDR R0, =bpm_past2
    LDR R1, [R0]
    LDR R0, =bpm_past3
    STR R1, [R0]

    LDR R0, =bpm_past1
    LDR R1, [R0]
    LDR R0, =bpm_past2
    STR R1, [R0]

    LDR R0, =bpm_current
    LDR R1, [R0]
    LDR R0, =bpm_past1
    STR R1, [R0]

   
    LDR R0, =final_bpm
    LDR R2, [R0]
    LDR R0, =bpm_current
    STR R2, [R0]

    
    LDR R0, =bpm_hist_count
    LDRB R4, [R0]
    CMP R4, #6
    BEQ wa_draw
    ADD R4, R4, #1
    STRB R4, [R0]

wa_draw
   
    LDR R0, =COLOR_BLACK
    BL TFT_Fill

    CMP R4, #0
    BEQ.W end_wa_menu         

   
    MOV R0, #60
    MOV R1, #20
    LDR R2, =str_bpm_c
    LDR R3, =COLOR_RED
    BL TFT_DrawString
    LDR R0, =bpm_current
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #20
    LDR R3, =COLOR_RED
    BL TFT_DrawNumber
    MOV R0, #200
    MOV R1, #20
    LDR R2, =str_unit1      
    LDR R3, =COLOR_RED
    BL TFT_DrawString

    CMP R4, #2
    BLT end_wa_menu

  
    MOV R0, #60
    MOV R1, #55
    LDR R2, =str_bpm_p1
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    LDR R0, =bpm_past1
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #55
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #3
    BLT end_wa_menu


    MOV R0, #60
    MOV R1, #90
    LDR R2, =str_bpm_p2
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    LDR R0, =bpm_past2
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #90
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #4
    BLT end_wa_menu

 
    MOV R0, #60
    MOV R1, #125
    LDR R2, =str_bpm_p3
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    LDR R0, =bpm_past3
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #125
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #5
    BLT end_wa_menu

  
    MOV R0, #60
    MOV R1, #160
    LDR R2, =str_bpm_p4
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    LDR R0, =bpm_past4
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #160
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #6
    BLT end_wa_menu


    MOV R0, #60
    MOV R1, #195
    LDR R2, =str_bpm_p5
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    LDR R0, =bpm_past5
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #195
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

end_wa_menu
    B main_loop

draw_kyo_menu

    LDR  R0, =spo2_idx
    LDRB R1, [R0]          
    LDR  R2, =spo2_past1   
    LSL  R3, R1, #2        
    ADD  R3, R2, R3        
    LDR  R4, =spo2_current
    LDR  R5, [R4]          
    STR  R5, [R3]          
    ADD  R1, R1, #1
    CMP  R1, #5
    BLT  idx_ok
    MOV  R1, #0
idx_ok
    STRB R1, [R0]


    LDR  R0, =final_spo2
    LDR  R2, [R0]
    LDR  R0, =spo2_current
    STR  R2, [R0]

    LDR R0, =spo2_hist_count
    LDRB R4, [R0]          
    CMP R4, #6
    BEQ kyo_draw
    ADD R4, R4, #1
    STRB R4, [R0]

kyo_draw

    LDR  R0, =COLOR_BLACK
    BL   TFT_Fill

    CMP R4, #0
    BEQ.W end_kyo_menu       

    MOV  R0, #60
    MOV  R1, #20
    LDR  R2, =str_spo2_c
    LDR  R3, =COLOR_RED
    BL   TFT_DrawString
    LDR  R0, =spo2_current
    LDR  R2, [R0]
    MOV  R0, #180
    MOV  R1, #20
    LDR  R3, =COLOR_RED
    BL   TFT_DrawNumber
    MOV  R0, #200
    MOV  R1, #20
    LDR  R2, =str_unit2
    LDR  R3, =COLOR_RED
    BL   TFT_DrawString


    LDR  R6, =spo2_idx     
    LDRB R6, [R6]          
    LDR  R7, =spo2_past1   

    CMP R4, #2
    BLT.W end_kyo_menu

    ADD  R2, R6, #4
    CMP  R2, #5
    BLT  p1_ok
    SUB  R2, R2, #5
p1_ok
    LSL  R2, R2, #2
    LDR  R2, [R7, R2]
    MOV  R0, #60
    MOV  R1, #55
    LDR  R3, =COLOR_CYAN
    PUSH {R2}
    LDR  R2, =str_spo2_p1
    BL   TFT_DrawString
    POP  {R2}
    MOV  R0, #180
    MOV  R1, #55
    BL   TFT_DrawNumber

    CMP R4, #3
    BLT end_kyo_menu

    ADD  R2, R6, #3
    CMP  R2, #5
    BLT  p2_ok
    SUB  R2, R2, #5
p2_ok
    LSL  R2, R2, #2
    LDR  R2, [R7, R2]
    MOV  R0, #60
    MOV  R1, #90
    LDR  R3, =COLOR_CYAN
    PUSH {R2}
    LDR  R2, =str_spo2_p2
    BL   TFT_DrawString
    POP  {R2}
    MOV  R0, #180
    MOV  R1, #90
    BL   TFT_DrawNumber

    CMP R4, #4
    BLT end_kyo_menu

    ADD  R2, R6, #2
    CMP  R2, #5
    BLT  p3_ok
    SUB  R2, R2, #5
p3_ok
    LSL  R2, R2, #2
    LDR  R2, [R7, R2]
    MOV  R0, #60
    MOV  R1, #125
    LDR  R3, =COLOR_CYAN
    PUSH {R2}
    LDR  R2, =str_spo2_p3
    BL   TFT_DrawString
    POP  {R2}
    MOV  R0, #180
    MOV  R1, #125
    BL   TFT_DrawNumber

    CMP R4, #5
    BLT end_kyo_menu


    ADD  R2, R6, #1
    CMP  R2, #5
    BLT  p4_ok
    SUB  R2, R2, #5
p4_ok
    LSL  R2, R2, #2
    LDR  R2, [R7, R2]
    MOV  R0, #60
    MOV  R1, #160
    LDR  R3, =COLOR_CYAN
    PUSH {R2}
    LDR  R2, =str_spo2_p4
    BL   TFT_DrawString
    POP  {R2}
    MOV  R0, #180
    MOV  R1, #160
    BL   TFT_DrawNumber

    CMP R4, #6
    BLT end_kyo_menu

    ADD  R2, R6, #0
    CMP  R2, #5
    BLT  p5_ok
    SUB  R2, R2, #5
p5_ok
    LSL  R2, R2, #2
    LDR  R2, [R7, R2]
    MOV  R0, #60
    MOV  R1, #195
    LDR  R3, =COLOR_CYAN
    PUSH {R2}
    LDR  R2, =str_spo2_p5
    BL   TFT_DrawString
    POP  {R2}
    MOV  R0, #180
    MOV  R1, #195
    BL   TFT_DrawNumber

end_kyo_menu
    B main_loop
	LTORG


draw_mo_menu

    LDR R0, =COLOR_BLACK
    BL TFT_Fill


    LDR R0, =mtemp_history
    LDR R1, [R0, #16]
    STR R1, [R0, #20]
    LDR R1, [R0, #12]
    STR R1, [R0, #16]
    LDR R1, [R0, #8]
    STR R1, [R0, #12]
    LDR R1, [R0, #4]
    STR R1, [R0, #8]
    LDR R1, [R0, #0]
    STR R1, [R0, #4]


    LDR R1, =temp_int
    LDRB R2, [R1]          
    STR R2, [R0, #0]        

    LDR R1, =mtemp_hist_count
    LDRB R3, [R1]
    CMP R3, #6
    BEQ mtemp_draw_list
    ADD R3, R3, #1
    STRB R3, [R1]

mtemp_draw_list
    MOV R4, #0

mtemp_history_loop
    LDR R1, =mtemp_hist_count
    LDRB R3, [R1]
    CMP R4, R3
    BGE end_mo_draw

    MOV R5, #35
    MUL R5, R4, R5
    ADD R5, R5, #30

    CMP R4, #0
    BNE mtemp_draw_past_label
    LDR R2, =str_mt_curr
    LDR R3, =COLOR_RED
    B mtemp_print_label
mtemp_draw_past_label
    LDR R2, =str_mt_past
    LDR R3, =COLOR_CYAN

mtemp_print_label
    MOV R0, #60
    MOV R1, R5
    BL TFT_DrawString

    LDR R0, =mtemp_history
    LSL R6, R4, #2
    LDR R2, [R0, R6]

    MOV R0, #180
    MOV R1, R5
    LDR R3, =COLOR_RED
    BL TFT_DrawNumber

    ADD R4, R4, #1
    B mtemp_history_loop

end_mo_draw
    B main_loop



draw_kawaii_menu

    BL read_velostat    
    MOV R2, R0         

    LDR R0, =press_past4
    LDR R1, [R0]
    LDR R0, =press_past5
    STR R1, [R0]

    LDR R0, =press_past3
    LDR R1, [R0]
    LDR R0, =press_past4
    STR R1, [R0]

    LDR R0, =press_past2
    LDR R1, [R0]
    LDR R0, =press_past3
    STR R1, [R0]

    LDR R0, =press_past1
    LDR R1, [R0]
    LDR R0, =press_past2
    STR R1, [R0]

    LDR R0, =press_current
    LDR R1, [R0]
    LDR R0, =press_past1
    STR R1, [R0]

    LDR R0, =press_current
    STR R2, [R0]


    LDR R0, =press_hist_count
    LDRB R4, [R0]
    CMP R4, #6
    BEQ kawaii_draw
    ADD R4, R4, #1
    STRB R4, [R0]

kawaii_draw

    LDR R0, =COLOR_BLACK
    BL TFT_Fill
    
    CMP R4, #0
    BEQ.W end_kawaii_menu 

    MOV R0, #60          
    MOV R1, #20          
    LDR R2, =str_press_c 
    LDR R3, =COLOR_RED   
    BL TFT_DrawString
    
    LDR R0, =press_current
    LDR R2, [R0]
    MOV R0, #180         
    MOV R1, #20
    LDR R3, =COLOR_RED
    BL TFT_DrawNumber

    CMP R4, #1
    BLE end_kawaii_menu

   
    MOV R0, #60
    MOV R1, #55          
    LDR R2, =str_press_p
    LDR R3, =COLOR_CYAN  
    BL TFT_DrawString

    LDR R0, =press_past1
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #55
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #2
    BLE end_kawaii_menu


    MOV R0, #60
    MOV R1, #90
    LDR R2, =str_press_p
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString

    LDR R0, =press_past2
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #90
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #3
    BLE end_kawaii_menu

    MOV R0, #60
    MOV R1, #125
    LDR R2, =str_press_p
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString

    LDR R0, =press_past3
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #125
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #4
    BLE end_kawaii_menu


    MOV R0, #60
    MOV R1, #160
    LDR R2, =str_press_p
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString

    LDR R0, =press_past4
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #160
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

    CMP R4, #5
    BLE end_kawaii_menu


    MOV R0, #60
    MOV R1, #195
    LDR R2, =str_press_p
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString

    LDR R0, =press_past5
    LDR R2, [R0]
    MOV R0, #180
    MOV R1, #195
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber

end_kawaii_menu
    B main_loop
	LTORG	

draw_hoshiyome_menu

    LDR R0, =COLOR_BLACK
    BL TFT_Fill


    MOV R0, #20
    MOV R1, #40
    LDR R2, =str_target
    LDR R3, =COLOR_CYAN
    BL TFT_DrawString
    
    MOV R0, #20
    MOV R1, #80
    LDR R2, =str_actual
    LDR R3, =COLOR_GREEN
    BL TFT_DrawString
    
    MOV R0, #20
    MOV R1, #120
    LDR R2, =str_status
    LDR R3, =COLOR_YELLOW
    BL TFT_DrawString


    MOV R5, #0     
    MOV R6, #0      

wait_3_digits
    
    LDR R0, =ir_flag
    LDRB R1, [R0]
    CMP R1, #0
    BNE IR_recieved
	
wait_3_digits_BT
    BL BT_Get_Data
    CMP R0, #0
    BEQ wait_3_digits

BT_recieved

	BL Convert_IR_To_Digit_BT
    CMP R7, #0xFF
    BEQ wait_3_digits   
	BL continue_calc
	
IR_recieved

    MOV R1, #0
    STRB R1, [R0]
    

    LDR R0, =ir_command
    LDRB R4, [R0]
    

    BL Convert_IR_To_Digit
    CMP R7, #0xFF
    BEQ wait_3_digits   

continue_calc
    
    MOV R8, #10
    MUL R6, R6, R8
    ADD R6, R6, R7
    
    
    MOV R0, #100
    MOV R1, #40
    MOV R2, R6
    LDR R3, =COLOR_CYAN
    BL TFT_DrawNumber
    

    ADD R5, R5, #1
    CMP R5, #3
    BLT wait_3_digits

  
    LDR R0, =desired_drop_rate
    STR R6, [R0]

   
hoshiyome_monitor

    BL IR_Drop_Update
    

    LDR R0, =Last_Rate
    LDR R7, [R0]
    
    
    MOV R0, #100     
    MOV R1, #80      
    MOV R2, #40      
    MOV R3, #16      
    LDR R12, =COLOR_BLACK
    SUB SP, SP, #8
    STR R12, [SP, #0]
    BL TFT_DrawRect
    ADD SP, SP, #8

	MOV R4, #16         
    MOV R5, #80          
clear_actual_loop
    MOV R0, #100        
    MOV R1, R5           
    MOV R2, #40          
    LDR R3, =COLOR_BLACK 
    BL TFT_DrawHLine
    ADD R5, R5, #1      
    SUBS R4, R4, #1      
    BNE clear_actual_loop

    MOV R0, #100
    MOV R1, #80
    MOV R2, R7
    LDR R3, =COLOR_GREEN
    BL TFT_DrawNumber
    
   
    MOV R0, #100     
    MOV R1, #120      
    MOV R2, #60      
    MOV R3, #16      
    LDR R12, =COLOR_BLACK
    SUB SP, SP, #8
    STR R12, [SP, #0]
    BL TFT_DrawRect
    ADD SP, SP, #8
	
	
    MOV R4, #16          
    MOV R5, #120         
clear_status_loop
    MOV R0, #100        
    MOV R1, R5           
    MOV R2, #48          
    LDR R3, =COLOR_BLACK 
    BL TFT_DrawHLine
    ADD R5, R5, #1       
    SUBS R4, R4, #1     
    BNE clear_status_loop

   
    SUBS R2, R7, R6     
    BPL diff_positive   
    RSB R2, R2, #0      
diff_positive

    
    CMP R2, #12
    BLE status_ok

status_out_of_bounds
    
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #0x14]
    ORR R1, R1, #0x8000    
    STR R1, [R0, #0x14]

    
    MOV R0, #100
    MOV R1, #120
    CMP R7, R6
    BGT status_high
    
status_low
    LDR R2, =str_low
    LDR R3, =COLOR_RED
    B draw_status_msg

status_high
    LDR R2, =str_high
    LDR R3, =COLOR_RED
    B draw_status_msg

status_ok
    
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #0x14]
    BIC R1, R1, #0x8000     
    STR R1, [R0, #0x14]

    MOV R0, #100
    MOV R1, #120
    LDR R2, =str_ok
    LDR R3, =COLOR_GREEN

draw_status_msg
    BL TFT_DrawString

   
    LDR R0, =ir_flag
    LDRB R1, [R0]
    CMP R1, #0
    BEQ check_bt_press 
	
check_bt_press
	BL BT_Get_Data
    CMP R0, #0
	BEQ hoshiyome_monitor	
	
	
   
    MOV R1, #0
    STRB R1, [R0]
    
   
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #0x14]
    BIC R1, R1, #0x02
    STR R1, [R0, #0x14]
    
   
    MOV R11, #STATE_MAIN_MENU
    LDR R0, =screen_state
    STRB R11, [R0]
    MOV R0, #0
    LDR R1, =current_selection
    STRB R0, [R1]
    BL DrawMainMenu
    B main_loop
	
	

    ENDFUNC


	LTORG
; =========================================================================
; Font Matrix (8x8 Font)
; =========================================================================
    ALIGN 4
font8x8
    DCB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; Space
    DCB 0x18,0x3C,0x3C,0x18,0x18,0x00,0x18,0x00 ; !
    DCB 0x6C,0x6C,0x6C,0x00,0x00,0x00,0x00,0x00 ; "
    DCB 0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00 ; #
    DCB 0x18,0x7E,0xC0,0x7C,0x06,0xFC,0x18,0x00 ; $
    DCB 0x00,0xC6,0xCC,0x18,0x30,0x66,0xC6,0x00 ; %
    DCB 0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00 ; &
    DCB 0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00 ; '
    DCB 0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00 ; (
    DCB 0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00 ; )
    DCB 0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00 ; *
    DCB 0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00 ; +
    DCB 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30 ; ,
    DCB 0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00 ; -
    DCB 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00 ; .
    DCB 0x00,0x06,0x0C,0x18,0x30,0x60,0x00,0x00 ; /
    DCB 0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00 ; 0
    DCB 0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00 ; 1
    DCB 0x3C,0x66,0x06,0x0C,0x30,0x60,0x7E,0x00 ; 2
    DCB 0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00 ; 3
    DCB 0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00 ; 4
    DCB 0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00 ; 5
    DCB 0x3C,0x60,0x7C,0x66,0x66,0x66,0x3C,0x00 ; 6
    DCB 0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0x00 ; 7
    DCB 0x3C,0x66,0x3C,0x66,0x66,0x66,0x3C,0x00 ; 8
    DCB 0x3C,0x66,0x66,0x66,0x3E,0x06,0x3C,0x00 ; 9
    DCB 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x00 ; :
    DCB 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x30 ; ;
    DCB 0x00,0x0C,0x18,0x30,0x18,0x0C,0x00,0x00 ; <
    DCB 0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00 ; =
    DCB 0x00,0x30,0x18,0x0C,0x18,0x30,0x00,0x00 ; >
    DCB 0x3C,0x66,0x06,0x0C,0x18,0x00,0x18,0x00 ; ?
    DCB 0x3C,0x66,0x6E,0x6E,0x60,0x66,0x3C,0x00 ; @
    DCB 0x3C,0x66,0x66,0x7E,0x66,0x66,0x66,0x00 ; A
    DCB 0x7C,0x66,0x7C,0x66,0x66,0x66,0x7C,0x00 ; B
    DCB 0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00 ; C
    DCB 0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00 ; D
    DCB 0x7E,0x60,0x7C,0x60,0x60,0x60,0x7E,0x00 ; E
    DCB 0x7E,0x60,0x7C,0x60,0x60,0x60,0x60,0x00 ; F
    DCB 0x3C,0x66,0x60,0x6E,0x66,0x66,0x3E,0x00 ; G
    DCB 0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00 ; H
    DCB 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00 ; I
    DCB 0x06,0x06,0x06,0x06,0x06,0x66,0x3C,0x00 ; J
    DCB 0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00 ; K
    DCB 0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00 ; L
    DCB 0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00 ; M
    DCB 0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00 ; N
    DCB 0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00 ; O
    DCB 0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00 ; P
    DCB 0x3C,0x66,0x66,0x66,0x6A,0x6C,0x36,0x00 ; Q
    DCB 0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00 ; R
    DCB 0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00 ; S
    DCB 0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00 ; T
    DCB 0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00 ; U
    DCB 0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00 ; V
    DCB 0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00 ; W
    DCB 0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00 ; X
    DCB 0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00 ; Y
    DCB 0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00 ; Z
    DCB 0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00 ; [
    DCB 0x00,0x60,0x30,0x18,0x0C,0x06,0x00,0x00 ; 
    DCB 0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00 ; ]
    DCB 0x18,0x3C,0x66,0x00,0x00,0x00,0x00,0x00 ; ^
    DCB 0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0x00 ; 
    DCB 0x30,0x18,0x00,0x00,0x00,0x00,0x00,0x00 ; `
    DCB 0x00,0x00,0x3C,0x06,0x3E,0x66,0x3E,0x00 ; a
    DCB 0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00 ; b
    DCB 0x00,0x00,0x3C,0x60,0x60,0x60,0x3C,0x00 ; c
    DCB 0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00 ; d
    DCB 0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00 ; e
    DCB 0x1C,0x30,0x7C,0x30,0x30,0x30,0x30,0x00 ; f
    DCB 0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x3C ; g
    DCB 0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00 ; h
    DCB 0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00 ; i
    DCB 0x06,0x00,0x06,0x06,0x06,0x66,0x3C,0x00 ; j
    DCB 0x60,0x60,0x66,0x6C,0x78,0x6C,0x66,0x00 ; k
    DCB 0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00 ; l
    DCB 0x00,0x00,0x66,0x7F,0x7F,0x6B,0x63,0x00 ; m
    DCB 0x00,0x00,0x7C,0x66,0x66,0x66,0x66,0x00 ; n
    DCB 0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00 ; o
    DCB 0x00,0x00,0x7C,0x66,0x66,0x7C,0x60,0x60 ; p
    DCB 0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x06 ; q
    DCB 0x00,0x00,0x7C,0x66,0x60,0x60,0x60,0x00 ; r
    DCB 0x00,0x00,0x3E,0x60,0x3C,0x06,0x7C,0x00 ; s
    DCB 0x30,0x30,0x7C,0x30,0x30,0x30,0x1C,0x00 ; t
    DCB 0x00,0x00,0x66,0x66,0x66,0x66,0x3E,0x00 ; u
    DCB 0x00,0x00,0x66,0x66,0x66,0x3C,0x18,0x00 ; v
    DCB 0x00,0x00,0x63,0x6B,0x7F,0x3E,0x36,0x00 ; w
    DCB 0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00 ; x
    DCB 0x00,0x00,0x66,0x66,0x66,0x3E,0x06,0x3C ; y
    DCB 0x00,0x00,0x7E,0x0C,0x18,0x30,0x7E,0x00 ; z
    DCB 0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00 ; {
    DCB 0x18,0x18,0x18,0x00,0x18,0x18,0x18,0x00 ; |
    DCB 0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00 ; }
    DCB 0x3A,0x6E,0x00,0x00,0x00,0x00,0x00,0x00 ; ~

    END