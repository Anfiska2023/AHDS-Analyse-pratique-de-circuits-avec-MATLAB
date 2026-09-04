%% AHDS - Analyse pratique de circuits avec MATLAB #01
% Titre du script et identification de l'exemple étudié.

% NE555 en mode astable : R1 = 1 kOhm, R2 = 470 kOhm, C1 = 1 uF, VCC = 9 V.
% Rappel des valeurs principales utilisées dans le schéma.

clear;                      % Supprime toutes les variables présentes dans l'espace de travail MATLAB.
clc;                        % Efface le contenu affiché dans la fenêtre de commande.
close all;                  % Ferme toutes les fenêtres graphiques ouvertes précédemment.

%% Parametres du circuit
% Début de la section contenant les paramètres électriques du montage.

VCC = 9;                    % Définit la tension d'alimentation du NE555 à 9 V.
R1  = 1e3;                  % Définit R1 = 1 kOhm, résistance supérieure du réseau de temporisation.
R2  = 470e3;                % Définit R2 = 470 kOhm, résistance principale de charge/décharge.
C1  = 1e-6;                 % Définit C1 = 1 uF, condensateur de temporisation.

VTL = VCC/3;                % Calcule le seuil inférieur interne du NE555 : 1/3 de VCC.
VTH = 2*VCC/3;              % Calcule le seuil supérieur interne du NE555 : 2/3 de VCC.

%% Calculs theoriques
% Début du calcul des temps haut, bas, de la période, de la fréquence et du rapport cyclique.

tH = log(2)*(R1+R2)*C1;     % Calcule la durée de l'état haut pendant la charge de C1 via R1 + R2.
tL = log(2)*R2*C1;          % Calcule la durée de l'état bas pendant la décharge de C1 via R2.

T = tH + tL;                % Calcule la période complète d'oscillation.
f = 1/T;                    % Calcule la fréquence d'oscillation en hertz.
D = 100*tH/T;               % Calcule le rapport cyclique de la sortie en pourcentage.

fprintf('tH = %.4f s\n',tH); % Affiche dans la console la durée théorique de l'état haut.
fprintf('tL = %.4f s\n',tL); % Affiche dans la console la durée théorique de l'état bas.
fprintf('T  = %.4f s\n',T);  % Affiche dans la console la période complète.
fprintf('f  = %.3f Hz\n',f); % Affiche dans la console la fréquence d'oscillation.
fprintf('D  = %.2f %%\n',D); % Affiche dans la console le rapport cyclique en pourcentage.

%% Axe temporel
% Création de l'axe temporel utilisé pour la simulation comportementale.

dt = 0.0005;                % Définit le pas de calcul à 0,5 ms.
tFin = 3;                   % Définit une durée totale de simulation de 3 secondes.
t = 0:dt:tFin;              % Crée le vecteur temps allant de 0 à 3 s avec le pas dt.

Vc = zeros(size(t));        % Préalloue le tableau qui contiendra la tension sur le condensateur C1.
Vout = zeros(size(t));      % Préalloue le tableau qui contiendra la tension de sortie du NE555.

%% Premiere charge du condensateur
% Au démarrage, C1 est considéré comme totalement déchargé.

tFirst = -(R1+R2)*C1*log(1-VTH/VCC);
% Calcule le temps nécessaire pour que C1 passe de 0 V au seuil supérieur VTH.

%% Simulation temporelle
% La boucle suivante calcule l'état du circuit pour chaque instant du vecteur temps.

for k = 1:length(t)         % Parcourt successivement tous les instants de la simulation.

    if t(k) <= tFirst       % Vérifie si le circuit se trouve encore dans la première phase de charge.

        Vc(k) = VCC*(1-exp(-t(k)/((R1+R2)*C1)));
        % Calcule la charge exponentielle initiale de C1 depuis 0 V vers VCC.

        Vout(k) = VCC;      % Maintient la sortie à l'état haut pendant cette première phase de charge.

    else                    % Exécute le régime périodique après la première commutation.

        tau = t(k)-tFirst;  % Calcule le temps écoulé depuis la première commutation du NE555.
        tc = mod(tau,T);    % Ramène ce temps à la position correspondante dans une seule période T.

        if tc < tL          % Vérifie si le circuit se trouve dans la phase de décharge de C1.

            Vc(k) = VTH*exp(-tc/(R2*C1));
            % Calcule la décharge exponentielle de C1 depuis 2/3 VCC vers 1/3 VCC.

            Vout(k) = 0;    % Place la sortie du NE555 à l'état bas pendant la décharge.

        else                % Exécute la phase de charge suivante de C1.

            tch = tc-tL;    % Calcule le temps écoulé depuis le début de la phase de charge.

            Vc(k) = VCC-(VCC-VTL)*exp(-tch/((R1+R2)*C1));
            % Calcule la charge exponentielle de C1 depuis 1/3 VCC vers 2/3 VCC.

            Vout(k) = VCC;  % Place la sortie du NE555 à l'état haut pendant la charge.

        end                 % Termine le test entre la phase de charge et la phase de décharge.
    end                     % Termine le test concernant la première charge du condensateur.
end                         % Termine la boucle de simulation temporelle.

%% Generation du graphique
% Création des courbes permettant de comparer Vc et la sortie du NE555.

figure;                     % Ouvre une nouvelle fenêtre graphique MATLAB.
plot(t,Vc,'LineWidth',1.8); % Trace la tension du condensateur C1 en fonction du temps.
hold on;                    % Conserve la première courbe afin d'en superposer d'autres.
plot(t,Vout,'LineWidth',1.5);
% Trace sur le même graphique la tension de sortie du NE555.

yline(VTL,'--','1/3 VCC = 3 V');
% Ajoute une ligne horizontale indiquant le seuil inférieur du NE555.

yline(VTH,'--','2/3 VCC = 6 V');
% Ajoute une ligne horizontale indiquant le seuil supérieur du NE555.

grid on;                    % Active la grille afin de faciliter la lecture des valeurs.
xlabel('Temps (s)');        % Ajoute le titre de l'axe horizontal.
ylabel('Tension (V)');      % Ajoute le titre de l'axe vertical.

title('NE555 en mode astable - Simulation theorique');
% Ajoute le titre principal du graphique.

legend('Tension sur C1','Sortie NE555 (Pin 3)','Location','best');
% Ajoute la légende et demande à MATLAB de choisir automatiquement sa meilleure position.

