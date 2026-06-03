% MATLAB Serial Data Logger - Multi-Sensor Update
clear; clc;

% 1. Configuration Setup
portName = "COM6";          % <-- CHANGE to your actual Arduino COM port
baudRate = 9600;            
outputFileName = fullfile(pwd, 'data_4.txt'); 

% 2. Initialize Serial Port
try
    arduinoPort = serialport(portName, baudRate);
    configureTerminator(arduinoPort, "LF");
    arduinoPort.Timeout = 1;  % [FIXED] Short timeout — 5s was causing readline to block the loop
    disp("Connected to " + portName + " successfully.");
catch ME
    error("Could not connect. Ensure Arduino Serial Monitor is CLOSED.");
end

% 3. Open the Text File
fileID = fopen(outputFileName, 'w');
if fileID == -1
    error("Could not create the file.");
end

% Write expanded layout headers
fprintf(fileID, "====================================================================================================\n");
fprintf(fileID, "                               PNEUMATIC EXPERIMENT DATA LOG (ALL SENSORS)                          \n");
fprintf(fileID, "====================================================================================================\n");
% [CHANGED] Updated columns — time from MATLAB timer, P1 removed, safety now numeric
fprintf(fileID, "%-10s %-10s %-10s %-12s %-14s %-12s\n", ...
    "Time(s)", "V_P2(V)", "V_Q(V)", "P2(MPa)", "Q(L/min)", "Safety");
fprintf(fileID, "------------------------------------------------------------------------------------\n");

% 4. Set up real-time figure BEFORE the loop
% [ADDED] Create live plot figure with two subplots updated during collection
% [CHANGED] Light theme figure, side-by-side layout (1 row, 2 cols)
hFig = figure('Name', 'Live Pneumatic Data', 'NumberTitle', 'off', 'Color', 'white');

% --- Subplot 1: Pressure (live) ---
ax1 = subplot(1, 2, 1);
set(ax1, 'Color', 'white', 'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], 'GridColor', [0.8 0.8 0.8]);
hold(ax1, 'on');
grid(ax1, 'on');
hPressureLine = animatedline(ax1, 'Color', [0.0 0.45 0.85], 'LineWidth', 1.8);
yline(ax1, 0.5, '--', 'Color', [0.85 0.1 0.1], 'LineWidth', 1.2, 'Label', 'Safety Limit (0.5 MPa)', ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 8);
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Pressure (MPa)');
title(ax1, 'P2 Pressure — LIVE', 'FontWeight', 'bold');
legend(ax1, 'P2 (MPa)', 'Safety Limit', 'Location', 'northwest');

% --- Subplot 2: Flow rate (live) ---
ax2 = subplot(1, 2, 2);
set(ax2, 'Color', 'white', 'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], 'GridColor', [0.8 0.8 0.8]);
hold(ax2, 'on');
grid(ax2, 'on');
hFlowLine = animatedline(ax2, 'Color', [0.1 0.65 0.2], 'LineWidth', 1.8);
xlabel(ax2, 'Time (s)');
ylabel(ax2, 'Flow Rate (L/min)');
title(ax2, 'Air Flow Rate — LIVE', 'FontWeight', 'bold');
legend(ax2, 'Q (L/min)', 'Location', 'northwest');

sgtitle(hFig, 'Pneumatic Experiment — Live Data', 'FontSize', 13, 'FontWeight', 'bold');
drawnow;

% 5. Data Collection Loop
disp("Logging started. Recording until you close the plot window or press Ctrl+C...");
flush(arduinoPort); 

pointsCollected = 0;
startTime = tic; % Used for elapsed time timestamps

% Pre-allocate arrays to store all data for the final static plot
allTime   = [];
allV_P2   = [];
allV_Q    = [];
allP2_MPa = [];
allQ_Lmin = [];
allSafety = [];

% Wrapped in try-catch so either way the file is saved and port is released.
try
    while isvalid(hFig)  % exits automatically when plot window is closed

        % Only call readline when bytes are actually waiting.
        if arduinoPort.NumBytesAvailable == 0
            drawnow;  % Keep the figure responsive while waiting for data
            continue;
        end

        % Read one line — wrapped in try-catch to survive any read error
        try
            rawLineData = readline(arduinoPort);
        catch
            drawnow;
            continue;
        end

        if isempty(rawLineData)
            drawnow;
            continue;
        end

        % Parse label:value format from Arduino
        % Arduino sends: "V_P2:x.xxx,V_Q:x.xxx,P2_MPa:x.xxxx,Q_Lmin:xx.xx,Safety:0"
        cleanedLine = regexprep(rawLineData, '[A-Za-z0-9_]+:', '');
        splitData = sscanf(cleanedLine, '%f,%f,%f,%f,%f');

        if length(splitData) == 5
            pointsCollected = pointsCollected + 1;

            time_s    = toc(startTime);
            V_P2      = splitData(1);
            V_Q       = splitData(2);
            P2_MPa    = splitData(3);
            Q_L_min   = splitData(4);
            safetyVal = splitData(5);  % 0 = NORMAL, 1 = CRITICAL_OVERPRESSURE

            % Decode safety status for display and file
            if safetyVal == 1
                safetyStatus = "CRITICAL_OVERPRESSURE";
            else
                safetyStatus = "NORMAL";
            end

            % Store data for post-collection static plot
            allTime(end+1)   = time_s;
            allV_P2(end+1)   = V_P2;
            allV_Q(end+1)    = V_Q;
            allP2_MPa(end+1) = P2_MPa;
            allQ_Lmin(end+1) = Q_L_min;
            allSafety(end+1) = safetyVal;

            % Append new points to the live animated lines
            addpoints(hPressureLine, time_s, P2_MPa);
            addpoints(hFlowLine,     time_s, Q_L_min);

            % Flash background light red on overpressure
            if safetyVal == 1
                set(ax1, 'Color', [1.0 0.88 0.88]);
                title(ax1, '!! P2 Pressure -- OVERPRESSURE DETECTED', 'Color', [0.8 0.0 0.0], 'FontWeight', 'bold');
            else
                set(ax1, 'Color', 'white');
                title(ax1, 'P2 Pressure -- LIVE', 'Color', [0.2 0.2 0.2], 'FontWeight', 'bold');
            end

            drawnow;

            % Write data point to file
            fprintf(fileID, "%-10.3f %-10.3f %-10.3f %-12.4f %-14.2f %-12s\n", ...
                    time_s, V_P2, V_Q, P2_MPa, Q_L_min, safetyStatus);

            % Live Command Window output
            fprintf("Point %d: Time=%.3fs | P2=%.4f MPa | Flow=%.1f L/min | Status=%s\n", ...
                    pointsCollected, time_s, P2_MPa, Q_L_min, safetyStatus);
        end
    end
catch  % Ctrl+C or any fatal error — fall through to cleanup
end


% 6. Safe Cleanup (runs after figure closed, Ctrl+C, or any error)
elapsedTime = toc(startTime);
fclose(fileID);
clear arduinoPort;

fprintf("\n====================================================================================================\n");
fprintf("Recording stopped. %.1f seconds elapsed. %d points saved.\n", elapsedTime, pointsCollected);
fprintf("Data successfully written to: %s\n", outputFileName);
fprintf("====================================================================================================\n");

% 7. Final static plot after collection
% [ADDED] Replace live plot with clean final plot once collection is done
if pointsCollected > 0
    % [CHANGED] Light theme, side-by-side layout for final plot
    figure('Name', 'Pneumatic Experiment Results - Final', 'NumberTitle', 'off', 'Color', 'white');
    
    % --- Subplot 1: Pressure ---
    ax3 = subplot(1, 2, 1);
    plot(ax3, allTime, allP2_MPa, '-', 'Color', [0.0 0.45 0.85], 'LineWidth', 1.5);
    hold(ax3, 'on');
    yline(ax3, 0.5, '--', 'Color', [0.85 0.1 0.1], 'LineWidth', 1.2, 'Label', 'Safety Limit (0.5 MPa)', ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);
    hold(ax3, 'off');
    xlabel(ax3, 'Time (s)');
    ylabel(ax3, 'Pressure (MPa)');
    title(ax3, 'P2 Pressure over Time', 'FontWeight', 'bold');
    grid(ax3, 'on');
    set(ax3, 'Color', 'white', 'GridColor', [0.8 0.8 0.8]);
    legend(ax3, 'P2 (MPa)', 'Safety Limit', 'Location', 'best');
    
    % --- Subplot 2: Flow rate ---
    ax4 = subplot(1, 2, 2);
    plot(ax4, allTime, allQ_Lmin, '-', 'Color', [0.1 0.65 0.2], 'LineWidth', 1.5);
    xlabel(ax4, 'Time (s)');
    ylabel(ax4, 'Flow Rate (L/min)');
    title(ax4, 'Air Flow Rate over Time', 'FontWeight', 'bold');
    grid(ax4, 'on');
    set(ax4, 'Color', 'white', 'GridColor', [0.8 0.8 0.8]);
    legend(ax4, 'Q (L/min)', 'Location', 'best');
    
    sgtitle('Pneumatic Experiment Data - Final', 'FontSize', 13, 'FontWeight', 'bold');
else
    disp("No data points were collected — nothing to plot.");
end
