% MATLAB Serial Data Logger - 5-Second Auto-Stop
clear; clc;

% 1. Configuration Setup
portName = "COM7";
baudRate = 9600;
outputFileName = fullfile(pwd, 'pneumatic_data.txt');

% 2. Initialize Serial Port
try
    arduinoPort = serialport(portName, baudRate);
    configureTerminator(arduinoPort, "LF");
    arduinoPort.Timeout = 5;
    disp("Connected to " + portName + " successfully.");
catch ME
    error("Could not connect. Ensure Arduino Serial Monitor is CLOSED.");
end

% 3. Open the Text File
fileID = fopen(outputFileName, 'w');
if fileID == -1
    error("Could not create the file.");
end

% Header now matches Arduino output columns
fprintf(fileID, "================================================================================================================\n");
fprintf(fileID, "                                      PNEUMATIC EXPERIMENT DATA LOG\n");
fprintf(fileID, "================================================================================================================\n");
fprintf(fileID, "%-12s %-10s %-10s %-10s %-12s %-12s %-12s %-25s\n", ...
    "Time_s", "V_P1", "V_P2", "V_Q", "P1_MPa", "P2_MPa", "Q_L_min", "Status");
fprintf(fileID, "----------------------------------------------------------------------------------------------------------------\n");

% 4. Data Collection Loop
disp("Logging started. Collecting data for 5 seconds...");
flush(arduinoPort);

pointsCollected = 0;
startTime = tic;

while toc(startTime) < 5.0

    rawLine = strtrim(readline(arduinoPort));

    if rawLine == ""
        continue;
    end

    % Skip Arduino CSV header line
    if contains(rawLine, "time_s")
        continue;
    end

    % Split full Arduino CSV line instead of reading only 3 values
    parts = split(rawLine, ",");

    % Arduino sends 7 numeric columns:
    % time_s,V_P1,V_P2,V_Q,P1_MPa,P2_MPa,Q_L_min
    if numel(parts) == 7

        values = str2double(parts);

        if any(isnan(values))
            continue;
        end

        pointsCollected = pointsCollected + 1;

        %% Correct column assignment
        time_s  = values(1);
        V_P1    = values(2);
        V_P2    = values(3);
        V_Q     = values(4);
        P1_MPa  = values(5);
        P2_MPa  = values(6);
        Q_L_min = values(7);

        %Arduino prints safety status on the next line
        status = "UNKNOWN";

        if arduinoPort.NumBytesAvailable > 0
            possibleStatus = strtrim(readline(arduinoPort));

            if possibleStatus == "NORMAL" || possibleStatus == "CRITICAL_OVERPRESSURE"
                status = possibleStatus;
            end
        end

        % Write all variables to file
        fprintf(fileID, "%-12.3f %-10.3f %-10.3f %-10.3f %-12.4f %-12.4f %-12.2f %-25s\n", ...
            time_s, V_P1, V_P2, V_Q, P1_MPa, P2_MPa, Q_L_min, status);

        % Live display now shows real pressure/flow values
        fprintf("Saved Point %d: t=%.3f s, P1=%.4f MPa, P2=%.4f MPa, Q=%.2f L/min, Status=%s\n", ...
            pointsCollected, time_s, P1_MPa, P2_MPa, Q_L_min, status);
    end
end

% 5. Safe Cleanup
fclose(fileID);
clear arduinoPort;

fprintf("\n=========================================\n");
fprintf("Done! 5 seconds elapsed. %d points saved.\n", pointsCollected);
fprintf("Data successfully written to: %s\n", outputFileName);
fprintf("=========================================\n");
