# Near-Isothermal Compressed Air Energy Storage (I-CAES) Model

This folder (`EST-model-main/`) is a component of the project repository containing the high-fidelity, first-principles Simulink/MATLAB model of a **Near-Isothermal Compressed Air Energy Storage (I-CAES)** system. The model simulates the coupled thermodynamic behaviour of an underground salt cavern (exergy storage) and a surface-level Thermal Energy Storage (TES) tank operating in conjunction with the electrical grid over an annual time horizon.

The simulation is built from four coupled MATLAB Function blocks (implemented as Stateflow EML charts) that faithfully encode the governing physics at each timestep. All parameters are SI-unit consistent and parameterised in `preprocessing.m`.

---

## Table of Contents

1. [System Overview and Motivation](#1-system-overview-and-motivation)
2. [Theoretical Background](#2-theoretical-background)
   - 2.1 [Thermodynamic Process Classification](#21-thermodynamic-process-classification)
   - 2.2 [Polytropic Process Theory](#22-polytropic-process-theory)
   - 2.3 [Exergy Analysis](#23-exergy-analysis)
3. [Model Architecture](#3-model-architecture)
   - 3.1 [Simulink Block Diagram Structure](#31-simulink-block-diagram-structure)
   - 3.2 [Signal Flow and State Variables](#32-signal-flow-and-state-variables)
4. [Mathematical Model: Full Equation Reference](#4-mathematical-model-full-equation-reference)
   - 4.1 [Controller Block](#41-controller-block)
   - 4.2 [Compressor Block (Injection System)](#42-compressor-block-injection-system)
   - 4.3 [Expander Block (Extraction System) — Dual-Mode](#43-expander-block-extraction-system--dual-mode)
   - 4.4 [Cavern Pressure Dynamics](#44-cavern-pressure-dynamics)
   - 4.5 [TES Dynamics Block](#45-tes-dynamics-block)
5. [Parameter Reference Table](#5-parameter-reference-table)
6. [Folder Structure](#6-folder-structure)
7. [Getting Started](#7-getting-started)
8. [Running the Model](#8-running-the-model)
9. [Output and Post-Processing](#9-output-and-post-processing)

---

## 1. System Overview and Motivation

### The Problem: Intermittent Renewable Energy

Modern electrical grids increasingly rely on intermittent renewable sources (solar, wind), which generate power asynchronously with demand. This creates persistent imbalances between supply and demand that must be managed through large-scale energy storage.

### Why Compressed Air?

Compressed Air Energy Storage (CAES) stores electrical energy by compressing atmospheric air into an underground geological formation (typically a salt cavern or depleted gas reservoir) during periods of excess supply. During periods of deficit, the high-pressure air is released, expanded through a turbine, and the mechanical work is converted back to electricity.

### The Isothermal Advantage

A standard adiabatic CAES system suffers a fundamental thermodynamic limitation: during adiabatic compression, the air heats up dramatically; that heat is wasted as it dissipates to the environment. During expansion, the air must cool rapidly (approaching cryogenic temperatures) as it does work, reducing both the power output and risking mechanical damage to the turbine.

**Near-Isothermal CAES** addresses this by explicitly capturing and storing the heat of compression in a Thermal Energy Storage (TES) system and re-injecting it during expansion. This approach:

- **Decouples** the stored energy into two independent streams: pressure exergy (cavern) and thermal energy (TES).
- **Avoids Carnot limits**: Unlike a heat engine, the process does not pass through a high-temperature cycle, circumventing the fundamental efficiency ceiling imposed by $\eta_{Carnot} = 1 - T_{cold}/T_{hot}$.
- **Sustains expansion temperatures**: By re-heating the air from the TES, the expansion process is sustained at near-constant temperature, maintaining pressure and power output throughout the discharge cycle.
- **Prevents cryogenic damage**: Without TES heat input, the expander outlet temperature would fall to cryogenic levels.

---

## 2. Theoretical Background

### 2.1 Thermodynamic Process Classification

Gas compression and expansion processes are characterised by a **polytropic relation**:

$$pV^n = \text{const}$$

The polytropic index $n$ parameterises the heat exchange behaviour:

| Process | $n$ | Heat exchange $Q$ |
|---|---|---|
| Isothermal | $n = 1$ | Maximum heat exchange (temperature constant) |
| Near-Isothermal | $1 < n < \gamma$ | Partial heat exchange |
| Adiabatic (Isentropic) | $n = \gamma \approx 1.4$ | No heat exchange ($Q = 0$) |
| Isobaric | $n = 0$ | Constant pressure |
| Isochoric | $n = \infty$ | Constant volume |

For air modelled as an ideal diatomic gas:
$$\gamma = \frac{c_p}{c_v} = \frac{c_p}{c_p - R_{air}} \approx \frac{1005}{1005 - 287.05} \approx 1.400$$

The model uses $n_{poly} = 1.1$ for compression and for near-isothermal expansion (when TES water is available). This is achievable in practice through staged compression with intercooling or by injecting liquid water mist into the compression chamber. When TES water is exhausted, the expander falls back to adiabatic behaviour ($n = \gamma = 1.4$).

### 2.2 Polytropic Process Theory

For a polytropic process between states 1 and 2, the temperature ratio is:

$$\frac{T_2}{T_1} = \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}}$$

The specific work input (or output) for a steady-flow process (shaft work per unit mass) is derived from the steady-flow energy equation (SFEE):

$$w_{poly} = \frac{n}{n-1} R_{air} T_1 \left[ \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}} - 1 \right] \quad \text{[J/kg]}$$

This reduces correctly to the isothermal specific work $w_{iso} = R_{air} T \ln(p_2/p_1)$ in the limit $n \to 1$.

### 2.3 Exergy Analysis

**Exergy** is the maximum useful work extractable from a system as it moves reversibly to thermodynamic equilibrium with its environment (defined by $T_{amb}$, $p_{amb}$). For an ideal gas at pressure $p_{store}$ and temperature $T_{amb}$ (thermal equilibrium with environment), the specific mechanical exergy is:

$$e_{mech} = R_{air} T_{amb} \ln\left(\frac{p_{store}}{p_{amb}}\right) \quad \text{[J/kg]}$$

The rate of exergy stored in the cavern during compression is therefore:

$$\dot{E}_{exergy} = \dot{m}_{charge} \cdot R_{air} \cdot T_{amb} \cdot \ln\left(\frac{p_{store}}{p_{amb}}\right) \quad \text{[W]}$$

This equation is implemented directly in the Compressor block.

---

## 3. Model Architecture

### 3.1 Simulink Block Diagram Structure

The Simulink model is organised into five hierarchical subsystems, each containing one or more MATLAB Function blocks:

```
ICAES (Root)
├── Controller/                  → EML: controller
│     Evaluates P_net, routes power to charge/discharge/sell/buy.
│
├── Injection System/
│   └── Compressor/              → EML: compressor
│         Polytropic compression; outputs mdot_charge, P_thermal, P_exergy.
│
├── Extraction System/
│   └── Expander/                → EML: expander
│         Dual-mode polytropic expansion; outputs mdot_discharge, Q_in_needed, P_output.
│
├── Cavern (Pressure Storage)/   → Simulink Integrator block
│     Integrates dp/dt = (R_air * T_amb / V_cavern) * (mdot_charge - mdot_discharge)
│
└── TES/
    └── MATLAB Function/         → EML: tes_dynamics
          Variable-mass water tank; outputs dm_water/dt.
          Integrated by a Simulink Integrator block with saturation [0, m_tes_max].
```

### 3.2 Signal Flow and State Variables

The model has **two continuous state variables** integrated by Simulink integrators:

| State Variable | Symbol | Units | Description |
|---|---|---|---|
| Cavern Pressure | $p_{store}$ | Pa | Absolute pressure of compressed air in the underground cavern |
| TES Water Mass | $m_{water}$ | kg | Current mass of hot water stored in the TES tank |

All other quantities (mass flow rates, power flows, temperatures) are algebraic functions computed at each timestep from the states and inputs. Signal flow proceeds in this order each timestep:

$$[\text{Supply, Demand}] \xrightarrow{\text{Controller}} [P_{charge}, P_{demand,req}] \xrightarrow{\text{Compressor / Expander}} [\dot{m}_{charge}, P_{thermal}, \dot{m}_{discharge}, \dot{Q}_{in}] \xrightarrow{\text{Integrators}} [p_{store}, m_{water}]$$

---

## 4. Mathematical Model: Full Equation Reference

### 4.1 Controller Block

**MATLAB Function:** `controller`

**Inputs:** $P_{supply}$, $P_{demand}$, $p_{store}$, $\eta_{tran}$, $P_{limit}$, $p_{store,max}$, $p_{amb}$

**Outputs:** $P_{charge}$, $P_{demand,req}$, $P_{sell}$, $P_{buy}$

**Step 1 — Compute net grid power:**
$$P_{net} = P_{supply} - P_{demand} \quad \text{[W]}$$

**Case A — Surplus: $P_{net} \geq 0$ (Charging Mode)**

The available surplus is capped by the maximum compressor input power:
$$P_{available} = \min(P_{net},\ P_{limit}) \quad \text{[W]}$$

Transmission losses are applied before delivering power to the compressor:
$$P_{charge} = \eta_{tran} \cdot P_{available} \quad \text{[W]}$$

Surplus beyond the power limit is sold to the grid:
$$P_{sell} = P_{net} - P_{available} \quad \text{[W]}$$

Cavern saturation guard — if the cavern is at maximum pressure, all compressor power is redirected to selling:
$$\text{if } p_{store} \geq p_{store,max}: \quad P_{sell} \mathrel{+}= P_{charge}, \quad P_{charge} = 0$$

**Case B — Deficit: $P_{net} < 0$ (Discharging Mode)**

The required power from the expander is the magnitude of the deficit:
$$P_{demand,req} = -P_{net} \quad \text{[W]}$$

Cavern depletion guard — if the cavern pressure is at or below a 5% margin above ambient, the system cannot expand air and must buy from the grid:
$$\text{if } p_{store} \leq 1.05 \cdot p_{amb}: \quad P_{buy} = P_{demand,req}, \quad P_{demand,req} = 0$$

---

### 4.2 Compressor Block (Injection System)

**MATLAB Function:** `compressor`

**Inputs:** $P_{charge}$, $p_{store}$, $\eta_{comp}$, $n_{poly}$, $R_{air}$, $c_p$, $T_{amb}$, $p_{amb}$

**Outputs:** $\dot{m}_{charge}$, $P_{thermal}$, $P_{exergy}$

The compressor converts electrical power into compressed air mass flow. All processes use the polytropic index $n_{poly}$ (a fixed constant set in `preprocessing.m`).

**Step 1 — Pressure ratio:**
$$r = \frac{p_{store}}{p_{amb}} \qquad [r \geq 1.001 \text{ (numerical guard)}]$$

**Step 2 — Polytropic specific work factor [J/kg]:**

This is the theoretical shaft work required to compress 1 kg of air from $p_{amb}$ to $p_{store}$ polytropically:
$$w_{comp} = \frac{n_{poly}}{n_{poly}-1} \cdot R_{air} \cdot T_{amb} \cdot \left( r^{\frac{n_{poly}-1}{n_{poly}}} - 1 \right) \quad \text{[J/kg]}$$

**Step 3 — Mass flow rate [kg/s]:**

Applying compressor isentropic efficiency $\eta_{comp}$:
$$\dot{m}_{charge} = \frac{P_{charge}}{\eta_{comp} \cdot w_{comp}} \quad \text{[kg/s]}$$

**Step 4 — Compressor outlet temperature [K]:**

From the polytropic temperature-pressure relation:
$$T_{out} = T_{amb} \cdot r^{\frac{n_{poly}-1}{n_{poly}}} \quad \text{[K]}$$

**Step 5 — Thermal power captured by TES [W]:**

The difference between total electrical input and the specific enthalpy rise of the compressed air (Steady-Flow Energy Equation):
$$P_{thermal} = P_{charge} - \dot{m}_{charge} \cdot c_p \cdot (T_{out} - T_{amb}) \quad \text{[W]}$$
$$P_{thermal} = \max(P_{thermal},\ 0) \quad \text{(non-negativity guard)}$$

This power represents the heat of compression that is captured and transferred to the TES water tank, heating water from $T_{amb}$ to $T_{tes}$.

**Step 6 — Pressure exergy rate stored in cavern [W]:**

From mechanical exergy theory (see §2.3):
$$P_{exergy} = \dot{m}_{charge} \cdot R_{air} \cdot T_{amb} \cdot \ln(r) \quad \text{[W]}$$

> **Note:** $P_{thermal}$ and $P_{exergy}$ are output signals for monitoring and post-processing. The actual state updates use $\dot{m}_{charge}$ (for cavern pressure) and $P_{thermal}$ (for TES mass).

---

### 4.3 Expander Block (Extraction System) — Dual-Mode

**MATLAB Function:** `expander`

**Inputs:** $P_{demand,req}$, $p_{store}$, $m_{water}$, $\eta_{exp}$, $\eta_{tran}$, $n_{poly}$, $R_{air}$, $c_p$, $p_{amb}$, $T_{amb}$, $c_{tes}$, $T_{tes}$

**Outputs:** $\dot{m}_{discharge}$, $\dot{Q}_{in,needed}$, $P_{output}$

The expander implements a **dual-mode polytropic expansion** process. The polytropic index $n$ and the expansion inlet temperature $T_{in}$ are **not constants** — they depend dynamically on the availability of thermal energy in the TES tank.

**Step 1 — Required shaft power (before transmission losses):**
$$P_{discharge} = \frac{P_{demand,req}}{\eta_{tran}} \quad \text{[W]}$$

**Step 2 — Expansion pressure ratio:**
$$r_{exp} = \frac{p_{amb}}{p_{store}} \qquad [r_{exp} < 1; \text{ return if } r_{exp} \geq 1]$$

**Step 3 — Adiabatic index of air:**
$$\gamma = \frac{c_p}{c_p - R_{air}} \approx 1.400$$

**Step 4 — Dynamic mode selection based on TES state:**

$$\begin{cases}
n = n_{poly} = 1.1, \quad T_{in} = T_{tes} = 372\text{ K} & \text{if } m_{water} > 0 \quad \textbf{(Near-Isothermal Mode)} \\
n = \gamma = 1.400, \quad T_{in} = T_{amb} = 300\text{ K} & \text{if } m_{water} = 0 \quad \textbf{(Adiabatic Fallback Mode)}
\end{cases}$$

**Step 5 — Polytropic expansion specific work [J/kg]:**
$$w_{exp} = \frac{n}{n-1} \cdot R_{air} \cdot T_{in} \cdot \left(1 - r_{exp}^{\frac{n-1}{n}}\right) \quad \text{[J/kg]}$$

**Step 6 — Discharge mass flow rate [kg/s]:**
$$\dot{m}_{discharge} = \frac{P_{discharge}}{\eta_{exp} \cdot w_{exp}} \quad \text{[kg/s]}$$

**Step 7 — Expander outlet temperature [K]:**
$$T_{out} = T_{in} \cdot r_{exp}^{\frac{n-1}{n}} \quad \text{[K]}$$

**Step 8 — Thermal power drawn from TES [W]:**

In Near-Isothermal Mode ($m_{water} > 0$), the TES must supply heat to the turbine to sustain the polytropic temperature profile. This is derived from the SFEE applied to the expander:
$$\dot{Q}_{in,needed} = \frac{P_{discharge}}{\eta_{exp}} - \dot{m}_{discharge} \cdot c_p \cdot (T_{in} - T_{out}) \quad \text{[W]}$$
$$\dot{Q}_{in,needed} = \max(\dot{Q}_{in,needed},\ 0) \quad \text{(non-negativity guard)}$$

In Adiabatic Fallback Mode ($m_{water} = 0$): $\dot{Q}_{in,needed} = 0$

**Step 9 — Net electrical power output [W]:**
$$P_{output} = \eta_{tran} \cdot P_{discharge} \quad \text{[W]}$$

---

### 4.4 Cavern Pressure Dynamics

**Implementation:** Simulink Integrator block fed by the algebraic output of the Compressor and Expander blocks.

The cavern is modelled as a rigid volume $V_{cavern}$ containing an ideal gas at uniform conditions. From the ideal gas law $pV = mRT_{amb}$ (assuming the injected air reaches thermal equilibrium with the underground rock at $T_{amb}$), differentiating with respect to time:

$$\frac{d}{dt}(pV) = \frac{d}{dt}(m R_{air} T_{amb})$$

Since $V_{cavern}$, $R_{air}$, and $T_{amb}$ are constants:

$$\boxed{\frac{dp_{store}}{dt} = \frac{R_{air} \cdot T_{amb}}{V_{cavern}} \cdot (\dot{m}_{charge} - \dot{m}_{discharge})} \quad \text{[Pa/s]}$$

**Initial condition:** $p_{store}(0) = p_{store,initial} = 2\text{ bar}$ (cushion gas pre-charge)

**Saturation:** $p_{store} \in [p_{amb},\ p_{store,max}]$

The Simulink integrator clamps $p_{store}$ at the maximum safe operating pressure $p_{store,max}$ (100 bar by default). The controller also prevents charging when $p_{store} \geq p_{store,max}$.

---

### 4.5 TES Dynamics Block

**MATLAB Function:** `tes_dynamics`

**Inputs:** $P_{thermal}$, $\dot{Q}_{in,needed}$, $T_{amb}$, $c_{tes}$, $m_{tes,max}$, $m_{water}$, $T_{tes}$

**Output:** $\dot{m}_{water}$ [kg/s]

The TES is modelled as a **variable-mass, constant-temperature** reservoir. Rather than tracking temperature in a fixed-mass tank, the model tracks the *mass* of hot water stored at a fixed temperature $T_{tes} = 372\text{ K}$ (99°C). This reflects a flow-through thermal store where hot water from the compressor intercoolers is added during charging and consumed through a heat exchanger during discharging.

The thermal energy stored per unit mass of TES water relative to ambient is:
$$\Delta h = c_{tes} \cdot (T_{tes} - T_{amb}) = 4184 \cdot (372 - 300) = 301{,}248 \text{ J/kg}$$

The net power balance across the TES determines the rate of water mass change:

$$\boxed{\dot{m}_{water} = \frac{P_{thermal} - \dot{Q}_{in,needed}}{c_{tes} \cdot (T_{tes} - T_{amb})}} \quad \text{[kg/s]}$$

| Sign of $\dot{m}_{water}$ | Physical interpretation |
|---|---|
| $\dot{m}_{water} > 0$ | Hot water is being added (charging: compressor heat exceeds expander demand) |
| $\dot{m}_{water} < 0$ | Hot water is being consumed (discharging: expander draws heat from tank) |
| $\dot{m}_{water} = 0$ | Thermal equilibrium or no active energy exchange |

**Initial condition:** $m_{water}(0) = 0\text{ kg}$ (TES starts empty)

**Saturation:** $m_{water} \in [0,\ m_{tes,max}]$

The Simulink integrator enforces lower saturation at 0 kg and upper saturation at $m_{tes,max} = 300{,}000\text{ kg}$.

---

## 5. Parameter Reference Table

All parameters are set in `preprocessing.m` using the SI unit library in `scripts/constants.m`.

### Physical Constants

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `p_amb` | $p_{amb}$ | 101,325 | Pa | Atmospheric pressure |
| `T_amb` | $T_{amb}$ | 300 | K | Ambient temperature |
| `R_air` | $R_{air}$ | 287.05 | J/(kg·K) | Specific gas constant of air |
| `c_p` | $c_p$ | 1,005 | J/(kg·K) | Specific heat of air at constant pressure |
| `c_tes` | $c_{tes}$ | 4,184 | J/(kg·K) | Specific heat capacity of TES water |
| `n_poly` | $n_{poly}$ | 1.1 | — | Polytropic index (compression; near-isothermal expansion) |

### System Design Parameters

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `eta_tran` | $\eta_{tran}$ | 0.97 | — | Transmission/grid interface efficiency |
| `eta_comp` | $\eta_{comp}$ | 0.833 | — | Compressor isentropic efficiency |
| `eta_exp` | $\eta_{exp}$ | 0.85 | — | Expander isentropic efficiency |
| `P_limit` | $P_{limit}$ | 300 | MW | Maximum compressor input power from grid |
| `p_store_max` | $p_{store,max}$ | 100 | bar | Maximum safe cavern operating pressure |
| `V_cavern` | $V_{cavern}$ | 5,000,000 | m³ | Volume of underground salt cavern |
| `T_tes` | $T_{tes}$ | 372 | K | Operating temperature of TES water (99°C) |
| `m_tes_max` | $m_{tes,max}$ | 300,000 | kg | Maximum water storage capacity of TES tank |

### Initial Conditions

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `p_store_initial` | $p_{store}(0)$ | 2 | bar | Initial cavern pressure (cushion gas) |
| `m_water_initial` | $m_{water}(0)$ | 0 | kg | Initial TES water mass (empty at start) |

---

## 6. Folder Structure

The project repository includes folders for data analysis and optimization alongside the main model folder:

- **`EST-model-main/`** (This folder)
  - `ICAES_R2025a.slx` / `ICAES_R2025b.slx`: Main Simulink models.
  - `preprocessing.m`: Initialisation script (loads data and parameters).
  - `postprocessing.m`: Post-simulation plotting script.
  - `data/`: Contains solar/wind supply and electrical demand profiles.
  - `scripts/`: Utility scripts to load data and define physical constants.
- **`data analysis/`** (In repository root)
  - Contains scripts, Live Scripts (`.mlx`), and Jupyter notebooks to analyze, simulate, and optimize the model's performance under various parameter configurations.

---

## 7. Getting Started

### Prerequisites
- MATLAB R2022b or newer with Simulink.

### Setup
1. Open MATLAB and set the **Current Folder** to `EST-model-main/`. (The initialization script `preprocessing.m` requires this folder context to locate data and scripts).

---

## 8. Running the Model

1. Open `ICAES_R2025a.slx` (or `ICAES_R2025b.slx` for newer releases) in Simulink.
2. Click **Run** (▶).

The model automatically runs the initialization callback (`preprocessing.m`) to load data and parameters, runs the annual simulation (5-minute timesteps), and triggers the post-processing script (`postprocessing.m`) to plot results.

---

## 9. Output and Post-Processing

The `postprocessing.m` script generates four figures after every simulation run:

| Figure | Plot(s) | Description |
|---|---|---|
| **Figure 1** | 2×2 subplot | System state overview: Supply & Demand, Cavern Pressure, TES Water Mass, Load Balancing (Sell/Buy) |
| **Figure 2** | 2×1 subplot | Mass flow rates (charging/discharging) and Energy split during charging (Thermal to TES vs. Exergy to Cavern) |
| **Figure 3** | Pie chart | Annual demand energy sources: Direct Supply, I-CAES Discharge, Bought from Grid |
| **Figure 4** | Time series | Deficit power vs. I-CAES discharging power — illustrates how much of the deficit is covered |

### Key Performance Metric

The primary performance indicator is the **I-CAES supply fraction**, defined as:

$$f_{ICAES} = \frac{E_{ICAES}}{E_{demand,total}} = \frac{\int P_{ICAES}(t)\,dt}{\int P_{demand}(t)\,dt}$$

This represents the fraction of total annual electrical demand that is satisfied by the I-CAES system, as opposed to being bought from the external grid.
