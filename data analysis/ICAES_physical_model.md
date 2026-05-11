# I-CAES Physical & Mathematical Model

## 1. Energy Distribution During Compression

### 1.1 First Law of Thermodynamics for a Compression Process

When surplus electrical power $P_{net}$ drives a compressor, the First Law of Thermodynamics for an open system (steady-state flow) states:

$$\dot{W}_{comp} = \dot{m} \left( h_2 - h_1 \right) + \dot{Q}_{loss}$$

For an **ideal gas** compressed from state 1 (ambient) to state 2 (storage), the specific enthalpy change is:

$$h_2 - h_1 = c_p (T_2 - T_1)$$

The key question is: where does this compression work $\dot{W}_{comp}$ go?

---

### 1.2 Polytropic Compression — The Bridge Between Isothermal and Adiabatic

Real compression with spray cooling follows a **polytropic process** with index $n$:

$$P V^n = \text{constant}$$

| Process | $n$ | Heat exchange |
|---------|-----|---------------|
| Perfect isothermal | $n = 1$ | All work → heat released to TES |
| Real near-isothermal (I-CAES) | $n \approx 1.05$ | Most work → heat, small $\Delta U$ |
| Adiabatic (no cooling) | $n = \gamma = 1.4$ | All work → internal energy |

The **exit temperature** after polytropic compression from $P_1$ to $P_2$:

$$\boxed{T_2 = T_1 \left(\frac{P_2}{P_1}\right)^{\frac{n-1}{n}}}$$

For $n = 1.05$, $T_1 = 300\ \text{K}$, $P_2/P_1 = 80$:

$$T_2 = 300 \cdot 80^{\frac{0.05}{1.05}} \approx 300 \cdot 1.233 \approx 370\ \text{K}$$

---

### 1.3 Energy Split: Thermal vs. Pressure (Mechanical)

The **specific work** of polytropic compression (per kg of air) is:

$$w_{comp} = \frac{n}{n-1} R_{air} T_1 \left[ \left(\frac{P_2}{P_1}\right)^{\frac{n-1}{n}} - 1 \right]$$

This work divides into two parts via the First Law:

$$w_{comp} = \underbrace{\Delta u}_{= c_v (T_2 - T_1)} + \underbrace{q_{thermal}}_{= \text{heat to TES}}$$

where $c_v = c_p - R_{air}$ is the specific heat at constant volume.

**Solving for the thermal fraction:**

$$q_{thermal} = w_{comp} - c_v (T_2 - T_1)$$

For a **perfect isothermal process** ($n = 1$), $T_2 = T_1$, so $\Delta u = 0$ and:

$$q_{thermal,iso} = w_{comp,iso} = R_{air} T_1 \ln\left(\frac{P_2}{P_1}\right)$$

> **All compression work becomes heat** — 100% goes to TES. The compressed air stores only pressure-form energy (its internal energy is unchanged because $T$ is constant).

For the **near-isothermal case** ($n \approx 1.05$), a small fraction goes to increasing internal energy. The split is:

$$\frac{q_{thermal}}{w_{comp}} = 1 - \frac{c_v (T_2 - T_1)}{w_{comp}} \approx 0.90 \quad \text{(≈ 90% to TES)}$$

**Energy stored as compressed air (pressure form):**

The energy stored as mechanical exergy in the pressurised air (at constant cavern volume $V$, isothermal reference) is the **Helmholtz free energy** change:

$$\boxed{E_{air} = V \left[ P_{store} \ln\left(\frac{P_{store}}{P_{atm}}\right) - (P_{store} - P_{atm}) \right]}$$

This is the maximum work extractable by expanding the gas from $P_{store}$ back to $P_{atm}$ at constant temperature $T_{amb}$.

**Summary of energy split per timestep:**

$$\underbrace{P_{net} \cdot \Delta t}_{\text{electrical input}} \xrightarrow{\times(1 - a_{supply})(1-a_{inj})} \underbrace{E_{air}}_{\text{pressure form}} \quad + \quad \underbrace{Q_{TES} \approx E_{air}}_{\text{thermal form (TES)}}$$

Since for near-isothermal compression $Q_{thermal} \approx W_{comp}$, and the air's pressure energy equals the work done on it, the **ratio is approximately 1:1**. The simulation uses:

$$Q_{TES,in}(t) = E_{air,stored}(t)$$

---

## 2. Required Cavern Volume from Energy Storage Needs

### 2.1 Deriving the Helmholtz Energy Formula

A cavern of fixed volume $V$ contains ideal gas at pressure $P$ and temperature $T$. The maximum recoverable work by isothermal expansion to $P_{atm}$ is found by integrating the expansion work:

$$W_{exp} = \int_{V_{store}}^{V_{final}} P\, dV$$

Using the ideal gas law $PV = nRT = \text{const}$ (isothermal), $P = \frac{nRT}{V}$:

$$W_{exp} = nRT \int_{V_i}^{V_f} \frac{dV}{V} = nRT \ln\left(\frac{V_f}{V_i}\right)$$

Since $P_i V_i = P_f V_f$, we have $V_f/V_i = P_i/P_f = P_{store}/P_{atm}$. But the gas occupies a fixed cavern — what flows out is the **mass** of air. The correct expression for exergy stored in a fixed-volume vessel is the Helmholtz free energy change relative to the dead state $(P_{atm}, T_{amb})$:

$$E_{stored}(P) = V \left[ P \ln\left(\frac{P}{P_{atm}}\right) - (P - P_{atm}) \right]$$

**Derivation step by step:**

Starting from the ideal gas: $n = PV/(R_{air}T)$ moles at pressure $P$.

Exergy of a fixed-volume ideal gas reservoir:

$$\Phi = (U - U_0) - T_0(S - S_0) + P_0(V - V_0)$$

Since volume is fixed ($V = V_0$) and temperature is constant ($T = T_0$):

$$\Phi = T_0 \Delta S_{isothermal} = nR_{air}T_0 \ln\left(\frac{P}{P_{atm}}\right) = \frac{PV}{T_0} \cdot T_0 \ln\left(\frac{P}{P_{atm}}\right) - (P - P_{atm})V$$

$$\boxed{E_{stored}(P) = V \left[ P \ln\left(\frac{P}{P_{atm}}\right) - (P - P_{atm}) \right]}$$

### 2.2 Inverting to Find Required Volume

Given a target energy $E_{target}$ to store, the required cavern volume is:

$$\boxed{V_{cavern} = \frac{E_{target}}{P_{store} \ln\!\left(\dfrac{P_{store}}{P_{atm}}\right) - (P_{store} - P_{atm})}}$$

**Numerical example** for $E_{target} = 66{,}203\ \text{MWh}$, $P_{store} = 80\ \text{bar}$:

$$V_{cavern} = \frac{66203 \times 3.6 \times 10^9}{8\times10^6 \cdot \ln(79.0) - (8\times10^6 - 101325)} \approx 6.8 \times 10^6\ \text{m}^3$$

> **Note:** This formula accounts for the non-recoverable $P_{atm}$ baseline. The simpler formula $E = PV\ln(P/P_{atm})$ neglects the $(P - P_{atm})$ displacement work term and slightly overestimates recoverable energy.

---

## 3. How Isothermal Expansion Governs Discharge Power

### 3.1 The Expansion Work Equation

During discharge, compressed air expands from $P_{store}$ to $P_{atm}$ in the turbine. If the expansion is isothermal at temperature $T_{exp}$, the specific work output per kg of air is:

$$w_{exp} = R_{air}\, T_{exp} \ln\left(\frac{P_{store}}{P_{atm}}\right)$$

This is the **maximum isothermal work**. The key variable is $T_{exp}$, which depends on the heat source available.

### 3.2 The Role of TES vs. Environment

| Heat Source | $T_{exp}$ | Work output |
|------------|-----------|-------------|
| TES (stored compression heat) | $T_{hot} \approx 370\ \text{K}$ | $w_{TES} = R_{air} \cdot T_{hot} \cdot \ln(P_r)$ |
| Environment only | $T_{amb} = 300\ \text{K}$ | $w_{amb} = R_{air} \cdot T_{amb} \cdot \ln(P_r)$ |

where $P_r = P_{store}/P_{atm} = 80/1.013 \approx 79$.

The **boost ratio** from TES:

$$\boxed{\text{Boost} = \frac{w_{TES}}{w_{amb}} = \frac{T_{hot}}{T_{amb}} \approx \frac{370}{300} \approx 1.23}$$

TES provides **23% more work output** per kg of air released.

### 3.3 Why Environment-Only Is Not Zero But Is Limited

A common misconception is that without TES the discharge power is zero. This is incorrect. The environment **can** supply heat, but at a limited rate governed by the heat transfer coefficient of the expander:

$$\dot{Q}_{env} = U \cdot A \cdot (T_{amb} - T_{air})$$

As expansion proceeds adiabatically, $T_{air}$ drops rapidly below $T_{amb}$. The environment can only supply heat slowly — so in practice a fast-discharge turbine behaves **adiabatically**, not isothermally, reducing output power significantly.

In the model, the "environment-only" case corresponds to expansion at $T_{amb}$ (lower bound), and the discharge power is:

$$P_{discharge,env} = \dot{m} \cdot w_{amb} \cdot \eta_{extract} \cdot (1 - a_{demand})$$

### 3.4 Achievable Discharge Power at Partial TES

When the TES is partially depleted (fraction $f_{TES}$ of required heat available), the effective expansion temperature interpolates linearly:

$$T_{eff} = T_{amb} + f_{TES} \cdot (T_{hot} - T_{amb})$$

The achievable discharge power given a required demand $P_{demand}$ and effective temperature $T_{eff}$:

$$\dot{m}_{required} = \frac{P_{demand}}{\eta_{extract} \cdot (1 - a_{demand}) \cdot R_{air} \cdot T_{eff} \cdot \ln(P_r)}$$

The required TES heat supply rate:

$$\dot{Q}_{TES,needed} = \dot{m}_{required} \cdot c_p \cdot (T_{hot} - T_{amb})$$

If $\dot{Q}_{TES,needed} > \dot{Q}_{TES,available}$, the system operates at reduced power. The maximum deliverable power using all available TES heat:

$$\boxed{P_{max}(t) = \frac{Q_{TES}(t)}{\Delta t} \cdot \frac{T_{eff}}{T_{hot} - T_{amb}} \cdot \eta_{extract} \cdot (1 - a_{demand}) \cdot R_{air} \cdot \ln(P_r)}$$

### 3.5 Summary: Power Constraint Hierarchy

At each timestep, the achievable discharge power is limited by **whichever constraint binds first**:

$$P_{discharge}(t) = \min\left(P_{demand}(t),\quad \frac{E_{air}(t)}{\Delta t} \cdot \eta_{chain},\quad P_{TES-limited}(t)\right)$$

where $\eta_{chain} = (1 - a_{extraction})(1 - a_{demand}) \cdot \text{Boost}(f_{TES})$.

This means:
- **No air** → zero power regardless of TES
- **Full air + full TES** → maximum power with 23% boost
- **Full air + no TES** → power reduced by factor $T_{amb}/T_{hot} \approx 0.81$
- **Partial air or partial TES** → intermediate power
