function [J0, D, T, Y, E, iter, Inneriter] = SolveMatterEquations_EmAb_FP( Jin, Chi, D, T, Y, E )

% g_E_N       : nE_G x 1 (energy grid)
% J, J_0    : nE_G x 1 (size of energy grid)
% Chi       : nE_G x 1 (size of energy grid)
% W2_N, W3_N: nE_G x 1 (size of energy grid)

% constants
global AtomicMassUnit BoltzmannConstant Erg2MeV SpeedOfLight PlanckConstant;

% energy grid
global g_E_N g_W2_N g_W3_N;

% iteration data

global g_Iterations_Min g_Iterations_Max g_Iterations_Ave;

hc = PlanckConstant * SpeedOfLight;
c = SpeedOfLight;

Rtol = 1e-8; Utol = 1e-10; maxIter = 100;

iY = 1;
iE = 2;
U = zeros(2,1);
C = zeros(2,1);
Unew = zeros(2,1);


% \rho / m_B
N_B = D / AtomicMassUnit;

Chi = Chi * c;

% scales
s_Y = N_B;
s_E = D;


% (scaled) weights
Theta2_N = 4 * pi * g_W2_N;
Theta3_N = 4 * pi * g_W3_N;

Theta2_N = Theta2_N / (hc)^3;
Theta3_N = Theta3_N / (hc)^3;

% store initial values
Y0 = Y;
E0 = E * Erg2MeV; % change unit

% update scales
s_Y = s_Y * Y0;
s_E = s_E * E0;

% initial guess (both 1 for now)
U(iY) = Y / Y0;
U(iE) = E * Erg2MeV / E0; % change unit

U0 = U;

% calculate known values
C(iY) = Theta2_N' * Jin / s_Y;
C(iE) = Theta3_N' * Jin / s_E;


k = 0;
Inneriter = 0;
CONVERGED = false;

while((~CONVERGED)&&(k<=maxIter))
    
    k = k + 1;
    
    % compute chemical potential and derivatives
    [Mnu, ~, ~] = ComputeNeutrinoChemicalPotentials(D, T, Y);
    
    % equilibrium distribution
    J0 = FermiDirac( g_E_N, Mnu, BoltzmannConstant * T );
    
    % compute new J
%     [Jout, iter_in] = UpdateNeutrinoDistribution(Jin, J0, Chi);
    [Jout, iter_in] = UpdateNeutrinoDistribution_exact(Jin, J0, Chi);
%     [Jout, iter_in] = UpdateNeutrinoDistribution_NES(Jin, J0, Chi);

    Inneriter = Inneriter + iter_in;
    
    % Picard iteration (update U)
    Unew(iY) = 1 + C(iY) - Theta2_N' * Jout / s_Y;
    Unew(iE) = 1 + C(iE) - Theta3_N' * Jout / s_E;
    
    % check convergence
    if (norm(Unew-U) <= Rtol * norm(U0))
        CONVERGED = true;
        g_Iterations_Min = min( g_Iterations_Min, k );
        g_Iterations_Max = max( g_Iterations_Max, k );
        g_Iterations_Ave = g_Iterations_Ave + k;
    end
    
    % update U, Y, E, T
    U = Unew;
    
    Y = U(iY) * Y0;
    E = U(iE) * E0 / Erg2MeV; % change unit    
    T = ComputeTemperatureFromSpecificInternalEnergy_TABLE(D, E, Y);
end

if(k >= maxIter)
    disp("Failed to converge within maxIter.");
end

% --- Neutrino Chemical Potential and Derivatives ---
[Mnu, ~, ~] = ComputeNeutrinoChemicalPotentials(D, T, Y);

% --- Equilibrium Distribution ---
J0 = FermiDirac( g_E_N, Mnu, BoltzmannConstant * T );

iter = k;






end












