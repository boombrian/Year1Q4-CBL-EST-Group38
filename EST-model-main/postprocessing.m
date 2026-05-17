% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).
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

% --- TES temperature ---
subplot(2,2,3);
plot(tout/unit("day"), T_tes_out/unit("K"), 'Color', [0.85 0.33 0.1]);
xlim([0 tout(end)/unit("day")]);
grid on;
title('TES Temperature');
xlabel('Time [day]');
ylabel('Temperature [K]');

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