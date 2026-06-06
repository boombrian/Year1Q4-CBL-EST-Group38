# Near-Isothermal Compressed Air Energy Storage (I-CAES) Model

This folder (`EST-model-main/`) contains the high-fidelity, first-principles Simulink/MATLAB model of a **Near-Isothermal Compressed Air Energy Storage (I-CAES)** system. The model simulates the coupled thermodynamic behaviour of an underground salt cavern (pressure/exergy storage) and a surface-level Thermal Energy Storage (TES) salt-bed tank, operating in conjunction with the electrical grid over an annual time horizon.

The simulation is built from five coupled MATLAB Function blocks (implemented as Stateflow EML charts) that encode the governing physics at each fixed timestep. All parameters are SI-unit consistent and fully parameterised in `preprocessing.m` and the `design_params/` configuration files.

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
   - 4.3 [Expander Block (Extraction System)](#43-expander-block-extraction-system--dual-mode)
   - 4.4 [Cavern Pressure Dynamics](#44-cavern-dynamics-mass-state-formulation)
   - 4.5 [TES Dynamics Block](#45-tes-dynamics-block)
   - 4.6 [Transport Blocks](#46-transport-blocks)
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
- **Avoids Carnot limits**: Unlike a heat engine, the process does not pass through a high-temperature cycle.
- **Sustains expansion temperatures**: By re-heating the air from the TES, the expansion process is sustained at near-constant temperature.
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
| Adiabatic (Isentropic) | $n = \gamma$ | No heat exchange ($Q = 0$) |

For air modelled as an ideal diatomic gas:
$$\gamma = \frac{c_p}{c_v} = \frac{c_p}{c_p - R_{air}}$$

The model uses a design polytropic index $n_{poly} = 1.14$ for compression and near-isothermal expansion (when TES is available). When TES thermal energy is exhausted, the expander falls back to adiabatic behaviour ($n = \gamma$).

### 2.2 Polytropic Process Theory

For a polytropic process between states 1 and 2, the temperature ratio is:

$$\frac{T_2}{T_1} = \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}}$$

The specific work input (or output) for a steady-flow process is derived from the Steady-Flow Energy Equation (SFEE):

$$w_{poly} = \frac{n}{n-1} R_{air} T_1 \left[ \left(\frac{p_2}{p_1}\right)^{\frac{n-1}{n}} - 1 \right] \quad \text{[J/kg]}$$

### 2.3 Exergy Analysis

**Exergy** is the maximum useful work extractable from a system as it moves reversibly to thermodynamic equilibrium with its environment ($T_{amb}$, $p_{amb}$). For an ideal gas at pressure $p_{store}$ and temperature $T_{amb}$, the specific mechanical exergy is:

$$e_{mech} = R_{air} T_{amb} \ln\left(\frac{p_{store}}{p_{amb}}\right) \quad \text{[J/kg]}$$

The rate of exergy stored in the cavern during compression is:

$$\dot{E}_{exergy} = \dot{m}_{charge} \cdot R_{air} \cdot T_{amb} \cdot \ln\left(\frac{p_{store}}{p_{amb}}\right) \quad \text{[W]}$$

---

## 3. Model Architecture

### 3.1 Simulink Block Diagram Structure

```
ICAES (Root)
├── Controller/                  → EML: controller
│     Evaluates P_net, routes power to charge/discharge/sell/buy.
│
├── Injection System/
│   └── Compressor/              → EML: compressor
│         Polytropic compression; outputs mdot_charge (capped at mdot_max),
│         P_thermal, P_exergy.
│
├── Extraction System/
│   └── Expander/                → EML: expander
│         Dual-mode polytropic expansion; outputs mdot_discharge (capped at
│         mdot_max), Q_in_needed, P_output.
│
├── Cavern (Pressure Storage)/   → Simulink Integrator block
│     Integrates dm_air/dt = mdot_charge - mdot_discharge.
│     EoS block converts m_air → p_store.
│
└── TES/
    └── MATLAB Function/         → EML: tes_dynamics
          Fixed-mass salt bed with passive thermal decay.
          Outputs dT_tes/dt and P_thermal_loss (monitorable via Scope).
          Integrated by a Simulink Integrator with saturation [T_amb, T_tes_max].
```

### 3.2 Signal Flow and State Variables

The model has **two continuous state variables** integrated by Simulink integrators:

| State Variable | Symbol | Units | Description |
|---|---|---|---|
| Cavern Air Mass | $m_{air}$ | kg | Total mass of air stored in the cavern |
| TES Temperature | $T_{tes}$ | K | Current average temperature of the salt bed |

Signal flow each timestep:

$$[\text{Supply, Demand}] \xrightarrow{\text{Controller}} [P_{charge}, P_{demand,req}] \xrightarrow{\text{Compressor / Expander}} [\dot{m}_{charge}, P_{thermal}, \dot{m}_{discharge}, \dot{Q}_{in}] \xrightarrow{\text{Integrators}} [m_{air}, T_{tes}] \xrightarrow{\text{EoS}} [p_{store}]$$

---

## 4. Mathematical Model: Full Equation Reference

### 4.1 Controller Block

**MATLAB Function:** `controller`

**Inputs:** $P_{supply}$, $P_{demand}$, $p_{store}$, $P_{limit}$, $p_{store,max}$, $p_{amb}$

**Outputs:** $P_{charge}$, $P_{demand,req}$, $P_{sell}$, $P_{buy}$

**Case A — Surplus: $P_{net} \geq 0$ (Charging Mode)**

$$P_{net} = P_{supply} - P_{demand}$$
$$P_{available} = \min(P_{net},\ P_{limit})$$
$$P_{charge} = P_{available}$$
$$P_{sell} = P_{net} - P_{available}$$

Cavern saturation guard — if $p_{store} \geq p_{store,max}$: all compressor power redirected to selling.

**Case B — Deficit: $P_{net} < 0$ (Discharging Mode)**

$$P_{demand,req} = -P_{net}$$

Cavern depletion guard — if $p_{store} \leq 1.05 \cdot p_{amb}$: system buys from grid instead.

> **Note:** Transmission efficiency $\eta_{tran}$ is applied by dedicated Transport Gain blocks on the root canvas, not inside the controller.

---

### 4.2 Compressor Block (Injection System)

**MATLAB Function:** `compressor`

**Inputs:** $P_{charge}$, $p_{store}$

**Parameters:** $\eta_{comp}$, $n_{poly}$, $R_{air}$, $c_p$, $T_{amb}$, $p_{amb}$, $\dot{m}_{max}$

**Outputs:** $\dot{m}_{charge}$, $P_{thermal}$, $P_{exergy}$

#### Multi-Stage Compression — Model Simplification

In practice, compression from atmospheric to cavern pressure (70–100 bar) uses a **multi-stage train with intercoolers**. This model represents the entire train as a **single equivalent polytropic process** with index $n_{poly}$. This is thermodynamically justified: multi-stage intercooled compression is precisely what a polytropic index between 1 (isothermal) and $\gamma$ (adiabatic) represents. $n_{poly} = 1.14$ is consistent with well-designed intercooled compression.

**Step 1 — Pressure ratio:**
$$r = \frac{p_{store}}{p_{amb}} \qquad [r \geq 1.001 \text{ guard}]$$

**Step 2 — Polytropic specific work [J/kg]:**
$$w_{comp} = \frac{n_{poly}}{n_{poly}-1} \cdot R_{air} \cdot T_{amb} \cdot \left( r^{\frac{n_{poly}-1}{n_{poly}}} - 1 \right)$$

**Step 3 — Thermodynamic mass flow rate [kg/s]:**
$$\dot{m}_{thermo} = \frac{P_{charge}}{\eta_{comp} \cdot w_{comp}}$$

**Step 4 — Pipe flow limit [kg/s]:**

The mass flow is physically limited by the injection pipe capacity:
$$\dot{m}_{charge} = \min\!\left(\dot{m}_{thermo},\ \dot{m}_{max}\right)$$

where $\dot{m}_{max} = \rho_{amb} \cdot A_{pipe} \cdot v_{flow}$ is derived from pipe geometry in `preprocessing.m`.

When the pipe is the bottleneck, the actual electrical power consumed is:
$$P_{used} = \dot{m}_{charge} \cdot \eta_{comp} \cdot w_{comp} \leq P_{charge}$$

**Step 5 — Compressor outlet temperature [K]:**
$$T_{out} = T_{amb} \cdot r^{\frac{n_{poly}-1}{n_{poly}}}$$

**Step 6 — Thermal power to TES [W]:**
$$P_{thermal} = P_{used} - \dot{m}_{charge} \cdot c_p \cdot (T_{out} - T_{amb}) \quad [\geq 0]$$

**Step 7 — Pressure exergy rate [W]:**
$$P_{exergy} = \dot{m}_{charge} \cdot R_{air} \cdot T_{amb} \cdot \ln(r)$$

---

### 4.3 Expander Block (Extraction System) — Dual-Mode

**MATLAB Function:** `expander`

**Inputs:** $P_{demand,req}$, $p_{store}$, $T_{tes,state}$

**Parameters:** $\eta_{exp}$, $n_{poly}$, $R_{air}$, $c_p$, $p_{amb}$, $T_{amb}$, $T_{expand}$, $\dot{m}_{max}$

**Outputs:** $\dot{m}_{discharge}$, $\dot{Q}_{in,needed}$, $P_{output}$

**Step 1 — Expansion pressure ratio:**
$$r_{exp} = \frac{p_{amb}}{p_{store}} \qquad [r_{exp} < 1 \text{ required}]$$

**Step 2 — Adiabatic index:**
$$\gamma = \frac{c_p}{c_p - R_{air}}$$

**Step 3 — Dynamic mode selection:**

$$\begin{cases}
n = n_{poly},\quad T_{in} = T_{expand} & \text{if } T_{tes,state} \geq T_{expand} \quad \textbf{(Near-Isothermal)} \\
n = \gamma,\quad T_{in} = T_{amb} & \text{if } T_{tes,state} < T_{expand} \quad \textbf{(Adiabatic Fallback)}
\end{cases}$$

**Step 4 — Polytropic expansion specific work [J/kg]:**
$$w_{exp} = \frac{n}{n-1} \cdot R_{air} \cdot T_{in} \cdot \left(1 - r_{exp}^{\frac{n-1}{n}}\right)$$

**Step 5 — Thermodynamic discharge mass flow rate [kg/s]:**
$$\dot{m}_{thermo} = \frac{P_{demand,req}}{\eta_{exp} \cdot w_{exp}}$$

**Step 6 — Pipe flow limit [kg/s]:**
$$\dot{m}_{discharge} = \min\!\left(\dot{m}_{thermo},\ \dot{m}_{max}\right)$$

When flow-limited, actual output power is less than the requested demand:
$$P_{output} = \dot{m}_{discharge} \cdot \eta_{exp} \cdot w_{exp} \leq P_{demand,req}$$

**Step 7 — Expander outlet temperature [K]:**
$$T_{out} = T_{in} \cdot r_{exp}^{\frac{n-1}{n}}$$

**Step 8 — Thermal power drawn from TES [W] (Near-Isothermal Mode only):**
$$\dot{Q}_{in,needed} = \frac{P_{output}}{\eta_{exp}} - \dot{m}_{discharge} \cdot c_p \cdot (T_{in} - T_{out}) \quad [\geq 0]$$

---

### 4.4 Cavern Dynamics (Mass-State Formulation)

The cavern is modelled using a **mass-state formulation**. The primary continuous state variable is $m_{air}$ (mass of air stored):

$$\boxed{\frac{dm_{air}}{dt} = \dot{m}_{charge} - \dot{m}_{discharge}} \quad \text{[kg/s]}$$

Cavern pressure is then recovered algebraically via the Ideal Gas Law:

$$p_{store} = \frac{m_{air} \cdot R_{air} \cdot T_{amb}}{V_{cavern}} \quad \text{[Pa]}$$

**Initial condition:** $m_{air}(0)$ = cushion gas mass at 1.01 bar

**Saturation:** $m_{air} \in [0,\ m_{air,max}]$

---

### 4.5 TES Dynamics Block

**MATLAB Function:** `tes_dynamics`

**Inputs:** $P_{thermal}$, $\dot{Q}_{in,needed}$

**Parameters:** $m_{tes}$, $c_{tes}$, $UA_{tes}$, $T_{amb}$, $T_{tes,initial}$, $T_{tes,max}$, $\Delta t$

**Outputs:** $\dot{T}_{tes}$ [K/s], $P_{thermal,loss}$ [W]

The TES is modelled as a **fixed-mass, variable-temperature** salt bed with **passive thermal decay** to the environment.

**Thermal capacitance:**
$$C_{tes} = m_{tes} \cdot c_{tes} \quad \text{[J/K]}$$

**Passive heat loss (Newton's law of cooling):**
$$\dot{Q}_{loss} = UA_{tes} \cdot \max(0,\ T_{tes} - T_{amb}) \quad \text{[W]}$$

where $UA_{tes} = U_{tes} \cdot A_{tes}$ [W/K] is the overall thermal conductance, computed from the insulation quality $U_{tes}$ [W/(m²·K)] and the TES surface area $A_{tes}$ (derived from $V_{tes}$ assuming an equivalent sphere).

**Net temperature rate:**

$$\boxed{\frac{dT_{tes}}{dt} = \frac{P_{thermal} - \dot{Q}_{in,needed} - \dot{Q}_{loss}}{m_{tes} \cdot c_{tes}}} \quad \text{[K/s]}$$

**Implementation note — persistent variable:** Because $\dot{Q}_{loss}$ depends on the current $T_{tes}$ but no feedback wire exists, the block internally tracks $T_{tes}$ using a persistent variable that is advanced by forward Euler at each fixed timestep $\Delta t = 300$ s, mirroring the Simulink integrator exactly (same step size and saturation clamp).

**$P_{thermal,loss}$ output:** Connect to a Scope block to monitor instantaneous heat loss to the environment throughout the simulation.

| Signal | Physical interpretation |
|---|---|
| $\dot{T}_{tes} > 0$ | TES heating (charging) |
| $\dot{T}_{tes} < 0$ | TES cooling (discharging or decaying) |
| $P_{thermal,loss} > 0$ | Active passive heat leak to environment |

**Initial condition:** $T_{tes}(0) = T_{amb}$ (cold start)

**Saturation:** $T_{tes} \in [T_{amb},\ T_{tes,max}]$

---

### 4.6 Transport Blocks

**Implementation:** Simple Gain blocks on the top-level canvas.

- **Charging (grid → compressor):** $P_{charge,actual} = \eta_{tran} \cdot P_{charge,raw}$
- **Discharging (expander → grid):** $P_{delivered} = \eta_{tran} \cdot P_{output,raw}$

---

## 5. Parameter Reference Table

All parameters are configured in `preprocessing.m` and `design_params/design_param1.m`.

### Physical Constants (`preprocessing.m`)

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `p_amb` | $p_{amb}$ | 101 325 | Pa | Atmospheric pressure |
| `T_amb` | $T_{amb}$ | 297 | K | Ambient temperature (≈ 24 °C) |
| `R_air` | $R_{air}$ | 287.05 | J/(kg·K) | Specific gas constant of air |
| `c_p` | $c_p$ | 1 005 | J/(kg·K) | Specific heat of air at const. pressure |
| `c_tes` | $c_{tes}$ | 880 | J/(kg·K) | Specific heat of TES salt bed |
| `n_poly` | $n_{poly}$ | 1.14 | — | Polytropic index (near-isothermal) |

### System Design Parameters (`design_params/design_param1.m`)

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `p_store_max` | $p_{store,max}$ | 100 | bar | Maximum safe cavern pressure |
| `V_cavern` | $V_{cavern}$ | 5 × 10⁶ | m³ | Volume of underground salt cavern |
| `V_tes` | $V_{tes}$ | 50 000 | m³ | TES tank volume |
| `T_tes_max` | $T_{tes,max}$ | 773 | K (500 °C) | Maximum TES operating temperature |
| `T_expand` | $T_{expand}$ | 373 | K (100 °C) | Target expansion inlet air temperature |
| `U_tes` | $U_{tes}$ | 0.3 | W/(m²·K) | TES wall heat transfer coefficient (insulation quality; range 0.1–1.0) |
| `D_pipe` | $D_{pipe}$ | — | m | Injection/extraction pipe diameter |
| `v_flow` | $v_{flow}$ | — | m/s | Maximum air flow velocity in pipe |

### Fixed Efficiencies and Limits (`preprocessing.m`)

| Parameter | Symbol | Value | Units | Description |
|---|---|---|---|---|
| `eta_tran` | $\eta_{tran}$ | 0.97 | — | Grid transmission efficiency |
| `eta_comp` | $\eta_{comp}$ | 0.833 | — | Compressor isentropic efficiency |
| `eta_exp` | $\eta_{exp}$ | 0.82 | — | Expander isentropic efficiency |
| `P_limit` | $P_{limit}$ | 300 | MW | Maximum compressor power draw |

### Derived Quantities (computed in `preprocessing.m`)

| Variable | Formula | Units | Description |
|---|---|---|---|
| `m_tes` | $\rho_{tes} \cdot V_{tes}$ | kg | TES salt bed mass |
| `A_pipe` | $\frac{\pi}{4} D_{pipe}^2$ | m² | Pipe cross-sectional area |
| `rho_amb` | $p_{amb} / (R_{air} T_{amb})$ | kg/m³ | Ambient air density |
| `mdot_max` | $\rho_{amb} \cdot A_{pipe} \cdot v_{flow}$ | kg/s | **Maximum pipe mass flow rate** — caps both `mdot_charge` and `mdot_discharge` |
| `r_tes_equiv` | $(3 V_{tes} / 4\pi)^{1/3}$ | m | Equivalent sphere radius of TES |
| `A_tes` | $4\pi r_{tes}^2$ | m² | TES outer surface area |
| `UA_tes` | $U_{tes} \cdot A_{tes}$ | W/K | **TES overall thermal conductance** — drives passive heat decay |

### Initial Conditions

| Parameter | Formula | Units | Description |
|---|---|---|---|
| `m_air_initial` | $1.01\ \text{bar} \cdot V_{cavern} / (R_{air} T_{amb})$ | kg | Initial cavern air mass (cushion gas) |
| `m_air_max` | $p_{store,max} \cdot V_{cavern} / (R_{air} T_{amb})$ | kg | Maximum cavern air mass |
| `T_tes_initial` | $T_{amb}$ | K | Initial TES temperature (cold start) |

### Simulink Outputs and Intermediate Variables

The following dynamic variables are calculated at each timestep and passed between blocks or logged to the workspace.

| Variable | Source Block | Units | Description |
|---|---|---|---|
| **`P_charge`** | Controller | W | Electrical power routed to the compressor |
| **`P_demand_req`** | Controller | W | Electrical power requested from the expander |
| **`P_sell`** | Controller | W | Excess surplus power sold to the grid |
| **`P_buy`** | Controller | W | Deficit power bought from the grid |
| **`mdot_charge`** | Compressor | kg/s | Actual air mass flow rate into the cavern (capped) |
| **`P_thermal`** | Compressor | W | Heat power captured and sent to TES |
| **`P_exergy`** | Compressor | W | Rate of pressure exergy stored in cavern |
| **`mdot_discharge`** | Expander | kg/s | Actual air mass flow rate out of the cavern (capped) |
| **`Q_in_needed`** | Expander | W | Heat power drawn from TES for near-isothermal expansion |
| **`P_output`** | Expander | W | Actual mechanical power generated by the expander |
| **`T_tes_dot`** | TES Dynamics | K/s | Rate of change of TES temperature |
| **`P_thermal_loss`** | TES Dynamics | W | Instantaneous passive heat leak to environment |
| **`m_air`** | Integrator (Cavern) | kg | Current mass of air in the cavern (state variable) |
| **`T_tes`** | Integrator (TES) | K | Current temperature of the TES salt bed (state variable) |
| **`p_store`** | Equation of State | Pa | Current cavern pressure derived from `m_air` |

---

## 6. Folder Structure

```
EST-model-main/
├── ICAES_R2025aa.slx              Main Simulink model
├── ICAES_R2025aa_experiment.slx   Experiment variant
├── preprocessing.m                InitFcn — loads data, computes all parameters
├── postprocessing.m               StopFcn — generates plots (muted by default)
├── design_params/
│   └── design_param1.m            Default design configuration
├── scripts/
│   ├── constants.m                SI unit dictionary (global `unit` map)
│   ├── loadSupplyData.m           Loads renewable supply CSV
│   └── loadDemandData.m           Loads demand CSV
├── data/
│   ├── Team38_supply.csv          Annual renewable supply profile [MW, 5-min]
│   └── Team38_demand.csv          Annual electrical demand profile [MW, 5-min]
└── old_baseline/                  Archived baseline results
```

---

## 7. Getting Started

### Prerequisites

- MATLAB R2022b or newer
- Simulink
- Stateflow (required for EML function blocks)

### Setup

1. Open MATLAB and set the **Current Folder** to `EST-model-main/`.
2. The `unit` global map is initialised by `scripts/constants.m`, which is called automatically via the model's `InitFcn`.
3. To switch design scenarios, edit the selector in `preprocessing.m`:
   ```matlab
   design_params_file = fullfile('design_params', 'design_param1.m');
   ```
   and duplicate `design_param1.m` as `design_param2.m`, etc.

---

## 8. Running the Model

1. Open `ICAES_R2025aa.slx` in Simulink.
2. Click **Run (▶)**.

The `InitFcn` automatically runs `preprocessing.m` to load data and populate the workspace. The `StopFcn` runs `postprocessing.m` after the simulation ends.

> **First-time tip:** If Simulink reports `mdot_max`, `UA_tes`, or other new parameters as missing, run `preprocessing` once manually in the MATLAB Command Window to populate the base workspace, then click Run.

---

## 9. Output and Post-Processing

Post-processing is **muted by default** (a `return` statement at line 5 of `postprocessing.m`). Remove it to enable automatic plotting on simulation stop.

### Standard Figures

| Figure | Layout | Description |
|---|---|---|
| **Figure 1** — System State | 2×2 subplot | Supply & Demand / Cavern Pressure / TES Temperature / Load Balancing (Sell/Buy) |
| **Figure 2** — I-CAES Flows | 2×1 subplot | Mass flow rates (charge/discharge) / Energy split during charging (Thermal → TES vs Exergy → Cavern) |
| **Figure 3** — Energy Distribution | 2×1 pie charts | Demand sources (Direct Supply / I-CAES / Bought) / Supply routing (Direct / To Storage / Sold) |
| **Figure 4** — Deficit Coverage | Time series | Grid deficit vs. I-CAES discharging power |

### Efficiency & Loss Breakdown

The efficiency block (in the Live Script or post-processing) computes:

| Metric | Formula | Description |
|---|---|---|
| Round-trip efficiency | $E_{ICAES} / E_{surplus}$ | Fraction of stored surplus recovered as discharge |
| Self-sufficiency | $(E_{direct} + E_{ICAES}) / E_{demand}$ | Fraction of demand met without buying |
| $L_{tran,in}$ | $E_{in}(1 - \eta_{tran})$ | Transmission loss (charging path) |
| $L_{comp}$ | $E_{in} \cdot \eta_{tran}(1 - \eta_{comp})$ | Compressor irreversibility loss |
| $L_{exp}$ | $E_{in} \cdot \eta_{tran}\eta_{comp}(1 - \eta_{exp})$ | Expander irreversibility loss |
| $L_{tran,out}$ | $E_{in} \cdot \eta_{tran}\eta_{comp}\eta_{exp}(1 - \eta_{tran})$ | Transmission loss (discharging path) |
| $L_{tes,decay}$ | $\sum UA_{tes}(T_{tes} - T_{amb}) \cdot \Delta t$ | **Passive TES heat leak to environment** (now simulated dynamically) |
| $L_{tes,stranded}$ | $m_{tes} c_{tes} \max(0,\, T_{tes,final} - T_{amb}) / \Delta t$ | Heat left in TES at year-end (never extracted) |

### Key Performance Metric

$$f_{ICAES} = \frac{E_{ICAES}}{E_{demand,total}} = \frac{\int P_{ICAES}(t)\,dt}{\int P_{demand}(t)\,dt}$$

This is the fraction of total annual electrical demand satisfied by the I-CAES system.

---

## 10. Model Change Log

| Version | Change | Impact |
|---|---|---|
| R2025aa | **Mass-state cavern formulation** — integrates $m_{air}$ instead of $p_{store}$; $p_{store}$ recovered via Ideal Gas Law | Improves physical rigour; enables real-gas extensions |
| R2025aa | **Pipe flow cap on $\dot{m}_{charge}$ and $\dot{m}_{discharge}$** — both capped at $\dot{m}_{max} = \rho_{amb} A_{pipe} v_{flow}$; actual power recomputed after capping | Prevents unphysical mass flow spikes at low cavern pressure |
| R2025aa | **TES passive thermal decay** — $\dot{Q}_{loss} = UA_{tes}(T_{tes} - T_{amb})$ subtracted from TES energy balance every timestep; tracked via persistent variable (no feedback wire) | Realistically models TES heat loss to environment; monitored via `P_thermal_loss` output |
| R2025aa | **`P_thermal_loss` output on TES block** — new output port for real-time monitoring of TES heat decay via Scope | Allows direct observation of instantaneous thermal decay power |
| R2025aa | **New design parameters** — `U_tes` (insulation quality), `D_pipe`, `v_flow` now drive both $\dot{m}_{max}$ and $UA_{tes}$ | All physical limits are design-variant and configurable per scenario |
