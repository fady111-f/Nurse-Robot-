; Memory Mapped Registers for GPIOA and TIM3/TIM5
GPIOA_BASE_RM   EQU 0x40020000
GPIOA_ODR_RM    EQU GPIOA_BASE_RM + 0x14

TIM3_BASE_RM    EQU 0x40000400
TIM5_BASE_RM    EQU 0x40000C00

TIM_CR1_RM      EQU 0x00
TIM_CNT_RM      EQU 0x24
TIM_PSC_RM      EQU 0x28
TIM_ARR_RM      EQU 0x2C
TIM_CCR1_RM     EQU 0x34
TIM_CCR2_RM     EQU 0x38
TIM_CCR3_RM     EQU 0x3C
TIM_CCR4_RM     EQU 0x40

; Distance thresholds (in centimeters) for robot navigation and arm delivery
DIST_ARM_LOW1    EQU 85      ; Lower bound for reaching Patient 1 bed
DIST_ARM_HIGH1   EQU 100     ; Upper bound for reaching Patient 1 bed
DIST_ARM_LOW2    EQU 155     ; Lower bound for reaching Patient 2 bed
DIST_ARM_HIGH2   EQU 170     ; Upper bound for reaching Patient 2 bed
DIST_STOP        EQU 30      ; Safety limit to avoid collision

; Import external functions and variables
    IMPORT  HCSR04_Measure     ; Function to measure distance using Ultrasonic
    IMPORT  hc_delay_us        ; Function to delay in microseconds
    IMPORT  distance_cm        ; Variable holding the measured distance
    IMPORT  ir_flag            ; Flag indicating if an IR command is active
    IMPORT  ir_command         ; The specific IR command received

    AREA    ROBOT_CODE, CODE, READONLY
    ALIGN   4

    EXPORT  Enter_Robot_Mode    

; Main entry point for Robot Autonomous Navigation and Delivery Mode
Enter_Robot_Mode FUNCTION
    PUSH    {R4-R11, LR}

    ; Ensure motors are stopped before starting the autonomous loop
    BL      RM_StopMotors

robot_main_loop

    ; 1. Check if the user has cancelled robot mode via IR Remote
    LDR     R0, =ir_flag
    LDRB    R1, [R0]
    CMP     R1, #0
    BNE     robot_exit          ; If an IR button was pressed, exit robot mode

    ; 2. Start moving the robot forward
    BL      RM_Forward

    ; 3. Measure distance to obstacles ahead
    BL      HCSR04_Measure

    ; Load the calculated distance in cm into R4
    LDR     R0, =distance_cm
    LDR     R4, [R0]          

    ; 4. Check for critical collision (If distance is 0 or less than safety threshold)
    CMP     R4, #0
    BEQ     rm_too_close        ; 0 usually means sensor timeout/error, assume unsafe
    CMP     R4, #DIST_STOP
    BLE     rm_too_close        ; Stop if obstacle is closer than 30 cm

CHECK1
    ; 5. Check if robot has reached Patient 1 bed area (85 cm to 100 cm)
    CMP     R4, #DIST_ARM_LOW1
    BLT     rm_continue         ; If less than 85, keep moving (or handle collision above)
    CMP     R4, #DIST_ARM_HIGH1
    BGT     CHECK2   	        ; If greater than 100, check if it reached Patient 2
	B 		TRIGGER_ARM         ; If between 85 and 100, deliver medicine!

CHECK2	
    ; 6. Check if robot has reached Patient 2 bed area (155 cm to 170 cm)
    CMP     R4, #DIST_ARM_LOW2
    BLT     rm_continue         ; If less than 155, keep moving
    CMP     R4, #DIST_ARM_HIGH2
    BGT     rm_continue         ; If greater than 170, keep moving

TRIGGER_ARM
    ; 7. Delivery sequence: Stop robot and trigger the robotic arm
    BL      RM_Brake
    BL      RM_ArmSequence      ; Execute pre-programmed arm movements
    B       rm_ping_delay

rm_too_close
    ; Obstacle detected too close: Brake and exit robot mode
    BL      RM_Brake
    B       robot_exit

rm_continue
    ; Safe to continue moving forward
    B       rm_ping_delay

rm_ping_delay
    ; Wait 60,000 microseconds (60ms) before the next ultrasonic ping to prevent echoes overlapping
    LDR     R0, =60000         
    BL      hc_delay_us
    B       robot_main_loop

robot_exit
    ; Clear the IR flag so we don't immediately trigger another action outside
    LDR     R0, =ir_flag
    MOV     R1, #0
    STRB    R1, [R0]

    ; Ensure motors are stopped completely before leaving
    BL      RM_StopMotors

    POP     {R4-R11, PC}
    ENDFUNC

; Moves the robot forward by controlling GPIO pins connected to Motor Driver
RM_Forward
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E       ; Clear motor control bits (Pins A1, A2, A3, A4)
    ORR     R1, R1, #0x0C       ; Set specific pins HIGH to drive motors forward
    STR     R1, [R0]
    POP     {R0, R1, PC}

; Cuts power to motors allowing the robot to coast to a stop
RM_StopMotors
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E       ; Clear all motor control bits
    STR     R1, [R0]
    POP     {R0, R1, PC}

; Actively brakes the robot by setting all motor pins HIGH (shorting motor terminals)
RM_Brake
    PUSH    {R0, R1, LR}
    LDR     R0, =GPIOA_ODR_RM
    LDR     R1, [R0]
    BIC     R1, R1, #0x1E
    ORR     R1, R1, #0x1E       ; Set Pins A1, A2, A3, A4 HIGH to brake
    STR     R1, [R0]
    POP     {R0, R1, PC}

; Pre-programmed sequence to move the robotic arm and deliver the medicine cup
; The arm has 4 servo motors controlled via PWM on TIM3 (Channels 1-4)
; Value stored in CCRx determines the PWM pulse width (in microseconds) and thus the angle.
RM_ArmSequence FUNCTION
    PUSH    {R0-R2, LR}
    LDR     R0, =TIM3_BASE_RM

    ; Step 1: Move Servo 2 to 1000us (Prepare to lift)
    LDR     R1, =1000
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s

    ; Step 2: Move Servo 4 to 750us (Open gripper slightly)
    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s

    ; Step 3: Move Servo 3 to 1500us (Extend arm)
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s

    ; Step 4: Move Servo 1 to 600us (Rotate base towards patient)
    LDR     R1, =600
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s
	
    ; Step 5: Move Servo 4 to 500us (Close gripper/drop medicine)
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s
	
    ; Step 6: Move Servo 1 back to 1600us (Rotate base back)
    LDR     R1, =1600
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s

    ; Step 7: Move Servo 3 back to 500us (Retract arm)
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s
	
    ; Step 8: Move Servo 2 to 700us (Lower arm)
    LDR     R1, =700
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s

    ; Reset sequence: Ensure all servos are back to default positions
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s
	
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR3_RM]
    BL      RM_Delay_1s
	
    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s

    LDR     R1, =1400
    STR     R1, [R0, #TIM_CCR1_RM]
    BL      RM_Delay_1s
 
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR2_RM]
    BL      RM_Delay_1s
 
    LDR     R1, =750
    STR     R1, [R0, #TIM_CCR4_RM]
    BL      RM_Delay_1s
  
    ; Final default resting position for all servos
    LDR     R1, =1600
    STR     R1, [R0, #TIM_CCR1_RM]    
    LDR     R1, =1500
    STR     R1, [R0, #TIM_CCR2_RM]    
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR3_RM]    
    LDR     R1, =500
    STR     R1, [R0, #TIM_CCR4_RM]    
    BL      RM_Delay_1s

    POP     {R0-R2, PC}
    ENDFUNC

; A simple software delay loop to wait ~1 second between arm movements
RM_Delay_1s
    PUSH    {R2, LR}
    LDR     R2, =4000000      ; Magic number tuned to roughly 1 second on 16MHz clock
rm_delay_loop
    SUBS    R2, R2, #1
    BNE     rm_delay_loop
    POP     {R2, PC}

    END