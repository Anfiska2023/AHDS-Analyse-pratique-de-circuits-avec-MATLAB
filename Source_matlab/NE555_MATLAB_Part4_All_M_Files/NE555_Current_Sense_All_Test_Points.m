%% NE555 Current-Sense / Frequency-Modulation Behavioral Model
% Project: Current-sense controlled NE555 / transformer signal generator
% Purpose: First-pass MATLAB model for test points TP6...TP14
%
% IMPORTANT:
% This is a BEHAVIORAL / ENGINEERING APPROXIMATION based on the current
% schematic and the preliminary calculations. It is intended to visualize
% signal relationships and timing before a more detailed transistor/diode
% model is added.
%
% Assumptions used in this first version:
%   VCC                  = 5 V
%   R-sense              = 5 mOhm
%   Load current         = 0...10 A
%   LM358 DC gain        ~= 30
%   C30 current-sense LPF tau ~= 200 us
%   NE555 nominal freq   ~= 18.4 kHz (including ~0.6 V on D31)
%   D33                  = 1N914
%   D34                  = 5.6 V Zener
%   R35/C29 modulation tau ~= 708 us
%   TP8 is modeled as a transient control node around a DC bias.
%   Q6/555 modulation sensitivity is represented by a tunable coefficient.
%   TP11/TP12 are treated as complementary 5-V primary-drive signals.
%   Transformer ratio is approximated as 100T / 80T = 1.25.
%
% All test-point waveforms are referenced to GND except the isolated
% transformer secondary, where TP13/TP14 are shown using an assumed
% midpoint reference for visualization. The differential TP13-TP14 is the
% physically meaningful output.

clear;
clc;
close all;

%% 1. Global simulation settings
VCC      = 5.0;          % V
dt       = 1e-6;         % 1 us time step
Tsim     = 10e-3;        % 10 ms simulation
t        = 0:dt:Tsim;
N        = numel(t);

%% 2. Circuit parameters
Rsense   = 5e-3;         % 5 mOhm
R38      = 1e3;
R37      = 10e3;
R36      = 330e3;
C30      = 220e-9;

R35      = 330e3;
R34      = 24e3;
C29      = 2e-9;

R32      = 10;
R33      = 5e3;
R29      = 1e3;
C27      = 10e-9;

Vf_D31   = 0.60;         % approximate 1N914 forward drop
Vf_D33   = 0.60;         % approximate 1N914 forward drop
Vz_D34   = 5.60;         % 5.6-V Zener
VCEsat   = 0.10;         % approximate 555 discharge saturation voltage

Npri     = 80;           % transformer primary turns
Nsec     = 100;          % transformer secondary turns
turns_ratio = Nsec / Npri;

%% 3. Derived values
Rin_eff  = R38 + R37;
A_LM358  = R36 / Rin_eff;                        % ~= 30

Rth_C30  = 1 / (1/R38 + 1/R37);
tau_sense = Rth_C30 * C30;
fc_sense  = 1 / (2*pi*tau_sense);

tau_mod   = (R35 + R34) * C29;
fc_mod    = 1 / (2*pi*tau_mod);

RA        = R32 + R33;
RB        = R29;

% NE555 thresholds
VTL = VCC/3;
VTH = 2*VCC/3;

% First-pass frequency estimate including D31 forward drop.
Vcharge_inf = VCC - Vf_D31;

t_charge = RA*C27 * log((Vcharge_inf - VTL) / (Vcharge_inf - VTH));
t_discharge = RB*C27 * log((VTH - VCEsat) / (VTL - VCEsat));

T555_nom = t_charge + t_discharge;
f555_nom = 1 / T555_nom;

fprintf('LM358 approximate DC gain       : %.2f V/V\n', A_LM358);
fprintf('Current-sense LPF tau           : %.1f us\n', tau_sense*1e6);
fprintf('Current-sense LPF fc            : %.1f Hz\n', fc_sense);
fprintf('Modulation path tau             : %.1f us\n', tau_mod*1e6);
fprintf('Modulation path fc              : %.1f Hz\n', fc_mod);
fprintf('Nominal NE555 frequency         : %.1f kHz\n', f555_nom/1e3);

%% 4. Load-current profile: 0...10 A
% This profile is intentionally dynamic so that TP7/TP8 response can be seen.
Iload = zeros(size(t));

% 0 to 1 ms: 0 A
idx = t >= 1e-3 & t < 3e-3;
Iload(idx) = 10 * (t(idx)-1e-3)/(2e-3);         % ramp 0 -> 10 A

idx = t >= 3e-3 & t < 5e-3;
Iload(idx) = 10;                                % hold at 10 A

idx = t >= 5e-3 & t < 6e-3;
Iload(idx) = 10 - 6*(t(idx)-5e-3)/(1e-3);      % ramp 10 -> 4 A

idx = t >= 6e-3 & t < 8e-3;
Iload(idx) = 4;                                 % hold at 4 A

idx = t >= 8e-3 & t < 9e-3;
Iload(idx) = 4 - 4*(t(idx)-8e-3)/(1e-3);       % ramp 4 -> 0 A

Iload(t >= 9e-3) = 0;

%% 5. TP6 - R-sense signal
% Polarity chosen so the inverting LM358 stage generates a positive output.
TP6 = -Iload * Rsense;      % V, 0 to -50 mV

%% 6. TP7 - LM358 amplified + filtered current-sense output
% Ideal target output from the inverting stage:
TP7_target = -A_LM358 * TP6;

% Simple single-pole low-pass approximation from C30 network.
TP7 = zeros(size(t));
alpha_sense = dt / (tau_sense + dt);

for k = 2:N
    TP7(k) = TP7(k-1) + alpha_sense*(TP7_target(k)-TP7(k-1));
end

% Approximate LM358 output swing limitation on 5-V supply.
TP7 = min(max(TP7, 0), 3.5);

%% 7. TP8 - transient modulation/control node
% The R35/C29 path is modeled as a high-pass response to TP7.
% A bias near the D32-clamped region is used so the transient can approach
% the BC558 conduction threshold.
Vbias_TP8 = 4.35;     % approximate bias/clamp level for first-pass model

TP7_lp_mod = zeros(size(t));
alpha_mod = dt / (tau_mod + dt);

for k = 2:N
    TP7_lp_mod(k) = TP7_lp_mod(k-1) + alpha_mod*(TP7(k)-TP7_lp_mod(k-1));
end

HP_mod = TP7 - TP7_lp_mod;

% Tunable shaping gain. Start with 1.0 for transparent interpretation.
Kmod_node = 1.0;

TP8 = Vbias_TP8 + Kmod_node*HP_mod;

% Keep visualization within a reasonable transient range.
TP8 = min(max(TP8, 0), 6.5);

%% 8. Convert TP8 transient into instantaneous 555 frequency
% Approximate BC558 turn-on threshold around VCC + 0.65 V.
VBE_PNP = 0.65;
VQ6_on  = VCC + VBE_PNP;

% Only the amount above threshold modulates frequency in this first model.
Q6_drive = max(TP8 - VQ6_on, 0);

% Frequency sensitivity is not yet known from a full transistor-level
% derivation. Keep it explicit and tunable.
Kf = 5e3;             % Hz/V, behavioral tuning coefficient

f_inst = f555_nom + Kf*Q6_drive;

% Keep frequency inside a practical plotting range.
f_inst = min(max(f_inst, 5e3), 40e3);

%% 9. Generate variable-frequency NE555 output phase
phase = zeros(size(t));
for k = 2:N
    phase(k) = phase(k-1) + 2*pi*f_inst(k)*dt;
end

% Approximate charge/discharge duty cycle from calculated timing.
duty_nom = t_charge / T555_nom;

phase01 = mod(phase, 2*pi)/(2*pi);
TP10 = VCC * (phase01 < duty_nom);    % 555 OUTPUT after R30

%% 10. TP9 - 555 DISCHARGE node
% Approximate:
%   charge interval    -> node near VCC
%   discharge interval -> node near VCEsat
TP9 = VCC * ones(size(t));
TP9(phase01 >= duty_nom) = VCEsat;

%% 11. TP11 and TP12 - complementary transformer-drive signals
% First-pass digital model of the two logic branches.
TP12 = TP10;
TP11 = VCC - TP10;

%% 12. TP13 and TP14 - transformer secondary visualization
% Primary differential drive:
Vpri_diff = TP12 - TP11;            % +/- 5 V in this idealized model

% Ideal transformer differential output:
Vsec_diff = turns_ratio * Vpri_diff;

% The secondary is floating in the schematic.
% For plotting only, assume a virtual midpoint reference:
TP13 = +0.5 * Vsec_diff;
TP14 = -0.5 * Vsec_diff;

f_OUT = TP13 - TP14;                 % differential output

%% 13. Basic numerical summaries
fprintf('\n--- Signal ranges ---\n');
fprintf('Iload   : %.2f to %.2f A\n', min(Iload), max(Iload));
fprintf('TP6     : %.1f to %.1f mV\n', min(TP6)*1e3, max(TP6)*1e3);
fprintf('TP7     : %.2f to %.2f V\n', min(TP7), max(TP7));
fprintf('TP8     : %.2f to %.2f V\n', min(TP8), max(TP8));
fprintf('f_inst  : %.2f to %.2f kHz\n', min(f_inst)/1e3, max(f_inst)/1e3);
fprintf('f_OUT differential peak: %.2f V\n', max(abs(f_OUT)));

%% 14. FIGURE 1 - Current-sense and analog control path
figure('Name','Analog Control Path','Color','w');

subplot(4,1,1);
plot(t*1e3, Iload, 'LineWidth', 1.2);
grid on;
ylabel('I_{LOAD} (A)');
title('Load Current and Analog Test Points');

subplot(4,1,2);
plot(t*1e3, TP6*1e3, 'LineWidth', 1.2);
grid on;
ylabel('TP6 (mV)');

subplot(4,1,3);
plot(t*1e3, TP7, 'LineWidth', 1.2);
grid on;
ylabel('TP7 (V)');

subplot(4,1,4);
plot(t*1e3, TP8, 'LineWidth', 1.2);
grid on;
ylabel('TP8 (V)');
xlabel('Time (ms)');

%% 15. FIGURE 2 - Instantaneous frequency
figure('Name','Instantaneous Frequency','Color','w');

plot(t*1e3, f_inst/1e3, 'LineWidth', 1.4);
grid on;
xlabel('Time (ms)');
ylabel('Frequency (kHz)');
title('Modeled Instantaneous NE555 Frequency');

%% 16. FIGURE 3 - NE555 timing signals, zoomed view
zoom_start = 3.0e-3;
zoom_stop  = 3.4e-3;
z = t >= zoom_start & t <= zoom_stop;

figure('Name','NE555 Timing Signals','Color','w');

subplot(2,1,1);
plot(t(z)*1e3, TP9(z), 'LineWidth', 1.2);
grid on;
ylabel('TP9 (V)');
title('NE555 Timing / Discharge and Output Signals');

subplot(2,1,2);
plot(t(z)*1e3, TP10(z), 'LineWidth', 1.2);
grid on;
ylabel('TP10 (V)');
xlabel('Time (ms)');

%% 17. FIGURE 4 - Transformer primary drive, zoomed view
figure('Name','Transformer Primary Drive','Color','w');

subplot(2,1,1);
plot(t(z)*1e3, TP11(z), 'LineWidth', 1.2);
grid on;
ylabel('TP11 (V)');
title('Transformer Primary Drive Signals');

subplot(2,1,2);
plot(t(z)*1e3, TP12(z), 'LineWidth', 1.2);
grid on;
ylabel('TP12 (V)');
xlabel('Time (ms)');

%% 18. FIGURE 5 - Transformer secondary output, zoomed view
figure('Name','Transformer Secondary','Color','w');

subplot(3,1,1);
plot(t(z)*1e3, TP13(z), 'LineWidth', 1.2);
grid on;
ylabel('TP13 (V)');
title('Transformer Secondary and Differential f-OUT');

subplot(3,1,2);
plot(t(z)*1e3, TP14(z), 'LineWidth', 1.2);
grid on;
ylabel('TP14 (V)');

subplot(3,1,3);
plot(t(z)*1e3, f_OUT(z), 'LineWidth', 1.2);
grid on;
ylabel('TP13-TP14 (V)');
xlabel('Time (ms)');

%% 19. FIGURE 6 - All test points on one diagnostic figure
% This is intentionally dense and intended as a virtual oscilloscope view.
figure('Name','All Test Points','Color','w');

subplot(5,2,1);
plot(t*1e3, TP6*1e3); grid on;
title('TP6'); ylabel('mV');

subplot(5,2,2);
plot(t*1e3, TP7); grid on;
title('TP7'); ylabel('V');

subplot(5,2,3);
plot(t*1e3, TP8); grid on;
title('TP8'); ylabel('V');

subplot(5,2,4);
plot(t(z)*1e3, TP9(z)); grid on;
title('TP9'); ylabel('V');

subplot(5,2,5);
plot(t(z)*1e3, TP10(z)); grid on;
title('TP10'); ylabel('V');

subplot(5,2,6);
plot(t(z)*1e3, TP11(z)); grid on;
title('TP11'); ylabel('V');

subplot(5,2,7);
plot(t(z)*1e3, TP12(z)); grid on;
title('TP12'); ylabel('V');

subplot(5,2,8);
plot(t(z)*1e3, TP13(z)); grid on;
title('TP13'); ylabel('V');

subplot(5,2,9);
plot(t(z)*1e3, TP14(z)); grid on;
title('TP14'); ylabel('V');
xlabel('Time (ms)');

subplot(5,2,10);
plot(t(z)*1e3, f_OUT(z)); grid on;
title('TP13 - TP14'); ylabel('V');
xlabel('Time (ms)');

%% 20. Optional automatic PNG export
% Uncomment these lines after checking the figures in MATLAB Online:
%
% exportgraphics(figure(1),'01_Analog_Control_Path.png','Resolution',200);
% exportgraphics(figure(2),'02_Instantaneous_Frequency.png','Resolution',200);
% exportgraphics(figure(3),'03_NE555_Timing.png','Resolution',200);
% exportgraphics(figure(4),'04_Primary_Drive.png','Resolution',200);
% exportgraphics(figure(5),'05_Secondary_Output.png','Resolution',200);
% exportgraphics(figure(6),'06_All_Test_Points.png','Resolution',200);

%% 21. Notes for the next model revision
% 1. Replace behavioral Q6/Kf model with explicit BC558 transistor equations.
% 2. Add an explicit model for D32 once its exact part number is confirmed.
% 3. Replace constant diode drops with Shockley-diode models if desired.
% 4. Derive the exact frequency-control law from the 555 timing network.
% 5. Add transformer leakage inductance, winding resistance and load.
% 6. Compare MATLAB results with oscilloscope measurements at TP6...TP14.
