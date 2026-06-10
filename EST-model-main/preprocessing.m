% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

timeUnit   = 's';

supplyFile = "Team38_supply.csv";
supplyUnit = "MW"; 

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team38_demand.csv";
demandUnit = "MW";  

% load the demand data
Demand = loadDemandData(demandFile, timeUnit, demandUnit);

%% Simulation settings

deltat = 5*unit("min");
stopt  = min([Supply.Timeinfo.End, Demand.Timeinfo.End]);

%% Physical Constants

p_amb = 101325 * unit("Pa");                            % Atmospheric pressure
T_amb = 297 * unit("K");                                % Ambient temperature
R_air = 287.05 * unit("J") / (unit("kg") * unit("K"));  % Specific gas constant of air
c_p   = 1005 * unit("J") / (unit("kg") * unit("K"));    % Specific heat capacity of air (const. pressure)
c_tes = 880 * unit("J") / (unit("kg") * unit("K"));     % Specific heat capacity of TES medium (salt/rock)
n_poly = 1.14;                                           % Polytropic index (near-isothermal, 1.05-1.2)

%% System Design Parameters

% ---- Design Configuration Selector ----
% To switch design scenarios, change the number below to point to a
% different file in the design_params/ folder (e.g. 'design_param2.m').
design_params_file = fullfile('design_params', 'design_param1.m');
run(design_params_file);  % Loads: p_store_max, V_cavern, V_tes, T_tes_max,
                          %        T_expand, D_pipe, v_flow
% ----------------------------------------

% Input cable parameters (Transport from supply)
Cablevoltage = 345 * unit("kV");          % 345,000 V
Rprime       = 30*unit("mOhm") / unit("km");  % 0.00003 Ohm/meter
Cablelength  = 1000 * unit("km");          % 50,000 meters

% Fixed system efficiencies and limits (not design-variant)
eta_tran = 0.97;
eta_comp = 0.833;                                       % Compressor efficiency
eta_exp  = 0.82;                                        % Expander efficiency
P_limit  = 300 * unit("MW");                            % Maximum charging power draw from grid

% TES derived quantity (depends on V_tes from design file)
rho_tes = 2160 * unit("kg") / unit("m^3");               % Density of salt bed [kg/m³]
m_tes   = rho_tes * V_tes;                              % TES bed mass [kg] (derived from V_tes)

%% Initial Conditions

T_tes_initial    = T_amb;                                % Initial TES temperature [K] (starts at ambient)
m_air_initial = (1.01 * unit("bar") * V_cavern) / (R_air * T_amb);  % Initial air mass [kg] (cushion gas at 2 bar)
m_air_max     = (p_store_max * V_cavern) / (R_air * T_amb);      % Maximum air mass [kg] (at p_store_max)

%% Derived Quantities (computed from above)

A_pipe   = pi/4 * D_pipe^2;                              % Pipe cross-sectional area [m^2]
rho_amb  = p_amb / (R_air * T_amb);                      % Ambient air density [kg/m³]  (ideal gas)
mdot_max = rho_amb * A_pipe * v_flow;                    % Max pipe mass flow rate [kg/s]  (= ρ·A·v_max)

% TES thermal decay: passive heat loss to environment
% Surface area derived from V_tes assuming an equivalent sphere (minimum surface / volume ratio).
% Real geometry will have larger A_tes; scale U_tes down if tank is well-buried / insulated.
r_tes_equiv = (3 * V_tes / (4 * pi))^(1/3);             % Equivalent sphere radius [m]
A_tes       = 4 * pi * r_tes_equiv^2;                   % TES outer surface area [m²]
UA_tes      = U_tes * A_tes;                             % Overall heat loss conductance [W/K]