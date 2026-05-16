% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

timeUnit   = 's';

supplyFile = "Team38_supply.csv";
supplyUnit = "kW";

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team38_demand.csv";
demandUnit = "kW";

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
eta_exp  = 0.85;                                        % Expander efficiency (TODO: finalise)
P_limit  = 300 * unit("MW");                            % Maximum charging power draw from grid

p_store_max = 80 * unit("bar");                         % Maximum storage pressure in cavern

% TES parameters (TODO: fill in actual values)
U_tes = 0;    % Overall heat transfer coefficient [W/(m^2·K)]
A_tes = 0;    % TES surface area [m^2]
m_tes = 0;    % Mass of TES storage medium [kg]

% Pipe / flow parameters (TODO: fill in actual values)
D_pipe = 0;   % Pipe diameter [m]
v_flow = 0;   % Flow velocity [m/s]

% Cavern parameter (TODO: fill in actual value)
V_cavern = 0; % Cavern volume [m^3]

%% Initial Conditions

T_tes_initial    = T_amb;                               % Initial TES temperature [K]
p_store_initial  = 10 * unit("bar");                    % Initial cavern pressure [Pa] (TODO: finalise)

%% Derived Quantities (computed from above)

A_pipe = pi/4 * D_pipe^2;                              % Pipe cross-sectional area [m^2]