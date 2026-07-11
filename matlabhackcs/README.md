# Active Suspension Control System
### Problem Statement 4 — Control Systems Design

> A MATLAB-based simulation comparing passive, PID-reactive, and Edge-AI-predictive suspension strategies for disturbance rejection against a road-bump input.

---

## Table of Contents
- [Overview](#overview)
- [Plant Model](#plant-model)
- [Control Strategies](#control-strategies)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Results](#results)
- [Performance Metrics](#performance-metrics)
- [Theory](#theory)
- [Requirements](#requirements)

---

## Overview

This project designs and simulates an **active suspension control system** to minimize vehicle vibrations caused by road disturbances. Three strategies are implemented and compared:

| Strategy | Description |
|---|---|
| **Passive** | Open-loop, no controller — baseline |
| **PID Reactive** | Closed-loop PID feedback for disturbance rejection |
| **AI Predictive** | Feedforward pre-actuation (200 ms horizon) + PID feedback |

The simulation is entirely toolbox-free — runs on **base MATLAB R2020b+** only.

---

## Plant Model

The suspension plant transfer function is:

$$G(s) = \frac{1}{s^2 + 3s + 2}$$

**Open-loop characteristics:**

| Parameter | Value |
|---|---|
| Poles | s = −1, s = −2 |
| Natural frequency ωn | √2 ≈ 1.414 rad/s |
| Damping ratio ζ | 3/(2√2) ≈ 1.06 (overdamped) |
| DC gain G(0) | 0.5 |
| Stability | Stable — both poles in LHP |

The overdamped open-loop response has a dominant time constant of ~1 s, causing the chassis to slowly absorb a road bump and hold elevated displacement for ~5 s with no active control.

---

## Control Strategies

### 1. Passive (Open-Loop)
State-space realization of G(s) in controllable canonical form:

```
A = [ 0   1 ]    B = [ 0 ]    C = [ 1  0 ]
    [-2  -3 ]        [ 1 ]
```

Disturbance (road bump) modeled as a unit step at t = 2 s.
At steady state, chassis settles at y = 0.5 m — a permanent elevation with no restoring control force.

---

### 2. PID Reactive (Closed-Loop)

**Gains:** Kp = 20, Kd = 5, Ki = 10

PID controller:

$$C(s) = \frac{K_d s^2 + K_p s + K_i}{s} = \frac{5s^2 + 20s + 10}{s}$$

Closed-loop disturbance rejection transfer function:

$$T_d(s) = \frac{G(s)}{1 + C(s)G(s)} = \frac{s}{s^3 + 8s^2 + 22s + 10}$$

**Routh stability check** for `s³ + 8s² + 22s + 10`:

| Row | Values |
|---|---|
| s³ | 1, 22 |
| s² | 8, 10 |
| s¹ | 22 − 10/8 = **20.75 > 0** |
| s⁰ | 10 > 0 |

All entries positive → closed-loop is **stable**.

State-space (controllable canonical form of Td):

```
A = [  0    1    0  ]    B = [ 0 ]    C = [ 0  1  0 ]
    [  0    0    1  ]        [ 0 ]
    [-Ki  -(Kp+2)  -(Kd+3)]  [ 1 ]
```

---

### 3. AI Predictive (Feedforward + PID)

Models an **Edge-AI system** (LIDAR/camera + on-board inference) that detects a road obstacle 200 ms before impact and pre-actuates the damper with a counter-pulse.

**Composite input:**

```
U(t) = disturbance_step(t) + feedforward_pulse(t)

disturbance_step:   0 for t < 2,   1 for t ≥ 2
feedforward_pulse: −1 for 1.8 ≤ t < 2.0,   0 otherwise
```

Uses the same closed-loop transfer function Td(s) as the PID strategy. The pre-actuation phase loads the actuator before impact, reducing peak displacement and settling time.

---

## Project Structure

```
active-suspension-control/
│
├── main_presentation.m      # Master script: calls all sims, computes metrics, renders figure
├── sim_passive.m            # Open-loop passive suspension simulation (RK4)
├── sim_pid_reactive.m       # PID closed-loop disturbance rejection (RK4)
├── sim_ai_predictive.m      # AI feedforward + PID hybrid (RK4)
└── README.md
```

---

## Getting Started

### Prerequisites
- MATLAB R2020b or later
- No toolboxes required (base MATLAB only)

### Run

```matlab
% Clone or download all four .m files into the same folder.
% In MATLAB, navigate to that folder and run:

main_presentation.m
```

This will:
1. Print open-loop plant analysis to the Command Window
2. Run all three simulations (RK4 integration, dt = 0.01 s, 0–10 s)
3. Compute and print the performance metrics table
4. Render the dark-themed comparison figure

---

## Results

The comparison plot shows chassis displacement (m) vs time (s) for a unit-step road bump at t = 2 s:

- **Red dashed** — Passive: chassis rises to 0.5 m and stays permanently elevated
- **Blue solid** — PID reactive: disturbance rejected, chassis returns near zero within ~3 s
- **Green solid** — AI predictive: pre-actuation reduces peak, fastest settling

---

## Performance Metrics

| Metric | Passive | PID Reactive | AI Predictive |
|---|---|---|---|
| Peak displacement | ~0.5000 m | ~0.0031 m | ~0.0018 m |
| Settling time | > 8.0 s | ~2.8 s | ~2.2 s |
| Steady-state error | 0.5000 m | ~0.000 m | ~0.000 m |
| Damping quality | Overdamped/Sluggish | Critically Optimized | Critically Optimized |

> Settling threshold: ±0.02 m (2% band). Evaluated post-disturbance from t = 2 s.

---

## Theory

### Why the Passive Chassis Doesn't Return to Zero

The passive system has no feedback. For a sustained step input (wheel on raised road), the Final Value Theorem gives:

$$y(\infty) = \lim_{s \to 0} \, s \cdot G(s) \cdot \frac{1}{s} = G(0) = \frac{1}{2} = 0.5 \text{ m}$$

The chassis reaches a new equilibrium 0.5 m above rest — no restoring force exists without active control.

### Why PID Returns to Zero

The integral term in the PID controller accumulates an error signal and generates a sustained force that drives the steady-state error to exactly zero:

$$\lim_{s \to 0} \, s \cdot T_d(s) \cdot \frac{1}{s} = T_d(0) = \frac{0}{10} = 0$$

### Numerical Integration

All simulations use **4th-order Runge-Kutta (RK4)** with a fixed time step dt = 0.01 s:

$$x_{k+1} = x_k + \frac{\Delta t}{6}(k_1 + 2k_2 + 2k_3 + k_4)$$

No `ode45`, no Simulink, no toolbox dependencies.

---

## Requirements

| Item | Version |
|---|---|
| MATLAB | R2020b+ |
| Toolboxes | None |
| OS | Any (Windows / macOS / Linux) |

---

## Authors

**Shreesha**
Electronics and Communication Engineering — IV Semester
BNMIT, Bengaluru

**Yashwanth Udupa**
Artificial Intelligence & Machine Learning — IV Semester
BNMIT, Bengaluru

---

## License

This project is submitted as part of an academic control systems design challenge. Free to use for educational reference.
