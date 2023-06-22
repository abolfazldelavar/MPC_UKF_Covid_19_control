function models = modelMaker(params, func)
    
%% Simulation Time variables
    models.Tline = 0:params.step:params.Tout;
    
%% System modeling
    % Making plant
    models.covid = ru.nonlinearSystem(systems.covid, ...  % Covid 19 plant file
                                      params.step,   ...  % Sample sime
                                      models.Tline,  ...  % Time line
                                      params.initialStates);
    % Kalman filter making model
    models.extkf = ru.ekfnmpc(systems.covidModel,    ...  % Covid model of EKF
                              params.step,           ...  % Sample time
                              models.Tline,          ...  % Time line
                              params.initialStates);      % Initial condition of EKF (not necessary)
    
%% Nonlinear Model Predictive Control (NMPC)
    % Maximum and minimum amount of input signal
    models.const.uMin = [ones(1, params.n)*0;      % Minimum social distancing
                         ones(1, params.n)*0;      % Minimum hospitalized
                         ones(1, params.n)*0];     % Minimum vaccination
    models.const.uMax = [func.uMax(func, models.Tline, 'd');  % Social distancing capacity of society
                         func.uMax(func, models.Tline, 'h');  % Hospitalized capacity of society
                         func.uMax(func, models.Tline, 'v')]; % Vaccination capacity of society
    % Cost amount of input rates: (a1u1 + a2u2 + a3u3 < E)
    models.const.uCost = [func.uCost(func, models.Tline, 'd');   % Cost of social distancing rate
                          func.uCost(func, models.Tline, 'h');   % Cost of hospitalized rate
                          func.uCost(func, models.Tline, 'v')];  % Cost of vaccination rate
    models.const.allocatedPrice = func.allocatedPrice(func, models.Tline); % Maximum the budget
    % Reference signal
    models.const.ref = [func.exponen(models.Tline, [params.initialStates(1), 100, 5e-7]);     % Susceptible reference
                        func.exponen(models.Tline, [params.initialStates(2)*1.8, 100, 3e-7]); % Exposed reference
                        func.exponen(models.Tline, [params.initialStates(3), 100, 2e-6]);     % Infected reference
                        func.exponen(models.Tline, [params.initialStates(4), 100, 5e-7]);     % Quarantined reference
                        func.exponen(models.Tline, [params.initialStates(5), 100, 5e-7]);     % Hospitalized reference
                        func.exponen(models.Tline, [params.initialStates(6), 100, 5e-7]);     % Recovered reference
                        func.exponen(models.Tline, [params.initialStates(7), ...
                                                    params.initialStates(7)*5, 5e-8]);        % Deceased reference
                        func.exponen(models.Tline, [params.initialStates(8), 100, 5e-7])];    % Insusceptible reference
    
%% Filters
    filtTF = [tf(1,[params.cntrlFiltPole, 1]), 0, 0; 0, tf(1,[params.cntrlFiltPole, 1]), 0; 0, 0, tf(1,[params.cntrlFiltPole, 1])];
    models.controlFilter = ru.linearSystem(ss(filtTF), params.step, models.Tline);
    
%% Other Signals
    models.measurement = zeros(2, params.n); % Measurement signal
    models.inputCovid = zeros(3, params.n);  % Control signal - applied to Plant
    
    hospitalNoise = randn(1, params.n)*params.hospitalVariance; % Hospitalization noise
    deseasedNoise = randn(1, params.n)*params.deseasedVariance; % deseased count noise
    models.measurementNoise = [hospitalNoise; deseasedNoise];   % [Hos. Noi. ; Dese. Noi.]
end
