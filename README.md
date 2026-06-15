<div align="center">
  <img src="Images/Robot.jpeg" alt="Smart Nurse Robot" width="400"/>
  
  # 🏥 Smart Nurse Robot
  **Advanced Bare-Metal ARM Assembly Project**
  
  ![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge)
  ![Platform](https://img.shields.io/badge/Platform-STM32F4xx-blue?style=for-the-badge)
  ![Language](https://img.shields.io/badge/Language-ARM_Assembly-orange?style=for-the-badge)
  ![IDE](https://img.shields.io/badge/IDE-Keil_uVision_5-red?style=for-the-badge)
  ![Architecture](https://img.shields.io/badge/Architecture-Bare_Metal-black?style=for-the-badge)
</div>

<br/>

> **A comprehensive, fully autonomous medical assistant robot designed to navigate hospital corridors, monitor patient vital signs, and deliver medical supplies. This project is built entirely from scratch using Bare-Metal ARM Assembly (No HAL, No external C libraries), demonstrating register-level control of the STM32 microcontroller.**

---

## 📌 STM32 Pinout & Peripheral Mapping

Below is the visual map of the STM32 microcontroller, showing exactly which pins (البِنّات) are mapped to which sensors and actuators in the system:

```mermaid
graph LR
    %% Central MCU
    MCU["⚡ STM32F4xx MCU ⚡"]:::mcuStyle

    %% Port A Pins Subgraph (Left)
    subgraph PortA ["PORT A Pins"]
        PA0["PA0 ➔ 🧠 Velostat Pressure (ADC1)"]:::paStyle
        PA6["PA6 ➔ 🦾 Servo 1 Base (TIM3 PWM)"]:::paStyle
        PA7["PA7 ➔ 🦾 Servo 2 Shoulder (TIM3 PWM)"]:::paStyle
        PA8["PA8 ➔ 🪪 RFID CS (SPI CS)"]:::paStyle
        PA9["PA9 ➔ 🖥️ TFT SCK & 🪪 RFID SCK"]:::paStyle
        PA10["PA10 ➔ 🖥️ TFT MOSI & 🪪 RFID MOSI"]:::paStyle
        PA11["PA11 ➔ 🌡️ DS18B20 Temp (1-Wire)"]:::paStyle
        PA12["PA12 ➔ 💧 IR LED Power (IV Emitter)"]:::paStyle
    end

    %% Port B Pins Subgraph (Right)
    subgraph PortB ["PORT B Pins"]
        PB0["PB0 ➔ 🦾 Servo 3 Elbow (TIM3 PWM)"]:::pbStyle
        PB1["PB1 ➔ 🦾 Servo 4 Gripper (TIM3 PWM)"]:::pbStyle
        PB2["PB2 ➔ 🦇 HC-SR04 Echo (Input)"]:::pbStyle
        PB3["PB3 ➔ 💧 IR Receiver (IV Sensor)"]:::pbStyle
        PB4["PB4 ➔ 🚨 Buzzer/LED (IV Indicator)"]:::pbStyle
        PB5["PB5 ➔ 🎮 VS1838B IR Remote (EXTI5)"]:::pbStyle
        PB6["PB6 ➔ 📱 HC-05 TX (USART1 TX)"]:::pbStyle
        PB7["PB7 ➔ 📱 HC-05 RX (USART1 RX)"]:::pbStyle
        PB8["PB8 ➔ 🩸 MAX30102 SCL (I2C1 SCL)"]:::pbStyle
        PB9["PB9 ➔ 🩸 MAX30102 SDA (I2C1 SDA)"]:::pbStyle
        PB10["PB10 ➔ 🦇 HC-SR04 Trigger (Output)"]:::pbStyle
        PB12["PB12 ➔ 🖥️ TFT CS (SPI CS)"]:::pbStyle
        PB13["PB13 ➔ 🖥️ TFT RST (GPIO Out)"]:::pbStyle
        PB14["PB14 ➔ 🪪 RFID MISO (SPI MISO)"]:::pbStyle
        PB15["PB15 ➔ 🖥️ TFT D/C (GPIO Out)"]:::pbStyle
    end

    %% Connections to MCU
    PA0 --> MCU
    PA6 --> MCU
    PA7 --> MCU
    PA8 --> MCU
    PA9 --> MCU
    PA10 --> MCU
    PA11 --> MCU
    PA12 --> MCU

    MCU --> PB0
    MCU --> PB1
    MCU --> PB2
    MCU --> PB3
    MCU --> PB4
    MCU --> PB5
    MCU --> PB6
    MCU --> PB7
    MCU --> PB8
    MCU --> PB9
    MCU --> PB10
    MCU --> PB12
    MCU --> PB13
    MCU --> PB14
    MCU --> PB15

    %% Styling Definitions
    classDef mcuStyle fill:#1e1e38,stroke:#ffd700,stroke-width:3px,color:#ffffff,font-weight:bold,font-size:15px;
    classDef paStyle fill:#fff3e0,stroke:#fb8c00,stroke-width:1.5px,color:#e65100;
    classDef pbStyle fill:#e0f2f1,stroke:#009688,stroke-width:1.5px,color:#004d40;

    style PortA fill:#fff8e1,stroke:#ffe082,stroke-width:2px;
    style PortB fill:#e0f7fa,stroke:#80deea,stroke-width:2px;
```

---

## 🔌 Hardware Port Map & Wiring Table

For a quick reference of connections, here is the full hardware mapping table:

| Peripheral Module | STM32 Pin | Interface / Protocol | Purpose |
| :--- | :--- | :--- | :--- |
| **ST7735 TFT Display** | **PA9** (SCK)<br/>**PA10** (MOSI)<br/>**PB12** (CS)<br/>**PB13** (RST)<br/>**PB15** (D/C) | SPI (Bit-Bang) | Renders the dashboard UI, charts, and patient data. |
| **MAX30102 Oximeter** | **PB8** (SCL)<br/>**PB9** (SDA) | I2C | Monitors patient Heart Rate (BPM) and Blood Oxygen (SpO2). |
| **DS18B20 Temp Sensor**| **PA11** (DQ) | 1-Wire | Measures room/ambient temperature. |
| **MFRC522 RFID Reader** | **PA8** (CS)<br/>**PA9** (SCK)<br/>**PA10** (MOSI)<br/>**PB14** (MISO) | SPI (Bit-Bang) | Scans patient ID card to load local medical profile. |
| **HC-SR04 Ultrasonic** | **PB10** (Trigger)<br/>**PB2** (Echo) | GPIO Trigger / Echo | Measures distance for autonomous navigation & braking. |
| **Velostat Sensor** | **PA0** | Analog (ADC1) | Measures patient bed pressure/nerve touch levels. |
| **Custom IV Drop Gate** | **PA12** (IR Power)<br/>**PB3** (Sensor)<br/>**PB4** (Indicator) | GPIO Input/Output | Calculates IV fluid drop rate (drops/min) with Buzzer/LED alert. |
| **VS1838B IR Receiver** | **PB5** | EXTI / TIM4 | Decodes infrared signals from the remote control. |
| **HC-05 Bluetooth** | **PB6** (TX)<br/>**PB7** (RX) | USART | Transmits wireless telemetry data to the nurse's station. |
| **SG90 Servos (Arm)** | **PA6** (CH1)<br/>**PA7** (CH2)<br/>**PB0** (CH3)<br/>**PB1** (CH4) | PWM (TIM3) | Controls 4-axis robotic arm for medicine supply delivery. |

---

## 🧠 Software Flow & State Machine

The firmware coordinates dashboard interactions, telemetry polling, and navigation transitions:

```mermaid
graph TD
    classDef init fill:#eceff1,stroke:#607d8b,stroke-width:2px,color:#263238;
    classDef menu fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#01579b;
    classDef sub fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px,color:#4a148c;
    classDef robot fill:#fffde7,stroke:#fbc02d,stroke-width:2px,color:#f57f17;
    classDef err fill:#ffebee,stroke:#e53935,stroke-width:2px,color:#b71c1c,font-weight:bold;
    
    START([⚡ Power On]) --> INIT["⚙️ Hardware Initialization<br/>(GPIO, Timers, I2C, SPI)"]:::init
    INIT --> MENU["🖥️ Main Dashboard<br/>(Stationary Monitor Mode)"]:::menu
    
    MENU --> |"Remote UP/DOWN"| NAV["🔄 Navigate Menu<br/>(Select Metric)"]:::menu
    NAV --> MENU
    
    MENU --> |"Press OK"| SUB["📂 Sub-Menu Screen<br/>(Show History Logs)"]:::sub
    SUB --> |"Press LEFT (Back)"| MENU
    
    MENU --> |"Press Remote [1]"| RM_FORWARD["🤖 Robot Mode<br/>Move Forward"]:::robot
    
    subgraph AutoNavLoop["Corridor Navigation Loop"]
        RM_FORWARD --> SCAN["🔍 Scan Distance<br/>(HC-SR04 Echo)"]:::robot
        SCAN --> |"Distance 85-100cm / 155-170cm"| DETECT["🏥 Room Detected<br/>Brake Motors"]:::robot
        DETECT --> ARM_SEQ["🦾 SG90 Arm Sequence<br/>(Deliver Supply)"]:::robot
        ARM_SEQ --> |Resume| RM_FORWARD
    end
    style AutoNavLoop fill:#fffde7,stroke:#ffd54f,stroke-width:1.5px,stroke-dasharray: 4 4;
    
    SCAN --> |"Obstacle < 30cm"| STOP["🚨 Emergency Brake<br/>Halts Robot"]:::err
    RM_FORWARD --> |"Any Key Interrupt"| EXIT_RM["⏹️ Stop / Exit Mode"]:::init
    
    STOP --> MENU
    EXIT_RM --> MENU
```

---

## ✨ Key Innovations & Features

* 💧 **Precision IV Drop Rate Monitor:** A custom-built optical tracking system using IR sensors to calculate real-time IV fluid drop rates (drops/min) with automated **HIGH/LOW/OK** status alerts.
* 🧠 **Neural Pressure & Stress Sensing:** Integrates a Velostat piezoresistive sensor via ADC to measure patient pressure and stress levels.
* 🤖 **Autonomous Hospital Navigation:** Features an autonomous mode that uses ultrasonic sensors for corridor navigation. The robot halts at specific room distances and triggers a synchronized robotic arm sequence to deliver items.
* 🩸 **Real-Time Vitals DSP:** Interfaces with the MAX30102 oximeter to parse raw Red/IR buffers into accurate Heart Rate (BPM) and Blood Oxygen (SpO2) values.
* 🪪 **Patient Identification System:** Uses an RFID reader to authenticate patients. Scanning a tag dynamically loads the patient's local medical profile (Name, Age, Condition) onto the dashboard.
* 🖥️ **Custom TFT Smart Dashboard:** An entirely custom SPI display driver featuring a multi-state UI menu system, dynamic history rendering, and real-time vital sign tracking.

---

## 📱 Wireless Telemetry & App Integration

The robot acts as an IoT node communicating with remote nursing stations.

<div align="center">
  <img src="Images/Bluetooth%20App.jpeg" alt="Bluetooth App Interface" width="250"/>
  <p><i>Live Mobile Telemetry App developed specifically for this project.</i></p>
</div>

* **Local Control:** IR Remote decoder using EXTI for dashboard navigation.
* **Wireless Telemetry:** Live telemetry transmitted via HC-05 over USART. By sending a hex command (`0x9A`), the mobile app requests a full buffer dump of all current patient vitals.

---

## 📁 Source Code Structure

The entire codebase is structured in modular Assembly files, separating hardware drivers from application logic:

| File Name | Purpose | Hardware Interface |
| :--- | :--- | :--- |
| 📜 [main.s](file:///c:/Users/PC/Desktop/Nurse-Robot/main.s) | Main state machine, system clock init, UI rendering, and dashboard loops. | TFT UI Dashboard, System state |
| 📜 [max.s](file:///c:/Users/PC/Desktop/Nurse-Robot/max.s) | MAX30102 configuration, raw I2C buffers reading, and HR/SpO2 calculations. | I2C1 (PB8/PB9) |
| 📜 [RFID.s](file:///c:/Users/PC/Desktop/Nurse-Robot/RFID.s) | SPI Bit-Banged Driver for MFRC522. Handles REQA, anti-collision, and profiles lookup. | Bit-Banged SPI (PA8/PA9/PA10, PB14) |
| 📜 [Robot_mode.s](file:///c:/Users/PC/Desktop/Nurse-Robot/Robot_mode.s) | Autonomous navigation control loop, corridor scanning, and servo sequence calls. | GPIOA ODR (Motors), TIM3 (Servos) |
| 📜 [arm.s](file:///c:/Users/PC/Desktop/Nurse-Robot/arm.s) | TIM3 4-channel 50Hz PWM initialization for the SG90 servos. | TIM3 PWM (PA6/PA7, PB0/PB1) |
| 📜 [bluetooth.s](file:///c:/Users/PC/Desktop/Nurse-Robot/bluetooth.s) | HC-05 USART1 driver. Transmits formatted telemetry sensor data upon receiving request. | USART1 (PB6/PB7) |
| 📜 [DROP rate.s](file:///c:/Users/PC/Desktop/Nurse-Robot/DROP%20rate.s) | IV fluid drop counting, falling edge filtering, and SysTick-based calculation. | GPIOA Pin 12, GPIOB Pin 3 & Pin 4 |
| 📜 [IR.s](file:///c:/Users/PC/Desktop/Nurse-Robot/IR.s) | VS1838B IR Receiver decoding using EXTI Line 5 and TIM4 counters. | EXTI9_5 on PB5, TIM4 |
| 📜 [temperature.s](file:///c:/Users/PC/Desktop/Nurse-Robot/temperature.s) | DS18B20 1-Wire bit-banged timing sequence and temperature scratchpad read. | GPIOA Pin 11 (Open-Drain) |
| 📜 [TFT.s](file:///c:/Users/PC/Desktop/Nurse-Robot/TFT.s) | ST7735 1.8" TFT Bit-Banged SPI driver. Handles window rendering and custom font maps. | Bit-Banged SPI (PA9/PA10, PB12/PB13/PB15) |
| 📜 [ultrasonic.s](file:///c:/Users/PC/Desktop/Nurse-Robot/ultrasonic.s) | HC-SR04 distance measurement. Generates trigger pulse and measures echo length. | GPIOB Pin 10 (Trigger), Pin 2 (Echo) |
| 📜 [velostat.s](file:///c:/Users/PC/Desktop/Nurse-Robot/velostat.s) | ADC1 configuration for channel 0 to sample Velostat analog voltages. | ADC1 on PA0 |

---

## 🕹️ Operating Guide & IR Keymap

### 1. Stationary Monitor Mode (Dashboard)
* Upon boot, the system initializes the TFT display with the **Smart Control Dashboard**.
* Use the **IR Remote** (`UP`, `DOWN`, `OK`, `LEFT`) to navigate between:
    * Room Temp / Body Temp Logs
    * Heart Rate & SpO2 Analytics
    * Velostat Pressure Gauge
    * IV Drop Rate Target Configuration

### 2. Autonomous Robot Mode
* Press button `[1]` on the IR remote to transition to Robot Mode.
* The robot will automatically drive forward, utilizing the ultrasonic sensor to scan the corridor.
* **Logic Triggers:**
    * `Distance > 170cm`: Move Forward.
    * `Distance 85-100cm` OR `155-170cm`: Room Detected. Engage Brakes ➔ Execute Robotic Arm Delivery Sequence ➔ Resume.
    * `Distance < 30cm`: Emergency Brake.

### 3. Patient ID Scanner
* Bring a known patient RFID card close to the MFRC522 reader.
* The screen will clear and pull the matching clinical profile:
  * **Card 1 (`0x031F39CA`):** Name: **SAFWAT** | Age: **19** | Displays real-time SpO2, HR, Pressure, Room Temp.
  * **Card 2 (`0x023338E6`):** Name: **OMAR** | Age: **21** | Displays profile details.

### 4. IR Remote Controller NEC Keymap

| IR Remote Button | NEC Command (Hex) | Action on System |
| :--- | :--- | :--- |
| **UP** | `0x18` | Move selection UP in dashboard |
| **DOWN** | `0x52` | Move selection DOWN in dashboard |
| **LEFT** | `0x08` | Go back to Main Menu |
| **RIGHT** | `0x5A` | Navigate right |
| **OK** | `0x1C` | Confirm Selection / Enter Sub-Menu |
| **1** | `0x45` | Enter Autonomous Robot Mode |
| **0** | `0x19` | Reset / Stop Mode |

---

## 🚀 Getting Started

<details>
<summary><b>Click to expand Installation & Build Instructions</b></summary>

### Prerequisites
* **IDE:** Keil uVision 5 (configured for ARM Assembly).
* **Hardware:** STM32F4xx series Discovery/Nucleo board, ST-Link V2 Programmer.
* **Components:** See the Hardware BOM pin mapping.

### Build & Flash
1. Clone this repository to your local machine.
2. Open the project file (`.uvprojx`) in Keil uVision.
3. Verify the Target Options (ensure the correct STM32 MCU is selected).
4. Build the target (`F7`). Ensure there are **0 Errors**.
5. Connect the ST-Link and click **Download** (`F8`) to flash the firmware to the MCU.
</details>

---

## 📌 Workload Distribution

> *This project was accomplished through the hard work of the entire team. We all contributed to every part of the project — brainstorming, developing, and staying up late together. The following distribution represents the primary contributions of each team member.*

<details>
<summary><b>View Team Contributions</b></summary>

### 🛠️ Mechanical Design & Structure
- **Fady Fawzy, Ayman Alaa** — Design and implementation of the physical robot structure

### 💻 Software & System Integration
- **Omar Youssef & Fady Ashraf** — Main loop, code integration, and Sensor History
- **Fady Fawzy, Omar Youssef & Fady Ashraf** — Screen and menu system

### 🌡️ Sensors & Hardware Modules
- **Fady Ashraf** — Temperature sensor (DS18B20)
- **Kirellous Kamel, Kirellous Sameh, Ayman Alaa, Jody Ali, Mohammed Ahmed** — MAX30102 Oximeter module  
- **Kirellous Kamel & Jody Ali** — Velostat Pressure Sensor  
- **Omar Youssef** — IR Remote & Receiver System
- **Kirellous Kamel & Ayman Alaa** — Bluetooth (HC-05) module  
- **Yousuf Safwat, Eissa Ali & Kirellous Sameh** — RFID (MFRC522) System

### 🤖 Control & Logic
- **Yousuf Safwat & Mohammad Ahmed** — Core ARM logic & Peripheral Control
- **Kirellous Kamel & Fady Ashraf** — Item distribution / Robotic Arm logic
- **Eissa Hozayen & Yousuf Safwat** — Base Motion / Robot Movement system
- **Kirellous Kamel, Fady Ashraf, Omar Youssef & Fady Fawzy** — Custom Drop Rate sensing system

### 📱 Application Development
- **Fady Fawzy & Jody Ali** — Mobile application (Telemetry Interface)

</details>

---

<div align="center">
  <h2>👨‍💻 Developed by: MED-E</h2>
  <p><i>Computer Engineering | Cairo University<br/>Microprocessors & Embedded Systems Project</i></p>
</div>

### 📧 Team Contacts

| Name | Email Address |
| :--- | :--- |
| **Fady Fawzy** | fady.fawzy2006@gmail.com |
| **Fady Ashraf** | fadyashraf255200@gmail.com |
| **Eissa Hozayen** | eissahozayen123@gmail.com |
| **Jody Ali** | Jody.Ali06@eng-st.cu.edu.eg |
| **Kirellous Kamel** | kokokamel130@gmail.com |
| **Kirellous Sameh** | sameh.wagih331@gmail.com |
| **Yousuf Safwat** | yousuf.gabr06@eng-st.cu.edu.eg |
| **Ayman Alaa** | ayman.taher05@eng-st.cu.edu.eg |
| **Omar Youssef** | omaryoussefsaid12@gmail.com |
| **Mohamed Ahmed** | mohamed.ahmed0411@eng-st.cu.edu.eg |
