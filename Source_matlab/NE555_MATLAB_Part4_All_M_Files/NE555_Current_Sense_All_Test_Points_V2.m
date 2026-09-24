%% NE555 Current-Sense / Frequency-Modulation Behavioral Model - VERSION 2
% Purpose:
%   Test the existing circuit with a FAST 0 -> 10 A current step.
%
% IMPORTANT:
%   Component values, LM358 gain and transistor threshold assumptions are
%   intentionally kept the same as Version 1.
%
%   The only major change is the load-current waveform:
%       0 A -> 10 A STEP -> hold -> 0 A STEP
%
%   This lets us test whether the R35/C29 transient path can raise TP8 high
%   enough to turn on Q6 (BC558) and therefore change the NE555 frequency.
%
%   If TP8 still does not exceed the approximate Q6 threshold, the next
%   step will be to revisit the gain / bias / transistor model rather than
%   artificially forcing modulation.

clear;
clc;
close all;

%% 1. Global simulation settings
VCC  = 5.0;
dt   = 0.5e-6;      % 0.5 us for better edge resolution
Tsim = 6e-3;        % 6 ms
t    = 0:dt:Tsim;
N    = numel(t);

%% 2. Circuit parameters
Rsense = 5e-3;      % 5 mOhm

R38 = 1e3;
R37 = 10e3;
R36 = 330e3;
C30 = 220e-9;

R35 = 330e3;
R34 = 24e3;
C29 = 2e-9;

R32 = 10;
R33 = 5e3;
R29 = 1e3;
C27 = 10e-9;

Vf_D31 = 0.60;      % 1N914 approximation
Vf_D33 = 0.60;      % 1N914 approximation
Vz_D34 = 5.60;      % Zener
VCEsat = 0.10;

Npri = 80;
Nsec = 100;
turns_ratio = Nsec/Npri;

%% 3. Derived values
Rin_eff = R38 + R37;
A_LM358 = R36 / Rin_eff;

Rth_C30  = 1/(1/R38 + 1/R37);
tau_sense = Rth_C30*C30;
fc_sense  = 1/(2*pi*tau_sense);

tau_mod = (R35 + R34)*C29;
fc_mod  = 1/(2*pi*tau_mod);

RA = R32 + R33;
RB = R29;

VTL = VCC/3;
VTH = 2*VCC/3;

Vcharge_inf = VCC - Vf_D31;

t_charge = RA*C27 * log((Vcharge_inf - VTL)/(Vcharge_inf - VTH));
t_discharge = RB*C27 * log((VTH - VCEsat)/(VTL - VCEsat));

T555_nom = t_charge + t_discharge;
f555_nom = 1/T555_nom;
duty_nom = t_charge/T555_nom;

fprintf('VERSION 2 - FAST CURRENT STEP TEST\n');
fprintf('LM358 gain                  : %.2f V/V\n', A_LM358);
fprintf('Current-sense tau           : %.1f us\n', tau_sense*1e6);
fprintf('Current-sense fc            : %.1f Hz\n', fc_sense);
fprintf('Modulation-path tau         : %.1f us\n', tau_mod*1e6);
fprintf('Modulation-path fc          : %.1f Hz\n', fc_mod);
fprintf('Nominal NE555 frequency     : %.2f kHz\n\n', f555_nom/1e3);

%% 4. FAST load-current profile
% 0 A from 0 to 1 ms
% 10 A step at 1 ms
% hold 10 A until 4 ms
% 0 A step at 4 ms

Iload = zeros(size(t));
Iload(t >= 1e-3 & t < 4e-3) = 10;

%% 5. TP6 - R-sense voltage
% Polarity selected for the inverting LM358 model.
TP6 = -Iload * Rsense;

%% 6. TP7 - LM358 output
TP7_target = -A_LM358 * TP6;

TP7 = zeros(size(t));
alpha_sense = dt/(tau_sense + dt);

for k = 2:N
    TP7(k) = TP7(k-1) + alpha_sense*(TP7_target(k)-TP7(k-1));
end

% Approximate LM358 output range on 5-V supply
TP7 = min(max(TP7,0),3.5);

%% 7. TP8 - AC-coupled modulation node
% First-pass model:
%   R35/C29 acts as a high-pass / transient path.
%   TP8 has an assumed DC bias around 4.35 V.
%
% NOTE:
%   This bias is still a behavioral approximation and will be refined later.

Vbias_TP8 = 4.35;

TP7_lp_mod = zeros(size(t));
alpha_mod = dt/(tau_mod + dt);

for k = 2:N
    TP7_lp_mod(k) = TP7_lp_mod(k-1) + alpha_mod*(TP7(k)-TP7_lp_mod(k-1));
end

HP_mod = TP7 - TP7_lp_mod;

Kmod_node = 1.0;       % do NOT artificially increase in Version 2
TP8 = Vbias_TP8 + Kmod_node*HP_mod;

TP8 = min(max(TP8,0),6.5);

%% 8. Q6 threshold and drive
% BC558 is PNP.
% With base approximately at +5 V, emitter must rise above base by ~0.65 V.
VBE_PNP = 0.65;
VQ6_on  = VCC + VBE_PNP;      % ~5.65 V

Q6_drive = max(TP8 - VQ6_on,0);

%% 9. Frequency modulation model
% Keep the same behavioral sensitivity as Version 1.
% If Q6_drive remains zero, frequency MUST remain nominal.
Kf = 5e3;                     % Hz/V

f_inst = f555_nom + Kf*Q6_drive;
f_inst = min(max(f_inst,5e3),40e3);

%% 10. Variable-frequency phase generator
phase = zeros(size(t));

for k = 2:N
    phase(k) = phase(k-1) + 2*pi*f_inst(k)*dt;
end

phase01 = mod(phase,2*pi)/(2*pi);

%% 11. TP10 - NE555 output
TP10 = VCC*(phase01 < duty_nom);

%% 12. TP9 - NE555 discharge node
TP9 = VCC*ones(size(t));
TP9(phase01 >= duty_nom) = VCEsat;

%% 13. TP11 / TP12 - transformer primary drive
TP12 = TP10;
TP11 = VCC - TP10;

%% 14. TP13 / TP14 - transformer secondary
Vpri_diff = TP12 - TP11;
Vsec_diff = turns_ratio*Vpri_diff;

% Floating secondary represented with a virtual midpoint for plotting only
TP13 = +0.5*Vsec_diff;
TP14 = -0.5*Vsec_diff;

f_OUT = TP13 - TP14;

%% 15. Numerical results
fprintf('--- VERSION 2 RESULTS ---\n');
fprintf('TP6 range                  : %.1f to %.1f mV\n', min(TP6)*1e3, max(TP6)*1e3);
fprintf('TP7 range                  : %.3f to %.3f V\n', min(TP7), max(TP7));
fprintf('TP8 range                  : %.3f to %.3f V\n', min(TP8), max(TP8));
fprintf('Approx. Q6 threshold       : %.3f V\n', VQ6_on);
fprintf('Maximum Q6 drive           : %.3f V\n', max(Q6_drive));
fprintf('Frequency range            : %.3f to %.3f kHz\n', min(f_inst)/1e3, max(f_inst)/1e3);

if max(TP8) > VQ6_on
    fprintf('\nRESULT: TP8 crosses the Q6 threshold. Frequency modulation is expected.\n');
else
    fprintf('\nRESULT: TP8 does NOT cross the Q6 threshold.\n');
    fprintf('The fast 0 -> 10 A step is still insufficient in this behavioral model.\n');
    fprintf('Next step: revisit LM358 gain, TP8 bias, D32/Q6 model, or coupling network.\n');
end

%% 16. Figure 1 - Current and analog path
figure('Name','V2 Analog Control Path','Color','w');

subplot(4,1,1);
plot(t*1e3,Iload,'LineWidth',1.3);
grid on;
ylabel('I_{LOAD} (A)');
title('Version 2 - Fast 0 to 10 A Current Step');

subplot(4,1,2);
plot(t*1e3,TP6*1e3,'LineWidth',1.3);
grid on;
ylabel('TP6 (mV)');

subplot(4,1,3);
plot(t*1e3,TP7,'LineWidth',1.3);
grid on;
ylabel('TP7 (V)');

subplot(4,1,4);
plot(t*1e3,TP8,'LineWidth',1.3);
hold on;
yline(VQ6_on,'--','Q6 threshold');
grid on;
ylabel('TP8 (V)');
xlabel('Time (ms)');

%% 17. Figure 2 - TP8 and Q6 threshold
figure('Name','V2 Q6 Turn-On Test','Color','w');

plot(t*1e3,TP8,'LineWidth',1.5);
hold on;
yline(VQ6_on,'--','Q6 turn-on threshold');
grid on;
xlabel('Time (ms)');
ylabel('Voltage (V)');
title('TP8 Versus Approximate BC558 Turn-On Threshold');

%% 18. Figure 3 - Q6 drive
figure('Name','V2 Q6 Drive','Color','w');

plot(t*1e3,Q6_drive,'LineWidth',1.5);
grid on;
xlabel('Time (ms)');
ylabel('Q6 drive above threshold (V)');
title('Behavioral Q6 Drive');

%% 19. Figure 4 - Instantaneous frequency
figure('Name','V2 Instantaneous Frequency','Color','w');

plot(t*1e3,f_inst/1e3,'LineWidth',1.5);
grid on;
xlabel('Time (ms)');
ylabel('Frequency (kHz)');
title('Version 2 - Modeled Instantaneous NE555 Frequency');

%% 20. Zoom around rising current edge
zoom_start = 0.90e-3;
zoom_stop  = 1.60e-3;
z = t >= zoom_start & t <= zoom_stop;

figure('Name','V2 Rising Edge Detail','Color','w');

subplot(4,1,1);
plot(t(z)*1e3,Iload(z),'LineWidth',1.2);
grid on;
ylabel('A');
title('Rising-Edge Detail');

subplot(4,1,2);
plot(t(z)*1e3,TP7(z),'LineWidth',1.2);
grid on;
ylabel('TP7 (V)');

subplot(4,1,3);
plot(t(z)*1e3,TP8(z),'LineWidth',1.2);
hold on;
yline(VQ6_on,'--');
grid on;
ylabel('TP8 (V)');

subplot(4,1,4);
plot(t(z)*1e3,f_inst(z)/1e3,'LineWidth',1.2);
grid on;
ylabel('kHz');
xlabel('Time (ms)');

%% 21. Zoom around falling current edge
zoom_start2 = 3.90e-3;
zoom_stop2  = 4.60e-3;
z2 = t >= zoom_start2 & t <= zoom_stop2;

figure('Name','V2 Falling Edge Detail','Color','w');

subplot(4,1,1);
plot(t(z2)*1e3,Iload(z2),'LineWidth',1.2);
grid on;
ylabel('A');
title('Falling-Edge Detail');

subplot(4,1,2);
plot(t(z2)*1e3,TP7(z2),'LineWidth',1.2);
grid on;
ylabel('TP7 (V)');

subplot(4,1,3);
plot(t(z2)*1e3,TP8(z2),'LineWidth',1.2);
hold on;
yline(VQ6_on,'--');
grid on;
ylabel('TP8 (V)');

subplot(4,1,4);
plot(t(z2)*1e3,f_inst(z2)/1e3,'LineWidth',1.2);
grid on;
ylabel('kHz');
xlabel('Time (ms)');

%% 22. Test-point oscilloscope view
% Use a short interval after the rising edge for fast digital signals.
osc_start = 1.2e-3;
osc_stop  = 1.6e-3;
zo = t >= osc_start & t <= osc_stop;

figure('Name','V2 All Test Points','Color','w');

subplot(5,2,1);
plot(t*1e3,TP6*1e3); grid on;
title('TP6'); ylabel('mV');

subplot(5,2,2);
plot(t*1e3,TP7); grid on;
title('TP7'); ylabel('V');

subplot(5,2,3);
plot(t*1e3,TP8); hold on; yline(VQ6_on,'--'); grid on;
title('TP8'); ylabel('V');

subplot(5,2,4);
plot(t(zo)*1e3,TP9(zo)); grid on;
title('TP9'); ylabel('V');

subplot(5,2,5);
plot(t(zo)*1e3,TP10(zo)); grid on;
title('TP10'); ylabel('V');

subplot(5,2,6);
plot(t(zo)*1e3,TP11(zo)); grid on;
title('TP11'); ylabel('V');

subplot(5,2,7);
plot(t(zo)*1e3,TP12(zo)); grid on;
title('TP12'); ylabel('V');

subplot(5,2,8);
plot(t(zo)*1e3,TP13(zo)); grid on;
title('TP13'); ylabel('V');

subplot(5,2,9);
plot(t(zo)*1e3,TP14(zo)); grid on;
title('TP14'); ylabel('V');
xlabel('Time (ms)');

subplot(5,2,10);
plot(t(zo)*1e3,f_OUT(zo)); grid on;
title('TP13 - TP14'); ylabel('V');
xlabel('Time (ms)');

%% 23. Optional export
% Uncomment after checking the figures:
%
% exportgraphics(figure(1),'V2_01_Analog_Path.png','Resolution',200);
% exportgraphics(figure(2),'V2_02_TP8_Threshold.png','Resolution',200);
% exportgraphics(figure(3),'V2_03_Q6_Drive.png','Resolution',200);
% exportgraphics(figure(4),'V2_04_Frequency.png','Resolution',200);
% exportgraphics(figure(5),'V2_05_Rising_Edge.png','Resolution',200);
% exportgraphics(figure(6),'V2_06_Falling_Edge.png','Resolution',200);
% exportgraphics(figure(7),'V2_07_All_Test_Points.png','Resolution',200);
