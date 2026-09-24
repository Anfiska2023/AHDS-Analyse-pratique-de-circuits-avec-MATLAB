%% NE555 Current-Sense Model - VERSION 2.2
% MATLAB Online "export-only" version.
% This version does NOT rely on interactive figure rendering.
% It calculates the same Version 2.1 signals and writes PNG files directly.
%
% If the interactive MATLAB Online figure windows are blank but these PNG
% files contain the plots, the electrical model is fine and the problem is
% only the browser/figure renderer.

clear;
clc;
close all force;

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

%% 4. Fast 0 -> 10 A -> 0 A profile
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

%% 7. TP8
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
VQ6_on  = VCC + VBE_PNP;
Q6_drive = max(TP8 - VQ6_on,0);

%% 9. Frequency
Kf = 5e3;
f_inst = f555_nom + Kf*Q6_drive;

%% 10. NE555 signals
phase = zeros(size(t));

for k = 2:N
    phase(k) = phase(k-1) + 2*pi*f_inst(k)*dt;
end

phase01 = mod(phase,2*pi)/(2*pi);

TP10 = VCC*(phase01 < duty_nom);

TP9 = VCC*ones(size(t));
TP9(phase01 >= duty_nom) = VCEsat;

%% 11. Transformer signals
TP12 = TP10;
TP11 = VCC - TP10;

Vpri_diff = TP12 - TP11;
Vsec_diff = turns_ratio*Vpri_diff;

TP13 = +0.5*Vsec_diff;
TP14 = -0.5*Vsec_diff;

f_OUT = TP13 - TP14;

%% 12. Console summary
fprintf('\nVERSION 2.2 - EXPORT-ONLY PLOTTING\n');
fprintf('LM358 gain              : %.2f V/V\n', A_LM358);
fprintf('TP8 max                 : %.3f V\n', max(TP8));
fprintf('Q6 threshold            : %.3f V\n', VQ6_on);
fprintf('Max Q6 drive            : %.3f V\n', max(Q6_drive));
fprintf('Frequency               : %.3f to %.3f kHz\n', ...
        min(f_inst)/1e3,max(f_inst)/1e3);

%% 13. Simple graphics diagnostic image
fig = figure('Visible','off','Color','w');
set(fig,'Renderer','painters');
plot([0 1 2],[0 1 0],'LineWidth',2);
grid on;
xlabel('X');
ylabel('Y');
title('MATLAB Graphics Diagnostic');
print(fig,'Graphics_Diagnostic.png','-dpng','-r160');
close(fig);

%% 14. Analog/control figure
fig = figure('Visible','off','Color','w');
set(fig,'Renderer','painters');

subplot(5,1,1);
plot(t*1e3,Iload,'LineWidth',1.3);
grid on; ylabel('A'); title('Load Current');

subplot(5,1,2);
plot(t*1e3,TP6*1e3,'LineWidth',1.3);
grid on; ylabel('mV'); title('TP6');

subplot(5,1,3);
plot(t*1e3,TP7,'LineWidth',1.3);
grid on; ylabel('V'); title('TP7');

subplot(5,1,4);
plot(t*1e3,TP8,'LineWidth',1.3);
hold on;
plot(t*1e3,VQ6_on*ones(size(t)),'--','LineWidth',1.0);
grid on; ylabel('V'); title('TP8 and Q6 Threshold');

subplot(5,1,5);
plot(t*1e3,f_inst/1e3,'LineWidth',1.3);
grid on; ylabel('kHz'); xlabel('Time (ms)');
title('Instantaneous Frequency');

print(fig,'V2_2_Analog_Control.png','-dpng','-r180');
close(fig);

%% 15. Rising edge figure
z = t >= 0.90e-3 & t <= 1.80e-3;

fig = figure('Visible','off','Color','w');
set(fig,'Renderer','painters');

subplot(4,1,1);
plot(t(z)*1e3,Iload(z),'LineWidth',1.3);
grid on; ylabel('A'); title('0 A to 10 A Step');

subplot(4,1,2);
plot(t(z)*1e3,TP7(z),'LineWidth',1.3);
grid on; ylabel('V'); title('TP7');

subplot(4,1,3);
plot(t(z)*1e3,TP8(z),'LineWidth',1.3);
hold on;
plot(t(z)*1e3,VQ6_on*ones(1,sum(z)),'--','LineWidth',1.0);
grid on; ylabel('V'); title('TP8 and Q6 Threshold');

subplot(4,1,4);
plot(t(z)*1e3,f_inst(z)/1e3,'LineWidth',1.3);
grid on; ylabel('kHz'); xlabel('Time (ms)');
title('Instantaneous Frequency');

print(fig,'V2_2_Rising_Edge.png','-dpng','-r180');
close(fig);

%% 16. Digital test points
zo = t >= 1.20e-3 & t <= 1.60e-3;

fig = figure('Visible','off','Color','w');
set(fig,'Renderer','painters');

subplot(4,2,1);
plot(t(zo)*1e3,TP9(zo),'LineWidth',1.1);
grid on; title('TP9'); ylabel('V');

subplot(4,2,2);
plot(t(zo)*1e3,TP10(zo),'LineWidth',1.1);
grid on; title('TP10'); ylabel('V');

subplot(4,2,3);
plot(t(zo)*1e3,TP11(zo),'LineWidth',1.1);
grid on; title('TP11'); ylabel('V');

subplot(4,2,4);
plot(t(zo)*1e3,TP12(zo),'LineWidth',1.1);
grid on; title('TP12'); ylabel('V');

subplot(4,2,5);
plot(t(zo)*1e3,TP13(zo),'LineWidth',1.1);
grid on; title('TP13'); ylabel('V');

subplot(4,2,6);
plot(t(zo)*1e3,TP14(zo),'LineWidth',1.1);
grid on; title('TP14'); ylabel('V');

subplot(4,2,[7 8]);
plot(t(zo)*1e3,f_OUT(zo),'LineWidth',1.1);
grid on;
title('Differential f-OUT = TP13 - TP14');
ylabel('V'); xlabel('Time (ms)');

print(fig,'V2_2_Digital_Test_Points.png','-dpng','-r180');
close(fig);

%% 17. Save numeric data to CSV
T = table(t(:),Iload(:),TP6(:),TP7(:),TP8(:),TP9(:),TP10(:), ...
          TP11(:),TP12(:),TP13(:),TP14(:),f_OUT(:),f_inst(:), ...
          'VariableNames',{'Time_s','Iload_A','TP6_V','TP7_V','TP8_V', ...
          'TP9_V','TP10_V','TP11_V','TP12_V','TP13_V','TP14_V', ...
          'fOUT_V','Frequency_Hz'});

writetable(T,'V2_2_Simulation_Data.csv');

fprintf('\nFiles created in Current Folder:\n');
fprintf('  Graphics_Diagnostic.png\n');
fprintf('  V2_2_Analog_Control.png\n');
fprintf('  V2_2_Rising_Edge.png\n');
fprintf('  V2_2_Digital_Test_Points.png\n');
fprintf('  V2_2_Simulation_Data.csv\n');
fprintf('\nOpen the PNG files directly from the Current Folder.\n');
