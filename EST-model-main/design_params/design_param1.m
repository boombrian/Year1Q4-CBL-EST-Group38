% Design Parameters File — Configuration 1 (Default)
% -----------------------------------------------
% This file defines the key design parameters for the I-CAES system.
% Duplicate this file as design_param2.m, design_param3.m, etc. for new scenarios.
%
% Parameters defined here are loaded by preprocessing.m via run().

%% Air Storage (Cavern) Parameters

p_store_max = 100 * unit("bar");                        % Maximum storage pressure in cavern [Pa]
V_cavern    = 5000000 * unit("m^3");                    % Cavern volume [m³]

%% TES Parameters — Salt Bed Model
% Salt bed stores thermal energy as sensible heat.
% Mass is constant; temperature rises/falls during charge/discharge.

V_tes      = 50000 * unit("m^3");                       % TES tank volume (adjustable) [m³]
T_tes_max  = 773 * unit("K");                           % Max TES temperature (500°C, adjustable) [K]
T_expand   = 373 * unit("K");                           % Expansion inlet air temperature (100°C) [K]

%% Pipe / Flow Parameters

D_pipe = 50 * unit("m");                               % Pipe diameter [m]
v_flow = 2000 * unit("m")/unit("s");                      % Flow velocity [m/s]
