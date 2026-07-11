[t, yp] = sim_passive();
[~, ypid] = sim_pid_reactive();
[~, yai] = sim_ai_predictive();

pid_peak = max(abs(ypid));
ai_peak = max(abs(yai));

fprintf('PID overall peak: %f\n', pid_peak);
fprintf('AI overall peak: %f\n', ai_peak);
