# Legacy & Alternative Simulink Models

This directory (`other_simulink_models/`) contains archived legacy versions and forward/backward-compatibility models of the **Near-Isothermal Compressed Air Energy Storage (I-CAES)** Simulink simulation. 

These models document the iterative architectural evolution of the project from early baseline single-integrator models to full multi-stage mass-state formulations, and provide cross-version compatibility testbeds for different MATLAB/Simulink releases (R2022a through R2025b).

---

## 1. Directory Structure & File Inventory

```
other_simulink_models/
├── EST.slx                 # Original legacy model 1 (R2022a/R2023a format)
├── est_system.slx          # Intermediate prototype model 2 with early modular block setup
├── est_system_r2025b.slx   # Prototype model updated and compiled for Simulink R2025b
├── ICAES_R2025b.slx        # Pre-release version b of the main I-CAES Simulink model
└── ICAES_R2025b.slxc       # Simulink cache file for fast code generation and target compilation
```

---

## 2. Background Theory & Architectural Evolution

### 2.1 Pressure-State vs. Mass-State Cavern Dynamics

Early legacy models (`EST.slx`, `est_system.slx`) implemented cavern pressure storage as a **direct pressure integrator**:

$$\frac{dp_{\text{store}}}{dt} = f(P_{\text{charge}}, P_{\text{demand}})$$

While computationally simpler, direct pressure integration neglects real mass continuity and compressible flow limits.

The modern architecture (in `ICAES_R2025b.slx` and `EST-model-main/ICAES_R2025aa.slx`) replaces this with a **mass-state formulation**:

$$\frac{dm_{\text{air}}}{dt} = \dot{m}_{\text{charge}} - \dot{m}_{\text{discharge}} \quad [\text{kg/s}]$$

Cavern pressure is then calculated algebraically at each timestep via the Ideal Gas Equation of State (EoS):

$$p_{\text{store}} = \frac{m_{\text{air}} R_{\text{air}} T_{\text{amb}}}{V_{\text{cavern}}} \quad [\text{Pa}]$$

This shift enables physical mass flow rate caps ($\dot{m}_{\text{max}} = \rho_{\text{amb}} A_{\text{pipe}} v_{\text{flow}}$) to prevent unphysical flow spikes when cavern pressure is low.

---

### 2.2 Thermal Energy Storage (TES) Model Progression

| Feature | Legacy Models (`EST.slx`) | Compatibility Models (`ICAES_R2025b.slx`) |
|---|---|---|
| **TES Representation** | Fixed energy efficiency multiplier ($\eta_{\text{TES}} = \text{const}$) | Variable-mass differential thermal energy balance |
| **Passive Thermal Decay** | Ignored ($U_{\text{tes}} = 0$) | Newton's Law of Cooling heat loss: $\dot{Q}_{\text{loss}} = UA_{\text{tes}} (T_{\text{tes}} - T_{\text{amb}})$ |
| **Expansion Fallback** | Single polytropic mode | Dual-mode: Polytropic ($n = 1.14$) when $T_{\text{tes}} \ge T_{\text{expand}}$, Adiabatic ($n = \gamma = 1.4$) when depleted |

The differential equation for TES temperature rate of change $\dot{T}_{\text{tes}}$ encoded in EML charts is:

$$\frac{dT_{\text{tes}}}{dt} = \frac{P_{\text{thermal}} - \dot{Q}_{\text{in,needed}} - UA_{\text{tes}} \max(0, T_{\text{tes}} - T_{\text{amb}})}{m_{\text{tes}} c_{\text{tes}}} \quad [\text{K/s}]$$

---

### 2.3 Simulink File Formats & Version Compatibility

- **`.slx` files**: Zip-compressed XML representation of Simulink models. `.slx` files created in newer MATLAB versions (e.g., R2025a/b) cannot be opened directly in older releases (e.g., R2021b) without export downscaling.
- **`.slxc` files**: Simulink cache files holding pre-compiled target code, acceleration artifacts, and simulation target data.
- **`ICAES_R2025b.slx`**: Retains identical mathematical block structures to `EST-model-main/ICAES_R2025aa.slx`, but is pre-saved for users testing on MATLAB R2025b prerelease / future builds.

---

## 3. Usage Guidance

### 3.1 When to Use These Models

- **`EST.slx` & `est_system.slx`**: Use for baseline comparison to evaluate how the new mass-state cavern dynamics and passive TES thermal decay impact annual round-trip efficiency and grid load satisfaction relative to earlier baseline assumptions.
- **`ICAES_R2025b.slx`**: Use if running MATLAB R2025b or newer where version conversion prompts for R2025aa models occur.

### 3.2 Running Legacy Models

1. Launch MATLAB.
2. Set the **Current Folder** to `other_simulink_models/`.
3. Before running `EST.slx` or `ICAES_R2025b.slx`, ensure model parameters are loaded in the MATLAB workspace. If required variables are missing, execute the preprocessing script from `EST-model-main`:
   ```matlab
   run('../EST-model-main/preprocessing.m');
   ```
4. Open the desired `.slx` model in Simulink.
5. Press **Run (▶)**.

---

## 4. Model Comparison Summary

| Model | Cavern Formulation | TES Model | Max Flow Cap | Target MATLAB Release |
|---|---|---|---|---|
| `EST.slx` | Pressure Integrator | Fixed % Efficiency | No | R2022a |
| `est_system.slx` | Modular Pressure Integrator | Simple Thermal Reservoir | No | R2022b |
| `est_system_r2025b.slx` | Modular Pressure Integrator | Simple Thermal Reservoir | No | R2025b |
| `ICAES_R2025b.slx` | Mass-State ($m_{\text{air}}$) | Fixed-Mass Salt Bed + Passive Decay | Yes ($\dot{m}_{\text{max}}$) | R2025b |
| **`EST-model-main/ICAES_R2025aa.slx`** *(Primary)* | **Mass-State ($m_{\text{air}}$)** | **Fixed-Mass Salt Bed + Passive Decay** | **Yes ($\dot{m}_{\text{max}}$)** | **R2025a / R2022b+** |
