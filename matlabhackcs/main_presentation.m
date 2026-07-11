


clear; clc; close all;


PLANT_DEN           = [1 3 2];
SETTLE_THRESHOLD    = 0.00005;
FINAL_AVG_WINDOW    = 50;
DISTURBANCE_ONSET   = 2.0;
DT                  = 0.01;
SETTLE_SLUGGISH     = 6.0;
SETTLE_ADEQUATE     = 3.0;

% --- Colors (RGB) 
CLR_BG              = [0.10 0.10 0.10];
CLR_TEXT            = [1.00 1.00 1.00];
CLR_TEXT_SUB        = [0.85 0.85 0.85];
CLR_GRID            = [0.30 0.30 0.30];
CLR_PASSIVE         = [0.75 0.25 0.25];
CLR_PID             = [0.20 0.60 1.00];
CLR_AI              = [0.20 1.00 0.40];
CLR_BUMP_LINE       = [1 1 1 0.6];
CLR_LEGEND_BG       = [0.15 0.15 0.15];

% --- Line widths & font sizes 
LW_PASSIVE          = 2.0;
LW_PID              = 2.5;
LW_AI               = 2.5;
LW_BUMP             = 1.2;
FONT_TITLE          = 16;
FONT_SUBTITLE       = 11;
FONT_AXIS           = 12;
FONT_LEGEND         = 11;
FONT_ANNOTATION     = 10;


fprintf('\n');
fprintf('=========================================================\n');
fprintf('  OPEN-LOOP PLANT ANALYSIS\n');
fprintf('=========================================================\n');
fprintf('  Plant: G(s) = 1 / (s^2 + 3s + 2)\n\n');

ol_poles = roots(PLANT_DEN);
wn       = sqrt(PLANT_DEN(3));
zeta     = PLANT_DEN(2) / (2 * wn);

fprintf('  Open-loop poles:      s = %.4f,  s = %.4f\n', ol_poles(1), ol_poles(2));
fprintf('  Natural frequency:    wn   = %.4f rad/s\n', wn);
fprintf('  Damping ratio:        zeta = %.4f\n', zeta);

if all(real(ol_poles) < 0)
    fprintf('  Stability:            Stable -- both poles in LHP\n');
else
    fprintf('  Stability:            UNSTABLE -- pole(s) in RHP!\n');
end
fprintf('=========================================================\n\n');

%% =====================  Simulation Calls  ===============================
[t, y_passive] = sim_passive();
[t, y_pid]     = sim_pid_reactive();
[t, y_ai]      = sim_ai_predictive();



dt = t(2) - t(1);   % extract dt from time vector = 0.01

% ─────────────────────────────────────────────
% STEP 2 — ISE calculation (ADD THIS BLOCK HERE)
% ─────────────────────────────────────────────
ISE_passive = sum(y_passive.^2) * dt;
ISE_pid     = sum(y_pid.^2)     * dt;
ISE_ai      = sum(y_ai.^2)      * dt;

cancellation_pid = (1 - ISE_pid / ISE_passive) * 100;
cancellation_ai  = (1 - ISE_ai  / ISE_passive) * 100;


% ─────────────────────────────────────────────
% ISE ANNOTATION BOX on the graph
% ─────────────────────────────────────────────
% Build the text string
str = {sprintf('ISE Analysis (Vibration Energy)'), ...
       sprintf('─────────────────────────────'), ...
       sprintf('Passive  : %.5f', ISE_passive), ...
       sprintf('PID      : %.5f', ISE_pid), ...
       sprintf('AI       : %.5f', ISE_ai), ...
       sprintf('─────────────────────────────'), ...
       sprintf('PID cancellation: %.1f%%', cancellation_pid), ...
       sprintf('AI  cancellation: %.1f%%', cancellation_ai)};

% Place annotation box in top right of the plot
% 'Units','normalized' means 0-1 regardless of axis scale
annotation('textbox', [0.55, 0.55, 0.35, 0.32], ...
    'String',          str, ...
    'FontSize',        9, ...
    'FontName',        'Courier New', ...
    'BackgroundColor', [0.1 0.1 0.1], ...
    'EdgeColor',       [0.4 0.4 0.4], ...
    'Color',           [1 1 1], ...
    'FitBoxToText',    'off');


% ─────────────────────────────────────────────
% FIGURE 2 — ISE bar chart + cancellation
% ─────────────────────────────────────────────
figure('Color', [0.05 0.05 0.05], 'Position', [200 200 900 400]);

% ── Left subplot: ISE values ──
subplot(1, 2, 1);
set(gca, 'Color', [0.08 0.08 0.08], ...
         'XColor', [0.8 0.8 0.8], ...
         'YColor', [0.8 0.8 0.8], ...
         'GridColor', [0.3 0.3 0.3]);
hold on; grid on;

bar_data   = [ISE_passive, ISE_pid, ISE_ai];
bar_colors = [0.87 0.29 0.29;   % red   — passive
              0.27 0.56 0.85;   % blue  — PID
              0.23 0.43 0.07];  % green — AI

b = bar(bar_data, 'FaceColor', 'flat');
b.CData = bar_colors;
b.EdgeColor = 'none';

set(gca, 'XTickLabel', {'Passive', 'PID Reactive', 'AI Predictive'}, ...
         'XColor', [0.8 0.8 0.8], ...
         'YColor', [0.8 0.8 0.8]);

% Value labels on top of each bar
for i = 1:3
    text(i, bar_data(i) + max(bar_data)*0.02, ...
         sprintf('%.5f', bar_data(i)), ...
         'HorizontalAlignment', 'center', ...
         'Color', [1 1 1], 'FontSize', 8);
end

title('ISE — Total Vibration Energy', ...
      'Color', [1 1 1], 'FontSize', 11);
ylabel('ISE (m²·s)', 'Color', [0.8 0.8 0.8]);

% ── Right subplot: cancellation percentage ──
subplot(1, 2, 2);
set(gca, 'Color', [0.08 0.08 0.08], ...
         'XColor', [0.8 0.8 0.8], ...
         'YColor', [0.8 0.8 0.8], ...
         'GridColor', [0.3 0.3 0.3]);
hold on; grid on;

cancel_data   = [cancellation_pid, cancellation_ai];
cancel_colors = [0.27 0.56 0.85;    % blue — PID
                 0.23 0.43 0.07];   % green — AI

b2 = bar(cancel_data, 'FaceColor', 'flat');
b2.CData      = cancel_colors;
b2.EdgeColor  = 'none';

set(gca, 'XTickLabel', {'PID Reactive', 'AI Predictive'}, ...
         'XColor', [0.8 0.8 0.8], ...
         'YColor', [0.8 0.8 0.8], ...
         'YLim', [0 100]);

% Percentage labels on bars
for i = 1:2
    text(i, cancel_data(i) + 1.5, ...
         sprintf('%.1f%%', cancel_data(i)), ...
         'HorizontalAlignment', 'center', ...
         'Color', [1 1 1], 'FontSize', 10, ...
         'FontWeight', 'bold');
end

% Reference line at 100%
yline(100, '--', '100% (perfect)', ...
      'Color', [0.5 0.5 0.5], 'FontSize', 8, ...
      'LabelColor', [0.7 0.7 0.7]);

title('Vibration Cancellation vs Passive', ...
      'Color', [1 1 1], 'FontSize', 11);
ylabel('Cancellation (%)', 'Color', [0.8 0.8 0.8]);

sgtitle('ISE Performance Analysis — Active Suspension', ...
        'Color', [1 1 1], 'FontSize', 13, 'FontWeight', 'bold');

% ─────────────────────────────────────────────
% STEP 3 — print to console so you can see it
% ─────────────────────────────────────────────
fprintf('\n========== ISE ANALYSIS ==========\n');
fprintf('ISE Passive  : %.6f\n', ISE_passive);
fprintf('ISE PID      : %.6f\n', ISE_pid);
fprintf('ISE AI       : %.6f\n', ISE_ai);
fprintf('----------------------------------\n');
fprintf('PID cancellation : %.1f%%\n', cancellation_pid);
fprintf('AI  cancellation : %.1f%%\n', cancellation_ai);
fprintf('ISE improvement PID over AI: %.1f%%\n', ...
        (1 - ISE_pid/ISE_ai) * 100);
fprintf('==================================\n\n');
%% =====================  Performance Metrics  ============================
idx_onset   = find(t >= DISTURBANCE_ONSET, 1, 'first');
strategies  = {'Passive', 'PID Reactive', 'AI Predictive'};
responses   = {y_passive, y_pid, y_ai};

peak_dev    = zeros(1, 3);
settle_time = zeros(1, 3);
settle_str  = cell(1, 3);
ss_error    = zeros(1, 3);
quality_lbl = cell(1, 3);

for i = 1:3
    yy = responses{i};

    % -- Maximum Peak Deviation -------------------------------------------
    peak_dev(i) = max(abs(yy));

    % -- Settling Time (manual, post-disturbance) -------------------------
  % OLD — searches from j=1 (onset), so PID triggers instantly
y_post = abs(yy(idx_onset:end));
settled_idx = [];
for j = 1:length(y_post)
    if all(y_post(j:end) < SETTLE_THRESHOLD)
        settled_idx = j;
        break;
    end
end

% NEW — searches only AFTER the local peak (correct ISE definition)
y_post = abs(yy(idx_onset:end));
[~, peak_local_idx] = max(y_post);          % find peak index first
settled_idx = [];
for j = peak_local_idx:length(y_post)       % only search after peak
    if all(y_post(j:end) < SETTLE_THRESHOLD)
        settled_idx = j;
        break;
    end
end

    if isempty(settled_idx)
        settle_time(i) = NaN;
        settle_str{i}  = '> 8.0s (did not settle)';
    else
        settle_time(i) = (settled_idx - 1) * DT;
        settle_str{i}  = sprintf('%.2f s', settle_time(i));
    end

    % -- Steady-State Error -----------------------------------------------
    ss_error(i) = mean(abs(yy(end - FINAL_AVG_WINDOW:end)));

    % -- Damping Quality Label --------------------------------------------
    if isnan(settle_time(i)) || settle_time(i) > SETTLE_SLUGGISH
        quality_lbl{i} = 'Overdamped / Sluggish';
    elseif settle_time(i) >= SETTLE_ADEQUATE
        quality_lbl{i} = 'Adequately Damped';
    else
        quality_lbl{i} = 'Critically Optimized';
    end
end

% --- Print metrics table -------------------------------------------------
fprintf('=========================================================\n');
fprintf('  PERFORMANCE METRICS -- Disturbance Rejection (Regulator)\n');
fprintf('=========================================================\n');
fprintf('  %-22s %-16s %-16s %-16s\n', ...
    'Metric', strategies{1}, strategies{2}, strategies{3});
fprintf('  %-22s %-16s %-16s %-16s\n', ...
    '----------------------', '----------------', ...
    '----------------', '----------------');
fprintf('  %-22s %-16.4f %-16.4f %-16.4f\n', ...
    'Peak Deviation (m)', peak_dev(1), peak_dev(2), peak_dev(3));
fprintf('  %-22s %-16s %-16s %-16s\n', ...
    'Settling Time', settle_str{1}, settle_str{2}, settle_str{3});
fprintf('  %-22s %-16.6f %-16.6f %-16.6f\n', ...
    'Steady-State Err (m)', ss_error(1), ss_error(2), ss_error(3));
fprintf('  %-22s %-16s %-16s %-16s\n', ...
    'Damping Quality', quality_lbl{1}, quality_lbl{2}, quality_lbl{3});
fprintf('=========================================================\n\n');

%% =====================  Visualization  ==================================
fig = figure('Color', CLR_BG, 'Position', [100 100 1100 600], ...
             'Name', 'Active Suspension Control');
ax  = axes('Parent', fig, 'Color', CLR_BG);
hold(ax, 'on');

% --- Response curves -----------------------------------------------------
h1 = plot(ax, t, y_passive, '--', ...
    'Color', CLR_PASSIVE, 'LineWidth', LW_PASSIVE, ...
    'DisplayName', 'Passive (Open-Loop)');
h2 = plot(ax, t, y_pid, '-', ...
    'Color', CLR_PID, 'LineWidth', LW_PID, ...
    'DisplayName', 'PID Reactive');
h3 = plot(ax, t, y_ai, '-', ...
    'Color', CLR_AI, 'LineWidth', LW_AI, ...
    'DisplayName', 'AI Predictive');

% --- Bump marker ---------------------------------------------------------
xline(ax, DISTURBANCE_ONSET, '--', 'Color', CLR_BUMP_LINE, ...
    'LineWidth', LW_BUMP);
text(ax, DISTURBANCE_ONSET + 0.15, max(y_passive)*0.95, ...
    'Road Bump Impact', 'Color', CLR_TEXT, ...
    'FontSize', FONT_ANNOTATION, 'FontWeight', 'bold');

% --- Passive peak annotation --------------------------------------------
[pk_val, pk_idx] = max(y_passive);
pk_time = t(pk_idx);
plot(ax, pk_time, pk_val, 'o', 'MarkerSize', 8, ...
    'MarkerEdgeColor', CLR_PASSIVE, 'MarkerFaceColor', CLR_PASSIVE, ...
    'HandleVisibility', 'off');
text(ax, pk_time + 0.2, pk_val, sprintf('Peak = %.3f m', pk_val), ...
    'Color', CLR_PASSIVE, 'FontSize', FONT_ANNOTATION, ...
    'FontWeight', 'bold');

% --- Axes formatting -----------------------------------------------------
grid(ax, 'on');
ax.GridColor       = CLR_GRID;
ax.GridAlpha       = 1;
ax.MinorGridLineStyle = ':';
ax.MinorGridColor  = CLR_GRID;
ax.MinorGridAlpha  = 0.5;
ax.XMinorGrid      = 'on';
ax.YMinorGrid      = 'on';
ax.XColor          = CLR_TEXT;
ax.YColor          = CLR_TEXT;
ax.FontSize        = FONT_AXIS;
ax.TickDir         = 'out';

xlabel(ax, 'Time (seconds)', 'Color', CLR_TEXT, 'FontSize', FONT_AXIS);
ylabel(ax, 'Chassis Displacement (m)', 'Color', CLR_TEXT, ...
    'FontSize', FONT_AXIS);
title(ax, 'Active Suspension Control — Strategy Comparison', ...
    'Color', CLR_TEXT, 'FontSize', FONT_TITLE, 'FontWeight', 'bold');
subtitle(ax, ...
    'Passive vs PID Reactive vs Edge-AI Predictive  |  Plant: G(s) = 1 / (s^2 + 3s + 2)', ...
    'Color', CLR_TEXT_SUB, 'FontSize', FONT_SUBTITLE);

% --- Legend --------------------------------------------------------------
lgd = legend(ax, [h1 h2 h3], 'Location', 'northeast');
lgd.Color     = CLR_LEGEND_BG;
lgd.TextColor = CLR_TEXT;
lgd.FontSize  = FONT_LEGEND;
lgd.EdgeColor = CLR_GRID;
lgd.Box       = 'on';

hold(ax, 'off');
fprintf('  >> Demo figure rendered. Ready for presentation.\n\n');

% --- Launch Cinematic Animation ------------------------------------------
fprintf('  >> Launching high-end cinematic visualization...\n\n');
animate_suspension(t, y_passive, y_pid, y_ai);
