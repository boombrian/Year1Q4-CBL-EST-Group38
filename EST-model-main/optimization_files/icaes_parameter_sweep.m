% I-CAES Parameter Sweep: V_cavern x m_tes -> ICAES Supply Fraction
%
% Standalone MATLAB script that replicates the Simulink I-CAES model
% physics as a fast time-stepping loop, enabling 2D parameter sweeps.
%
% Produces:
%   - 3D surface plot: ICAES fraction vs (V_cavern, m_tes)
%   - Contour plot: iso-fraction lines for easy reading
%
% The physics (controller, compressor, expander, TES, pressure storage)
% are faithfully reconstructed from the Simulink block diagrams.

clear; clc; close all;

%% 1. Load Supply & Demand Data
% Use the CSVs in the data/ subfolder (same as Simulink preprocessing)
supply_raw = importdata('data/Team38_supply.csv', ',');
demand_raw = importdata('data/Team38_demand.csv', ',');

P_supply = supply_raw.data(:,2) * 1e6;   % [W] (CSV is in MW)
P_demand = demand_raw.data(:,2) * 1e6;   % [W]
P_net    = P_supply - P_demand;           % [W] positive = surplus

N  = length(P_net);
dt = 900;  % [s] timestep (data sampled at 15 min intervals)

% Total demand energy for the metric [J]
E_demand_total = sum(P_demand) * dt;

fprintf('Data loaded: %d timesteps, %.0f days\n', N, N*dt/86400);
fprintf('Total demand energy: %.1f GWh\n', E_demand_total / 3.6e12);

%% 2. Physical Constants (identical to preprocessing.m)
p_amb       = 101325;       % [Pa] Atmospheric pressure
T_amb       = 300;          % [K]  Ambient temperature
R_air       = 287.05;       % [J/(kg*K)] Specific gas constant of air
c_p         = 1005;         % [J/(kg*K)] Specific heat (const. pressure)
c_tes       = 4184;         % [J/(kg*K)] Specific heat of TES medium (water)
n_poly      = 1.1;          % Polytropic index (near-isothermal)

%% 3. System Design Parameters (fixed during sweep)
eta_tran    = 0.97;         % Transmission efficiency
eta_comp    = 0.833;        % Compressor efficiency
eta_exp     = 0.85;         % Expander efficiency
P_limit     = 300e6;        % [W] Max charging power (300 MW)
p_store_max = 100e5;        % [Pa] = 100 bar

% TES: constant-temperature, variable-mass model
% Water is stored at T_tes = 372 K (99°C). Charging adds hot water,
% discharging consumes it (thrown away after use).
T_tes       = 372;          % [K] Constant TES water temperature

% Initial conditions and constraints
m_water_init = 0;           % [kg] Initial water mass in TES (starts empty)
p_store_min  = 2e5;         % [Pa] = 2 bar (initial / minimum cavern pressure)
p_store_init = p_store_min; % Start at minimum operating pressure

%% 4. Sweep Configuration
V_cav_range = linspace(0.5e6, 12e6, 25);      % [m^3] 0.5 Mm^3 to 12 Mm^3
m_tes_range = linspace(50000, 10000000, 25);   % [kg]  50 t to 10,000 t (max water tank capacity)

n_V = length(V_cav_range);
n_m = length(m_tes_range);
ICAES_frac = zeros(n_V, n_m);

fprintf('Starting sweep: %d x %d = %d simulations\n', n_V, n_m, n_V*n_m);

%% 5. Run the 2D Sweep
tic;
for iv = 1:n_V
    for im = 1:n_m
        V_cavern = V_cav_range(iv);
        m_tes    = m_tes_range(im);

        ICAES_frac(iv, im) = run_sim( ...
            P_net, N, dt, ...
            p_amb, T_amb, R_air, c_p, c_tes, n_poly, ...
            eta_tran, eta_comp, eta_exp, P_limit, ...
            p_store_max, p_store_min, T_tes, ...
            m_water_init, p_store_init, V_cavern, m_tes, ...
            E_demand_total);
    end
    fprintf('  Row %d/%d (V_cavern = %.1f Mm^3) done\n', iv, n_V, V_cav_range(iv)/1e6);
end
elapsed = toc;
fprintf('Sweep complete in %.1f seconds.\n', elapsed);

%% 6. Convert fraction to percentage
ICAES_pct = ICAES_frac * 100;

%% 7. Find optimal point
[max_val, max_idx] = max(ICAES_pct(:));
[opt_iv, opt_im] = ind2sub(size(ICAES_pct), max_idx);
fprintf('\n--- Results ---\n');
fprintf('Max ICAES fraction: %.2f%%\n', max_val);
fprintf('  at V_cavern = %.2f Mm^3, m_tes = %.0f kg (%.0f tonnes)\n', ...
    V_cav_range(opt_iv)/1e6, m_tes_range(opt_im), m_tes_range(opt_im)/1000);

%% 8. Plotting (3D Surface and Contour in one figure)
[M_grid, V_grid] = meshgrid(m_tes_range/1000, V_cav_range/1e6);

figure('Name','ICAES Fraction — Parameter Sweep Results','NumberTitle','off', ...
       'Position', [100 100 1600 700]);

% Subplot 1: 3D Surface Plot
subplot(1, 2, 1);
surf(V_grid, M_grid, ICAES_pct, 'EdgeAlpha', 0.3, 'FaceAlpha', 0.9);
colormap(turbo);
cb = colorbar;
cb.Label.String = 'ICAES Fraction [%]';
xlabel('Cavern Volume [Mm^3]');
ylabel('TES Mass [tonnes]');
zlabel('E_{ICAES} / E_{demand} [%]');
title('3D Surface Plot (Z-axis = Performance)');
view([-35, 30]);
grid on;

% Subplot 2: 2D Contour Plot
subplot(1, 2, 2);
contourf(V_grid, M_grid, ICAES_pct, 15, 'LineWidth', 0.5);
colormap(turbo);
cb = colorbar;
cb.Label.String = 'ICAES Fraction [%]';
xlabel('Cavern Volume [Mm^3]');
ylabel('TES Mass [tonnes]');
title('Contour Map (Top-Down View)');
grid on;
hold on;
% Mark current design point
plot(5, 300, 'kp', 'MarkerSize', 15, 'MarkerFaceColor', 'w', 'LineWidth', 2);
text(5.3, 400, 'Current design', 'FontSize', 10, 'FontWeight', 'bold');


%% =========================================================================
%  SIMULATION FUNCTION — Variable-mass TES, dynamic polytropic index
%  =========================================================================
function frac = run_sim(P_net, N, dt, ...
    p_amb, T_amb, R_air, c_p, c_tes, n_poly, ...
    eta_tran, eta_comp, eta_exp, P_limit, ...
    p_store_max, p_store_min, T_tes, ...
    m_water_init, p_store_init, V_cavern, m_tes_max, ...
    E_demand_total)

    % State variables
    p_store = p_store_init;
    m_water = m_water_init;     % [kg] current hot water in TES tank

    % Accumulators
    E_ICAES = 0;   % Energy supplied by ICAES to meet demand [J]

    % Precompute
    exp_np = (n_poly - 1) / n_poly;   % 0.0909 for n=1.1
    coeff  = n_poly / (n_poly - 1);   % 11 for n=1.1
    c_v    = c_p - R_air;             % 718 J/(kg*K)
    gamma  = c_p / c_v;               % 1.4
    dT_water = T_tes - T_amb;         % 72 K (energy per kg of water)
    exp_g  = (gamma - 1) / gamma;     % 0.2857
    coeff_g = gamma / (gamma - 1);    % 3.5

    for k = 1:N
        Pnet = P_net(k);

        if Pnet > 0
            %% ============ SURPLUS MODE: CHARGE ============
            P_charge = min(Pnet * eta_tran, P_limit);

            % Don't charge if cavern is full
            if p_store >= p_store_max
                P_charge = 0;
            end

            mdot_charge = 0;
            P_thermal   = 0;

            if P_charge > 0
                pr = p_store / p_amb;
                if pr < 1.001, pr = 1.001; end

                % Polytropic compression: specific work [J/kg]
                w_comp = coeff * R_air * T_amb * (pr^exp_np - 1);

                % Mass flow rate [kg/s]
                mdot_charge = P_charge * eta_comp / w_comp;

                % Compressor exit temperature [K]
                T_out = T_amb * pr^exp_np;

                % Thermal power rejected to TES [W]
                P_thermal = mdot_charge * c_p * (T_out - T_amb);
            end

            % Update cavern pressure (Euler integration)
            dp = R_air * T_amb * mdot_charge / V_cavern;
            p_store = p_store + dp * dt;
            p_store = min(p_store, p_store_max);

            % Update TES: add hot water
            % P_thermal heats water from T_amb to T_tes (372K)
            dm_water = P_thermal / (c_tes * dT_water);  % [kg/s] water added
            m_water = m_water + dm_water * dt;
            m_water = min(m_water, m_tes_max);  % tank capacity limit

        else
            %% ============ DEFICIT MODE: DISCHARGE ============
            P_deficit = -Pnet;  % [W] positive value

            mdot_discharge = 0;
            Q_in_needed    = 0;
            P_ICAES_step   = 0;

            if p_store > p_store_min + 1000 && P_deficit > 0
                pr_exp = p_amb / p_store;  % < 1

                % Available air (don't drain below cushion pressure)
                mdot_max_air = (p_store - p_store_min) * V_cavern / ...
                               (R_air * T_amb * dt);
                mdot_max_air = max(mdot_max_air, 0);

                P_remain = P_deficit;
                mdot_iso = 0;
                mdot_adi = 0;

                % --- Mode A: Near-isothermal at T_tes (TES water available) ---
                if m_water > 0
                    w_exp_iso = coeff * R_air * T_tes * (1 - pr_exp^exp_np);

                    % Heat per kg for near-isothermal expansion [J/kg]
                    T_exit_iso = T_tes * pr_exp^exp_np;
                    q_per_kg = w_exp_iso + c_p * (T_exit_iso - T_tes);
                    q_per_kg = max(q_per_kg, 0);

                    if q_per_kg > 0 && w_exp_iso > 0
                        % Water consumed per kg of air expanded [kg_water/kg_air]
                        water_per_kg_air = q_per_kg / (c_tes * dT_water);

                        % Max air flow limited by water availability
                        mdot_water_limit = m_water / (water_per_kg_air * dt);

                        % Mass flow needed for full deficit
                        mdot_needed_iso = P_remain / (w_exp_iso * eta_exp * eta_tran);

                        mdot_iso = min([mdot_needed_iso, mdot_water_limit, mdot_max_air]);
                        mdot_iso = max(mdot_iso, 0);

                        P_from_iso  = mdot_iso * w_exp_iso * eta_exp * eta_tran;
                        Q_in_needed = mdot_iso * q_per_kg;  % [W]

                        P_remain = P_remain - P_from_iso;
                        mdot_max_air = mdot_max_air - mdot_iso;
                    end
                end

                % --- Mode B: Adiabatic fallback (no TES water) ---
                if P_remain > 0 && mdot_max_air > 0
                    w_exp_adi = coeff_g * R_air * T_amb * (1 - pr_exp^exp_g);

                    if w_exp_adi > 0
                        mdot_needed_adi = P_remain / (w_exp_adi * eta_exp * eta_tran);
                        mdot_adi = min([mdot_needed_adi, mdot_max_air]);
                        mdot_adi = max(mdot_adi, 0);
                    end
                end

                mdot_discharge = mdot_iso + mdot_adi;

                % Total ICAES power delivered
                P_total = 0;
                if mdot_iso > 0
                    P_total = P_total + mdot_iso * coeff * R_air * T_tes * ...
                              (1 - pr_exp^exp_np) * eta_exp * eta_tran;
                end
                if mdot_adi > 0
                    P_total = P_total + mdot_adi * coeff_g * R_air * T_amb * ...
                              (1 - pr_exp^exp_g) * eta_exp * eta_tran;
                end
                P_ICAES_step = min(P_total, P_deficit);
            end

            % Update cavern pressure
            dp = -R_air * T_amb * mdot_discharge / V_cavern;
            p_store = p_store + dp * dt;
            p_store = max(p_store, p_store_min);

            % Update TES: consume hot water
            dm_water = Q_in_needed / (c_tes * dT_water);  % [kg/s] consumed
            m_water = m_water - dm_water * dt;
            m_water = max(m_water, 0);  % can't go negative

            % Accumulate ICAES energy
            E_ICAES = E_ICAES + P_ICAES_step * dt;
        end
    end

    % Return ICAES fraction of total demand
    frac = E_ICAES / E_demand_total;
end
