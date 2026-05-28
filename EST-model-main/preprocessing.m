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

eta_tran = 0.97;                                        % Transmission efficiency
eta_comp = 0.833;                                       % Compressor efficiency
eta_exp  = 0.82;                                        % Expander efficiency
P_limit  = 300 * unit("MW");                            % Maximum charging power draw from grid

p_store_max = 100 * unit("bar");                         % Maximum storage pressure in cavern

% TES parameters — variable-temperature salt bed model
% Salt bed stores thermal energy as sensible heat. Mass is constant;
% temperature rises during charging and falls during discharging.
rho_tes    = 2160 * unit("kg") / unit("m^3");             % Density of salt bed [kg/m³]
V_tes      = 50000 * unit("m^3");                           % TES tank volume (adjustable) [m³]
m_tes      = rho_tes * V_tes;                             % TES bed mass [kg] (derived from volume)
T_tes_max  = 773 * unit("K");                             % Max TES temperature (500°C, adjustable) [K]
T_expand   = 373 * unit("K");                             % Expansion inlet air temperature [K]

% Pipe / flow parameters
% [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST]
D_pipe = 0.5 * unit("m");                               % Pipe diameter [m]
v_flow = 20 * unit("m")/unit("s");                      % Flow velocity [m/s]

% Cavern parameter
V_cavern = 5000000 * unit("m^3");                        % Cavern volume [m^3] 

%% Initial Conditions

T_tes_initial    = T_amb;                                % Initial TES temperature [K] (starts at ambient)
m_air_initial = (1.01 * unit("bar") * V_cavern) / (R_air * T_amb);  % Initial air mass [kg] (cushion gas at 2 bar)
m_air_max     = (p_store_max * V_cavern) / (R_air * T_amb);      % Maximum air mass [kg] (at p_store_max)

%% Derived Quantities (computed from above)

A_pipe = pi/4 * D_pipe^2;                              % Pipe cross-sectional area [m^2]