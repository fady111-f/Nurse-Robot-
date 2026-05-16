# 🏥 Smart Nurse Robot (Bare-Metal ARM Assembly)

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![Platform](https://img.shields.io/badge/Platform-STM32F4xx-blue)
![Language](https://img.shields.io/badge/Language-ARM_Assembly-orange)
![Architecture](https://img.shields.io/badge/Architecture-Bare_Metal-red)

A comprehensive, fully autonomous medical assistant robot designed to navigate hospital corridors, monitor patient vital signs, and deliver medical supplies. This project is built **entirely from scratch using Bare-Metal ARM Assembly** (No HAL, No external C libraries), demonstrating advanced register-level manipulation of the STM32 microcontroller.

## ✨ Key Innovations & Features

* **💧 Precision IV Drop Rate Monitor (In-House Design):** A custom-built optical tracking system using IR sensors and SysTick interrupts to calculate real-time IV fluid drop rates (drops/min) with automated HIGH/LOW/OK threshold alerts.
* **🧠 Neural Pressure & Stress Sensing:** Integrates a Velostat piezoresistive sensor via ADC to measure patient nerve pressure and stress levels, adding a psychological monitoring dimension to standard biometrics.
* **🤖 Autonomous Hospital Navigation:** Features a "Robot Mode" that uses HC-SR04 ultrasonic sensors for corridor navigation. The robot autonomously halts at specific room distances and triggers a synchronized robotic arm sequence (via multi-channel PWM) to deliver items.
* **🩸 Real-Time Vitals DSP:** Interfaces with the MAX30102 via custom I2C drivers. Includes an assembly-level Digital Signal Processing (DSP) algorithm to parse raw Red/IR FIFO buffers into accurate Heart Rate (BPM) and Blood Oxygen (SpO2) values.
* **🪪 Patient Identification System:** Uses an RC522 RFID reader over SPI to authenticate patients. Scanning a tag dynamically loads the patient's local medical profile (Name, Age, Condition) onto the dashboard.
* **📱 Dual Telemetry & Control:** * **Local Control:** IR Remote decoder using EXTI for dashboard navigation.
    * **Wireless Telemetry:** HC-05 Bluetooth module over USART transmits live patient vitals and drop rates to remote nursing stations.
* **🖥️ Custom TFT Smart Dashboard:** An entirely custom SPI display driver featuring a multi-state UI menu system, dynamic history rendering, and real-time vital sign tracking.

## 🧰 Hardware Architecture

The system orchestrates a wide array of peripherals through direct memory-mapped register configuration:

| Peripheral / Sensor | Protocol / Interface | STM32 Hardware Block Used | Purpose |
| :--- | :--- | :--- | :--- |
| **TFT Display** | SPI (Custom Bit-bang / HW) | GPIO, Timers | UI Dashboard & Menu System |
| **MAX30102** | I2C | I2C1 | Heart Rate & SpO2 Monitoring |
| **DS18B20** | 1-Wire | GPIO (Delay-based) | Ambient / Room Temperature |
| **RC522 RFID** | SPI | SPI / GPIO | Patient Identification |
| **HC-SR04** | Trigger/Echo | TIM3 (Input Capture/Delay) | Obstacle Avoidance & Navigation |
| **Velostat** | Analog | ADC1 | Nerve/Touch Pressure Sensing |
| **IR Drop Sensor** | Digital Interrupt | SysTick, GPIO | IV Fluid Drop Rate Tracking |
| **IR Receiver** | EXTI | EXTI, TIM4 | Remote Control Decoding |
| **HC-05 Bluetooth**| UART | USART1 | Wireless Data Transmission |
| **Robotic Arm** | PWM | TIM2, TIM3, TIM5 | Servo Control for Delivery Sequence |

## 🧬 Software Architecture (Bare-Metal Assembly)

This project strictly avoids abstraction layers (like STM32 HAL or CMSIS C-headers). All control logic is implemented in ARM Thumb-2 Assembly:

1.  **State Machine:** The UI operates on a non-blocking state machine (`STATE_MAIN_MENU`, `STATE_SUISEI_MENU`, `STATE_WA_MENU`, etc.) managing screen renders and history buffers.
2.  **Interrupt Service Routines (ISRs):** Uses EXTI for the IR remote to ensure inputs are captured instantly without blocking the DSP calculations.
3.  **Timing & Delays:** Employs nested hardware timers (TIM4, TIM5) and SysTick for microsecond-accurate delays required by the 1-Wire protocol and HC-SR04 echoes.
4.  **I2C & SPI Drivers:** Custom-written synchronous transaction sequences managing TXE/RXNE flags directly in the `I2C_SR1` and SPI registers.

## 🚀 Getting Started

### Prerequisites
* **IDE:** Keil uVision 5 (or any ARM cross-compiler configured for pure assembly).
* **Hardware:** STM32F4xx series Discovery/Nucleo board, ST-Link V2 Programmer.
* **Components:** List of sensors mentioned in the hardware architecture table.

### Build & Flash
1.  Clone this repository to your local machine.
2.  Open the project file (`.uvprojx`) in Keil uVision.
3.  Verify the Target Options (ensure the correct STM32 MCU is selected).
4.  Build the target (`F7`). Ensure there are 0 Errors.
5.  Connect the ST-Link and click **Download** (`F8`) to flash the firmware to the MCU.

## 🕹️ Operating Guide

### 1. Stationary Monitor Mode (Dashboard)
* Upon boot, the system initializes the TFT display with the **Smart Control Dashboard**.
* Use the **IR Remote** (`UP`, `DOWN`, `OK`, `LEFT`) to navigate between:
    * Room Temp / Body Temp Logs
    * Heart Rate & SpO2 Analytics
    * Velostat Pressure Gauge
    * IV Drop Rate Target Configuration
* **Bluetooth:** Pair a smartphone/PC to the HC-05. Send command `0x9A` to request a full telemetry dump.

### 2. Autonomous Robot Mode
* Press button `[1]` on the IR remote to transition to Robot Mode.
* The robot will automatically drive forward, utilizing the ultrasonic sensor to scan the corridor.
* **Logic Triggers:**
    * `Distance > 170cm`: Move Forward.
    * `Distance 85-100cm` OR `155-170cm`: Room Detected. Engage Brakes -> Execute Robotic Arm Delivery Sequence -> Resume.
    * `Distance < 30cm`: Emergency Brake.


## 📌 Workload Distribution

> This project was accomplished through the hard work of the entire team.  
> We all contributed to every part of the project — brainstorming, developing, and staying up late together.  
> The following distribution represents the primary contributions of each team member.

### 🛠️ Mechanical Design & Structure
- **Fady Fawzy , Ayman Alaa** — Design and implementation of the physical robot structure

### 💻 Software & System Integration
- **Omar Youssef & Fady Ashraf** — Main loop , code integration and Sensor History
- **Fady Fawzy, Omar Youssef & Fady Ashraf** — Screen and menu system
  

### 🌡️ Sensors & Hardware Modules
- **Fady Ashraf** — Temperature sensor  
- **Kirellous Kamel , Kirellous Sameh , Ayman Alaa , Jody Ali , Mohammed Ahmed** — MAX module  
- **Kirellous Kamel & Jody Ali** — Velostat  
- **Omar Youssef** — IR remote  
- **Kirellous Kamel & Ayman Alaa** — Bluetooth module  
- **Yousuf Safwat, Eissa Ali & Kirellous Sameh** — RFID system

### 🤖 Control & Logic
- **Yousuf Safwat & Mohammad Ahmed** — ARM control  
- **Kirellous Kamel & Fady Ashraf** — Item distribution logic  
- **Eissa Hozayen & Yousuf Safwat** — Motion system  
- **Kirellous Kamel, Fady Ashraf, Omar Youssef & Fady Fawzy** — Drop rate system

### 📱 Application Development
- **Fady Fawzy & Jody Ali** — Mobile application



  
---
## 👨‍💻 Developed by: MED-E  
*Computer Engineering | Cairo University*  
*Microprocessors & Embedded Systems Project*

### 📧 Team Contacts
- fady.fawzy2006@gmail.com
- fadyashraf255200@gmail.com  
- eissahozayen123@gmail.com  
- Jody.Ali06@eng-st.cu.edu.eg  
- kokokamel130@gmail.com  
- sameh.wagih331@gmail.com  
- yousuf.griezmann@gmail.com  
- aymanalaa3g@gmail.com  
- omaryoussefsaid12@gmail.com  
- mohamed.ahmed0411@eng-st.cu.edu.eg
