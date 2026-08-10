# CBL Energy Storage System (4CBLA30) — Near-Isothermal CAES (TU Eindhoven, 2025/2026, Group 38)

This repository contains the modeling, simulation, thermodynamic analysis, and experimental validation codebase for the **[4CBLA30] CBL Energy Storage System** project at Eindhoven University of Technology, developed by **Group 38**.

The project focuses on the design of a **Near-Isothermal Compressed Air Energy Storage (I-CAES)** system. The codebase integrates physical transient pneumatic experiments (utilizing an Arduino sensor suite and MATLAB serial logging) with a high-fidelity Simulink model to evaluate annual grid-scale energy balancing, exergy efficiency, and thermal integration.

---

## 1. Repository Structure

The repository is modularly organized into four main directories, each accompanied by a dedicated, detailed `README.md`:

```
Year1Q4-CBL-EST-Group38/
├── README.md                           # Main project documentation (this file)
│
├── EST-model-main/                     # Main I-CAES Simulink model & MATLAB components
│   ├── README.md                       # Detailed simulation & mathematical equation manual
│   ├── ICAES_R2025aa.slx               # Primary Simulink model (mass-state cavern formulation)
│   ├── ICAES_R2025aa_real_a.slx        # Experimental validation variant Simulink model
│   ├── preprocessing.m                 # InitFcn callback: parameter calculation & CSV profile loading
│   ├── postprocessing.m                # StopFcn callback: performance metric plotting & loss breakdown
│   ├── design_params/                  # Scenario parameter configuration files
│   └── data/                           # Annual 5-minute renewable supply & grid demand CSV profiles
│
├── data analysis/                      # Data post-processing, optimization & Jupyter notebooks
│   ├── README.md                       # Comprehensive data analysis & derivation guide
│   ├── data_analysis.mlx               # MATLAB Live Script: Full annual evaluation & energy balance
│   ├── modeling_analysis.mlx           # MATLAB Live Script: Parameter sweeps & cavern volume optimization
│   ├── plots.ipynb                     # Python Jupyter Notebook: Interactive visualizations
│   ├── energy_distribution_model.m     # Standalone MATLAB script: Time-series thermal/pressure split model
│   ├── ICAES_physical_model.md         # Detailed physical energy split & Helmholtz exergy derivations
│   └── energy_distribution_derivation.md# Detailed extraction work & TES boost derivations
│
├── validation/                         # Physical pneumatic validation experiment & sensor suite
│   ├── README.md                       # Experimental hardware setup, calibration & post-processing manual
│   ├── NEWEST_ARDUINO                  # Microcontroller firmware: sensor reading, ADC & safety trip
│   ├── NEWEST_MATLAB.m                 # Real-time MATLAB serial logging & animated GUI interface
│   ├── new_processing.m                # Multi-run peak synchronization & theoretical overlay script
│   ├── post_processing.m               # Statistical mean/SD calculation & dP/dt derived airflow script
│   └── data_1.txt to data_4.txt        # Aligned, synchronized physical experimental runs
│
└── other_simulink_models/              # Archive of legacy & cross-version compatibility models
    ├── README.md                       # Model evolution history & version compatibility guide
    ├── EST.slx                         # Original baseline legacy model (single-bus integrator)
    ├── est_system.slx                  # Intermediate prototype model
    └── ICAES_R2025b.slx                # Compatibility model pre-saved for MATLAB R2025b
```

---

## 2. System Overview & Physical Concepts

### 2.1 The I-CAES Concept

Standard Compressed Air Energy Storage (CAES) compresses atmospheric air into underground salt caverns during periods of excess renewable supply and expands it through turbines during energy deficits. However, uncooled (adiabatic) compression generates significant heat that is lost to the environment, while unheated expansion drops air temperatures to cryogenic levels, degrading efficiency and risking turbine damage.

**Near-Isothermal CAES (I-CAES)** overcomes these limitations by capturing the thermal energy of compression in a **Thermal Energy Storage (TES)** salt-bed reservoir and re-injecting this heat during expansion.

```
                      +-------------------+
                      | Renewable Supply  |
                      |   (Wind / Solar)  |
                      +---------+---------+
                                |
                                v
+------------------+   +-------------------+   +--------------------+
|  Grid Demand /   |<--|    Controller     |-->| Grid Power Sale /  |
| Deficit Purchase |   +---------+---------+   |  Surplus Storage   |
+------------------+             |             +--------------------+
                                 |
           +---------------------+---------------------+
           |                                           |
           v (Charging: P_net > 0)                     v (Discharging: P_net < 0)
+----------------------+                   +----------------------+
| Multi-Stage Compressor|                  |   Expander Turbine   |
+----------+-----------+                   +-----------+----------+
           |                                           ^
           |-- Heat -> [ Thermal Energy Storage (TES) ]--| (Re-heat)
           |                (Salt Bed Tank)            |
           v                                           |
+------------------------------------------------------+--+
|           Underground Salt Cavern (Mass Integration)     |
+---------------------------------------------------------+
```

---

## 3. Key Mathematical Models & Background Theory

### 3.1 Polytropic Compression & Heat Partitioning

Gas compression follows a polytropic process $p V^n = \text{const}$ with index $n \approx 1.14$. Specific compression work $w_{\text{comp}}$ is:

$$w_{\text{comp}} = \frac{n}{n-1} R_{\text{air}} T_{\text{amb}} \left[ \left(\frac{p_{\text{store}}}{p_{\text{amb}}}\right)^{\frac{n-1}{n}} - 1 \right] \quad [\text{J/kg}]$$

The input electrical work splits into stored pressure exergy and captured thermal energy ($q_{\text{thermal}}$) sent to the TES:

$$q_{\text{thermal}} = w_{\text{comp}} - c_v (T_{\text{out}} - T_{\text{amb}}), \quad T_{\text{out}} = T_{\text{amb}} \left(\frac{p_{\text{store}}}{p_{\text{amb}}}\right)^{\frac{n-1}{n}}$$

---

### 3.2 Cavern Exergy & Helmholtz Cavern Sizing

The mechanical exergy stored in a fixed cavern volume $V_{\text{cavern}}$ is derived from the **Helmholtz free energy** relative to atmospheric dead state $(p_{\text{atm}}, T_{\text{amb}})$:

$$E_{\text{air}} = V_{\text{cavern}} \left[ p_{\text{store}} \ln\left(\frac{p_{\text{store}}}{p_{\text{atm}}}\right) - (p_{\text{store}} - p_{\text{atm}}) \right] \quad [\text{J}]$$

To size the cavern volume required for a target energy storage capacity $E_{\text{target}}$:

$$V_{\text{cavern}} = \frac{E_{\text{target}}}{p_{\text{store}} \ln\left(\dfrac{p_{\text{store}}}{p_{\text{atm}}}\right) - (p_{\text{store}} - p_{\text{atm}})}$$

---

### 3.3 Expander Thermal Boost Factor

Re-heating expanding air with TES thermal energy ($T_{\text{expand}} = 373\text{ K}$) increases specific expansion work $w_{\text{exp}} = R_{\text{air}} T_{\text{in}} \ln(p_{\text{store}}/p_{\text{atm}})$ by:

$$\text{Boost Factor} = \frac{T_{\text{expand}}}{T_{\text{amb}}} = \frac{373\text{ K}}{297\text{ K}} \approx 1.256 \quad (\mathbf{+25.6\%\text{ mechanical work boost}})$$

---

## 4. Software Dependencies & Requirements

| Layer | Component | Required Version | Purpose |
|---|---|---|---|
| **Simulation** | MATLAB & Simulink | R2022b or newer (R2025a recommended) | Main simulation model & callback execution |
| **Simulation** | Stateflow Toolbox | Included with MATLAB | Required for EML chart function blocks |
| **Firmware** | Arduino IDE | v1.8.x or v2.x | Compiling & uploading sensor acquisition code |
| **Hardware** | Arduino Microcontroller | Uno / Mega / Nano | Real-time ADC sampling & serial transmission |
| **Sensors** | SMC PSE570-02 & PF2A521-F03-1 | Analog 1-5V output | Pressure & airflow measurements |
| **Data Analysis**| Python Environment | Python 3.8+ (`pandas`, `numpy`, `matplotlib`, `jupyter`) | Interactive notebook execution |

---

## 5. Getting Started & Execution Guidance

### 5.1 Running the Main Simulink Simulation

1. Open MATLAB and set the Current Folder to `EST-model-main/`.
2. Open `ICAES_R2025aa.slx` in Simulink.
3. Click **Run (▶)**. 
   - `preprocessing.m` runs automatically via `InitFcn` to compute parameters and load `data/Team38_supply.csv` & `data/Team38_demand.csv`.
   - `postprocessing.m` runs automatically via `StopFcn` upon completion to display annual state trajectories and efficiency metrics.

> For detailed block descriptions and EML equations, see [`EST-model-main/README.md`](file:///d:/OneDrive%20-%20TU%20Eindhoven/Study/TUe%20past%20courses/CBL%20Energy%20Storage%20Y1Q4/Year1Q4-CBL-EST-Group38/EST-model-main/README.md).

---

### 5.2 Executing Data Analysis & Parameter Sweeps

- **MATLAB Live Scripts**: Navigate to `data analysis/` and open `data_analysis.mlx` or `modeling_analysis.mlx` in MATLAB Live Editor.
- **Python Notebooks**: Launch Jupyter from the project root:
  ```bash
  jupyter notebook "data analysis/plots.ipynb"
  ```

> For full energy split derivations and data format specifications, see [`data analysis/README.md`](file:///d:/OneDrive%20-%20TU%20Eindhoven/Study/TUe%20past%20courses/CBL%20Energy%20Storage%20Y1Q4/Year1Q4-CBL-EST-Group38/data%20analysis/README.md).

---

### 5.3 Conducting Physical Pneumatic Validation

1. **Hardware Setup**: Wire the SMC PSE570-02 pressure sensor to pin `A0` and the SMC PF2A521-F03-1 flow sensor to pin `A1` on your Arduino board.
2. **Firmware Upload**: Open `validation/NEWEST_ARDUINO` in Arduino IDE, select your board/port, and upload the code. Close the Arduino Serial Monitor.
3. **Data Logging**: Open `validation/NEWEST_MATLAB.m`, set `portName = "COMx"`, and run the script to launch the real-time GUI logger.
4. **Post-Processing**: Run `validation/new_processing.m` to synchronize experimental runs with theoretical model curves.

> For sensor pinouts, calibration formulas, and software safety trip details, see [`validation/README.md`](file:///d:/OneDrive%20-%20TU%20Eindhoven/Study/TUe%20past%20courses/CBL%20Energy%20Storage%20Y1Q4/Year1Q4-CBL-EST-Group38/validation/README.md).

---

### 5.4 Accessing Archived & Compatibility Models

To run legacy model baselines or test on MATLAB R2025b:
1. Navigate to `other_simulink_models/`.
2. Load parameters into the workspace: `run('../EST-model-main/preprocessing.m')`.
3. Open `EST.slx` or `ICAES_R2025b.slx`.

> For version comparison tables and model progression notes, see [`other_simulink_models/README.md`](file:///d:/OneDrive%20-%20TU%20Eindhoven/Study/TUe%20past%20courses/CBL%20Energy%20Storage%20Y1Q4/Year1Q4-CBL-EST-Group38/other_simulink_models/README.md).

---

## 6. License & Course Attribution

Developed for **CBL Energy Storage (Year 1 Quarter 4)** at **Eindhoven University of Technology (TU Eindhoven)** by **Group 38**. Released under the MIT License. See `LICENSE` for details.
