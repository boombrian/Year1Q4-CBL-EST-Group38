% MATLAB Serial Data Logger - 5-Second Auto-Stop
clear; clc;

% 1. Configuration Setup
portName = "COM7";          % <-- CHANGE to your actual Arduino COM port
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

% Write layout headers
fprintf(fileID, "=========================================\n");
fprintf(fileID, "      PNEUMATIC EXPERIMENT DATA LOG     \n");
fprintf(fileID, "=========================================\n");
fprintf(fileID, "%-15s %-15s %-15s\n", "Time (ms)", "Voltage (V)", "Pressure (MPa)");
fprintf(fileID, "-----------------------------------------\n");

% 4. Data Collection Loop (Timer-Based T)
disp("Logging started. Collecting data for 5 seconds...");
flush(arduinoPort); 

pointsCollected = 0;
startTime = tic; % Start the 5-second stopwatch

% The loop will run ONLY while the elapsed time is less than 5.0 seconds
while toc(startTime) < 5.0
    rawLine = readline(arduinoPort);
    
    if isempty(rawLine)
        continue; % Skip if a timeout occurred but 5 seconds aren't up yet
    end
    
    splitData = sscanf(rawLine, '%f,%f,%f');
    
    if length(splitData) == 3
        pointsCollected = pointsCollected + 1;
        
        time_ms  = splitData(1);
        voltage  = splitData(2);
        pressure = splitData(3);
        
        % Write to the text file buffer
        fprintf(fileID, "%-15d %-15.3f %-15.4f\n", time_ms, voltage, pressure);
        
        % Display live progress in Command Window
        fprintf("Saved Point %d: Time=%d ms, Elapsed=%.2f s\n", ...
                pointsCollected, time_ms, toc(startTime));
    end
end

% 5. Safe Cleanup (This runs automatically after 5 seconds!)
fclose(fileID);
clear arduinoPort;

fprintf("\n=========================================\n");
fprintf("Done! 5 seconds elapsed. %d points saved.\n", pointsCollected);
fprintf("Data successfully written to: %s\n", outputFileName);
fprintf("=========================================\n");