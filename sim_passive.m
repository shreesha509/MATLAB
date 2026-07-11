function [t, y] = sim_passive()
% =========================================================================
%
% PASSIVE SUSPENSION PHYSICS
% -------------------------------------------------------------------------
% The plant transfer function is:
%
%   G(s) = 1 / (s^2 + 3s + 2)
%
% Denominator roots (open-loop poles):
%   s^2 + 3s + 2 = (s + 1)(s + 2) = 0  =>  s = -1, s = -2
%
% Both poles are real and negative, so the open-loop plant is BIBO stable.
%
% Natural frequency:  wn   = sqrt(2) ~ 1.414 rad/s
% Damping ratio:      zeta = 3 / (2*sqrt(2)) ~ 1.06
%
% Since zeta > 1 the system is overdamped — no oscillatory ringing occurs.
% However, the dominant pole at s = -1 dictates a time constant of 1 s,
% giving a sluggish 63 % rise in ~1 s and full settling only after ~5 s.
%
% For ride comfort this is unacceptable: the chassis slowly "soaks in" the
% bump and holds an elevated displacement for several seconds before
% gravity and the spring eventually restore equilibrium. Passengers feel a
% long, drawn-out heave rather than a quick, damped correction.
%
% This file serves as the baseline against which the PID-reactive and
% Edge-AI-predictive strategies are compared.
% =========================================================================
%
% STATE-SPACE REALIZATION
% -------------------------------------------------------------------------
% G(s) = 1 / (s^2 + 3s + 2)  in controllable canonical form:
%
%   x' = A*x + B*u       A = [  0   1 ]    B = [ 0 ]
%   y  = C*x                 [ -2  -3 ]        [ 1 ]
%                          C = [ 1   0 ]    D = 0
% =========================================================================


A  = [0 1; -2 -3];
B  = [0; 1];
C_out = [1 0];


dt = 0.01;
t  = (0:dt:10)';               % Unified time vector, 0 to 10 s
N  = length(t);


% Unit step disturbance (road bump) applied at t = 2 s.
% Real bump — wheel goes up then comes back down
u = zeros(N,1);
u(t >= 2.0 & t < 2.3) = 1;   % bump lasts 0.3 seconds

n_states = size(A, 1);
x = zeros(n_states, 1);        % Initial state: chassis at rest
y = zeros(N, 1);

for k = 1:N
    y(k) = C_out * x;
    if k < N
        uk = u(k);
        k1 = A*x       + B*uk;
        k2 = A*(x + dt/2*k1) + B*uk;
        k3 = A*(x + dt/2*k2) + B*uk;
        k4 = A*(x + dt*k3)   + B*uk;
        x  = x + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end

end
