function params = setParameters(extOpt)
    
    %% Simulation parameters
    params.step = 4*60*60; % Simulation time step (sec)
    params.Tout = 2*360*24*60*60; % Simulation end time (sec)
    params.n = floor(params.Tout/params.step);
    
    %% System parameters
    params.initialStates = [3.75e+7, ...  % Susceptible
                            35000,   ...  % Exposed
                            34000,   ...  % Infected
                            40000,   ...  % Quarantined
                            40000,   ...  % Hospitalized
                            47000,   ...  % Recovered
                            7000,    ...  % Deceased
                            37500];       % Insusceptible
                           
    %% Nonlinear Model Predictive Control (NMPC)
    params.cntrlFiltPole = 100000;  % Pole of control filter
    params.filterCntrlorNot = 0;    % 1 ~> Filtered, 0 ~> filter is off
    
    
    %% Measurement Noise parameters
    params.hospitalVariance = 1e0; % Variance of hospitalized noise
    params.deseasedVariance = 1e0; % Variance of deseased noise
    
    %% External properties - used to control 'main.m from other files
    if nargin > 0
        params.extopt = extOpt;
    end
end
