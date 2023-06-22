classdef covidModel %Nonlinear Dynamic System
    properties
        numStates = 8   % Number of states
        numInputs = 3   % Number of inputs
        numOutputs = 2  % Number of outputs
        time = 'c';     % 'c' ~> Continuous, 'd' ~> discrete
        
        %% kalman filter variables
        initialStates = zeros(8,1);    % Initial value of states
        covariance = 1e+1*eye(8);      % Covariance of states
        qMatrix = diag([1e0,    ...    % S noise variance
                        1e0,    ...    % E noise variance
                        1e0,    ...    % I noise variance
                        1e0,    ...    % Q noise variance
                        1e0,    ...    % H noise variance
                        1e0,    ...    % R noise variance
                        1e0,    ...    % D noise variance
                        1e0]);         % P noise variance
        rMatrix = diag([1e0, 1e0]);    % External noise weights

        kappa = 17;                    % A non-negative real number
        alpha = 0.24;                  % a \in (0, 1]
        
        %% nonlinear model predictive control variables
        numPrediction = 10;            % Number of Prediction horizon
        Uopt = rand(3, 9);             % Start search on input area
        Qx = diag([ 0,      ...        % S cost
                    10,     ...        % E cost
                    10,     ...        % I cost
                    0,      ...        % Q cost
                    0,      ...        % H cost
                    0,      ...        % R cost
                    10,     ...        % D cost
                    0]);               % P cost
        Qu = diag([1,       ...        % Social distancing cost
                   1,       ...        % Hospitalized cost
                   1]);                % Vaccination cost
        Qdu = diag([0,      ...
                    0,      ...
                    0]);
        Qf = eye(8)*0;  % Final state cost
        constA = [];    % Linear inequality matrix 'A' from optimization (A*x<B)
        constB = [];    % Linear inequality matrix 'B' from optimization (A*x<B)
        constAeq = [];  % Linear Equality matrix 'A' from optimization (Aeq*x=Beq)
        constBeq = [];  % Linear Equality matrix 'B' from optimization (Aeq*x=Beq)
        
        %% Other variables
        betta = 0.000002;
        malpha = 0.00000172;
        gamma = 0.5;
        delta = 10;
        landa = 0.025;
        mkappa = 0.004;
        kissi = 0.92*0.2;
        ettta = 0.08*0.2;
        zetta1 = 0.02; % Recovered to susceptible rate
        zetta2 = 0.5;        
        setta = 60*24*60*60; % 3 month (in second) after vaccina or recovered, people will not safety
        shif = 7*24*60*60; % Convert second to 1 week (time-scale)
    end
    
    methods
        %% Internal function that represented internal relation between States and inputs.
        % ~~> dx = f(x,u)
        function dx = dynamics(obj, x, u, t, st)
            sett = ceil(obj.setta/st);
            if t - sett > 0
                Rdelayed = x(1, t-sett)*u(3,t-sett)*obj.zetta2;
            else
                Rdelayed = 0;
            end
            dx(1) = -obj.betta*x(1,t)*x(3,t)*(1 - u(1,t)) - obj.malpha*x(1,t) - u(3,t)*x(1,t) + obj.zetta1*x(6,t) + Rdelayed; % dS
            dx(2) = obj.betta*x(1,t)*x(3,t)*(1 - u(1,t)) - obj.gamma*x(2,t); % dE
            dx(3) = obj.gamma*x(2,t) - obj.delta*x(3,t) - u(2,t)*x(3,t); % dI
            dx(4) = obj.delta*x(3,t) - obj.landa*x(4,t) - obj.mkappa*x(4,t); % dQ
            dx(5) = u(2,t)*x(3,t) - obj.kissi*x(5,t) - obj.ettta*x(5,t); % dH
            dx(6) = obj.landa*x(4,t) + u(3,t)*x(1,t) + obj.kissi*x(5,t) - obj.zetta1*x(6,t) - Rdelayed; % dR
            dx(7) = obj.mkappa*x(4,t) + obj.ettta*x(5,t); % dD
            dx(8) = obj.malpha*x(1,t); % dP
            dx = dx / obj.shif;
        end
        
        %% Output functions ~~> y = g(x,u)
        function y = external(~, x, ~, t, ~)
            y(1) = x(5, t); % Hospitalization
            y(2) = x(7, t); % Deseased
        end
        
        %% Get jacobians
        function [A, L, H, M] = jacobians(obj, x, u, t, st)
            sett = ceil(obj.setta/st);
            if t - sett > 0
                Vdelayed = u(3,t-sett)*obj.zetta2;
            else
                Vdelayed = 0;
            end
            
            % A matrix
            A = zeros(8, 8);
            A(1,1) = -obj.betta*x(3,t)*(1 - u(1,t)) - obj.malpha - u(3,t);
            A(1,3) = -obj.betta*x(3,t)*(1 - u(1,t));
            A(1,6) = obj.zetta1 + Vdelayed;
            A(2,1) = obj.betta*x(1,t)*(1 - u(1,t));
            A(2,2) = -obj.gamma;
            A(3,2) = obj.gamma;
            A(3,3) = -obj.delta - u(2,t);
            A(4,3) = obj.delta;
            A(4,4) = -obj.landa - obj.mkappa;
            A(5,3) = u(2,t);
            A(5,5) = -obj.kissi - obj.ettta;
            A(6,1) = u(3,t);
            A(6,4) = obj.landa;
            A(6,5) = obj.kissi;
            A(6,6) = -obj.zetta1 - Vdelayed;
            A(7,4) = obj.mkappa;
            A(7,5) = obj.ettta;
            A(8,1) = obj.malpha;
            A = st*A/obj.shif;
            A(1,1) = A(1,1) + 1;
            A(2,2) = A(2,2) + 1;
            A(3,3) = A(3,3) + 1;
            A(4,4) = A(4,4) + 1;
            A(5,5) = A(5,5) + 1;
            A(6,6) = A(6,6) + 1;
            A(7,7) = A(7,7) + 1;
            A(8,8) = A(8,8) + 1;
            
            % L matrix - Process noise style
            L = 1;
            
            % H matrix
            H = zeros(2, 8);
            H(1,5) = 1;
            H(2,7) = 1;
            
            % M matrix - Measurement Noise style
            M = 1;
        end
        
        %% Constriants for NMPC tool
        function [C, Ceq] = constriants(obj, U, consts, t, upStep)
            C = zeros(obj.numPrediction - 1, 1);
            for i = 1:(obj.numPrediction - 1)
                indi = (1:obj.numInputs) + (i-1)*obj.numInputs;
                u = U(indi);
                if t + i - 1 < upStep
                    cost = consts.uCost(:, t + i - 1);
                    price = consts.allocatedPrice(:, t + i - 1);
                else
                    cost = consts.uCost(:, upStep - 1);
                    price = consts.allocatedPrice(:, upStep - 1);
                end
                C(i) = cost'*(u.^2) - price;
            end
            Ceq = [];
        end
        
    end
end

