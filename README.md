# CBL Energy Storage (Y1Q4, Group 38)

This repository contains the modeling, simulation, and experimental data acquisition codebase for the **CBL Energy Storage System** project at Eindhoven University of Technology (TU Eindhoven), Year 1, Quarter 4, developed by **Group 38**.

The project focuses on the thermodynamic analysis, simulation, and experimental validation of a **Near-Isothermal Compressed Air Energy Storage (I-CAES)** system. It couples a physical pneumatic transient experiment (utilizing an Arduino-based sensor suite and MATLAB logging) with a high-fidelity, first-principles Simulink model to evaluate large-scale grid balancing and thermal energy integration.

---

## 1. Repository Structure

The repository is structured into distinct folders separating physical experiment code, main simulation blocks, and advanced data analysis:

```
Year1Q4-CBL-EST-Group38/
├── EST-model-main/             # Main I-CAES Simulink model and MATLAB components
│   ├── ICAES_R2025a.slx        # Main Simulink Model (R2025a format)
│   ├── ICAES_R2025b.slx        # Compatibility model (R2025b format)
│   ├── preprocessing.m         # Initialization callback (loads parameters & data)
│   ├── postprocessing.m        # Simulation post-processing (generates performance plots)
│   └── data/                   # Annual wind/solar supply and grid demand CSV profiles
│
├── data analysis/              # Data post-processing and optimization scripts
│   ├── data_analysis.mlx      # Live Script for system evaluation
│   ├── modeling_analysis.mlx  # Live Script for model parameters
│   └── plots.ipynb             # Jupyter Notebook for advanced plotting & parameter sweeps
│
├── MatLab-simulink/            # Archive of legacy/alternative Simulink models
│   ├── EST.slx
│   └── est_system.slx
│
├── pneumatic_data_collection.ino # Arduino source code for sensor data acquisition
├── data_collection.m           # MATLAB script for real-time serial logging from Arduino
├── post_processing.m           # MATLAB script for experimental statistical averaging and theory comparison
└── pneumatic_data.txt          # Logged raw experimental data from the pneumatic test rig
```

---

## 2. Experimental Data Acquisition & Post-Processing

A core component of the project is a pneumatic charging experiment used to validate transient gas dynamics.

### 2.1 Sensor Interface (`pneumatic_data_collection.ino`)
The Arduino reads voltages from two analog pressure sensors and an airflow sensor:
- **Pressure Sensors (e.g., SMC PSE570-02)**: Configured with a voltage range of 1V–5V mapping linearly to 0–1 MPa.
- **Airflow Sensor (e.g., SMC PF2A521-F03-1)**: Configured with a voltage range of 1V–5V mapping to 0–100 L/min.
- **Safety Protocol**: Implements a software safety trip if pressure exceeds the maximum safe limit ($0.5\text{ MPa}$ / 5 bar) for longer than 2 seconds.

### 2.2 Real-time Logging (`data_collection.m`)
An automated MATLAB script connects to the Arduino serial port (configured by default on `COM7` at 9600 baud), samples the data streaming from the microcontroller, and logs timestamps, voltages, and calculated pressure values into `pneumatic_data.txt`.

### 2.3 Experimental Analysis (`post_processing.m`)
The MATLAB analysis script loads multiple experimental runs, performs uniform temporal interpolation, calculates the statistical mean and standard deviation, and overlays the experimental curves with theoretical thermodynamic models:
- **Charging Pressure**: $P(t) = P_{max} \left(1 - e^{-t/\tau}\right)$
- **Theoretical Flow Decay**: $Q(t) = Q_{max} e^{-t/\tau}$
- **Derived Flow**: Estimates physical airflow dynamically from the experimental pressure derivative ($\frac{dP}{dt}$) using ideal gas dynamics.

---

## 3. Isothermal CAES Simulation Model

The main simulation is located in the `EST-model-main/` folder. It models:
- **Salt Cavern Dynamics**: Integrating mass flows to determine pressure exergy.
- **Thermal Energy Storage (TES)**: Modeling a variable-mass hot water reservoir that captures compressor intercooling heat to reheat air during expansion.
- **Dual-Mode Expansion**: Operating near-isothermally ($n_{poly} = 1.1$) when hot water is available, and falling back to adiabatic expansion ($n = 1.4$) upon TES depletion.

*For full physical and mathematical derivations of the I-CAES equations, see the detailed [EST-model-main/README.md](file:///D:/OneDrive%20-%20TU%20Eindhoven/Study/CBL%20Energy%20Storage%20Y1Q4/Year1Q4-CBL-EST-Group38/EST-model-main/README.md).*

---

## 4. Dependencies & System Requirements

To compile the firmware, run the serial logging, execute the simulations, and run the notebook, the following software environment is required:

### 4.1 MATLAB & Simulink Environment
- **Version**: MATLAB R2025b or newer.
- **Required Toolboxes**:
  - Simulink
  - Stateflow (required for the MATLAB function blocks)

### 4.2 Arduino Toolchain
- **Software**: Arduino IDE (v1.8.x or v2.x) to compile and upload `pneumatic_data_collection.ino`.
- **Microcontroller Hardware**: Arduino Uno, Mega, Nano, or compatible board.
- **Sensors**: SMC PSE570-02 pressure sensors, SMC PF2A521-F03-1 flow sensor, or equivalent analog instrumentation.

### 4.3 Python Environment (For Data Analysis Notebooks)
- **Version**: Python 3.8 or newer.
- **Required Packages**:
  - `numpy`
  - `pandas`
  - `matplotlib`
  - `seaborn`
  - `jupyter` / `notebook` (to run the Jupyter environment)
  - `ipykernel`

---

## 5. Getting Started & Execution Instructions

### 5.1 Setting up and Running the Simulation
1. Launch MATLAB.
2. Change the **Current Folder** directory to `EST-model-main/`.
3. Open `ICAES_R2025a.slx` (or `ICAES_R2025b.slx`).
4. Click **Run** in Simulink. The initialization callback (`preprocessing.m`) will run automatically to load supply/demand data and configure the parameters, and `postprocessing.m` will automatically generate system state plots upon simulation completion.

### 5.2 Setting up the Physical Data Acquisition
1. Open `pneumatic_data_collection.ino` in the Arduino IDE.
2. Connect the Arduino board to your computer and select the correct port and board type. Click **Upload**.
3. Close the Arduino Serial Monitor.
4. Open MATLAB and open `data_collection.m`. Modify line 5 (`portName = "COM7"`) to match the actual serial port allocated to your Arduino.
5. Run `data_collection.m` in MATLAB to start the 5-second automatic data logging sequence.
6. Open and run `post_processing.m` to load `pneumatic_data.txt` and generate comparative plots of experimental data vs. theory.

### 5.3 Running the Python Data Analysis Notebook
1. Open your terminal or Command Prompt in the repository root folder.
2. Launch the Jupyter Notebook environment:
   ```bash
   jupyter notebook
   ```
3. Navigate to `data analysis/plots.ipynb` and run the notebook cells to view the visualization and optimization scripts.
