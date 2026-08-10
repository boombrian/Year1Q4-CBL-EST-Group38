# Physical Pneumatic Experiment & Sensor Data Acquisition

This directory (`validation/`) contains the complete physical validation codebase for the **Compressed Air Energy Storage** project. It includes the microcontroller C++ firmware, MATLAB serial logging scripts, real-time GUI interfaces, post-processing alignment tools, and raw experimental test datasets.

The experimental setup models transient pneumatic charging dynamics using a sensor suite connected to an Arduino microcontroller, providing empirical validation for the Simulink pneumatic storage equations.

---

## 1. Directory Structure & File Inventory

```
validation/
├── NEWEST_ARDUINO              # Arduino firmware: Analog reading, calibration, and safety trip logic
├── NEWEST_MATLAB.m             # MATLAB live serial logger & real-time animated plotting GUI
├── new_processing.m            # Post-processing script: Peak-trigger alignment & theoretical overlay
├── post_processing.m           # Post-processing script: Multi-run mean/SD & dP/dt derived airflow
├── data_collection.m           # Legacy serial logging script
├── data_collection_corrected.m # Legacy serial logging script with updated string parsing
├── plot_saved_data.m           # Quick visualization utility for raw text logs
├── postprecessing.mlx          # MATLAB Live Script for interactive validation visualization
├── data_1.txt to data_4.txt    # Processed, aligned experimental test run profiles
├── tial_1.txt to tial_9.txt    # Raw logged trial datasets from physical experiment runs
└── pneumatic_data.txt          # Baseline experimental dataset
```

---

## 2. Hardware Wiring & Sensor Interfaces

The physical experimental rig utilizes two primary analog sensors interfaced with an Arduino (Uno/Mega/Nano):

| Sensor Type | Part Number | Arduino Pin | Measurement Range | Output Signal Range |
|---|---|---|---|---|
| **Pressure Sensor ($P_2$)** | SMC PSE570-02 | Analog Input `A0` | $0.0 \text{ to } 1.0 \text{ MPa}$ ($0 \text{ to } 10 \text{ bar}$) | $1.0 \text{ to } 5.0 \text{ V}$ |
| **Airflow Sensor ($Q$)** | SMC PF2A521-F03-1 | Analog Input `A1` | $0 \text{ to } 100 \text{ L/min}$ | $1.0 \text{ to } 5.0 \text{ V}$ |

### Circuit Pinout Table

```
Arduino Pin A0  <--->  SMC PSE570-02 Signal Wire (Pressure P2)
Arduino Pin A1  <--->  SMC PF2A521-F03-1 Signal Wire (Airflow Q)
Arduino 5V      <--->  Sensor VCC Power Supply
Arduino GND     <--->  Sensor Ground (Common GND)
```

---

## 3. Theoretical Background & Calibration Equations

### 3.1 Analog-to-Digital (ADC) Conversion

The Arduino microcontroller samples analog inputs using a 10-bit Analog-to-Digital Converter (ADC) with a $5.0\text{ V}$ reference voltage ($V_{\text{REF}}$):

$$V_{\text{analog}} = \text{ADC}_{\text{raw}} \times \left(\frac{5.0}{1023}\right) \quad [\text{V}]$$

---

### 3.2 Sensor Calibration Equations

- **Pressure Sensor Calibration (SMC PSE570-02):**
  Maps $1.0\text{ V} \to 0.0\text{ bar}$ and $5.0\text{ V} \to 10.0\text{ bar}$:
  $$P_2\,[\text{bar}] = \max\left(0, \frac{V_{\text{P2}} - 1.0}{4.0} \times 10.0\right)$$

- **Airflow Sensor Calibration (SMC PF2A521-F03-1):**
  Linear transfer function mapping voltage to volumetric flow rate:
  $$Q\,[\text{L/min}] = \max\left(0, 45.0 \times V_Q - 25.0\right)$$

---

### 3.3 Pneumatic Transient Dynamics Equations

During transient charging of a pneumatic accumulator vessel of volume $V$, the pressure buildup follows a first-order exponential response:

$$P(t) = P_{\text{max}} \left(1 - e^{-t/\tau}\right)$$

where $P_{\text{max}}$ is the regulated supply pressure and $\tau$ is the system pneumatic time constant.

The volumetric airflow rate $Q(t)$ decays exponentially as pressure equalizes:

$$Q(t) = Q_{\text{max}} e^{-t/\tau}$$

---

### 3.4 Derived Airflow from Pressure Rate of Change ($\frac{dP}{dt}$)

From the Ideal Gas Law ($P V = m R_{\text{air}} T$), the mass flow rate into a fixed volume vessel $V$ is directly proportional to the time rate of change of pressure:

$$\dot{m} = \frac{V}{R_{\text{air}} T} \frac{dP}{dt}$$

In `post_processing.m`, experimental airflow $Q_{\text{derived}}(t)$ is computed numerically from pressure time-derivatives:

$$Q_{\text{derived}}(t) = \left(\frac{\Delta P}{\Delta t}\right) \times \left(\frac{Q_{\text{max}}}{P_{\text{max}} / \tau}\right) \quad [\text{L/min}]$$

---

### 3.5 Software Safety Trip Logic

To prevent sensor damage or over-pressurization during physical charging, the Arduino firmware (`NEWEST_ARDUINO`) enforces a continuous software safety monitor:

- **Maximum Safe Pressure:** $P_{\text{safe}} = 5.0\text{ bar}$ ($0.5\text{ MPa}$)
- **Spike Tolerance Window:** $t_{\text{safe}} = 2000\text{ ms}$

If $P_2 > P_{\text{safe}}$ continuously for more than $2000\text{ ms}$, the microcontroller sets `safetyTripped = true`, transmits a `"CRITICAL_OVERPRESSURE"` alert string over serial, and the MATLAB GUI (`NEWEST_MATLAB.m`) flashes the live chart background light red.

---

## 4. Experimental Execution Guidance

### 4.1 Step 1: Microcontroller Setup

1. Connect the Arduino board to your computer via USB.
2. Open `validation/NEWEST_ARDUINO` (or `NEWEST_ARDUINO.ino`) in the Arduino IDE.
3. Select your Board (e.g., *Arduino Uno*) and Serial Port under `Tools -> Port`.
4. Click **Upload** (Ctrl+U).
5. **Crucial:** Close the Arduino Serial Monitor window after uploading (MATLAB requires exclusive access to the COM port).

### 4.2 Step 2: Real-time MATLAB Data Acquisition

1. Open MATLAB.
2. Open `validation/NEWEST_MATLAB.m`.
3. Modify line 5 to match your Arduino's serial port:
   ```matlab
   portName = "COM6";  % Replace with your actual COM port
   ```
4. Run `NEWEST_MATLAB.m`.
5. A live graphical window will open showing animated plots for **Pressure $P_2$** and **Flow Rate $Q$**. Data is logged simultaneously to `tial_9.txt` in CSV format.
6. To end logging, simply close the plot window or press Ctrl+C in MATLAB.

### 4.3 Step 3: Experimental Data Analysis & Theoretical Overlay

1. Open `validation/new_processing.m`.
2. Run the script. It will read `data_1.txt` through `data_4.txt`, automatically detect valve actuation trigger points based on voltage rise above baseline ($V_{\text{baseline}} + 0.05\text{ V}$), crop a 15-second evaluation window starting at $t_{\text{sync}} = 0$, and overlay theoretical charging curves against experimental data.
3. Run `validation/post_processing.m` to generate statistical figures displaying mean experimental pressure/flow with standard deviation error bars ($\mu \pm \sigma$).

---

## 5. Output Data Format (`data_x.txt` & `tial_x.txt`)

Logged files contain text headers followed by 6 formatted columns:

```
Time(s)    V_P2(V)    V_Q(V)     P2(MPa)      Q(L/min)       Safety      
------------------------------------------------------------------------------------
0.000      1.002      0.556      0.0005       0.00           NORMAL      
0.102      1.045      1.210      0.0113       29.45          NORMAL      
...
```
