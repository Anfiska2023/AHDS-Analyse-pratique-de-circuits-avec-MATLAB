%% NE555 Current-Sense Model - VERSION 2.3
% MATLAB Online exportgraphics version
%
% Purpose:
%   Re-run the Version 2 fast-current-step model and save all plots using
%   exportgraphics(), which is generally more reliable in MATLAB Online.
%
% Electrical assumptions are intentionally unchanged from Versions 2.1/2.2:
%   - VCC = 5 V
%   - R-sense = 5 mOhm
%   - Load current step = 0 A -> 10 A -> 0 A
%   - LM358 gain ~= 30
%   - TP8 behavioral bias ~= 4.35 V
%   - BC558 turn-on threshold approximation ~= 5.65 V
%   - Nominal NE555 frequency ~= 18.39 kHz
%
% IMPORTANT:
%   This remains a behavioral engineering model.
%   The purpose of Version 2.3 is mainly to solve the MATLAB Online
%   graphics/export problem while keeping the same electrical calculation.

clear;
clc;
close all force;

%% 1. Simulation settings
VCC  = 5.0;
dt   = 0.5e-6;      % 0.5 us
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

Vf_D31 = 0.60;      % Approx. 1N914 forward drop
VCEsat = 0.10;      % Approx. 555 discharge-transistor saturation

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
% 0 A from 0 to 1 ms
% 10 A from 1 to 4 ms
% 0 A after 4 ms
Iload = zeros(size(t));
Iload(t >= 1e-3 & t < 4e-3) = 10;

%% 5. TP6 - R-sense voltage
% Polarity chosen for the inverting LM358 model.
TP6 = -Iload*Rsense;

%% 6. TP7 - LM358 output
TP7_target = -A_LM358*TP6;

TP7 = zeros(size(t));
alpha_sense = dt/(tau_sense+dt);

for k = 2:N
    TP7(k) = TP7(k-1) + alpha_sense*(TP7_target(k)-TP7(k-1));
end

% Approximate LM358 output range on 5-V supply
TP7 = min(max(TP7,0),3.5);

%% 7. TP8 - behavioral transient modulation node
Vbias_TP8 = 4.35;

TP7_lp_mod = zeros(size(t));
alpha_mod = dt/(tau_mod+dt);

for k = 2:N
    TP7_lp_mod(k) = TP7_lp_mod(k-1) + ...
                    alpha_mod*(TP7(k)-TP7_lp_mod(k-1));
end

HP_mod = TP7 - TP7_lp_mod;

Kmod_node = 1.0;     % no artificial gain increase
TP8 = Vbias_TP8 + Kmod_node*HP_mod;

TP8 = min(max(TP8,0),6.5);

%% 8. Q6 threshold and behavioral drive
VBE_PNP = 0.65;
VQ6_on  = VCC + VBE_PNP;      % approx. 5.65 V

Q6_drive = max(TP8 - VQ6_on,0);

%% 9. Instantaneous frequency
Kf = 5e3;                     % Hz/V behavioral sensitivity

f_inst = f555_nom + Kf*Q6_drive;
f_inst = min(max(f_inst,5e3),40e3);

%% 10. Variable-frequency NE555 phase
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

%% 13. TP11 / TP12 - primary-drive signals
TP12 = TP10;
TP11 = VCC - TP10;

%% 14. TP13 / TP14 - transformer secondary
Vpri_diff = TP12 - TP11;
Vsec_diff = turns_ratio*Vpri_diff;

% Floating secondary represented with a virtual midpoint for visualization
TP13 = +0.5*Vsec_diff;
TP14 = -0.5*Vsec_diff;

f_OUT = TP13 - TP14;

%% 15. Console summary
fprintf('\nVERSION 2.3 - EXPORTGRAPHICS VERSION\n');
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
fprintf('Frequency range             : %.3f to %.3f kHz\n', ...
        min(f_inst)/1e3,max(f_inst)/1e3);

if max(TP8) > VQ6_on
    fprintf('\nRESULT: TP8 crosses the Q6 threshold.\n');
    fprintf('Frequency modulation is expected in this model.\n');
else
    fprintf('\nRESULT: TP8 does NOT cross the Q6 threshold.\n');
    fprintf('Q6 remains OFF in this behavioral model.\n');
    fprintf('The NE555 frequency therefore remains nominal.\n');
end

%% 16. FIGURE 1 - Analog and control path
fig1 = figure('Visible','off','Color','w');

subplot(5,1,1);
plot(t*1e3,Iload,'LineWidth',1.4);
grid on;
ylabel('A');
title('Load Current');

subplot(5,1,2);
plot(t*1e3,TP6*1e3,'LineWidth',1.4);
grid on;
ylabel('mV');
title('TP6 - Current Sense');

subplot(5,1,3);
plot(t*1e3,TP7,'LineWidth',1.4);
grid on;
ylabel('V');
title('TP7 - LM358 Output');

subplot(5,1,4);
plot(t*1e3,TP8,'LineWidth',1.4);
hold on;
plot(t*1e3,VQ6_on*ones(size(t)),'--','LineWidth',1.0);
grid on;
ylabel('V');
title('TP8 - Modulation Node and Q6 Threshold');

subplot(5,1,5);
plot(t*1e3,f_inst/1e3,'LineWidth',1.4);
grid on;
ylabel('kHz');
xlabel('Time (ms)');
title('Instantaneous NE555 Frequency');

exportgraphics(fig1,'V2_3_01_Analog_Control.png','Resolution',180);
close(fig1);

%% 17. FIGURE 2 - Rising-edge detail
z1 = t >= 0.90e-3 & t <= 1.80e-3;

fig2 = figure('Visible','off','Color','w');

subplot(4,1,1);
plot(t(z1)*1e3,Iload(z1),'LineWidth',1.4);
grid on;
ylabel('A');
title('Rising Edge: 0 A to 10 A');

subplot(4,1,2);
plot(t(z1)*1e3,TP7(z1),'LineWidth',1.4);
grid on;
ylabel('V');
title('TP7');

subplot(4,1,3);
plot(t(z1)*1e3,TP8(z1),'LineWidth',1.4);
hold on;
plot(t(z1)*1e3,VQ6_on*ones(1,sum(z1)),'--','LineWidth',1.0);
grid on;
ylabel('V');
title('TP8 and Q6 Threshold');

subplot(4,1,4);
plot(t(z1)*1e3,f_inst(z1)/1e3,'LineWidth',1.4);
grid on;
ylabel('kHz');
xlabel('Time (ms)');
title('Instantaneous Frequency');

exportgraphics(fig2,'V2_3_02_Rising_Edge.png','Resolution',180);
close(fig2);

%% 18. FIGURE 3 - Falling-edge detail
z2 = t >= 3.90e-3 & t <= 4.80e-3;

fig3 = figure('Visible','off','Color','w');

subplot(4,1,1);
plot(t(z2)*1e3,Iload(z2),'LineWidth',1.4);
grid on;
ylabel('A');
title('Falling Edge: 10 A to 0 A');

subplot(4,1,2);
plot(t(z2)*1e3,TP7(z2),'LineWidth',1.4);
grid on;
ylabel('V');
title('TP7');

subplot(4,1,3);
plot(t(z2)*1e3,TP8(z2),'LineWidth',1.4);
hold on;
plot(t(z2)*1e3,VQ6_on*ones(1,sum(z2)),'--','LineWidth',1.0);
grid on;
ylabel('V');
title('TP8 and Q6 Threshold');

subplot(4,1,4);
plot(t(z2)*1e3,f_inst(z2)/1e3,'LineWidth',1.4);
grid on;
ylabel('kHz');
xlabel('Time (ms)');
title('Instantaneous Frequency');

exportgraphics(fig3,'V2_3_03_Falling_Edge.png','Resolution',180);
close(fig3);

%% 19. FIGURE 4 - Q6 drive
fig4 = figure('Visible','off','Color','w');

plot(t*1e3,Q6_drive,'LineWidth',1.5);
grid on;
xlabel('Time (ms)');
ylabel('Voltage above threshold (V)');
title('Behavioral Q6 Drive');

exportgraphics(fig4,'V2_3_04_Q6_Drive.png','Resolution',180);
close(fig4);

%% 20. FIGURE 5 - Fast digital test points
zo = t >= 1.20e-3 & t <= 1.60e-3;

fig5 = figure('Visible','off','Color','w');

subplot(4,2,1);
plot(t(zo)*1e3,TP9(zo),'LineWidth',1.1);
grid on;
title('TP9');
ylabel('V');

subplot(4,2,2);
plot(t(zo)*1e3,TP10(zo),'LineWidth',1.1);
grid on;
title('TP10');
ylabel('V');

subplot(4,2,3);
plot(t(zo)*1e3,TP11(zo),'LineWidth',1.1);
grid on;
title('TP11');
ylabel('V');

subplot(4,2,4);
plot(t(zo)*1e3,TP12(zo),'LineWidth',1.1);
grid on;
title('TP12');
ylabel('V');

subplot(4,2,5);
plot(t(zo)*1e3,TP13(zo),'LineWidth',1.1);
grid on;
title('TP13');
ylabel('V');

subplot(4,2,6);
plot(t(zo)*1e3,TP14(zo),'LineWidth',1.1);
grid on;
title('TP14');
ylabel('V');

subplot(4,2,[7 8]);
plot(t(zo)*1e3,f_OUT(zo),'LineWidth',1.1);
grid on;
title('Differential f-OUT = TP13 - TP14');
ylabel('V');
xlabel('Time (ms)');

exportgraphics(fig5,'V2_3_05_Digital_Test_Points.png','Resolution',180);
close(fig5);

%% 21. FIGURE 6 - All test points overview
fig6 = figure('Visible','off','Color','w');

subplot(5,2,1);
plot(t*1e3,TP6*1e3,'LineWidth',1.1);
grid on;
title('TP6');
ylabel('mV');

subplot(5,2,2);
plot(t*1e3,TP7,'LineWidth',1.1);
grid on;
title('TP7');
ylabel('V');

subplot(5,2,3);
plot(t*1e3,TP8,'LineWidth',1.1);
hold on;
plot(t*1e3,VQ6_on*ones(size(t)),'--','LineWidth',0.8);
grid on;
title('TP8');
ylabel('V');

subplot(5,2,4);
plot(t(zo)*1e3,TP9(zo),'LineWidth',1.0);
grid on;
title('TP9');
ylabel('V');

subplot(5,2,5);
plot(t(zo)*1e3,TP10(zo),'LineWidth',1.0);
grid on;
title('TP10');
ylabel('V');

subplot(5,2,6);
plot(t(zo)*1e3,TP11(zo),'LineWidth',1.0);
grid on;
title('TP11');
ylabel('V');

subplot(5,2,7);
plot(t(zo)*1e3,TP12(zo),'LineWidth',1.0);
grid on;
title('TP12');
ylabel('V');

subplot(5,2,8);
plot(t(zo)*1e3,TP13(zo),'LineWidth',1.0);
grid on;
title('TP13');
ylabel('V');

subplot(5,2,9);
plot(t(zo)*1e3,TP14(zo),'LineWidth',1.0);
grid on;
title('TP14');
ylabel('V');
xlabel('Time (ms)');

subplot(5,2,10);
plot(t(zo)*1e3,f_OUT(zo),'LineWidth',1.0);
grid on;
title('TP13 - TP14');
ylabel('V');
xlabel('Time (ms)');

exportgraphics(fig6,'V2_3_06_All_Test_Points.png','Resolution',180);
close(fig6);

%% 22. Save numeric data to CSV
T = table(t(:),Iload(:),TP6(:),TP7(:),TP8(:),TP9(:),TP10(:), ...
          TP11(:),TP12(:),TP13(:),TP14(:),f_OUT(:),f_inst(:), ...
          'VariableNames',{'Time_s','Iload_A','TP6_V','TP7_V','TP8_V', ...
          'TP9_V','TP10_V','TP11_V','TP12_V','TP13_V','TP14_V', ...
          'fOUT_V','Frequency_Hz'});

writetable(T,'V2_3_Simulation_Data.csv');

%% 23. Final message
fprintf('\nFiles created in MATLAB Drive / Current Folder:\n');
fprintf('  V2_3_01_Analog_Control.png\n');
fprintf('  V2_3_02_Rising_Edge.png\n');
fprintf('  V2_3_03_Falling_Edge.png\n');
fprintf('  V2_3_04_Q6_Drive.png\n');
fprintf('  V2_3_05_Digital_Test_Points.png\n');
fprintf('  V2_3_06_All_Test_Points.png\n');
fprintf('  V2_3_Simulation_Data.csv\n');

fprintf('\nOpen the PNG files directly from the Files panel.\n');
fprintf('The script intentionally creates no interactive figure windows.\n');
