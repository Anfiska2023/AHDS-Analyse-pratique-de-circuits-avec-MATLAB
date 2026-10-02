%% 1 kW MOSFET Power Amplifier - Measurement Analysis
% AHDS Engineering Reference
% This script analyzes measured amplifier data versus frequency.
% Replace the example measurement arrays with your own measured values.
% The script can also import the same data from a CSV file.
%
% Expected CSV column names:
% Frequency_Hz, Vin_RMS_V, TP2_RMS_V, TP3_RMS_V, TP4_RMS_V,
% TP5_RMS_V, TP6_RMS_V, TP7_RMS_V, Vout_RMS_V, Iout_RMS_A,
% Vrail_Pos_V, Vrail_Neg_V, Phase_deg
%
% IMPORTANT:
% The internal TP2-TP7 labels are placeholders until the final annotated
% original schematic is inserted and each point is electrically verified.

%% User settings

% Clear variables from the MATLAB workspace.
clear;

% Close all open figure windows.
close all;

% Clear the MATLAB Command Window.
clc;

% Select how the measurement data will be loaded.
% Use "manual" to enter values directly below.
% Use "csv" to import values from a CSV file.
dataMode = "manual";

% Define the CSV file name used when dataMode is set to "csv".
csvFileName = "amplifier_measurements.csv";

% Define the nominal resistive load in ohms.
loadResistance_Ohm = 8;

%% Load measurement data

% Check whether manual data entry was selected.
if dataMode == "manual"

    % Define the test frequencies in hertz.
    Frequency_Hz = [100 200 500 1000 2000 5000 10000 15000 20000];

    % Enter the measured RMS input voltage at every test frequency.
    Vin_RMS_V = [1 1 1 1 1 1 1 1 1];

    % Enter the measured RMS voltage at internal test point TP2.
    TP2_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS voltage at internal test point TP3.
    TP3_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS voltage at internal test point TP4.
    TP4_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS voltage at internal test point TP5.
    TP5_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS voltage at upper gate-drive test point TP6.
    TP6_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS voltage at lower gate-drive test point TP7.
    TP7_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS amplifier output voltage.
    Vout_RMS_V = nan(size(Frequency_Hz));

    % Enter the measured RMS load current.
    % Leave values as NaN if current was not measured directly.
    Iout_RMS_A = nan(size(Frequency_Hz));

    % Enter the measured positive supply-rail voltage.
    Vrail_Pos_V = nan(size(Frequency_Hz));

    % Enter the measured negative supply-rail voltage as a negative value.
    Vrail_Neg_V = nan(size(Frequency_Hz));

    % Enter the measured output phase relative to the input in degrees.
    Phase_deg = nan(size(Frequency_Hz));

% Check whether CSV import was selected.
elseif dataMode == "csv"

    % Read the measurement table from the selected CSV file.
    T = readtable(csvFileName);

    % Copy the frequency column from the imported table.
    Frequency_Hz = T.Frequency_Hz.';

    % Copy the RMS input-voltage column from the imported table.
    Vin_RMS_V = T.Vin_RMS_V.';

    % Copy the internal TP2 voltage column from the imported table.
    TP2_RMS_V = T.TP2_RMS_V.';

    % Copy the internal TP3 voltage column from the imported table.
    TP3_RMS_V = T.TP3_RMS_V.';

    % Copy the internal TP4 voltage column from the imported table.
    TP4_RMS_V = T.TP4_RMS_V.';

    % Copy the internal TP5 voltage column from the imported table.
    TP5_RMS_V = T.TP5_RMS_V.';

    % Copy the upper gate-drive TP6 voltage column from the imported table.
    TP6_RMS_V = T.TP6_RMS_V.';

    % Copy the lower gate-drive TP7 voltage column from the imported table.
    TP7_RMS_V = T.TP7_RMS_V.';

    % Copy the RMS output-voltage column from the imported table.
    Vout_RMS_V = T.Vout_RMS_V.';

    % Copy the RMS output-current column from the imported table.
    Iout_RMS_A = T.Iout_RMS_A.';

    % Copy the positive supply-rail voltage column from the imported table.
    Vrail_Pos_V = T.Vrail_Pos_V.';

    % Copy the negative supply-rail voltage column from the imported table.
    Vrail_Neg_V = T.Vrail_Neg_V.';

    % Copy the phase column from the imported table.
    Phase_deg = T.Phase_deg.';

% Stop the script if an unsupported data mode was entered.
else
    error('dataMode must be "manual" or "csv".');
end

%% Validate the measurement arrays

% Store the number of frequency points for later consistency checks.
numberOfPoints = numel(Frequency_Hz);

% Verify that the input-voltage array has the correct number of values.
assert(numel(Vin_RMS_V) == numberOfPoints, 'Vin_RMS_V length does not match Frequency_Hz.');

% Verify that the output-voltage array has the correct number of values.
assert(numel(Vout_RMS_V) == numberOfPoints, 'Vout_RMS_V length does not match Frequency_Hz.');

% Verify that every test frequency is greater than zero.
assert(all(Frequency_Hz > 0), 'All test frequencies must be greater than zero.');

% Verify that every finite input-voltage value is greater than zero.
assert(all(Vin_RMS_V(isfinite(Vin_RMS_V)) > 0), 'Vin_RMS_V must be greater than zero.');

%% Calculate amplifier performance

% Calculate the linear voltage gain at every frequency.
VoltageGain = Vout_RMS_V ./ Vin_RMS_V;

% Convert the linear voltage gain to decibels.
Gain_dB = 20 .* log10(abs(VoltageGain));

% Calculate output power from measured RMS voltage and the resistive load.
PowerFromVoltage_W = (Vout_RMS_V .^ 2) ./ loadResistance_Ohm;

% Calculate output power from measured voltage and current when current exists.
PowerFromMeasuredCurrent_W = Vout_RMS_V .* Iout_RMS_A;

% Calculate the expected load current from output voltage and load resistance.
CalculatedLoadCurrent_A = Vout_RMS_V ./ loadResistance_Ohm;

% Calculate positive-rail droop relative to the largest measured positive rail.
PositiveRailDroop_V = max(Vrail_Pos_V, [], 'omitnan') - Vrail_Pos_V;

% Calculate negative-rail magnitude for easier comparison on a graph.
NegativeRailMagnitude_V = abs(Vrail_Neg_V);

%% Display a numerical results table

% Build a MATLAB table containing measured and calculated results.
Results = table(Frequency_Hz.', Vin_RMS_V.', Vout_RMS_V.', ...
    VoltageGain.', Gain_dB.', CalculatedLoadCurrent_A.', ...
    PowerFromVoltage_W.', Phase_deg.', ...
    'VariableNames', {'Frequency_Hz','Vin_RMS_V','Vout_RMS_V', ...
    'VoltageGain','Gain_dB','CalculatedLoadCurrent_A', ...
    'OutputPower_W','Phase_deg'});

% Display the results table in the Command Window.
disp(Results);

%% Plot voltage gain versus frequency

% -------------------------------------------------------------------------
% TP1-TP10 INDIVIDUAL FREQUENCY-SWEEP GRAPHS
% -------------------------------------------------------------------------
% The ten numbered test points on the annotated schematic correspond to:
% TP1  = amplifier input signal (Vin_RMS_V)
% TP2  = internal small-signal point 2 (TP2_RMS_V)
% TP3  = internal small-signal point 3 (TP3_RMS_V)
% TP4  = upper driver-path measurement point (TP4_RMS_V)
% TP5  = lower driver-path measurement point (TP5_RMS_V)
% TP6  = upper gate-drive measurement point (TP6_RMS_V)
% TP7  = lower gate-drive measurement point (TP7_RMS_V)
% TP8  = amplifier output signal (Vout_RMS_V)
% TP9  = positive supply rail (Vrail_Pos_V)
% TP10 = negative supply rail (Vrail_Neg_V)

% Store all ten measured traces in one cell array.
TP_Data = {Vin_RMS_V, TP2_RMS_V, TP3_RMS_V, TP4_RMS_V, ...
           TP5_RMS_V, TP6_RMS_V, TP7_RMS_V, Vout_RMS_V, ...
           Vrail_Pos_V, Vrail_Neg_V};

% Store the corresponding plot titles.
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

% Create one separate graph for each numbered test point.
for k = 1:10

    % Read the measured trace for the current test point.
    y = TP_Data{k};

    % Create the figure only when at least one valid measurement exists.
    if any(isfinite(y))

        % Open a new MATLAB figure window.
        figure('Name', TP_Titles{k});

        % Plot RMS voltage versus frequency on a logarithmic frequency axis.
        semilogx(Frequency_Hz, y, '-o', 'LineWidth', 1.2);

        % Turn on the major and minor grid to make frequency reading easier.
        grid on;
        grid minor;

        % Label the horizontal axis.
        xlabel('Frequency (Hz)');

        % Label the vertical axis.
        ylabel('Measured RMS Voltage (V)');

        % Display the test-point name as the graph title.
        title(TP_Titles{k});

        % Limit the displayed frequency range to the planned audio sweep.
        xlim([100 20000]);

    end
end

% -------------------------------------------------------------------------
% EXPORT CALCULATED RESULTS
% -------------------------------------------------------------------------
% Write the calculated results table to a CSV file for documentation.
writetable(Results, 'amplifier_analysis_results.csv');

% Display a completion message in the MATLAB Command Window.
disp('Analysis complete: TP1-TP10 frequency-sweep graphs generated where data are available.');
