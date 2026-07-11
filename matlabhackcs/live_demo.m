function live_demo()
% =========================================================================
% live_demo.m
% Purpose : Interactive live demo — adjust PID gains, bump timing, and
%           AI preview horizon with sliders; see all three suspension
%           responses update in real time.
% Author  : [Your Name]
% Date    : [Date]
% NOTE: Pure base MATLAB. No toolboxes. Does NOT modify existing files.
% =========================================================================

    %% --- Simulation constants -------------------------------------------
    dt = 0.01;
    t  = (0:dt:10)';
    N  = length(t);
    SETTLE_THR  = 0.02;
    SS_WINDOW   = 50;

    %% --- Default parameter values ---------------------------------------
    def_Kp = 20;  def_Ki = 10;  def_Kd = 5;
    def_bump = 2.0;  def_preview = 0.2;

    %% --- Colors ---------------------------------------------------------
    CLR_BG   = [0.10 0.10 0.10];
    CLR_PNL  = [0.13 0.13 0.13];
    CLR_TXT  = [1 1 1];
    CLR_SUB  = [0.85 0.85 0.85];
    CLR_GRD  = [0.30 0.30 0.30];
    CLR_PAS  = [0.75 0.25 0.25];
    CLR_PID  = [0.20 0.60 1.00];
    CLR_AI   = [0.20 1.00 0.40];
    CLR_ACC  = [0.30 0.75 1.00];

    %% =====================  Figure  =====================================
    fig = figure('Color', CLR_BG, 'Position', [40 60 1420 720], ...
        'Name', 'Live Suspension Demo — Adjust & Observe', ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'figure');

    %% =====================  Axes  =======================================
    ax = axes('Parent', fig, 'Units', 'normalized', ...
        'Position', [0.23 0.13 0.74 0.76], 'Color', CLR_BG);
    hold(ax, 'on');
    grid(ax, 'on');
    ax.GridColor  = CLR_GRD;  ax.GridAlpha = 1;
    ax.XColor = CLR_TXT;  ax.YColor = CLR_TXT;
    ax.XMinorGrid = 'on';  ax.YMinorGrid = 'on';
    ax.MinorGridColor = CLR_GRD;  ax.MinorGridAlpha = 0.4;
    ax.FontSize = 11;  ax.TickDir = 'out';
    xlabel(ax, 'Time (seconds)', 'Color', CLR_TXT, 'FontSize', 12);
    ylabel(ax, 'Chassis Displacement (m)', 'Color', CLR_TXT, 'FontSize', 12);
    title(ax, 'Active Suspension — Live Tuning', ...
        'Color', CLR_TXT, 'FontSize', 15, 'FontWeight', 'bold');
    subtitle(ax, 'Drag sliders to adjust parameters in real time', ...
        'Color', CLR_SUB, 'FontSize', 10);

    % Pre-create line objects (fast YData swap on updates)
    hL1 = plot(ax, t, nan(N,1), '--', 'Color', CLR_PAS, 'LineWidth', 2.0, ...
        'DisplayName', 'Passive');
    hL2 = plot(ax, t, nan(N,1), '-',  'Color', CLR_PID, 'LineWidth', 2.5, ...
        'DisplayName', 'PID Reactive');
    hL3 = plot(ax, t, nan(N,1), '-',  'Color', CLR_AI,  'LineWidth', 2.5, ...
        'DisplayName', 'AI Predictive');
    hBump = xline(ax, def_bump, '--', 'Color', [1 1 1 0.5], 'LineWidth', 1.2);

    lgd = legend(ax, [hL1 hL2 hL3], 'Location', 'northeast');
    lgd.Color = [0.15 0.15 0.15];  lgd.TextColor = CLR_TXT;
    lgd.EdgeColor = CLR_GRD;  lgd.FontSize = 10;

    %% =====================  Slider Panel  ===============================
    % Helper to create one slider group (label + slider + value readout)
    sliders = struct();  valTexts = struct();
    yPositions = [0.84 0.70 0.56 0.42 0.28];
    names   = {'Kp', 'Ki', 'Kd', 'BumpTime', 'Preview'};
    labels  = {'Kp  (Proportional)', 'Ki  (Integral)', ...
               'Kd  (Derivative)', 'Bump Onset (s)', 'AI Preview (s)'};
    ranges  = [0 50; 0 30; 0 20; 0.5 5.0; 0 0.5];
    defaults= [def_Kp, def_Ki, def_Kd, def_bump, def_preview];

    for i = 1:5
        yy = yPositions(i);
        % Label
        uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
            'Position', [0.01 yy+0.04 0.18 0.035], ...
            'String', labels{i}, 'FontSize', 9, 'FontWeight', 'bold', ...
            'ForegroundColor', CLR_ACC, 'BackgroundColor', CLR_BG, ...
            'HorizontalAlignment', 'left');
        % Slider
        s = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
            'Position', [0.01 yy 0.155 0.03], ...
            'Min', ranges(i,1), 'Max', ranges(i,2), ...
            'Value', defaults(i), 'BackgroundColor', CLR_PNL);
        % Value readout
        vt = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
            'Position', [0.165 yy 0.045 0.03], ...
            'String', sprintf('%.1f', defaults(i)), 'FontSize', 10, ...
            'ForegroundColor', CLR_TXT, 'BackgroundColor', CLR_BG, ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        % Continuous listener (fires while dragging)
        addlistener(s, 'ContinuousValueChange', @(~,~) update_plot());
        % Also set Callback for click-release fallback
        s.Callback = @(~,~) update_plot();
        sliders.(names{i}) = s;
        valTexts.(names{i}) = vt;
    end

    %% =====================  Metrics Text  ===============================
    uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.01 0.17 0.18 0.035], ...
        'String', 'PERFORMANCE METRICS', 'FontSize', 10, ...
        'FontWeight', 'bold', 'ForegroundColor', [1 0.85 0.3], ...
        'BackgroundColor', CLR_BG, 'HorizontalAlignment', 'left');
    hMetrics = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.005 0.01 0.21 0.165], ...
        'String', '', 'FontSize', 8, 'FontName', 'Courier New', ...
        'ForegroundColor', CLR_SUB, 'BackgroundColor', [0.08 0.08 0.08], ...
        'HorizontalAlignment', 'left', 'Max', 2);

    %% =====================  Initial render  =============================
    update_plot();

    %% =================================================================
    %  NESTED FUNCTIONS
    %  =================================================================

    function update_plot(~, ~)
        % Read current slider values
        Kp   = get(sliders.Kp, 'Value');
        Ki   = get(sliders.Ki, 'Value');
        Kd   = get(sliders.Kd, 'Value');
        bT   = get(sliders.BumpTime, 'Value');
        pv   = get(sliders.Preview, 'Value');

        % Update value readouts
        set(valTexts.Kp,       'String', sprintf('%.1f', Kp));
        set(valTexts.Ki,       'String', sprintf('%.1f', Ki));
        set(valTexts.Kd,       'String', sprintf('%.1f', Kd));
        set(valTexts.BumpTime, 'String', sprintf('%.2f', bT));
        set(valTexts.Preview,  'String', sprintf('%.2f', pv));

        % --- Disturbance input -------------------------------------------
        u_step = double(t >= bT);

        % --- 1) Passive --------------------------------------------------
        y1 = run_rk4([0 1; -2 -3], [0;1], [1 0], u_step);

        % --- 2) PID Reactive ---------------------------------------------
        % Td(s) = s / (s^3 + (3+Kd)s^2 + (2+Kp)s + Ki)
        A_cl = [0 1 0; 0 0 1; -Ki -(2+Kp) -(3+Kd)];
        y2 = run_rk4(A_cl, [0;0;1], [0 1 0], u_step);

        % --- 3) AI Predictive --------------------------------------------
        ff = zeros(N,1);
        if pv > 0
            ff(t >= (bT - pv) & t < bT) = -1;
        end
        y3 = run_rk4(A_cl, [0;0;1], [0 1 0], u_step + ff);

        % --- Update plot lines -------------------------------------------
        set(hL1, 'YData', y1);
        set(hL2, 'YData', y2);
        set(hL3, 'YData', y3);
        hBump.Value = bT;

        % Auto-scale Y axis with padding
        ym = max([max(abs(y1)) max(abs(y2)) max(abs(y3))]);
        if ym > 0
            ylim(ax, [-ym*0.3  ym*1.25]);
        end

        % --- Compute metrics ---------------------------------------------
        mStr = '';
        labels_m = {'PAS', 'PID', ' AI'};
        ys = {y1, y2, y3};
        idx0 = find(t >= bT, 1, 'first');
        for m = 1:3
            yy_m = ys{m};
            pk = max(abs(yy_m));

            % Settling time
            if ~isempty(idx0)
                yp = abs(yy_m(idx0:end));
                si = [];
                for j = 1:length(yp)
                    if all(yp(j:end) < SETTLE_THR)
                        si = j; break;
                    end
                end
                if isempty(si)
                    st_s = 'N/A';
                else
                    st_s = sprintf('%.2fs', (si-1)*dt);
                end
            else
                st_s = 'N/A';
            end

            ss = mean(abs(yy_m(max(1,end-SS_WINDOW):end)));
            mStr = [mStr sprintf('%s Pk:%.3f Ts:%s SS:%.4f\n', ...
                labels_m{m}, pk, st_s, ss)]; %#ok<AGROW>
        end
        set(hMetrics, 'String', mStr);
        drawnow limitrate;
    end

    function y = run_rk4(A, B, C_out, u)
        ns = size(A, 1);
        x  = zeros(ns, 1);
        y  = zeros(N, 1);
        for kk = 1:N
            y(kk) = C_out * x;
            if kk < N
                uk = u(kk);
                r1 = A*x + B*uk;
                r2 = A*(x + dt/2*r1) + B*uk;
                r3 = A*(x + dt/2*r2) + B*uk;
                r4 = A*(x + dt*r3)   + B*uk;
                x  = x + (dt/6)*(r1 + 2*r2 + 2*r3 + r4);
            end
        end
    end

end
