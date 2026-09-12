% AHDS - Practical Circuit Analysis with MATLAB #03
% NE555 PWM DC Motor Controller
% Educational first-order model of TP1..TP4 and motor response.

clear; clc; close all;

%% Circuit parameters
VCC      = 12;          % Supply voltage [V]
Rfixed   = 1e3;         % R12 [ohm]
Rpot     = 50e3;        % R14 total resistance [ohm]
Ctiming  = 100e-9;      % C8 [F]
Vzener   = 10;          % D30 = 1N4740A, nominal Zener voltage [V]
potPos   = 0.50;        % 0.01 ... 0.99 (50% here)

%% Approximate NE555 timing with steering diodes
Rcharge    = Rfixed + potPos*Rpot;
Rdischarge = (1-potPos)*Rpot;

tHigh = log(2)*Rcharge*Ctiming;
tLow  = log(2)*Rdischarge*Ctiming;
T      = tHigh + tLow;
fPWM   = 1/T;
duty   = tHigh/T;

Vmotor_avg = VCC*duty;

fprintf('PWM frequency = %.2f Hz\n', fPWM);
fprintf('Duty cycle    = %.2f %%\n', duty*100);
fprintf('Motor Vavg    = %.2f V\n', Vmotor_avg);

%% Time-domain simulation: six PWM periods
Nperiods = 6;
t = linspace(0, Nperiods*T, 5000);
phase = mod(t,T);
isHigh = phase < tHigh;

% TP1: NE555 output
TP1 = VCC*double(isHigh);

% TP2: simplified P-MOS gate control node.
% OFF ~= VCC; ON ~= VCC - Vzener (about 2 V for 12 V / 10 V clamp).
TP2 = VCC*ones(size(t));
TP2(isHigh) = max(0, VCC - Vzener);

% TP3: idealized switched motor node
TP3 = VCC*double(isHigh);

% TP4: timing capacitor, 1/3 VCC <-> 2/3 VCC
Vlow  = VCC/3;
Vhigh = 2*VCC/3;
TP4 = zeros(size(t));

for k = 1:length(t)
    if phase(k) < tHigh
        tau = Rcharge*Ctiming;
        TP4(k) = VCC - (VCC-Vlow)*exp(-phase(k)/tau);
    else
        tau = Rdischarge*Ctiming;
        td = phase(k)-tHigh;
        TP4(k) = Vhigh*exp(-td/tau);
    end
end

%% Plot TP1 ... TP4
figure('Name','NE555 PWM Test Points');
tiledlayout(4,1);

nexttile;
plot(t*1e3,TP1,'LineWidth',1.2); grid on;
ylabel('V'); title('TP1 - NE555 Output');

nexttile;
plot(t*1e3,TP2,'LineWidth',1.2); grid on;
ylabel('V'); title('TP2 - Q4 Gate Control');

nexttile;
plot(t*1e3,TP3,'LineWidth',1.2); grid on;
ylabel('V'); title('TP3 - Motor Switching Node');

nexttile;
plot(t*1e3,TP4,'LineWidth',1.2); grid on;
ylabel('V'); xlabel('Time [ms]');
title('TP4 - Timing Capacitor');

%% Sweep potentiometer position
p = linspace(0.01,0.99,199);
Rchg = Rfixed + p*Rpot;
Rdis = (1-p)*Rpot;
TH = log(2).*Rchg*Ctiming;
TL = log(2).*Rdis*Ctiming;
F  = 1./(TH+TL);
D  = TH./(TH+TL);
Vavg = VCC.*D;

figure('Name','Duty Cycle vs Potentiometer');
plot(p*100,D*100,'LineWidth',1.5); grid on;
xlabel('Potentiometer position [%]');
ylabel('Duty cycle [%]');
title('Theoretical Duty Cycle');

figure('Name','PWM Frequency');
plot(p*100,F,'LineWidth',1.5); grid on;
xlabel('Potentiometer position [%]');
ylabel('Frequency [Hz]');
title('Theoretical PWM Frequency');

%% Simplified motor speed estimate
% Schematic label: 2300 RPM @ 5 V to 5600 RPM @ 12 V.
% Linear interpolation only -- not a physical dynamic motor model.
rpm = 2300 + (Vavg-5)*(5600-2300)/(12-5);
rpm = max(rpm,0);

figure('Name','Motor Response');
yyaxis left
plot(D*100,Vavg,'LineWidth',1.5); grid on;
ylabel('Average motor voltage [V]');

yyaxis right
plot(D*100,rpm,'--','LineWidth',1.5);
ylabel('Estimated no-load speed [RPM]');

xlabel('Duty cycle [%]');
title('Simplified Motor Response vs Duty Cycle');
