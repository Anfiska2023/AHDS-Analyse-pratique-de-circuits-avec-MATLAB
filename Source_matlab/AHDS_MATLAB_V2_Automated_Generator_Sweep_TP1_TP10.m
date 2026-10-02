%% AHDS - 1 kW MOSFET Amplifier - Automated Generator Sweep
% VERSION 2 - Automated frequency generator + TP1-TP10 acquisition workflow
%
% PURPOSE
% This script automatically changes the sine-wave generator frequency through
% a user-defined list, pauses for settling, records TP1-TP10 measurements,
% saves the complete table to CSV, and creates ten frequency-response graphs.
%
% IMPORTANT HARDWARE NOTE
% MATLAB can automate the generator only if the generator supports remote
% control such as VISA/USB/LAN/GPIB/serial and SCPI (or vendor commands).
% Automatic measurement of all ten TP points additionally requires suitable
% remotely controlled measurement hardware (oscilloscope/DAQ/multiplexer).
% The default mode below automates the generator but asks the operator to
% enter TP1-TP10 measurements at each frequency. This avoids assuming a
% specific oscilloscope or DAQ that may not exist in the laboratory.
%
% SAFETY
% This amplifier uses approximately +/-100 V supply rails. Use isolated or
% differential probes where required, respect instrument input ratings, and
% never connect an oscilloscope ground clip to a non-ground power node.

%% 1. CLEAN MATLAB
clear;
close all;
clc;

%% 2. USER SETTINGS - EDIT THIS SECTION ONLY

% Select the frequencies used for the sine-wave sweep.
% Add, remove, or change values here without changing the rest of the code.
Frequency_Hz = [100 200 500 1000 2000 5000 10000 15000 20000];

% Set the sine-wave generator output amplitude.
% IMPORTANT: confirm whether your generator interprets this value as Vpp,
% Vrms, or another unit. The SCPI command below assumes Vpp.
GeneratorAmplitude_Vpp = 1.0;

% Define how long MATLAB waits after each frequency change before measuring.
SettlingTime_s = 1.0;

% Select the VISA resource string reported by MATLAB for the generator.
% Replace this example with the actual resource shown by visadevlist.
generatorResource = "USB0::0x0000::0x0000::INSTR";

% Select measurement mode.
% "manual" = generator changes automatically; operator enters TP1-TP10.
% "daq"    = placeholder for a future automated oscilloscope/DAQ interface.
measurementMode = "manual";

% Define the resistive load used for output-power calculation.
loadResistance_Ohm = 8;

%% 3. CONNECT TO THE FUNCTION GENERATOR

% Display all VISA instruments visible to MATLAB.
disp(visadevlist);

% Open the VISA connection to the selected generator.
gen = visadev(generatorResource);

% Set a reasonable communication timeout in seconds.
gen.Timeout = 10;

% Ask the instrument for its identification string.
% Most SCPI-compatible instruments support *IDN?.
generatorID = writeread(gen, "*IDN?");

% Display the detected generator identification.
fprintf("Connected generator: %s\n", generatorID);

%% 4. CONFIGURE THE GENERATOR FOR A SINE WAVE

% Select a sine waveform.
% NOTE: SCPI syntax can vary by manufacturer; change this line if required.
writeline(gen, "FUNC SIN");

% Set the generator output amplitude.
% NOTE: this example uses Vpp.
writeline(gen, sprintf("VOLT %.6f", GeneratorAmplitude_Vpp));

% Set zero DC offset.
writeline(gen, "VOLT:OFFS 0");

% Turn the generator output on.
writeline(gen, "OUTP ON");

%% 5. PREALLOCATE TP1-TP10 MEASUREMENT ARRAYS

% Count how many frequency points will be measured.
N = numel(Frequency_Hz);

% Create an N-by-10 matrix filled with NaN.
% Each row corresponds to one frequency.
% Each column corresponds to TP1 through TP10.
TP_RMS_V = nan(N, 10);

% Create an optional phase array.
Phase_deg = nan(N, 1);

%% 6. AUTOMATED FREQUENCY SWEEP

% Step through every frequency in the user-defined frequency list.
for i = 1:N

    % Read the current test frequency.
    f = Frequency_Hz(i);

    % Send the new frequency to the generator.
    writeline(gen, sprintf("FREQ %.12g", f));

    % Display progress in the MATLAB Command Window.
    fprintf("\nFrequency %d of %d: %.12g Hz\n", i, N, f);

    % Wait for the amplifier and instruments to settle.
    pause(SettlingTime_s);

    % Check which measurement method is selected.
    if measurementMode == "manual"

        % Ask the operator to enter ten RMS voltage measurements.
        % Enter values in this exact order: TP1 TP2 ... TP10.
        prompt = sprintf(['Enter TP1-TP10 RMS voltages at %.12g Hz\n' ...
                          'as [TP1 TP2 TP3 TP4 TP5 TP6 TP7 TP8 TP9 TP10]: '], f);

        % Read the entered vector from the MATLAB Command Window.
        values = input(prompt);

        % Verify that exactly ten values were entered.
        if numel(values) ~= 10
            error("Exactly 10 values are required for TP1 through TP10.");
        end

        % Store the ten values in the current measurement row.
        TP_RMS_V(i, :) = values(:).';

        % Ask for optional output phase relative to the input.
        % Enter NaN if phase was not measured.
        Phase_deg(i) = input("Enter output phase in degrees, or NaN if not measured: ");

    elseif measurementMode == "daq"

        % FULL AUTOMATION PLACEHOLDER:
        % Replace the next line with instrument-specific acquisition code.
        %
        % A fully automatic system needs measurement hardware capable of
        % acquiring TP1-TP10 safely, for example:
        %   - a remotely controlled oscilloscope plus switching/multiplexer,
        %   - a multi-channel isolated DAQ,
        %   - or another suitable automated measurement system.
        %
        % The acquisition function should return one 1x10 vector containing
        % TP1 through TP10 RMS voltages in the same order.
        error(['DAQ mode requires instrument-specific TP1-TP10 acquisition ' ...
               'code for the actual oscilloscope/DAQ/multiplexer.']);

    else

        % Stop if the measurement mode name is invalid.
        error('measurementMode must be "manual" or "daq".');

    end
end

%% 7. TURN THE GENERATOR OUTPUT OFF

% Disable the generator output after the sweep is complete.
writeline(gen, "OUTP OFF");

% Release the VISA object.
clear gen;

%% 8. ASSIGN MEASUREMENT COLUMNS TO NAMED TP VARIABLES

% Copy TP1 measurements.
TP1_RMS_V = TP_RMS_V(:,1);

% Copy TP2 measurements.
TP2_RMS_V = TP_RMS_V(:,2);

% Copy TP3 measurements.
TP3_RMS_V = TP_RMS_V(:,3);

% Copy TP4 measurements.
TP4_RMS_V = TP_RMS_V(:,4);

% Copy TP5 measurements.
TP5_RMS_V = TP_RMS_V(:,5);

% Copy TP6 measurements.
TP6_RMS_V = TP_RMS_V(:,6);

% Copy TP7 measurements.
TP7_RMS_V = TP_RMS_V(:,7);

% Copy TP8 measurements.
TP8_RMS_V = TP_RMS_V(:,8);

% Copy TP9 measurements.
TP9_RMS_V = TP_RMS_V(:,9);

% Copy TP10 measurements.
TP10_RMS_V = TP_RMS_V(:,10);

%% 9. CALCULATE MAIN AMPLIFIER RESULTS

% Calculate closed-loop voltage gain using TP8 output divided by TP1 input.
VoltageGain = TP8_RMS_V ./ TP1_RMS_V;

% Convert voltage gain to decibels.
Gain_dB = 20 .* log10(abs(VoltageGain));

% Calculate output power into the selected resistive load.
OutputPower_W = (TP8_RMS_V .^ 2) ./ loadResistance_Ohm;

% Calculate load current from output voltage and load resistance.
CalculatedLoadCurrent_A = TP8_RMS_V ./ loadResistance_Ohm;

%% 10. BUILD AND SAVE THE COMPLETE MEASUREMENT TABLE

% Build a MATLAB table containing frequency, TP1-TP10, phase, and results.
Results = table(Frequency_Hz(:), ...
    TP1_RMS_V, TP2_RMS_V, TP3_RMS_V, TP4_RMS_V, TP5_RMS_V, ...
    TP6_RMS_V, TP7_RMS_V, TP8_RMS_V, TP9_RMS_V, TP10_RMS_V, ...
    Phase_deg, VoltageGain, Gain_dB, OutputPower_W, CalculatedLoadCurrent_A, ...
    'VariableNames', {'Frequency_Hz', ...
    'TP1_RMS_V','TP2_RMS_V','TP3_RMS_V','TP4_RMS_V','TP5_RMS_V', ...
    'TP6_RMS_V','TP7_RMS_V','TP8_RMS_V','TP9_RMS_V','TP10_RMS_V', ...
    'Phase_deg','VoltageGain','Gain_dB','OutputPower_W', ...
    'CalculatedLoadCurrent_A'});

% Display the completed table.
disp(Results);

% Save the measurement table to a CSV file.
writetable(Results, "AHDS_automated_frequency_sweep_results.csv");

%% 11. CREATE TEN TP1-TP10 FREQUENCY-RESPONSE GRAPHS

% Store all ten traces in a cell array for convenient plotting.
TP_Data = {TP1_RMS_V, TP2_RMS_V, TP3_RMS_V, TP4_RMS_V, TP5_RMS_V, ...
           TP6_RMS_V, TP7_RMS_V, TP8_RMS_V, TP9_RMS_V, TP10_RMS_V};

% Store the graph titles.
TP_Titles = {'TP1 - Input Signal', ...
             'TP2 - Internal Small-Signal Point', ...
             'TP3 - Internal Small-Signal Point', ...
             'TP4 - Upper Driver Path', ...
             'TP5 - Lower Driver Path', ...
             'TP6 - Upper Gate-Drive Point', ...
             'TP7 - Lower Gate-Drive Point', ...
             'TP8 - Amplifier Output', ...
             'TP9 - Positive Supply Rail', ...
             'TP10 - Negative Supply Rail'};

% Generate exactly one graph for each test point.
for k = 1:10

    % Open a new figure.
    figure('Name', TP_Titles{k});

    % Plot all measured frequency points on one logarithmic frequency axis.
    semilogx(Frequency_Hz, TP_Data{k}, '-o', 'LineWidth', 1.2);

    % Enable major and minor grid lines.
    grid on;
    grid minor;

    % Label the horizontal axis.
    xlabel('Frequency (Hz)');

    % Label the vertical axis.
    ylabel('Measured RMS Voltage (V)');

    % Add the test-point title.
    title(TP_Titles{k});

    % Use the actual first and last frequencies from the user settings.
    xlim([min(Frequency_Hz) max(Frequency_Hz)]);

end

%% 12. CREATE DERIVED PERFORMANCE GRAPHS

% Create the closed-loop gain graph.
figure('Name', 'Closed-Loop Gain');
semilogx(Frequency_Hz, Gain_dB, '-o', 'LineWidth', 1.2);
grid on;
grid minor;
xlabel('Frequency (Hz)');
ylabel('Gain (dB)');
title('Closed-Loop Voltage Gain - TP8 / TP1');

% Create the output-power graph.
figure('Name', 'Output Power');
semilogx(Frequency_Hz, OutputPower_W, '-o', 'LineWidth', 1.2);
grid on;
grid minor;
xlabel('Frequency (Hz)');
ylabel('Output Power (W)');
title('Calculated Output Power vs Frequency');

% Create the phase graph only when phase measurements exist.
if any(isfinite(Phase_deg))
    figure('Name', 'Output Phase');
    semilogx(Frequency_Hz, Phase_deg, '-o', 'LineWidth', 1.2);
    grid on;
    grid minor;
    xlabel('Frequency (Hz)');
    ylabel('Phase (degrees)');
    title('Output Phase vs Frequency');
end

%% 13. FINISH

% Confirm that the complete automated sweep has finished.
disp("Automated generator sweep complete.");

% Remind the user where the results were saved.
disp("Results saved to AHDS_automated_frequency_sweep_results.csv.");
