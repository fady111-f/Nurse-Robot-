
RCC_AHB1ENR  EQU 0x40023830  
RCC_APB2ENR  EQU 0x40023844  
GPIOA_MODER  EQU 0x40020000  
ADC1_SR      EQU 0x40012000  
ADC1_CR1     EQU 0x40012004  
ADC1_CR2     EQU 0x40012008  
ADC1_SQR3    EQU 0x40012034  
ADC1_DR      EQU 0x4001204C  

            AREA    |.text|, CODE, READONLY
            
            
            EXPORT  init_velostat
            EXPORT  read_velostat


init_velostat
            PUSH {R0-R2, LR}         

         
            LDR R0, =RCC_AHB1ENR
            LDR R1, [R0]
            ORR R1, R1, #0x01        
            STR R1, [R0]


            LDR R0, =RCC_APB2ENR
            LDR R1, [R0]
            ORR R1, R1, #0x0100
            STR R1, [R0]

 
            LDR R0, =GPIOA_MODER
            LDR R1, [R0]
            ORR R1, R1, #0x03       
            STR R1, [R0]

        
            LDR R0, =ADC1_SQR3
            LDR R1, [R0]
            BIC R1, R1, #0x1F       
     
            STR R1, [R0]

    
            LDR R0, =ADC1_CR2
            LDR R1, [R0]
            ORR R1, R1, #0x01
            STR R1, [R0]

          
            LDR R2, =10000
Delay_Init
            SUBS R2, R2, #1
            BNE Delay_Init

            POP {R0-R2, PC}         


read_velostat
            PUSH {R1, LR}           
            

            LDR R0, =ADC1_CR2
            LDR R1, [R0]
            ORR R1, R1, #0x40000000  
            STR R1, [R0]

Wait_EOC

            LDR R0, =ADC1_SR
            LDR R1, [R0]
            ANDS R1, R1, #0x02       
            BEQ Wait_EOC             


            LDR R0, =ADC1_DR
            LDR R0, [R0]             

            POP {R1, PC}             
            
            ALIGN
            END