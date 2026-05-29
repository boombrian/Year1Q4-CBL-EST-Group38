% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).

% --- MUTED: Remove the line below to re-enable automatic post-processing ---
return;
% ---------------------------------------------------------------------------
%
% Plots for the I-CAES thermodynamic model:
%   1) Supply & Demand
%   2) Cavern pressure
%   3) TES temperature
%   4) Load balancing (Buy/Sell)
%   5) Mass flow rates
%   6) Energy breakdown (thermal vs exergy)

close all;

%% Extract data — handle both Array and Timeseries formats
% Some To Workspace blocks may output Timeseries objects instead of plain
% arrays. This section converts everything to plain numeric arrays.

if isa(tout, 'timeseries'), tout = tout.Data; end
if isa(PSupply, 'timeseries'), PSupply = PSupply.Data; end
if isa(PDemand, 'timeseries'), PDemand = PDemand.Data; end
if isa(p_store_out, 'timeseries'), p_store_out = p_store_out.Data; end
if isa(T_tes_out, 'timeseries'), T_tes_out = T_tes_out.Data; end
if isa(PSell, 'timeseries'), PSell = PSell.Data; end
if isa(PBuy, 'timeseries'), PBuy = PBuy.Data; end

% Mass-state formulation: m_air_out is the primary state variable.
% Compute p_store_out from it if the user has not logged p_store separately.
has_mass = exist('m_air_out','var');
if has_mass
    if isa(m_air_out, 'timeseries'), m_air_out = m_air_out.Data; end
    if ~exist('p_store_out','var')
        p_store_out = m_air_out * R_air * T_amb / V_cavern;
    end
end
if exist('p_store_out','var') && isa(p_store_out, 'timeseries')
    p_store_out = p_store_out.Data;
end

% These may not exist yet if the To Workspace blocks are missing
has_flows = exist('mdot_charge_out','var') && exist('mdot_discharge_out','var');
has_energy = exist('P_thermal_out','var') && exist('P_exergy_out','var');

if has_flows
    if isa(mdot_charge_out, 'timeseries'), mdot_charge_out = mdot_charge_out.Data; end
    if isa(mdot_discharge_out, 'timeseries'), mdot_discharge_out = mdot_discharge_out.Data; end
end
if has_energy
    if isa(P_thermal_out, 'timeseries'), P_thermal_out = P_thermal_out.Data; end
    if isa(P_exergy_out, 'timeseries'), P_exergy_out = P_exergy_out.Data; end
end

%% Figure 1 — System state overview (2x2)
figure('Name','I-CAES System State','NumberTitle','off');

% --- Supply and Demand ---
subplot(2,2,1);
plot(tout/unit("day"), PSupply/unit("MW"), 'b'); hold on;
plot(tout/unit("day"), PDemand/unit("MW"), 'r');
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and Demand');
xlabel('Time [day]');
ylabel('Power [MW]');
legend('Supply','Demand');

% --- Cavern pressure ---
subplot(2,2,2);
plot(tout/unit("day"), p_store_out/unit("bar"), 'Color', [0.2 0.6 0.2]);
xlim([0 tout(end)/unit("day")]);
grid on;
title('Cavern Pressure');
xlabel('Time [day]');
ylabel('Pressure [bar]');

% --- TES Temperature ---
subplot(2,2,3);
plot(tout/unit("day"), T_tes_out - 273.15, 'Color', [0.85 0.33 0.1]);
xlim([0 tout(end)/unit("day")]);
grid on;
title('TES Temperature');
xlabel('Time [day]');
ylabel('Temperature [°C]');

% --- Load balancing ---
subplot(2,2,4);
plot(tout/unit("day"), PSell/unit("MW"), 'g'); hold on;
plot(tout/unit("day"), PBuy/unit("MW"), 'm');
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load Balancing');
xlabel('Time [day]');
ylabel('Power [MW]');
legend('Sell','Buy');

%% Figure 2 — Mass flow and energy (2x1)
if has_flows || has_energy
    figure('Name','I-CAES Flows','NumberTitle','off');

    if has_flows
        subplot(2,1,1);
        plot(tout/unit("day"), mdot_charge_out, 'b'); hold on;
        plot(tout/unit("day"), mdot_discharge_out, 'r');
        xlim([0 tout(end)/unit("day")]);
        grid on;
        title('Mass Flow Rates');
        xlabel('Time [day]');
        ylabel('Mass flow rate [kg/s]');
        legend('Charging','Discharging');
    end

    if has_energy
        subplot(2,1,2);
        plot(tout/unit("day"), P_thermal_out/unit("MW"), 'Color', [0.85 0.33 0.1]); hold on;
        plot(tout/unit("day"), P_exergy_out/unit("MW"),  'Color', [0.2 0.6 0.2]);
        xlim([0 tout(end)/unit("day")]);
        grid on;
        title('Energy Split during Charging');
        xlabel('Time [day]');
        ylabel('Power [MW]');
        legend('Thermal to TES','Exergy to Cavern');
    end
else
    warning('Mass flow / energy split variables not found in workspace. Skipping Figure 2.');
end

%% Figure 3 — Energy Sources and Supply Distribution (Pie Charts)
figure('Name','Energy Sources and Supply Distribution','NumberTitle','off');

% Calculate powers to satisfy demand
P_DirectSupply = min(PSupply, PDemand);
P_Deficit = max(0, PDemand - PSupply);
P_ICAES = max(0, P_Deficit - PBuy);

% Calculate powers from supply
P_Surplus = max(0, PSupply - PDemand);
P_ToStorage = max(0, P_Surplus - PSell);

% Calculate total energies (proportional to sum over time)
E_DirectSupply = sum(P_DirectSupply);
E_ICAES = sum(P_ICAES);
E_Bought = sum(PBuy);

E_ToStorage = sum(P_ToStorage);
E_Sold = sum(PSell);

% --- Left Pie Chart: Demand Energy Sources ---
subplot(1, 2, 1);
pie_data_demand = [E_DirectSupply, E_ICAES, E_Bought];
pie_labels_demand = {'Direct Supply', 'ICAES Discharge', 'Bought from Grid'};
% Remove zero entries from pie chart if any
idx_demand = pie_data_demand > 0;
if any(idx_demand)
    pct_demand = pie_data_demand(idx_demand) / sum(pie_data_demand(idx_demand)) * 100;
    active_labels_demand = pie_labels_demand(idx_demand);
    formatted_labels_demand = arrayfun(@(i) sprintf('%s (%.1f%%)', active_labels_demand{i}, pct_demand(i)), 1:length(pct_demand), 'UniformOutput', false);
    pie(pie_data_demand(idx_demand), formatted_labels_demand);
else
    pie([1], {'No Demand Data'});
end
title('Demand Energy Sources');

% --- Right Pie Chart: Supply Energy Distribution ---
subplot(1, 2, 2);
pie_data_supply = [E_DirectSupply, E_ToStorage, E_Sold];
pie_labels_supply = {'Direct to Demand', 'To Storage', 'Sold to Grid'};
% Remove zero entries from pie chart if any
idx_supply = pie_data_supply > 0;
if any(idx_supply)
    pct_supply = pie_data_supply(idx_supply) / sum(pie_data_supply(idx_supply)) * 100;
    active_labels_supply = pie_labels_supply(idx_supply);
    formatted_labels_supply = arrayfun(@(i) sprintf('%s (%.1f%%)', active_labels_supply{i}, pct_supply(i)), 1:length(pct_supply), 'UniformOutput', false);
    pie(pie_data_supply(idx_supply), formatted_labels_supply);
else
    pie([1], {'No Supply Data'});
end
title('Supply Energy Distribution');

%% Figure 4 — Deficit and Discharging Power Plot
figure('Name','Deficit vs. Discharging Power','NumberTitle','off');

plot(tout/unit("day"), P_Deficit/unit("MW"), 'r', 'LineWidth', 1.2); hold on;
plot(tout/unit("day"), P_ICAES/unit("MW"), 'b', 'LineWidth', 1.2);
xlim([0 tout(end)/unit("day")]);
grid on;
title('Deficit vs. Discharging Power');
xlabel('Time [day]');
ylabel('Power [MW]');
legend('Deficit', 'ICAES Discharging Power');