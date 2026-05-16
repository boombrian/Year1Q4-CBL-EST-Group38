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
figure('Name','I-CAES Flows','NumberTitle','off');

% --- Mass flow rates ---
subplot(2,1,1);
plot(tout/unit("day"), mdot_charge_out, 'b'); hold on;
plot(tout/unit("day"), mdot_discharge_out, 'r');
xlim([0 tout(end)/unit("day")]);
grid on;
title('Mass Flow Rates');
xlabel('Time [day]');
ylabel('Mass flow rate [kg/s]');
legend('Charging','Discharging');

% --- Energy split ---
subplot(2,1,2);
plot(tout/unit("day"), P_thermal_out/unit("MW"), 'Color', [0.85 0.33 0.1]); hold on;
plot(tout/unit("day"), P_exergy_out/unit("MW"),  'Color', [0.2 0.6 0.2]);
xlim([0 tout(end)/unit("day")]);
grid on;
title('Energy Split during Charging');
xlabel('Time [day]');
ylabel('Power [MW]');
legend('Thermal → TES','Exergy → Cavern');