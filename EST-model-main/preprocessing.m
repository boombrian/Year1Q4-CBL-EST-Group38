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
T_amb = 300 * unit("K");                                % Ambient temperature
R_air = 287.05 * unit("J") / (unit("kg") * unit("K"));  % Specific gas constant of air
c_p   = 1005 * unit("J") / (unit("kg") * unit("K"));    % Specific heat capacity of air (const. pressure)
c_tes = 4184 * unit("J") / (unit("kg") * unit("K"));    % Specific heat capacity of TES medium (water)
n_poly = 1.1;                                           % Polytropic index (near-isothermal, 1.05-1.2)

%% System Design Parameters

eta_tran = 0.97;                                        % Transmission efficiency
eta_comp = 0.833;                                       % Compressor efficiency
eta_exp  = 0.85;                                        % [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST] Expander efficiency
P_limit  = 300 * unit("MW");                            % Maximum charging power draw from grid

p_store_max = 100 * unit("bar");                         % Maximum storage pressure in cavern
T_tes       = 372 * unit("K");                            % Constant TES water temperature (99°C, just below boiling)

% TES parameters — Variable-mass, constant-temperature model
% Water is stored at T_tes = 372 K (99°C). During charging, hot water is
% added to the tank. During discharging, hot water is consumed and discarded.
m_water_init = 0 * unit("kg");                           % Initial water mass in TES tank (empty at start)
m_tes_max    = 300000 * unit("kg");                       % Maximum water storage capacity [kg]

% Pipe / flow parameters
% [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST]
D_pipe = 0.5 * unit("m");                               % Pipe diameter [m]
v_flow = 20 * unit("m")/unit("s");                      % Flow velocity [m/s]

% Cavern parameter
V_cavern = 5000000 * unit("m^3");                        % Cavern volume [m^3] 

%% Initial Conditions

m_water_initial  = m_water_init;                         % Initial water mass in TES [kg] (starts empty)
p_store_initial  = 2 * unit("bar");                      % Initial cavern pressure (cushion gas)

%% Derived Quantities (computed from above)

A_pipe = pi/4 * D_pipe^2;                              % Pipe cross-sectional area [m^2]