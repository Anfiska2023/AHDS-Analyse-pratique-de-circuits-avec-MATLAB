%% NE555 Current-Sense Model - VERSION 3.0
% R36 / LM358 GAIN SWEEP
%
% Purpose:
%   Keep the same circuit assumptions as Version 2.3, but sweep R36 to find
%   the approximate LM358 gain at which TP8 first crosses the BC558 (Q6)
%   turn-on threshold.
%
% Tested R36 values:
%   330 kOhm, 390 kOhm, 430 kOhm, 470 kOhm, 510 kOhm, 560 kOhm
%
% The script:
%   - Uses the same 0 A -> 10 A -> 0 A load-current step.
%   - Calculates TP6, TP7, TP8 for every R36 value.
%   - Checks whether TP8 crosses the Q6 threshold.
%   - Calculates the behavioral instantaneous frequency.
%   - Exports summary plots as PNG.
%   - Saves a CSV summary table.
%
% IMPORTANT:
%   This remains a behavioral engineering model.
%   The purpose is to find the approximate gain threshold before changing
%   the real circuit.

clear;
clc;
close all force;

%% 1. Simulation settings
VCC  = 5.0;
dt   = 0.5e-6;
Tsim = 6e-3;
t    = 0:dt:Tsim;
N    = numel(t);

%% 2. Fixed circuit parameters
Rsense = 5e-3;

R38 = 1e3;
R37 = 10e3;
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

%% 3. R36 sweep values
R36_values = [330e3 390e3 430e3 470e3 510e3 560e3];
numCases = numel(R36_values);

%% 4. Derived fixed values
Rin_eff = R38 + R37;

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

%% 5. Q6 threshold
VBE_PNP = 0.65;
VQ6_on  = VCC + VBE_PNP;      % approx. 5.65 V

%% 6. Current profile
Iload = zeros(size(t));
Iload(t >= 1e-3 & t < 4e-3) = 10;

%% 7. TP6
TP6 = -Iload*Rsense;

%% 8. Storage arrays
Gain_values       = zeros(1,numCases);
TP7_max_values    = zeros(1,numCases);
TP8_max_values    = zeros(1,numCases);
Q6_drive_max      = zeros(1,numCases);
f_max_values      = zeros(1,numCases);
f_min_values      = zeros(1,numCases);
CrossesThreshold  = false(1,numCases);

TP7_all = zeros(numCases,N);
TP8_all = zeros(numCases,N);
f_all   = zeros(numCases,N);

%% 9. Sweep loop
alpha_sense = dt/(tau_sense+dt);
alpha_mod   = dt/(tau_mod+dt);

Vbias_TP8 = 4.35;
Kmod_node = 1.0;
Kf = 5e3;                     % Hz/V

for n = 1:numCases

    R36 = R36_values(n);
    A_LM358 = R36/Rin_eff;
    Gain_values(n) = A_LM358;

    % TP7 target
    TP7_target = -A_LM358*TP6;

    % TP7 low-pass response
    TP7 = zeros(size(t));
    for k = 2:N
        TP7(k) = TP7(k-1) + alpha_sense*(TP7_target(k)-TP7(k-1));
    end

    % LM358 output swing approximation
    TP7 = min(max(TP7,0),3.5);

    % TP8 transient path
    TP7_lp_mod = zeros(size(t));
    for k = 2:N
        TP7_lp_mod(k) = TP7_lp_mod(k-1) + ...
                        alpha_mod*(TP7(k)-TP7_lp_mod(k-1));
    end

    HP_mod = TP7 - TP7_lp_mod;
    TP8 = Vbias_TP8 + Kmod_node*HP_mod;
    TP8 = min(max(TP8,0),6.5);

    % Q6 behavioral drive
    Q6_drive = max(TP8 - VQ6_on,0);

    % Frequency
    f_inst = f555_nom + Kf*Q6_drive;
    f_inst = min(max(f_inst,5e3),40e3);

    % Save results
    TP7_all(n,:) = TP7;
    TP8_all(n,:) = TP8;
    f_all(n,:)   = f_inst;

    TP7_max_values(n)   = max(TP7);
    TP8_max_values(n)   = max(TP8);
    Q6_drive_max(n)     = max(Q6_drive);
    f_max_values(n)     = max(f_inst);
    f_min_values(n)     = min(f_inst);
    CrossesThreshold(n) = any(TP8 > VQ6_on);
end

%% 10. Console summary
fprintf('\nVERSION 3.0 - R36 / GAIN SWEEP\n');
fprintf('Nominal NE555 frequency : %.3f kHz\n',f555_nom/1e3);
fprintf('Q6 threshold            : %.3f V\n',VQ6_on);
fprintf('Current-sense fc        : %.1f Hz\n',fc_sense);
fprintf('Modulation-path fc      : %.1f Hz\n\n',fc_mod);

fprintf(' R36(k)   Gain    TP7max(V)   TP8max(V)   Q6drive(V)   fmax(kHz)   Cross?\n');
fprintf(' ------------------------------------------------------------------------\n');

for n = 1:numCases
    if CrossesThreshold(n)
        crossText = 'YES';
    else
        crossText = 'NO ';
    end

    fprintf(' %6.0f   %5.2f     %7.3f     %7.3f      %7.3f      %7.3f     %s\n', ...
        R36_values(n)/1e3, ...
        Gain_values(n), ...
        TP7_max_values(n), ...
        TP8_max_values(n), ...
        Q6_drive_max(n), ...
        f_max_values(n)/1e3, ...
        crossText);
end

firstCross = find(CrossesThreshold,1,'first');

if isempty(firstCross)
    fprintf('\nRESULT: None of the tested R36 values crosses the Q6 threshold.\n');
else
    fprintf('\nRESULT: First tested value crossing the Q6 threshold:\n');
    fprintf('R36 = %.0f kOhm\n',R36_values(firstCross)/1e3);
    fprintf('Gain = %.2f V/V\n',Gain_values(firstCross));
    fprintf('TP8 max = %.3f V\n',TP8_max_values(firstCross));
    fprintf('Q6 drive max = %.3f V\n',Q6_drive_max(firstCross));
    fprintf('f max = %.3f kHz\n',f_max_values(firstCross)/1e3);
end

%% 11. Export summary table
Summary = table( ...
    R36_values(:)/1e3, ...
    Gain_values(:), ...
    TP7_max_values(:), ...
    TP8_max_values(:), ...
    Q6_drive_max(:), ...
    f_min_values(:)/1e3, ...
    f_max_values(:)/1e3, ...
    CrossesThreshold(:), ...
    'VariableNames', { ...
    'R36_kOhm', ...
    'LM358_Gain', ...
    'TP7_Max_V', ...
    'TP8_Max_V', ...
    'Q6_Drive_Max_V', ...
    'Frequency_Min_kHz', ...
    'Frequency_Max_kHz', ...
    'Crosses_Q6_Threshold'});

writetable(Summary,'V3_0_R36_Gain_Sweep_Summary.csv');

%% 12. FIGURE 1 - TP8 max versus R36
fig1 = figure('Visible','off','Color','w');

plot(R36_values/1e3,TP8_max_values,'o-','LineWidth',1.5);
hold on;
plot(R36_values/1e3,VQ6_on*ones(size(R36_values)),'--','LineWidth',1.2);
grid on;

xlabel('R36 (kOhm)');
ylabel('Maximum TP8 Voltage (V)');
title('Maximum TP8 Voltage vs R36');
legend('TP8 max','Q6 threshold','Location','best');

exportgraphics(fig1,'V3_0_01_TP8_Max_vs_R36.png','Resolution',180);
close(fig1);

%% 13. FIGURE 2 - Maximum frequency versus R36
fig2 = figure('Visible','off','Color','w');

plot(R36_values/1e3,f_max_values/1e3,'o-','LineWidth',1.5);
grid on;

xlabel('R36 (kOhm)');
ylabel('Maximum Frequency (kHz)');
title('Maximum Modeled NE555 Frequency vs R36');

exportgraphics(fig2,'V3_0_02_Frequency_vs_R36.png','Resolution',180);
close(fig2);

%% 14. FIGURE 3 - TP8 waveforms for all R36 values
fig3 = figure('Visible','off','Color','w');

hold on;

for n = 1:numCases
    plot(t*1e3,TP8_all(n,:),'LineWidth',1.1);
end

plot(t*1e3,VQ6_on*ones(size(t)),'k--','LineWidth',1.2);

grid on;
xlabel('Time (ms)');
ylabel('TP8 (V)');
title('TP8 Waveforms for R36 Gain Sweep');

legend( ...
    '330k','390k','430k','470k','510k','560k','Q6 threshold', ...
    'Location','best');

exportgraphics(fig3,'V3_0_03_TP8_Waveforms.png','Resolution',180);
close(fig3);

%% 15. FIGURE 4 - Frequency waveforms for all R36 values
fig4 = figure('Visible','off','Color','w');

hold on;

for n = 1:numCases
    plot(t*1e3,f_all(n,:)/1e3,'LineWidth',1.1);
end

grid on;
xlabel('Time (ms)');
ylabel('Frequency (kHz)');
title('Instantaneous Frequency for R36 Gain Sweep');

legend('330k','390k','430k','470k','510k','560k','Location','best');

exportgraphics(fig4,'V3_0_04_Frequency_Waveforms.png','Resolution',180);
close(fig4);

%% 16. FIGURE 5 - TP7 max and gain
fig5 = figure('Visible','off','Color','w');

yyaxis left
plot(R36_values/1e3,TP7_max_values,'o-','LineWidth',1.5);
ylabel('TP7 max (V)');

yyaxis right
plot(R36_values/1e3,Gain_values,'s-','LineWidth',1.5);
ylabel('LM358 gain (V/V)');

grid on;
xlabel('R36 (kOhm)');
title('TP7 Maximum and LM358 Gain vs R36');

exportgraphics(fig5,'V3_0_05_TP7_and_Gain_vs_R36.png','Resolution',180);
close(fig5);

%% 17. Optional detailed digital waveform for first crossing case
if ~isempty(firstCross)

    f_case = f_all(firstCross,:);

    phase = zeros(size(t));
    for k = 2:N
        phase(k) = phase(k-1) + 2*pi*f_case(k)*dt;
    end

    phase01 = mod(phase,2*pi)/(2*pi);

    TP10 = VCC*(phase01 < duty_nom);

    TP9 = VCC*ones(size(t));
    TP9(phase01 >= duty_nom) = VCEsat;

    TP12 = TP10;
    TP11 = VCC - TP10;

    Vpri_diff = TP12 - TP11;
    Vsec_diff = turns_ratio*Vpri_diff;

    TP13 = +0.5*Vsec_diff;
    TP14 = -0.5*Vsec_diff;
    f_OUT = TP13 - TP14;

    zo = t >= 1.20e-3 & t <= 1.60e-3;

    fig6 = figure('Visible','off','Color','w');

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
    title(sprintf('Differential f-OUT, R36 = %.0f kOhm', ...
          R36_values(firstCross)/1e3));
    ylabel('V');
    xlabel('Time (ms)');

    exportgraphics(fig6,'V3_0_06_First_Threshold_Crossing_Digital.png', ...
                   'Resolution',180);
    close(fig6);
end

%% 18. Final message
fprintf('\nFiles created:\n');
fprintf('  V3_0_R36_Gain_Sweep_Summary.csv\n');
fprintf('  V3_0_01_TP8_Max_vs_R36.png\n');
fprintf('  V3_0_02_Frequency_vs_R36.png\n');
fprintf('  V3_0_03_TP8_Waveforms.png\n');
fprintf('  V3_0_04_Frequency_Waveforms.png\n');
fprintf('  V3_0_05_TP7_and_Gain_vs_R36.png\n');

if ~isempty(firstCross)
    fprintf('  V3_0_06_First_Threshold_Crossing_Digital.png\n');
end

fprintf('\nOpen the PNG files directly from the MATLAB Files panel.\n');
