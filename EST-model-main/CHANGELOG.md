# I-CAES Model Changelog

**Date:** 2026-05-16  
**Author:** Assisted by AI  
**Purpose:** Transform generic EST Simulink template → I-CAES thermodynamic simulation

---

## Files Modified

### `scripts/constants.m`
- **Added** SI units: `Pa`, `kPa`, `MPa`, `bar` (pressure), `K` (temperature), `kg` (mass), `m`, `m^2`, `m^3` (length/area/volume)
- **Unchanged**: all existing time, energy, and power units

### `preprocessing.m`
- **Removed** old dissipation coefficients: `aSupplyTransport`, `aInjection`, `bStorage`, `aExtraction`, `aDemandTransport`
- **Removed** old storage initial energy: `EStorageInitial`
- **Added** physical constants: `p_amb`, `T_amb`, `R_air`, `c_p`, `c_tes`, `n_poly` (=1.1)
- **Added** system design parameters: `eta_tran` (0.97), `eta_comp` (0.833), `eta_exp` (0.85), `P_limit` (300 MW), `p_store_max` (80 bar)
- **Added** TES/cavern/pipe placeholders (set to 0, to be filled): `U_tes`, `A_tes`, `m_tes`, `D_pipe`, `v_flow`, `V_cavern`
- **Added** initial conditions: `T_tes_initial`, `p_store_initial`
- **Added** derived quantity: `A_pipe`
- **Kept** data loading and simulation settings unchanged
- **Values** aligned with `1. text.tex` Section 3 (Finalizing Parameters)

### `postprocessing.m`
- **Replaced** old 4-subplot layout (energy, dissipation) with I-CAES specific plots:
  - Figure 1 (2×2): Supply/Demand, Cavern pressure [bar], TES temperature [K], Load balancing [MW]
  - Figure 2 (2×1): Mass flow rates [kg/s], Energy split (thermal vs exergy) [MW]
- **Removed** old pie chart plots (incompatible with new model)
- **Signal names** updated to match new `To Workspace` block names

---

## Files NOT Modified (require manual Simulink changes)

### `EST.slx` — Changes Needed
See `walkthrough.md` for detailed step-by-step instructions. Summary:

| Original Block | Action | Replacement |
|---|---|---|
| Transport from supply | **Delete** | Absorbed into Controller (η_tran) |
| Injection | **Replace** | Compressor (MATLAB Function) |
| Storage | **Replace** | Cavern (Sum + Gain + Integrator) + TES (MATLAB Function + Integrator) |
| Extraction | **Replace** | Expander (MATLAB Function) |
| Transport to demand | **Delete** | Absorbed into Expander (η_tran) |
| Controller | **Rewrite** | New mode-switching controller |

### New Simulink blocks to add:
- 4 MATLAB Function blocks (Controller, Compressor, TES, Expander)
- 2 Integrator blocks (Cavern pressure, TES temperature)
- 1 Sum block, 1 Gain block (Cavern mass flow → pressure)
- ~12 To Workspace blocks for logging

---

## Equation Mapping (1. text.tex → Simulink)

| Eq. | Description | Implemented In |
|---|---|---|
| 2.5 | P_net = P_supply − P_demand | Controller |
| 2.6 | P_eff = η_tran · min(P_net, P_limit) | Controller |
| 2.8 | Polytropic compression work | Compressor |
| 2.9 | Charging mass flow rate | Compressor |
| 2.10 | Thermal power to TES | Compressor |
| 2.11 | Pressure exergy rate | Compressor |
| 2.12 | TES heat loss (Newton's cooling) | TES dynamics |
| 2.13 | TES temperature ODE | TES dynamics + Integrator |
| 2.15 | Polytropic expansion work | Expander |
| 2.18 | Heat drawn from TES | Expander |
| 2.19 | Output power | Expander |

---

## Parameters Still TBD

| Parameter | Variable | Status |
|---|---|---|
| Cavern volume | `V_cavern` | Set to 0 — **must fill before running** |
| TES heat transfer coeff. | `U_tes` | Set to 0 |
| TES surface area | `A_tes` | Set to 0 |
| TES mass | `m_tes` | Set to 0 |
| Pipe diameter | `D_pipe` | Set to 0 |
| Flow velocity | `v_flow` | Set to 0 |
| Expander efficiency | `eta_exp` | Placeholder 0.85 |
| Initial cavern pressure | `p_store_initial` | Placeholder 10 bar |
