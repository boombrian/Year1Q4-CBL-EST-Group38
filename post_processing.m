%% Pneumatic Data Multi-File Post-Processing Script
clear; clc; close all;

%% 1. File Setup
% List your experimental text files here
fileNames = {
    'pneumatic_data.txt'
};

numRuns = length(fileNames);
if numRuns == 0
    error('Please add your text filenames to the fileNames cell array.');
end

%% 2. Load and Interpolate Data
allRunsData = cell(1, numRuns);

for i = 1:numRuns
    fileID = fopen(fileNames{i}, 'r');
    if fileID == -1
        error('Could not open file: %s', fileNames{i});
    end
    
    % Read columns: Time (ms), Voltage (V), Pressure (MPa)
    dataScan = textscan(fileID, '%f %f %f', 'HeaderLines', 5);
    fclose(fileID);
    
    % Store [Time (s), Pressure (MPa)]
    % Note: Since your original file did not include an airflow column, 
    % we derive flow from pressure changes or placeholder calculations if needed.
    % If your .txt file *does* have a 4th column for Flow, change '%f %f %f' to '%f %f %f %f'
    allRunsData{i} = [dataScan{1}/1000, dataScan{3}]; 
end

% Create a uniform time base to average the runs
baseTime = allRunsData{1}(:, 1); 
alignedPressure = zeros(length(baseTime), numRuns);

for i = 1:numRuns
    alignedPressure(:, i) = interp1(allRunsData{i}(:, 1), allRunsData{i}(:, 2), baseTime, 'linear', 'extrap');
end

% Calculate statistical mean and standard deviation for Pressure
meanPressure = mean(alignedPressure, 2);
stdPressure  = std(alignedPressure, 0, 2);

%% 3. Theoretical Models (Physics Equations)
P_max = 0.5;  % Maximum supply pressure in MPa (5 bar)
tau = 1.2;    % System time constant (seconds)

% Equation 1: Charging Pressure Over Time
theoreticalPressure = P_max * (1 - exp(-baseTime / tau));

% Equation 2: Airflow Over Time (Derived from dP/dt of the Ideal Gas Law)
% Flow drops exponentially as the chamber equalizes with the supply tank
Q_max = 80;   % Initial peak flow in L/min
theoreticalFlow = Q_max * exp(-baseTime / tau);

% Back-calculate experimental flow estimation based on the pressure rate of change
% Q is proportional to dP/dt in a fixed volume container
dt = diff(baseTime);
derivedFlowMatrix = zeros(length(baseTime), numRuns);
for i = 1:numRuns
    dp = diff(alignedPressure(:, i));
    % Scale factor to convert dP/dt into L/min (example scaling)
    derivedFlowMatrix(1:end-1, i) = (dp ./ dt) * (Q_max / (P_max / tau)); 
    derivedFlowMatrix(end, i) = 0; % Clear final edge point
end
meanFlow = mean(derivedFlowMatrix, 2);
stdFlow  = std(derivedFlowMatrix, 0, 2);

%% 4. Plotting the Multi-Panel Figure
figure('Color', [1 1 1], 'Position', [100, 100, 800, 600]);

% --- SUBPLOT 1: PRESSURE OVER TIME ---
subplot(2, 1, 1);
hold on; grid on;

% Plot individual raw data runs as thin faded lines to show consistency
for i = 1:numRuns
    plot(baseTime, alignedPressure(:, i), 'Color', [0 0.4470 0.7410 0.3], 'LineWidth', 1);
end

% Overlay Mean Experimental Pressure with decimated error bars
decimateVal = 5; 
hExpP = errorbar(baseTime(1:decimateVal:end), meanPressure(1:decimateVal:end), ...
                 stdPressure(1:decimateVal:end), 'o', 'MarkerSize', 4, ...
                 'Color', [0 0.4470 0.7410], 'MarkerFaceColor', [0 0.4470 0.7410], 'LineWidth', 1.1);

% Overlay Theoretical Charging Equation Line
hTheoP = plot(baseTime, theoreticalPressure, 'r-', 'LineWidth', 2);

ylabel('Pressure (MPa)', 'FontWeight', 'bold');
title('Pneumatic Transient Behavior: Theory vs. Multiple Experimental Runs', 'FontSize', 12);
legend([hExpP, hTheoP], {'Experimental Pressure (Mean \pm SD)', 'Theoretical Model: P_{max}(1-e^{-t/\tau})'}, 'Location', 'southeast');
xlim([0 max(baseTime)]);

% --- SUBPLOT 2: AIRFLOW OVER TIME ---
subplot(2, 1, 2);
hold on; grid on;

% Plot individual derived flow runs as thin faded lines
for i = 1:numRuns
    plot(baseTime, derivedFlowMatrix(:, i), 'Color', [0.4660 0.6740 0.1880 0.3], 'LineWidth', 1);
end

% Overlay Mean Experimental Flow with error bars
hExpQ = errorbar(baseTime(1:decimateVal:end), meanFlow(1:decimateVal:end), ...
                 stdFlow(1:decimateVal:end), 's', 'MarkerSize', 4, ...
                 'Color', [0.4660 0.6740 0.1880], 'MarkerFaceColor', [0.4660 0.6740 0.1880], 'LineWidth', 1.1);

% Overlay Theoretical Flow Decay Line
hTheoQ = plot(baseTime, theoreticalFlow, 'm--', 'LineWidth', 2);

xlabel('Time (s)', 'FontWeight', 'bold');
ylabel('Airflow Rate (L/min)', 'FontWeight', 'bold');
legend([hExpQ, hTheoQ], {'Experimental Flow (Derived Mean \pm SD)', 'Theoretical Model: Q_{max}(e^{-t/\tau})'}, 'Location', 'northeast');
xlim([0 max(baseTime)]);

hold off;