% Design Parameters File — Configuration 1 (Default)
% -----------------------------------------------
% This file defines the key design parameters for the I-CAES system.
% Duplicate this file as design_param2.m, design_param3.m, etc. for new scenarios.
%
% Parameters defined here are loaded by preprocessing.m via run().

%% Air Storage (Cavern) Parameters

p_store_max = 100 * unit("bar");                        % Maximum storage pressure in cavern [Pa]
V_cavern    = 3600000 * unit("m^3");                    % Cavern volume [m³]

%% TES Parameters — Salt Bed Model
% Salt bed stores thermal energy as sensible heat.
% Mass is constant; temperature rises/falls during charge/discharge.

V_tes      = 20000 * unit("m^3");                       % TES tank volume (adjustable) [m³]
T_tes_max  = 773 * unit("K");                           % Max TES temperature (500°C, adjustable) [K]
T_expand   = 423 * unit("K");                           % Expansion inlet air temperature (100°C) [K]
U_tes      = 0.0;                                       % TES wall heat transfer coefficient [W/(m²·K)]
                                                        %   (insulation quality; typical range 0.1–1.0)
                                                        %   0.3 ≈ well-insulated industrial rock/salt bed

%% Pipe / Flow Parameters

D_pipe = 2 * unit("m");                               % Pipe diameter [m]
v_flow = 200* unit("m")/unit("s");                      % Flow velocity [m/s]
