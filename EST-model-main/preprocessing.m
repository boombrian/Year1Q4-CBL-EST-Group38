% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

timeUnit   = 's';

supplyFile = "Team38_supply.csv";
supplyUnit = "MW";   % CSV header says [MW] — was incorrectly set to kW!

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team38_demand.csv";
demandUnit = "MW";   % CSV header says [MW] — was incorrectly set to kW!

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

p_store_max = 80 * unit("bar");                         % Maximum storage pressure in cavern
T_tes_max   = 373 * unit("K");                          % Maximum TES temperature (boiling point of water)

% TES parameters
% [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST]
U_tes = 2.0;                                            % Overall heat transfer coeff [W/(m^2·K)] (Typical for insulated tanks)
A_tes = 2500 * unit("m^2");                             % TES surface area [m^2] (Assuming a large cylindrical tank)
m_tes = 20000000 * unit("kg");                           % Mass of TES storage medium (water) [kg] (approx 20000 m^3)

% Pipe / flow parameters
% [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST]
D_pipe = 0.5 * unit("m");                               % Pipe diameter [m]
v_flow = 20 * unit("m")/unit("s");                      % Flow velocity [m/s]

% Cavern parameter
% [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST]
V_cavern = 5000000 * unit("m^3");                        % Cavern volume [m^3] (Based on Huntorf plant scale)

%% Initial Conditions

T_tes_initial    = T_amb;                               % Initial TES temperature [K]
p_store_initial  = 40 * unit("bar");                    % [AI-GENERATED PLACEHOLDER FOR FEASIBILITY TEST] Initial cavern pressure [Pa] (40 bar is mid-range)

%% Derived Quantities (computed from above)

A_pipe = pi/4 * D_pipe^2;                              % Pipe cross-sectional area [m^2]