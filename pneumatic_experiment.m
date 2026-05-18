function data = processPneumaticData(filename)
    % processPneumaticData: Imports and plots pneumatic sensor data
    % Input: filename (string), e.g., 'experiment_data.csv'
    
    % Read the table (preserves the header names from your Serial.println)
    opts = detectImportOptions(filename);
    rawTable = readtable(filename, opts);
    
    % Store in a struct for easy access
    data.time = rawTable.time_s;
    data.P1 = rawTable.P1_MPa;
    data.P2 = rawTable.P2_MPa;
    data.Flow = rawTable.Q_L_min;
    
    % --- Optional: Quick Visualization ---
    figure('Color', 'w');
    
    % Subplot 1: Pressure
    subplot(2,1,1);
    plot(data.time, data.P1, 'LineWidth', 1.5); hold on;
    plot(data.time, data.P2, 'LineWidth', 1.5);
    ylabel('Pressure (MPa)');
    legend('Tank 1', 'Tank 2');
    grid on;
    title('Pneumatic Experiment Results');
    
    % Subplot 2: Flow Rate
    subplot(2,1,2);
    plot(data.time, data.Flow, 'r', 'LineWidth', 1.5);
    ylabel('Flow Rate (L/min)');
    xlabel('Time (s)');
    grid on;
end