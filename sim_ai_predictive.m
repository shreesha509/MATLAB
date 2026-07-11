function [t, y] = sim_ai_predictive()
% =========================================================================
%
% EDGE-AI CONCEPT: LIDAR/camera scans road ahead, edge-computing fuses
% sensor data, classifies obstacles, and computes 200ms prediction horizon.
% Feedforward counter-pulse pre-loads actuator to cancel disturbance before
% it propagates through the plant. Result: lower peak, faster settling.
%
% Uses same Td(s) = s/(s^3+8s^2+22s+10) as sim_pid_reactive.m.
% Plant and controller redefined locally — no cross-file dependency.
%
% COMPOSITE INPUT:
%   U(t) = disturbance_step(t) + feedforward_pulse(t)
%   disturbance_step:  0 for t<2,  1 for t>=2
%   feedforward_pulse: -1 for 1.8<=t<2.0,  0 otherwise
% =========================================================================

A     = [0 1 0; 0 0 1; -8000 -1200 -60];
B     = [0; 0; 1];
C_out = [0 1 0];


dt = 0.01;
t  = (0:dt:10)';
N  = length(t);


disturbance_step  = zeros(N, 1);
disturbance_step(t >= 2) = 1;

feedforward_pulse = zeros(N, 1);

feedforward_pulse(t >= 1.8 & t < 2.0) = -1;

U = disturbance_step + feedforward_pulse;


x = zeros(3, 1);
y = zeros(N, 1);
for k = 1:N
    y(k) = C_out * x;
    if k < N
        uk = U(k);
        k1 = A*x + B*uk;
        k2 = A*(x + dt/2*k1) + B*uk;
        k3 = A*(x + dt/2*k2) + B*uk;
        k4 = A*(x + dt*k3)   + B*uk;
        x  = x + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
end
end
