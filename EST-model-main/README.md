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
| Adiabatic (Isentropic) | $n = \gamma$ | No heat exchange ($Q = 0$) |
| Isobaric | $n = 0$ | Constant pressure |
| Isochoric | $n = \infty$ | Constant volume |

For air modelled as an ideal diatomic gas:
$$\gamma = \frac{c_p}{c_v} = \frac{c_p}{c_p - R_{air}}$$

The model uses a design polytropic index $n_{poly}$ for compression and for near-isothermal expansion (when TES water is available). This is achievable in practice through staged compression with intercooling or by injecting liquid water mist into the compression chamber. When TES water is exhausted, the expander falls back to adiabatic behaviour ($n = \gamma$).

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
          Fixed-mass salt bed; outputs dT_tes/dt.
          Integrated by a Simulink Integrator block with saturation [T_amb, T_tes_max].
```

### 3.2 Signal Flow and State Variables

The model has **two continuous state variables** integrated by Simulink integrators:

| State Variable | Symbol | Units | Description |
|---|---|---|---|
| Cavern Air Mass | $m_{air}$ | kg | Total mass of air stored in the cavern |
| TES Temperature | $T_{tes}$ | K | Current average temperature of the salt bed TES |

All other quantities (mass flow rates, power flows, temperatures) are algebraic functions computed at each timestep from the states and inputs. Signal flow proceeds in this order each timestep:

$$[\text{Supply, Demand}] \xrightarrow{\text{Transport}} \xrightarrow{\text{Controller}} [P_{charge}, P_{demand,req}] \xrightarrow{\text{Compressor / Expander}} [\dot{m}_{charge}, P_{thermal}, \dot{m}_{discharge}, \dot{Q}_{in}] \xrightarrow{\text{Integrators}} [m_{air}, T_{tes}] \xrightarrow{\text{EoS}} [p_{store}]$$

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

Cavern depletion guard — if the cavern pressure is at or below a specified safety margin above ambient, the system cannot expand air and must buy from the grid:
$$\text{if } p_{store} \leq f_{margin} \cdot p_{amb}: \quad P_{buy} = P_{demand,req}, \quad P_{demand,req} = 0$$

where $f_{margin}$ is the safety pressure margin factor.

---

### 4.2 Compressor Block (Injection System)

**MATLAB Function:** `compressor`

**Inputs:** $P_{charge}$, $p_{store}$, $\eta_{comp}$, $n_{poly}$, $R_{air}$, $c_p$, $T_{amb}$, $p_{amb}$

**Outputs:** $\dot{m}_{charge}$, $P_{thermal}$, $P_{exergy}$

#### Real-World Compressor Architecture

In practical large-scale Compressed Air Energy Storage plants, the compression from atmospheric pressure to cavern storage pressure (which can exceed 70–100 bar) is never performed in a single step. Real systems use a **multi-stage compression train**: a sequence of individual compressor stages, each handling a portion of the total pressure rise, connected by **intercoolers** between stages. After each stage, the hot compressed air is cooled back towards ambient temperature before entering the next stage. In near-isothermal CAES designs, this intercooling heat is not wasted — it is captured by heat exchangers and transferred into a Thermal Energy Storage (TES) system for later use during discharge.

This multi-stage approach is used for two fundamental reasons. First, compressing gas in smaller pressure steps with cooling in between requires significantly less total shaft work than compressing the same gas from start to finish in one step. Second, limiting the temperature rise inside each stage protects the mechanical components and reduces thermal stress. In practice, large I-CAES systems at the 100–300 MW scale would typically employ three to five compression stages with dedicated intercoolers and TES heat exchangers between each one.

#### Model Simplification and Justification

Modelling each compression stage individually would require specifying the pressure ratio, inlet temperature, efficiency, and heat exchanger effectiveness for every stage — a level of detail that introduces many uncertain parameters without meaningfully changing the annual energy balance results at the system scale.

This model therefore represents the entire multi-stage compression train as a **single equivalent polytropic process**. This simplification is thermodynamically justified because the net effect of multi-stage compression with intercooling is precisely what a polytropic index lower than the adiabatic index represents: a compression process that exchanges heat with its surroundings along the way. By choosing a polytropic index $n_{poly}$ between 1 (isothermal) and $\gamma \approx 1.4$ (adiabatic), the model directly captures the degree of heat exchange achieved by the intercooling system, without needing to resolve the internal stage-by-stage details. A value of $n_{poly} = 1.1$, as used in this model, is consistent with a well-designed multi-stage compression train operating close to isothermal conditions.

This approach is standard practice in system-level energy storage models and has been validated against more detailed multi-stage models in the literature. It allows the simulation to correctly predict mass flow rates, compressor outlet temperatures, thermal power delivered to the TES, and annual energy balances, while keeping the model tractable and the parameter set well-defined.

The compressor converts electrical power into compressed air mass flow. All processes use the polytropic index $n_{poly}$.

**Step 1 — Pressure ratio:**
$$r = \frac{p_{store}}{p_{amb}} \qquad [r \geq r_{guard} \text{ (numerical guard)}]$$

where $r_{guard}$ is a numerical floor factor just above unity.

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

**Inputs:** $P_{demand,req}$, $p_{store}$, $T_{tes,state}$, $\eta_{exp}$, $n_{poly}$, $R_{air}$, $c_p$, $p_{amb}$, $T_{amb}$, $T_{expand}$

**Outputs:** $\dot{m}_{discharge}$, $\dot{Q}_{in,needed}$, $P_{output}$

The expander implements a **dual-mode polytropic expansion** process. The polytropic index $n$ and the expansion inlet temperature $T_{in}$ are dynamically set depending on whether the TES salt bed temperature is high enough to preheat the air to the target expansion temperature $T_{expand} = 373$ K.

**Step 1 — Required shaft power:**
$$P_{discharge} = P_{demand,req} \quad \text{[W]}$$

**Step 2 — Expansion pressure ratio:**
$$r_{exp} = \frac{p_{amb}}{p_{store}} \qquad [r_{exp} < 1; \text{ return if } r_{exp} \geq 1]$$

**Step 3 — Adiabatic index of air:**
$$\gamma = \frac{c_p}{c_p - R_{air}}$$

**Step 4 — Dynamic mode selection based on TES state:**

$$\begin{cases}
n = n_{poly}, \quad T_{in} = T_{expand} & \text{if } T_{tes,state} \geq T_{expand} \quad \textbf{(Near-Isothermal Mode)} \\
n = \gamma, \quad T_{in} = T_{amb} & \text{if } T_{tes,state} < T_{expand} \quad \textbf{(Adiabatic Fallback Mode)}
\end{cases}$$

**Step 5 — Polytropic expansion specific work [J/kg]:**
$$w_{exp} = \frac{n}{n-1} \cdot R_{air} \cdot T_{in} \cdot \left(1 - r_{exp}^{\frac{n-1}{n}}\right) \quad \text{[J/kg]}$$

**Step 6 — Discharge mass flow rate [kg/s]:**
$$\dot{m}_{discharge} = \frac{P_{discharge}}{\eta_{exp} \cdot w_{exp}} \quad \text{[kg/s]}$$

**Step 7 — Expander outlet temperature [K]:**
$$T_{out} = T_{in} \cdot r_{exp}^{\frac{n-1}{n}} \quad \text{[K]}$$

**Step 8 — Thermal power drawn from TES [W]:**

In Near-Isothermal Mode ($T_{tes,state} \geq T_{expand}$), the TES must supply heat to the turbine to sustain the polytropic temperature profile. This is derived from the SFEE applied to the expander:
$$\dot{Q}_{in,needed} = \frac{P_{discharge}}{\eta_{exp}} - \dot{m}_{discharge} \cdot c_p \cdot (T_{in} - T_{out}) \quad \text{[W]}$$
$$\dot{Q}_{in,needed} = \max(\dot{Q}_{in,needed},\ 0) \quad \text{(non-negativity guard)}$$

In Adiabatic Fallback Mode ($T_{tes,state} < T_{expand}$): $\dot{Q}_{in,needed} = 0$

**Step 9 — Net mechanical power output [W]:**
$$P_{output} = P_{discharge} \quad \text{[W]}$$

---

### 4.4 Cavern Dynamics (Mass-State Formulation)

**Implementation:** Simulink Integrator block fed by the algebraic output of the Compressor and Expander blocks, followed by an Equation of State (EoS) block.

To improve physical rigour and enable future real-gas extensions, the cavern is modelled using a **mass-state formulation**. The primary continuous state variable is the mass of air in the cavern ($m_{air}$).

The rate of mass change is the net difference in mass flow rates:

$$\boxed{\frac{dm_{air}}{dt} = \dot{m}_{charge} - \dot{m}_{discharge}} \quad \text{[kg/s]}$$

**Initial condition:** $m_{air}(0) = m_{air,initial}$ (derived from initial cushion gas pressure)

**Saturation:** $m_{air} \in [0,\ m_{air,max}]$

The cavern pressure $p_{store}$ is then computed algebraically from the state variable $m_{air}$ using the Ideal Gas Law:

$$p_{store} = \frac{m_{air} \cdot R_{air} \cdot T_{amb}}{V_{cavern}} \quad \text{[Pa]}$$

The Simulink integrator clamps $m_{air}$ at the maximum safe air mass $m_{air,max}$. The controller also prevents charging when the computed $p_{store} \geq p_{store,max}$.

---

### 4.5 TES Dynamics Block

**MATLAB Function:** `tes_dynamics`

**Inputs:** $P_{thermal}$, $\dot{Q}_{in,needed}$

**Parameters:** $m_{tes}$, $c_{tes}$

**Output:** $\dot{T}_{tes}$ [K/s]

The TES is modelled as a **fixed-mass, variable-temperature** salt bed reservoir. The salt bed has a constant mass $m_{tes}$ derived from the user-specified tank volume and salt density ($m_{tes} = \rho_{tes} \cdot V_{tes}$). The thermal energy stored is tracked through the bed temperature $T_{tes}$, which rises when compression heat is deposited and falls when thermal energy is drawn for expansion preheating.

The thermal capacitance of the salt bed is:
$$C_{tes} = m_{tes} \cdot c_{tes} \quad \text{[J/K]}$$

The net power balance across the TES determines the rate of temperature change:

$$\boxed{\frac{dT_{tes}}{dt} = \frac{P_{thermal} - \dot{Q}_{in,needed}}{m_{tes} \cdot c_{tes}}} \quad \text{[K/s]}$$

| Sign of $\dot{T}_{tes}$ | Physical interpretation |
|---|---|
| $\dot{T}_{tes} > 0$ | TES is heating up (charging) |
| $\dot{T}_{tes} < 0$ | TES is cooling down (discharging) |
| $\dot{T}_{tes} = 0$ | Thermal equilibrium or no active energy exchange |

**Initial condition:** $T_{tes}(0) = T_{tes,initial}$ (typically $T_{amb}$, cold start)

**Saturation:** $T_{tes} \in [T_{amb},\ T_{tes,max}]$

The Simulink integrator enforces lower saturation at $T_{amb}$ and upper saturation at $T_{tes,max}$. The TES can only supply heat to the expander when $T_{tes} \geq T_{expand}$ (373 K).

---

### 4.6 Transport Blocks

**Implementation:** Simple Gain blocks on the top-level canvas.

Transmission losses are applied directly between the grid and the internal I-CAES components using the efficiency factor $\eta_{tran}$.

- **Charging (From grid to compressor):** $P_{charge,actual} = \eta_{tran} \cdot P_{charge,raw}$
- **Discharging (From expander to grid):** $P_{delivered} = \eta_{tran} \cdot P_{output,raw}$

---

## 5. Parameter Reference Table

All parameters are configured in `preprocessing.m` using the SI unit library in `scripts/constants.m`.

### Physical Constants

| Parameter | Symbol | Units | Description |
|---|---|---|---|
| `p_amb` | $p_{amb}$ | Pa | Atmospheric pressure |
| `T_amb` | $T_{amb}$ | K | Ambient temperature |
| `R_air` | $R_{air}$ | J/(kg·K) | Specific gas constant of air |
| `c_p` | $c_p$ | J/(kg·K) | Specific heat of air at constant pressure |
| `c_tes` | $c_{tes}$ | J/(kg·K) | Specific heat capacity of TES salt bed |
| `n_poly` | $n_{poly}$ | — | Polytropic index (compression and near-isothermal expansion) |

### System Design Parameters

| Parameter | Symbol | Units | Description |
|---|---|---|---|
| `eta_tran` | $\eta_{tran}$ | — | Transmission/grid interface efficiency |
| `eta_comp` | $\eta_{comp}$ | — | Compressor isentropic efficiency |
| `eta_exp` | $\eta_{exp}$ | — | Expander isentropic efficiency |
| `P_limit` | $P_{limit}$ | W | Maximum compressor input power from grid |
| `p_store_max` | $p_{store,max}$ | Pa | Maximum safe cavern operating pressure |
| `V_cavern` | $V_{cavern}$ | m³ | Volume of underground salt cavern |
| `rho_tes` | $\rho_{tes}$ | kg/m³ | Density of TES salt bed material |
| `V_tes` | $V_{tes}$ | m³ | TES tank volume (adjustable design parameter) |
| `m_tes` | $m_{tes}$ | kg | TES bed mass (derived: $\rho_{tes} \cdot V_{tes}$) |
| `T_tes_max` | $T_{tes,max}$ | K | Maximum TES operating temperature (adjustable) |
| `T_expand` | $T_{expand}$ | K | Target air inlet temperature for expansion (373 K) |

### Initial Conditions

| Parameter | Symbol | Units | Description |
|---|---|---|---|
| `m_air_initial` | $m_{air}(0)$ | kg | Initial cavern air mass (derived from cushion gas) |
| `T_tes_initial` | $T_{tes}(0)$ | K | Initial TES salt bed temperature |

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
