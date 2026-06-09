%% MATLAB Post-Processing Script: Multi-Run Overlay vs Theoretical Model
clear; clc; close all;

% Define physical constants from report
tau = 0.8;             % First-order decay time constant (seconds)
V_baseline = 0.044;    % Noise ceiling baseline sensor voltage (Volts)
V_peak = 3.47;         % Transient peak voltage (Volts)

% File listing for the 4 discrete test trials
fileList = {'data_1.txt', 'data_2.txt', 'data_3.txt', 'data_4.txt'};

% Pre-allocate cells to store synchronized experimental data for plotting
syncTimeCells = cell(1, 4);
vQExpCells    = cell(1, 4);
p2ExpCells    = cell(1, 4);

% Setup a master maximum time vector to generate a clean, continuous theoretical curve
maxDuration = 0;

%% 1. Data Processing Loop (Isolate & Synchronize Each Run)
for f = 1:length(fileList)
    fileName = fileList{f};
    
    % Configure import options to select only columns 1 to 5 (Ignore Safety)
    opts = detectImportOptions(fileName, 'NumHeaderLines', 5, 'FileType', 'text');
    opts.SelectedVariableNames = opts.VariableNames(1:5); 
    
    dataTable = readtable(fileName, opts);
    rawData = table2array(dataTable);
    
    % Extract variables
    rawTime = rawData(:, 1);
    vQExp   = rawData(:, 3); % Flow sensor voltage channel
    p2Exp   = rawData(:, 4); % Pressure (MPa)
    
    % Find the exact index where valve actuation triggers the peak voltage surge
    [~, peakIdx] = max(vQExp);
    
    % Locate the start of the experimental event (where voltage lifts above noise)
    startThreshold = V_baseline + 0.05; 
    startIdx = find(vQExp(1:peakIdx) > startThreshold, 1, 'first');
    if isempty(startIdx), startIdx = max(1, peakIdx - 10); end
    
    % Extract a standard 15-second tracking window post-start
    sampleRate = 1 / mean(diff(rawTime)); 
    endIdx = min(length(rawTime), round(startIdx + (15 * sampleRate)));
    
    % Crop and shift time base to begin exactly at t_sync = 0
    rawTimeCrop = rawTime(startIdx:endIdx);
    timeSync = rawTimeCrop - rawTimeCrop(1);
    
    % Store the shifted, isolated profiles
    syncTimeCells{f} = timeSync;
    vQExpCells{f}    = vQExp(startIdx:endIdx);
    p2ExpCells{f}    = p2Exp(startIdx:endIdx);
    
    % Track the longest runtime window to ensure theory curve covers it fully
    if timeSync(end) > maxDuration
        maxDuration = timeSync(end);
    end
end

%% 2. Compute Continuous Theoretical Curve
% Generate a high-resolution, uniform master timeline starting at 0s
tTheory = 0:0.01:maxDuration;

% Define where the theoretical step/peak happens based on the data average (~1.1 seconds)
t_peak_theory = 1.1; 

% Theoretical Pressure Curve calculation: P2(t) = P_initial * e^(-t/tau)
P_initial_nominal = 0.6; % Nominal starting pressure placeholder (Adjust if needed)
p2Theory = zeros(size(tTheory));
for i = 1:length(tTheory)
    if tTheory(i) < t_peak_theory
        p2Theory(i) = P_initial_nominal;
    else
        p2Theory(i) = P_initial_nominal * exp(-(tTheory(i) - t_peak_theory) / tau);
    end
end

% Theoretical Flow Voltage Curve calculation: Q(t) = Q_peak * e^(-t/tau)
vQTheory = zeros(size(tTheory));
for i = 1:length(tTheory)
    if tTheory(i) < t_peak_theory
        vQTheory(i) = V_baseline + (V_peak - V_baseline) * (tTheory(i) / t_peak_theory);
    else
        vQTheory(i) = V_baseline + (V_peak - V_baseline) * exp(-(tTheory(i) - t_peak_theory) / tau);
    end
end

%% 3. Generate Combined Figure Overlays
figure