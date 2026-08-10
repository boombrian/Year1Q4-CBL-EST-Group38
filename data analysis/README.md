# Data Analysis, Mathematical Derivations & Jupyter Notebooks

This directory (`data analysis/`) contains the data post-processing, thermodynamic parameter optimization, analytical energy distribution modeling, and interactive visualization scripts for the **Near-Isothermal Compressed Air Energy Storage (I-CAES)** project.

---

## 1. Directory Structure & Overview

```
data analysis/
├── data_analysis.mlx               # MATLAB Live Script: Full system annual evaluation & energy balance
├── modeling_analysis.mlx           # MATLAB Live Script: Parameter sensitivity & cavern sizing
├── plots.ipynb                     # Python Jupyter Notebook: Interactive sweeps & grid load plots
├── energy_distribution_model.m     # Standalone MATLAB script: Time-series thermal/pressure split model
├── ICAES_physical_model.md         # Documentation: Physical energy split & Helmholtz exergy derivations
├── energy_distribution_derivation.md# Documentation: Step-by-step extraction work & TES boost derivations
├── Team38_supply.csv               # Input dataset: Annual 5-minute renewable energy supply profile (MW)
├── Team38_demand.csv               # Input dataset: Annual 5-minute electrical grid demand profile (MW)
├── Team38_net_produce.csv          # Input dataset: Net surplus/deficit supply-demand profile (MW)
├── Figure_1.png                    # Output plot artifact: Annual storage dynamics & power flows
└── output.png                      # Output plot artifact: Optimization and sensitivity results
```

---

## 2. Theoretical Background

### 2.1 Polytropic Compression & First Law Energy Partitioning

During the charging phase, surplus electrical power $P_{\text{net}} > 0$ drives the multi-stage intercooled compressor. The steady-flow First Law of Thermodynamics governs the process:

$$\dot{W}_{\text{comp}} = \dot{m} (h_2 - h_1) + \dot{Q}_{\text{loss}}$$

For ideal air ($h_2 - h_1 = c_p (T_2 - T_1)$), compression follows a **polytropic process**:

$$p V^n = \text{const}$$

The compressor discharge temperature $T_2$ is:

$$T_2 = T_1 \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}}$$

The specific compression work $w_{\text{comp}}$ [J/kg] is:

$$w_{\text{comp}} = \frac{n}{n-1} R_{\text{air}} T_1 \left[ \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}} - 1 \right]$$

This work splits into internal energy change $\Delta u = c_v (T_2 - T_1)$ and thermal energy transferred to the TES $q_{\text{thermal}}$:

$$w_{\text{comp}} = \Delta u + q_{\text{thermal}}$$

The thermal energy capture fraction $\eta_{\text{thermal}}$ stored in the TES is:

$$\eta_{\text{thermal}} = \frac{q_{\text{thermal}}}{w_{\text{comp}}} = 1 - \frac{c_v (T_2 - T_1)}{w_{\text{comp}}}$$

For near-isothermal compression ($n \approx 1.05$), approximately **90%** of input mechanical work is converted to heat and stored in the Thermal Energy Storage (TES), while the remaining **10%** increases air internal energy.

---

### 2.2 Pressure Exergy & Cavern Sizing via Helmholtz Free Energy

The mechanical exergy stored in the pressurised cavern of fixed volume $V_{\text{cavern}}$ under isothermal dead-state conditions $(p_{\text{atm}}, T_{\text{amb}})$ is derived from the **Helmholtz free energy** change:

$$E_{\text{air}} = V_{\text{cavern}} \left[ p_{\text{store}} \ln\left(\frac{p_{\text{store}}}{p_{\text{atm}}}\right) - (p_{\text{store}} - p_{\text{atm}}) \right] \quad [\text{J}]$$

To size the required cavern volume $V_{\text{cavern}}$ for a given annual energy storage requirement $E_{\text{target}}$ at maximum storage pressure $p_{\text{store}}$:

$$V_{\text{cavern}} = \frac{E_{\text{target}}}{p_{\text{store}} \ln\left(\dfrac{p_{\text{store}}}{p_{\text{atm}}}\right) - (p_{\text{store}} - p_{\text{atm}})}$$

> **Note:** The subtraction of $(p_{\text{store}} - p_{\text{atm}})$ rigorously accounts for atmospheric displacement work that cannot be extracted during expansion.

---

### 2.3 Expansion Mechanics & Thermal Work Boost

During grid deficit ($P_{\text{net}} < 0$), high-pressure air expands through the turbine. The specific expansion work output $w_{\text{exp}}$ [J/kg] depends directly on the expander inlet temperature $T_{\text{in}}$:

$$w_{\text{exp}} = R_{\text{air}} T_{\text{in}} \ln\left(\frac{p_{\text{store}}}{p_{\text{atm}}}\right)$$

When heat from the TES is re-injected during expansion ($T_{\text{in}} = T_{\text{expand}} \approx 370\text{ K}$), the expansion work is boosted relative to ambient expansion ($T_{\text{amb}} = 300\text{ K}$):

$$\text{Boost Factor} = \frac{w_{\text{TES}}}{w_{\text{amb}}} = \frac{T_{\text{expand}}}{T_{\text{amb}}} \approx \frac{370}{300} \approx 1.233 \quad (\mathbf{+23.3\%\text{ power output boost}})$$

---

### 2.4 Time-Series Storage Dynamics Model

The standalone script `energy_distribution_model.m` updates stored energy levels at each timestep $\Delta t$:

- **Surplus ($P_{\text{net}} > 0$, Charging):**
  $$P_{\text{charge}} = \min(P_{\text{net}}, P_{\text{comp,max}})$$
  $$\Delta E_{\text{thermal}} = P_{\text{charge}} \Delta t \cdot \eta_{\text{thermal}}$$
  $$\Delta E_{\text{pressure}} = P_{\text{charge}} \Delta t \cdot \eta_{\text{pressure}}$$

- **Deficit ($P_{\text{net}} < 0$, Discharging):**
  $$\Delta E_{\text{thermal}} = -|P_{\text{net}}| \Delta t$$
  $$\Delta E_{\text{pressure}} = -|P_{\text{net}}| \Delta t$$

---

## 3. Data File Specifications

The simulation and scripts ingest 5-minute interval annual time-series data:

| File Name | Columns | Units | Description |
|---|---|---|---|
| `Team38_supply.csv` | `Time_s`, `Supply_MW` | seconds, MW | Annual wind + solar power generation profile |
| `Team38_demand.csv` | `Time_s`, `Demand_MW` | seconds, MW | Annual electrical grid load demand profile |
| `Team38_net_produce.csv` | `Time_s`, `Net_Produce_MW` | seconds, MW | Net balance profile ($P_{\text{net}} = P_{\text{supply}} - P_{\text{demand}}$) |

---

## 4. Usage Guidance

### 4.1 Running MATLAB Live Scripts (`.mlx`)

1. Open MATLAB (R2022a or newer).
2. Set the current working directory to `data analysis/`.
3. Double-click `data_analysis.mlx` or `modeling_analysis.mlx`.
4. Click **Run** in the Live Editor tab. The scripts will load the CSV profiles, calculate state trajectories, and display inline figures.

### 4.2 Executing the Standalone Energy Distribution Script (`.m`)

Run the following command in the MATLAB Command Window:

```matlab
cd('data analysis')
energy_distribution_model
```

This will output compression thermodynamics metrics to the Command Window and launch a figure displaying real-time TES and cavern stored energy levels over the 8760-hour annual profile.

### 4.3 Running Python Jupyter Notebooks (`.ipynb`)

1. Open a terminal or Command Prompt in the repository root.
2. Launch Jupyter:
   ```bash
   jupyter notebook "data analysis/plots.ipynb"
   ```
3. Run all cells (`Cell -> Run All`) to re-generate parametric sensitivity curves, grid surplus distributions, and energy balance charts.

---

## 5. Key References

- `ICAES_physical_model.md`: Full text derivation of compression heat splits and cavern volume equations.
- `energy_distribution_derivation.md`: Mathematical derivations for extraction work and dual-mode expansion logic.
