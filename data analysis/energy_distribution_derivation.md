# Mathematical Derivation of Energy Distribution in I-CAES

In an Isothermal Compressed Air Energy Storage (I-CAES) system, energy distribution occurs in two main phases: Compression (charging) and Expansion (discharging). The energy exists in two main forms within the storage system:
1. **Thermal Energy ($E_{thermal}$):** The heat stored in the Thermal Energy Storage (TES).
2. **Pressure Energy ($E_{pressure}$):** The mechanical exergy stored in the compressed air inside the cavern.

This document details the mathematical derivation of how energy enters these systems during charging and is extracted during discharging.

## 1. Compression Phase: Thermodynamic Work

Real compression with spray cooling follows a **polytropic process** with an index $n$. For near-isothermal compression, $n \approx 1.05$. The specific compression work $w_{comp}$ (in J/kg of air) is calculated as:

$$ w_{comp} = \frac{n}{n-1} R_{air} T_1 \left[ \left(\frac{P_2}{P_1}\right)^{\frac{n-1}{n}} - 1 \right] $$

where:
- $R_{air}$ is the specific gas constant for air ($\approx 287$ J/(kg·K))
- $T_1$ is the ambient temperature (e.g., $300$ K)
- $P_1$ is the ambient pressure (1 atm $\approx 101325$ Pa)
- $P_2$ is the target storage pressure (e.g., $80$ bar)

## 2. Compression Phase: Split Between Thermal and Internal Energy

According to the First Law of Thermodynamics for an open system (steady-flow), the input compression work is split between the change in the air's internal energy ($\Delta u$) and the heat removed ($q_{thermal}$):

$$ w_{comp} = \Delta u + q_{thermal} $$

The temperature of the air exiting the compressor is $T_2 = T_1 \left(\frac{P_2}{P_1}\right)^{\frac{n-1}{n}}$ and the internal energy change is $\Delta u = c_v (T_2 - T_1)$.

The fraction of the input compression work that becomes usable thermal energy is the thermal efficiency factor ($\eta_{thermal}$):

$$ \eta_{thermal} = \frac{q_{thermal}}{w_{comp}} = 1 - \frac{c_v (T_2 - T_1)}{w_{comp}} $$

## 3. Compression Phase: Pressure Energy (Mechanical Exergy)

The compressed air stores potential energy strictly in the form of pressure. Its ability to perform useful work corresponds to the reversible **isothermal work** of compression:

$$ w_{iso} = R_{air} T_1 \ln\left(\frac{P_2}{P_1}\right) $$

The fraction of input work successfully converted to stored mechanical exergy is the pressure efficiency factor ($\eta_{pressure}$):

$$ \eta_{pressure} = \frac{w_{iso}}{w_{comp}} $$

## 4. Extraction Phase (Discharging)

When there is an energy deficit ($P_{net} < 0$), energy is extracted from the storage system to meet demand. The turbine (expander) generates this power by expanding the compressed air.

According to the First Law of Thermodynamics for a control volume (turbine):

$$ \dot{Q} - \dot{W}_{out} = \dot{m} (h_2 - h_1) $$

Therefore, the work output is:

$$ \dot{W}_{out} = \dot{m} (h_1 - h_2) + \dot{Q} $$

where $\dot{Q}$ is the heat supplied from the TES to the air to maintain its temperature during expansion.

**Near-Isothermal Expansion Model:**
If the TES continuously supplies heat to the air, making the expansion process isothermal ($T_1 = T_2$), the change in enthalpy is zero ($h_1 - h_2 = c_p(T_1 - T_2) = 0$).

The specific work output (in J/kg) becomes entirely equal to the heat added from the TES:

$$ w_{iso,out} = q_{in} = R_{air} T \ln\left(\frac{P_2}{P_1}\right) $$

This output work is equal in magnitude and opposite in direction to the ideal isothermal compression work. 

To generate a required electrical energy output $E_{demand} = |P_{net}| \cdot \Delta t$, the turbine must perform equivalent mechanical work (assuming 100% turbine efficiency and no thermal decay). Because the process is isothermal, the heat extracted from the TES is exactly equal to the mechanical work produced:

$$ E_{thermal,out} = E_{demand} $$

Simultaneously, the expansion consumes the compressed air's flow exergy (pressure energy):

$$ E_{pressure,out} = E_{demand} $$

This means that to produce 1 unit of electrical energy, the system extracts exactly 1 unit of thermal energy from the TES and 1 unit of pressure energy from the cavern.

## 5. Total Energy Level Model

Given a net power profile $P_{net}$ over a timestep $\Delta t$, the real-time energy transfer is modeled as follows:

**For Surplus Power ($P_{net} > 0$, Charging):**
The compressors have a maximum global charging capacity $P_{comp,max}$ (e.g., 300 MW). The usable surplus power is therefore:
$$ P_{charge} = \min(P_{net}, P_{comp,max}) $$
$$ E_{in} = P_{charge} \cdot \Delta t $$
$$ \Delta E_{thermal} = E_{in} \cdot \eta_{thermal} $$
$$ \Delta E_{pressure} = E_{in} \cdot \eta_{pressure} $$

**For Deficit Power ($P_{net} < 0$, Discharging):**
$$ E_{out} = |P_{net}| \cdot \Delta t $$
$$ \Delta E_{thermal} = -E_{out} $$
$$ \Delta E_{pressure} = -E_{out} $$

By cumulatively integrating $\Delta E_{thermal}$ and $\Delta E_{pressure}$ over time, we obtain the absolute energy storage levels of the TES and the Cavern.
