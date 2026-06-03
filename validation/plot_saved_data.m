% Script to read saved pneumatic data and plot 4 datasets in subplots
clear; clc;

% 1. Define the file to read
dataFileName = 'data_3.txt';

if ~isfile(dataFileName)
    error('File %s not found in the current directory.', dataFileName);
end

% 2. Open and read the text file
fileID = fopen(dataFileName, 'r');

% Skip the first 5 lines (header information)
for i = 1:5
    fgetl(fileID);
end

% Read the data columns
% Format: Time(s) | V_P2(V) | V_Q(V) | P2(MPa) | Q(L/min) | Safety
data = textscan(fileID, '%f %f %f %f %f %s');
fclose(fileID);

% 3. Extract the variables we need for plotting
time_s  = data{1};
V_P2    = data{2};
V_Q     = data{3};
P2_MPa  = data{4};
Q_L_min = data{5};

if isempty(time_s)
    error('No data found in %s.', dataFileName);
end

% 4. Create a figure with 4 subplots
figure('Name', 'Saved Pneumatic Data - 4 Subplots', 'NumberTitle', 'off', 'Color', 'white');

% --- Subplot 1: V_P2 (Voltage) ---
subplot(2, 2, 1);
plot(time_s, V_P2, '-', 'Color', [0.0 0.45 0.85], 'LineWidth', 1.5);
ylabel('Voltage (V)', 'FontWeight', 'bold');
xlabel('Time (s)');
title('Raw Sensor Voltage: P2');
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8]);

% --- Subplot 2: V_Q (Voltage) ---
subplot(2, 2, 2);
plot(time_s, V_Q, '-', 'Color', [0.1 0.65 0.2], 'LineWidth', 1.5);
ylabel('Voltage (V)', 'FontWeight', 'bold');
xlabel('Time (s)');
title('Raw Sensor Voltage: Q');
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8]);

% --- Subplot 3: P2 (Pressure) ---
subplot(2, 2, 3);
plot(time_s, P2_MPa, '-', 'Color', [0.0 0.45 0.85], 'LineWidth', 1.5);
hold on;
yline(0.5, '--', 'Color', [0.85 0.1 0.1], 'LineWidth', 1.2, 'Label', 'Safety Limit');
hold off;
ylabel('Pressure (MPa)', 'FontWeight', 'bold');
xlabel('Time (s)');
title('Converted Pressure: P2');
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8]);
ylim([0, max([0.6, max(P2_MPa) * 1.1])]);

% --- Subplot 4: Q (Flow Rate) ---
subplot(2, 2, 4);
plot(time_s, Q_L_min, '-', 'Color', [0.1 0.65 0.2], 'LineWidth', 1.5);
ylabel('Flow Rate (L/min)', 'FontWeight', 'bold');
xlabel('Time (s)');
title('Converted Flow Rate: Q');
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8]);

% Overall Title
sgtitle('Pneumatic System Data: Raw Voltages vs Converted Units', 'FontSize', 14, 'FontWeight', 'bold');
