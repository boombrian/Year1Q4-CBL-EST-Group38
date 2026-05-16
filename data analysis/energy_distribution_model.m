% energy_distribution_model.m
% Energy Distribution Model for I-CAES
% This script models both the compression (charging) and expansion (discharging)
% phases, tracking the real energy levels in the Thermal and Pressure storage systems.

clear; clc; close all;

%% 1. Thermodynamic Parameters
R_air = 287;        % Specific gas constant of air [J/(kg*K)]
c_p = 1005;         % Specific heat of air at constant pressure [J/(kg*K)]
c_v = c_p - R_air;  % Specific heat of air at constant volume [J/(kg*K)]
gamma = c_p / c_v;  % Heat capacity ratio

T1 = 300;           % Ambient temperature [K]
P1 = 101325;        % Ambient pressure [Pa] (approx 1 atm)
P2 = 80 * 1e5;      % Storage pressure [Pa] (80 bar)
n = 1.05;           % Polytropic index for near-isothermal compression

%% 2. Calculate Compression Specific Energies & Efficiencies (Charging)
% Polytropic compression work [J/kg]
w_comp = (n / (n - 1)) * R_air * T1 * ((P2 / P1)^((n - 1) / n) - 1);
% Exit temperature [K]
T2 = T1 * (P2 / P1)^((n - 1) / n);
% Change in internal energy [J/kg]
delta_u = c_v * (T2 - T1);
% Thermal energy transferred to TES (Heat) [J/kg]
q_thermal = w_comp - delta_u;
% Pressure energy (Isothermal mechanical exergy) [J/kg]
w_iso = R_air * T1 * log(P2 / P1);

% Ratios of input work during charging
eta_thermal = q_thermal / w_comp;
eta_pressure = w_iso / w_comp;

fprintf('--- Compression Thermodynamics (Charging) ---\n');
fprintf('Thermal energy fraction (eta_thermal): %.2f%%\n', eta_thermal * 100);
fprintf('Pressure energy fraction (eta_pressure): %.2f%%\n\n', eta_pressure * 100);

%% 3. Apply Model to Timeseries Data (Charging and Discharging)
fprintf('Loading data...\n');
data = readtable('Team38_net_produce.csv');
time_s = data.Time_s;
net_produce_MW = data.Net_Produce_MW;

% Calculate timestep (dt)
dt = zeros(size(time_s));
dt(2:end) = diff(time_s);
dt(1) = dt(2); % Assume first timestep matches the second

% Initialize energy level arrays (in MWh)
E_thermal_level_MWh = zeros(size(time_s));
E_pressure_level_MWh = zeros(size(time_s));

current_thermal_MWh = 0;
current_pressure_MWh = 0;

% Calculate energy levels based on charging vs discharging
max_charging_power_MW = 300; % 300 MW global charging limit

for i = 1:length(time_s)
    P = net_produce_MW(i);
    
    if P > 0
        % Charging Phase (Surplus Energy)
        % Apply compressor charging limit
        P_charge = min(P, max_charging_power_MW);
        E_in_MWh = (P_charge * dt(i)) / 3600; % MW*s -> MWh
        
        delta_thermal = E_in_MWh * eta_thermal;
        delta_pressure = E_in_MWh * eta_pressure;
        
    elseif P < 0
        % Discharging Phase (Extraction / Deficit Energy)
        % Using Isothermal Expansion Model: 100% efficient, no thermal decay
        E_out_MWh = (abs(P) * dt(i)) / 3600;
        
        delta_thermal = -E_out_MWh;
        delta_pressure = -E_out_MWh;
        
    else
        % No energy exchange
        delta_thermal = 0;
        delta_pressure = 0;
    end
    
    % Update levels, preventing them from dropping below zero
    current_thermal_MWh = max(0, current_thermal_MWh + delta_thermal);
    current_pressure_MWh = max(0, current_pressure_MWh + delta_pressure);
    
    % Store history
    E_thermal_level_MWh(i) = current_thermal_MWh;
    E_pressure_level_MWh(i) = current_pressure_MWh;
end

%% 4. Results and Visualization
[max_thermal, idx_max_thermal] = max(E_thermal_level_MWh);
[max_pressure, idx_max_pressure] = max(E_pressure_level_MWh);

fprintf('--- Simulation Summary ---\n');
fprintf('Final Thermal Energy Level: %.2f MWh\n', E_thermal_level_MWh(end));
fprintf('Final Pressure Energy Level: %.2f MWh\n', E_pressure_level_MWh(end));
fprintf('Minimum Thermal Level reached: %.2f MWh\n', min(E_thermal_level_MWh));
fprintf('Minimum Pressure Level reached: %.2f MWh\n', min(E_pressure_level_MWh));
fprintf('Maximum Thermal Level reached: %.2f MWh (at hour %.1f)\n', max_thermal, time_s(idx_max_thermal)/3600);
fprintf('Maximum Pressure Level reached: %.2f MWh (at hour %.1f)\n', max_pressure, time_s(idx_max_pressure)/3600);

% Plot Real Energy Levels
figure('Name', 'I-CAES Storage Levels', 'Position', [100, 100, 900, 500]);
plot(time_s / 3600, E_thermal_level_MWh, 'r-', 'LineWidth', 1.5); hold on;
plot(time_s / 3600, E_pressure_level_MWh, 'b--', 'LineWidth', 1.5);

% Plot Maximum points
plot(time_s(idx_max_thermal) / 3600, max_thermal, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
plot(time_s(idx_max_pressure) / 3600, max_pressure, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'HandleVisibility', 'off');

% Adding text labels for maximums
text(time_s(idx_max_thermal) / 3600, max_thermal, sprintf('  Max: %.0f MWh', max_thermal), 'Color', 'r', 'VerticalAlignment', 'bottom');
text(time_s(idx_max_pressure) / 3600, max_pressure, sprintf('  Max: %.0f MWh', max_pressure), 'Color', 'b', 'VerticalAlignment', 'bottom');

% Plot a zero line for reference
yline(0, 'k:', 'LineWidth', 1.5, 'HandleVisibility','off');

xlabel('Time (Hours)');
ylabel('Stored Energy Level (MWh)');
title('Real-Time Energy Levels in I-CAES System');
legend('Thermal Energy (TES)', 'Pressure Energy (Cavern)', 'Location', 'best');
grid on;
set(gca, 'FontSize', 12);
