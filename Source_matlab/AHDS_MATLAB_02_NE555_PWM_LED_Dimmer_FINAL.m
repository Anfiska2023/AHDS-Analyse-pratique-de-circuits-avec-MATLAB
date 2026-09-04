%% AHDS - Analyse pratique de circuits avec MATLAB #02
% NE555 PWM LED Dimmer - comparaison BJT / N-MOSFET
% Ce script effectue les calculs, génère 7 figures et les sauvegarde en PNG.

clear; clc; close all;                     % Nettoie l'espace de travail et ferme les figures.

%% 1. Paramètres généraux
VCC = 12;                                  % Tension d'alimentation [V].
Rpot = 50e3;                               % Potentiomètre de réglage [ohm].
Rmin = 1e3;                                % Résistance minimale R3 [ohm].
Ctim = 100e-9;                             % Condensateur de temporisation C1 [F].
Rled = 68;                                 % Résistance série de chaque branche LED [ohm].
Vf = 3.0;                                  % Tension directe approximative d'une LED [V].
Nseries = 3;                               % Nombre de LED en série dans chaque branche.
Nbranches = 4;                             % Nombre de branches du schéma initial.
VCEsat = 0.30;                             % Chute de tension BJT en saturation [V].
Rds_on = 20e-3;                            % RDS(on) d'un MOSFET d'exemple [ohm].
Vout555 = 11;                              % Niveau haut approximatif de la sortie NE555 [V].
VBE = 0.8;                                 % Tension base-émetteur approximative [V].
Rb = 1e3;                                  % Résistance de base R2 corrigée à 1 kOhm.

%% 2. Courant de base du BJT
Ib = (Vout555 - VBE) / Rb;                 % Calcule le courant de base.
fprintf('Courant de base BJT : %.2f mA\n', Ib*1e3);

%% 3. Fréquence nominale du PWM
% Avec les deux diodes, la somme des chemins de charge et de décharge
% reste approximativement égale à Rpot + 2*Rmin.
Tnom = 0.693 * (Rpot + 2*Rmin) * Ctim;      % Période nominale [s].
fPWM = 1 / Tnom;                            % Fréquence nominale [Hz].
fprintf('Frequence PWM approximative : %.1f Hz\n', fPWM);

%% 4. Courant LED à l'état ON avec BJT
Ibranch_on = max((VCC - Nseries*Vf - VCEsat) / Rled, 0); % Courant d'une branche [A].
Itotal_on = Nbranches * Ibranch_on;         % Courant total des quatre branches [A].
fprintf('Courant ON d''une branche : %.1f mA\n', Ibranch_on*1e3);
fprintf('Courant ON total : %.1f mA\n', Itotal_on*1e3);

%% 5. Figure 1 - PWM pour plusieurs rapports cycliques
duties = [0.10 0.25 0.50 0.75 0.90];       % Rapports cycliques étudiés.
t = linspace(0, 4*Tnom, 4000);              % Base temporelle sur quatre périodes.

figure('Name','PWM Duty Cycles');           % Crée la première figure.
hold on;                                    % Permet de superposer plusieurs courbes.
offset = 0;                                 % Décalage vertical pour faciliter la lecture.

for k = 1:length(duties)                    % Parcourt les cinq rapports cycliques.
    D = duties(k);                          % Sélectionne le rapport cyclique courant.
    pwm = mod(t,Tnom) < D*Tnom;             % Génère le signal logique PWM.
    plot(t*1e3, double(pwm)+offset, ...
        'LineWidth',1.4, ...
        'DisplayName',sprintf('%d %%',round(D*100))); % Trace le PWM.
    offset = offset + 1.4;                  % Décale la courbe suivante.
end

grid on;                                    % Active la grille.
xlabel('Temps [ms]');                       % Nomme l'axe X.
ylabel('Niveau logique + décalage');        % Nomme l'axe Y.
title('NE555 PWM - Influence du rapport cyclique'); % Ajoute le titre.
legend('Location','best');                  % Affiche la légende.
exportgraphics(gcf,'01_PWM_duty_cycles.png','Resolution',300); % Sauvegarde le PNG.

%% 6. Figure 2 - Charge et décharge du condensateur C1
alpha = 0.50;                               % Position du potentiomètre : 50 %.
Rcharge = Rmin + alpha*Rpot;                % Résistance équivalente de charge.
Rdischarge = Rmin + (1-alpha)*Rpot;         % Résistance équivalente de décharge.
ton = 0.693*Rcharge*Ctim;                   % Temps ON approximatif.
toff = 0.693*Rdischarge*Ctim;               % Temps OFF approximatif.
T = ton + toff;                             % Période correspondante.
t2 = linspace(0,5*T,5000);                  % Base temporelle sur cinq périodes.
phase = mod(t2,T);                          % Position temporelle dans chaque période.
Vlow = VCC/3;                               % Seuil bas du NE555.
Vhigh = 2*VCC/3;                            % Seuil haut du NE555.
Vc = zeros(size(t2));                       % Préalloue le vecteur de tension C1.

for k = 1:length(t2)                        % Calcule la tension du condensateur.
    if phase(k) < ton                       % Teste si C1 est en phase de charge.
        Vc(k) = VCC-(VCC-Vlow)*exp(-phase(k)/(Rcharge*Ctim)); % Charge exponentielle.
    else                                    % Sinon, C1 est en phase de décharge.
        td = phase(k)-ton;                  % Calcule le temps depuis le début de la décharge.
        Vc(k) = Vhigh*exp(-td/(Rdischarge*Ctim)); % Décharge exponentielle.
    end
end

figure('Name','C1 Charge-Decharge');        % Crée la deuxième figure.
plot(t2*1e3,Vc,'LineWidth',1.4);            % Trace la tension de C1.
hold on;                                    % Permet d'ajouter les seuils.
yline(Vlow,'--','1/3 VCC');                 % Trace le seuil bas.
yline(Vhigh,'--','2/3 VCC');                % Trace le seuil haut.
grid on;                                    % Active la grille.
xlabel('Temps [ms]');                       % Nomme l'axe X.
ylabel('Tension V_C [V]');                  % Nomme l'axe Y.
title('Charge et decharge du condensateur C1'); % Ajoute le titre.
exportgraphics(gcf,'02_C1_charge_decharge.png','Resolution',300); % Sauvegarde le PNG.

%% 7. Figure 3 - Courants instantanés des LED
pwm50 = phase < ton;                        % Génère le PWM correspondant à alpha = 50 %.
Iled_t = Ibranch_on*double(pwm50);          % Courant instantané d'une branche.
Itotal_t = Itotal_on*double(pwm50);         % Courant instantané total.

figure('Name','LED Current');               % Crée la troisième figure.
plot(t2*1e3,Iled_t*1e3,'LineWidth',1.4);    % Trace le courant d'une branche.
hold on;                                    % Permet d'ajouter le courant total.
plot(t2*1e3,Itotal_t*1e3,'LineWidth',1.4);  % Trace le courant des quatre branches.
grid on;                                    % Active la grille.
xlabel('Temps [ms]');                       % Nomme l'axe X.
ylabel('Courant [mA]');                     % Nomme l'axe Y.
title('Courant instantane des LED - PWM a 50 %'); % Ajoute le titre.
legend('Une branche','4 branches','Location','best'); % Ajoute la légende.
exportgraphics(gcf,'03_LED_current_waveform.png','Resolution',300); % Sauvegarde le PNG.

%% 8. Figure 4 - Courant moyen en fonction du duty cycle
Dvec = linspace(0,1,101);                   % Crée un balayage de 0 à 100 %.
Iavg_branch = Ibranch_on.*Dvec;             % Calcule le courant moyen d'une branche.
Iavg_total = Itotal_on.*Dvec;               % Calcule le courant moyen total.

figure('Name','Average Current');            % Crée la quatrième figure.
plot(Dvec*100,Iavg_branch*1e3,'LineWidth',1.4); % Trace le courant moyen d'une branche.
hold on;                                    % Permet d'ajouter le courant total.
plot(Dvec*100,Iavg_total*1e3,'LineWidth',1.4); % Trace le courant moyen total.
grid on;                                    % Active la grille.
xlabel('Rapport cyclique [%]');             % Nomme l'axe X.
ylabel('Courant moyen [mA]');               % Nomme l'axe Y.
title('Courant moyen des LED en fonction du duty cycle'); % Ajoute le titre.
legend('Une branche','4 branches','Location','best'); % Ajoute la légende.
exportgraphics(gcf,'04_Average_current_vs_duty.png','Resolution',300); % Sauvegarde le PNG.

%% 9. Figure 5 - Comparaison des pertes BJT / MOSFET
Ivec = linspace(0,5,300);                   % Balaye le courant de charge de 0 à 5 A.
Dcompare = 0.80;                            % Utilise 80 % de duty cycle pour la comparaison.
Pbjt = VCEsat.*Ivec.*Dcompare;              % Calcule les pertes de conduction du BJT.
Pmos = (Ivec.^2).*Rds_on.*Dcompare;         % Calcule les pertes de conduction du MOSFET.

figure('Name','BJT vs MOSFET');             % Crée la cinquième figure.
plot(Ivec,Pbjt,'LineWidth',1.4);            % Trace les pertes du BJT.
hold on;                                    % Permet d'ajouter la courbe MOSFET.
plot(Ivec,Pmos,'LineWidth',1.4);            % Trace les pertes du MOSFET.
grid on;                                    % Active la grille.
xlabel('Courant de charge [A]');            % Nomme l'axe X.
ylabel('Pertes de conduction [W]');         % Nomme l'axe Y.
title('Comparaison des pertes - BJT vs N-MOSFET'); % Ajoute le titre.
legend('BJT','N-MOSFET','Location','northwest'); % Ajoute la légende.
exportgraphics(gcf,'05_BJT_vs_MOSFET_losses.png','Resolution',300); % Sauvegarde le PNG.

%% 10. Figure 6 - Courant total en fonction du nombre de LED
Nled = 3:3:300;                             % Fait varier le nombre total de LED de 3 à 300.
Nstrings = Nled/3;                          % Calcule le nombre de branches de trois LED.
Istring = 20e-3;                            % Fixe 20 mA par branche pour cette étude d'échelle.
Iload = Nstrings.*Istring;                  % Calcule le courant total à 100 % duty cycle.

figure('Name','LED Count Current');         % Crée la sixième figure.
plot(Nled,Iload,'LineWidth',1.4);           % Trace le courant total.
grid on;                                    % Active la grille.
xlabel('Nombre total de LED');              % Nomme l'axe X.
ylabel('Courant total a 100 % [A]');        % Nomme l'axe Y.
title('Courant total en fonction du nombre de LED'); % Ajoute le titre.
exportgraphics(gcf,'06_Total_current_vs_LED_count.png','Resolution',300); % Sauvegarde le PNG.

%% 11. Figure 7 - Pertes BJT / MOSFET en fonction du nombre de LED
Pbjt_led = VCEsat.*Iload;                   % Calcule les pertes BJT à 100 % duty cycle.
Pmos_led = (Iload.^2).*Rds_on;              % Calcule les pertes MOSFET à 100 % duty cycle.

figure('Name','Losses vs LED Count');       % Crée la septième figure.
plot(Nled,Pbjt_led,'LineWidth',1.4);        % Trace les pertes BJT.
hold on;                                    % Permet d'ajouter les pertes MOSFET.
plot(Nled,Pmos_led,'LineWidth',1.4);        % Trace les pertes MOSFET.
grid on;                                    % Active la grille.
xlabel('Nombre total de LED');              % Nomme l'axe X.
ylabel('Pertes de conduction [W]');         % Nomme l'axe Y.
title('Pertes BJT / MOSFET en fonction du nombre de LED'); % Ajoute le titre.
legend('BJT','N-MOSFET','Location','northwest'); % Ajoute la légende.
exportgraphics(gcf,'07_Losses_vs_LED_count.png','Resolution',300); % Sauvegarde le PNG.

%% 12. Fin du calcul
fprintf('\nSimulation terminee.\n');          % Confirme la fin du script.
fprintf('Les 7 graphiques ont ete sauvegardes au format PNG.\n'); % Confirme la sauvegarde.

