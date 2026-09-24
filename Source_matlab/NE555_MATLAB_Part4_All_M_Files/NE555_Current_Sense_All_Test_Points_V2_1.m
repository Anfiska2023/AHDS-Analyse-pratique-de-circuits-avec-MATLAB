%% NE555 Current-Sense Model - VERSION 2.1
% Robust plotting version for MATLAB Online
% Same electrical assumptions as Version 2.
% Main goals:
%   1) Force figures to render correctly in MATLAB Online.
%   2) Keep the fast 0 -> 10 A current-step test.
%   3) Show TP6...TP14 and the Q6 threshold clearly.
%
% NOTE:
% Version 2 result already showed:
%   TP8 max ~= 5.261 V
%   Q6 threshold ~= 5.650 V
% Therefore Q6 does NOT turn on in this behavioral model and the
% instantaneous frequency remains at the nominal ~18.39 kHz.
%
% This file DOES NOT artificially change gain, bias, or frequency.
% It only makes the plotting more robust and explicit.

clear;
clc;
close all force;

set(groot,'defaultFigureVisible','on');

%% 1. Simulation settings
VCC  = 5.0;
dt   = 0.5e-6;
Tsim = 6e-3;
t    = 0:dt:Tsim;
N    = numel(t);

%% 2. Circuit parameters
Rsense = 5e-3;

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

Vf_D31 = 0.60;
VCEsat = 0.10;

Npri = 80;
Nsec = 100;
turns_ratio = Nsec/Npri;

%% 3. Derived values
A_LM358 = R36/(R38+R37);

Rth_C30   = 1/(1/R38 + 1/R37);
tau_sense = Rth_C30*C30;
fc_sense  = 1/(2*pi*tau_sense);

tau_mod = (R35+R34)*C29;
fc_mod  = 1/(2*pi*tau_mod);

RA = R32 + R33;
RB = R29;

VTL = VCC/3;
VTH = 2*VCC/3;

Vcharge_inf = VCC - Vf_D31;

t_charge = RA*C27 * log((Vcharge_inf-VTL)/(Vcharge_inf-VTH));
t_discharge = RB*C27 * log((VTH-VCEsat)/(VTL-VCEsat));

T555_nom = t_charge + t_discharge;
f555_nom = 1/T555_nom;
duty_nom = t_charge/T555_nom;

%% 4. Fast current-step profile
Iload = zeros(size(t));
Iload(t >= 1e-3 & t < 4e-3) = 10;

%% 5. TP6
TP6 = -Iload*Rsense;

%% 6. TP7
TP7_target = -A_LM358*TP6;

TP7 = zeros(size(t));
alpha_sense = dt/(tau_sense+dt);

for k = 2:N
    TP7(k) = TP7(k-1) + alpha_sense*(TP7_target(k)-TP7(k-1));
end

TP7 = min(max(TP7,0),3.5);

%% 7. TP8 behavioral transient node
Vbias_TP8 = 4.35;

TP7_lp_mod = zeros(size(t));
alpha_mod = dt/(tau_mod+dt);

for k = 2:N
    TP7_lp_mod(k) = TP7_lp_mod(k-1) + alpha_mod*(TP7(k)-TP7_lp_mod(k-1));
end

HP_mod = TP7 - TP7_lp_mod;
TP8 = Vbias_TP8 + HP_mod;

TP8 = min(max(TP8,0),6.5);

%% 8. Q6 threshold
VBE_PNP = 0.65;
VQ6_on = VCC + VBE_PNP;
Q6_drive = max(TP8 - VQ6_on,0);

%% 9. Frequency
Kf = 5e3;
f_inst = f555_nom + Kf*Q6_drive;

%% 10. NE555 waveforms
phase = zeros(size(t));
for k = 2:N
    phase(k) = phase(k-1) + 2*pi*f_inst(k)*dt;
end

phase01 = mod(phase,2*pi)/(2*pi);

TP10 = VCC*(phase01 < duty_nom);

TP9 = VCC*ones(size(t));
TP9(phase01 >= duty_nom) = VCEsat;

%% 11. Primary and secondary
TP12 = TP10;
TP11 = VCC - TP10;

Vpri_diff = TP12 - TP11;
Vsec_diff = turns_ratio*Vpri_diff;

TP13 = +0.5*Vsec_diff;
TP14 = -0.5*Vsec_diff;
f_OUT = TP13 - TP14;

%% 12. Console summary
fprintf('\nVERSION 2.1 - ROBUST PLOTTING\n');
fprintf('LM358 gain                  : %.2f V/V\n',A_LM358);
fprintf('Current-sense tau           : %.1f us\n',tau_sense*1e6);
fprintf('Current-sense fc            : %.1f Hz\n',fc_sense);
fprintf('Modulation-path tau         : %.1f us\n',tau_mod*1e6);
fprintf('Modulation-path fc          : %.1f Hz\n',fc_mod);
fprintf('Nominal NE555 frequency     : %.3f kHz\n',f555_nom/1e3);

fprintf('\n--- RESULTS ---\n');
fprintf('TP6 range                   : %.1f to %.1f mV\n',min(TP6)*1e3,max(TP6)*1e3);
fprintf('TP7 range                   : %.3f to %.3f V\n',min(TP7),max(TP7));
fprintf('TP8 range                   : %.3f to %.3f V\n',min(TP8),max(TP8));
fprintf('Q6 threshold                : %.3f V\n',VQ6_on);
fprintf('Maximum Q6 drive            : %.3f V\n',max(Q6_drive));
fprintf('Frequency range             : %.3f to %.3f kHz\n',min(f_inst)/1e3,max(f_inst)/1e3);

%% 13. FIGURE 1 - Slow analog/control signals
f1 = figure('Name','V2.1 Analog and Control Signals','NumberTitle','off',...
            'Color','w','Visible','on');

ax1 = subplot(5,1,1);
plot(t*1e3,Iload,'LineWidth',1.4);
grid on;
ylabel('A');
title('Load Current');

ax2 = subplot(5,1,2);
plot(t*1e3,TP6*1e3,'LineWidth',1.4);
grid on;
ylabel('mV');
title('TP6 - Current Sense');

ax3 = subplot(5,1,3);
plot(t*1e3,TP7,'LineWidth',1.4);
grid on;
ylabel('V');
title('TP7 - LM358 Output');

ax4 = subplot(5,1,4);
plot(t*1e3,TP8,'LineWidth',1.4);
hold on;
plot(t*1e3,VQ6_on*ones(size(t)),'--','LineWidth',1.0);
grid on;
ylabel('V');
title('TP8 - Modulation Node / Q6 Threshold');

ax5 = subplot(5,1,5);
plot(t*1e3,f_inst/1e3,'LineWidth',1.4);
grid on;
ylabel('kHz');
xlabel('Time (ms)');
title('Instantaneous NE555 Frequency');

linkaxes([ax1 ax2 ax3 ax4 ax5],'x');
xlim([0 Tsim*1e3]);

drawnow;
pause(0.1);

%% 14. FIGURE 2 - Zoom around the rising edge
z = t >= 0.90e-3 & t <= 1.80e-3;

f2 = figure('Name','V2.1 Rising Edge Detail','NumberTitle','off',...
            'Color','w','Visible','on');

subplot(4,1,1);
plot(t(z)*1e3,Iload(z),'LineWidth',1.4);
grid on;
ylabel('A');
title('0 A to 10 A Step');

subplot(4,1,2);
plot(t(z)*1e3,TP7(z),'LineWidth',1.4);
grid on;
ylabel('V');
title('TP7');

subplot(4,1,3);
plot(t(z)*1e3,TP8(z),'LineWidth',1.4);
hold on;
plot(t(z)*1e3,VQ6_on*ones(1,sum(z)),'--','LineWidth',1.0);
grid on;
ylabel('V');
title('TP8 and Q6 Threshold');

subplot(4,1,4);
plot(t(z)*1e3,f_inst(z)/1e3,'LineWidth',1.4);
grid on;
ylabel('kHz');
xlabel('Time (ms)');
title('Instantaneous Frequency');

drawnow;
pause(0.1);

%% 15. FIGURE 3 - Fast digital test points
zo = t >= 1.20e-3 & t <= 1.60e-3;

f3 = figure('Name','V2.1 Digital Test Points','NumberTitle','off',...
            'Color','w','Visible','on');

subplot(4,2,1);
plot(t(zo)*1e3,TP9(zo),'LineWidth',1.2);
grid on; title('TP9'); ylabel('V');

subplot(4,2,2);
plot(t(zo)*1e3,TP10(zo),'LineWidth',1.2);
grid on; title('TP10'); ylabel('V');

subplot(4,2,3);
plot(t(zo)*1e3,TP11(zo),'LineWidth',1.2);
grid on; title('TP11'); ylabel('V');

subplot(4,2,4);
plot(t(zo)*1e3,TP12(zo),'LineWidth',1.2);
grid on; title('TP12'); ylabel('V');

subplot(4,2,5);
plot(t(zo)*1e3,TP13(zo),'LineWidth',1.2);
grid on; title('TP13'); ylabel('V');

subplot(4,2,6);
plot(t(zo)*1e3,TP14(zo),'LineWidth',1.2);
grid on; title('TP14'); ylabel('V');

subplot(4,2,[7 8]);
plot(t(zo)*1e3,f_OUT(zo),'LineWidth',1.2);
grid on;
title('Differential f-OUT = TP13 - TP14');
ylabel('V');
xlabel('Time (ms)');

drawnow;
pause(0.1);

%% 16. Automatic diagnostic PNG export
% This is useful if MATLAB Online displays a figure window incorrectly.
% The PNG files will appear in the Current Folder.

exportgraphics(f1,'V2_1_Analog_Control.png','Resolution',180);
exportgraphics(f2,'V2_1_Rising_Edge.png','Resolution',180);
exportgraphics(f3,'V2_1_Digital_Test_Points.png','Resolution',180);

fprintf('\nThree PNG files were exported automatically:\n');
fprintf('  V2_1_Analog_Control.png\n');
fprintf('  V2_1_Rising_Edge.png\n');
fprintf('  V2_1_Digital_Test_Points.png\n');
fprintf('If MATLAB Online figure windows are blank, open these PNG files directly.\n');

drawnow;
