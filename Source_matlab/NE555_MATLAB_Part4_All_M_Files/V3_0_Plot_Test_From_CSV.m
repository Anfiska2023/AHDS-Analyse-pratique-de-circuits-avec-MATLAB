%% V3.0 CSV Plot Test
% Minimal MATLAB plotting test using the already-created sweep CSV.
% Purpose:
%   Verify whether MATLAB Online can display simple plots from numeric data.
%
% Required file in the Current Folder:
%   V3_0_R36_Gain_Sweep_Summary.csv

clear;
clc;
close all force;

%% 1. Read the CSV
filename = 'V3_0_R36_Gain_Sweep_Summary.csv';

if ~isfile(filename)
    error('File not found: %s. Put the CSV in the Current Folder.', filename);
end

T = readtable(filename);

disp('CSV loaded successfully:');
disp(T);

%% 2. Extract columns
R36_kOhm = T.R36_kOhm;
Gain     = T.LM358_Gain;
TP8max   = T.TP8_Max_V;
Fmax_kHz = T.Frequency_Max_kHz;

Q6_threshold = 5.650;

%% 3. Figure 1 - TP8 max vs R36
figure(1);
clf;

plot(R36_kOhm, TP8max, 'o-', 'LineWidth', 1.8, 'MarkerSize', 7);
hold on;
plot(R36_kOhm, Q6_threshold*ones(size(R36_kOhm)), '--', 'LineWidth', 1.5);

grid on;
xlabel('R36 (kOhm)');
ylabel('Maximum TP8 Voltage (V)');
title('TP8 Maximum vs R36');
legend('TP8 max','Q6 threshold','Location','best');

xlim([min(R36_kOhm)-10, max(R36_kOhm)+10]);
ylim([min(TP8max)-0.1, max([TP8max; Q6_threshold])-0 + 0.15]);

drawnow;
shg;

%% 4. Figure 2 - Frequency vs R36
figure(2);
clf;

plot(R36_kOhm, Fmax_kHz, 's-', 'LineWidth', 1.8, 'MarkerSize', 7);

grid on;
xlabel('R36 (kOhm)');
ylabel('Maximum Frequency (kHz)');
title('Maximum Modeled Frequency vs R36');

xlim([min(R36_kOhm)-10, max(R36_kOhm)+10]);

drawnow;
shg;

%% 5. Figure 3 - LM358 gain vs R36
figure(3);
clf;

plot(R36_kOhm, Gain, 'd-', 'LineWidth', 1.8, 'MarkerSize', 7);

grid on;
xlabel('R36 (kOhm)');
ylabel('LM358 Gain (V/V)');
title('LM358 Gain vs R36');

xlim([min(R36_kOhm)-10, max(R36_kOhm)+10]);

drawnow;
shg;

%% 6. Simple graphics sanity check
figure(4);
clf;

x = 0:0.1:10;
y = sin(x);

plot(x, y, 'LineWidth', 1.8);
grid on;
xlabel('x');
ylabel('sin(x)');
title('Simple MATLAB Graphics Test');

drawnow;
shg;

fprintf('\nFour simple figures were created.\n');
fprintf('If these are still blank, the issue is with MATLAB Online graphics rendering,\n');
fprintf('not with the NE555 simulation calculations.\n');
