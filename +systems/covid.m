classdef covid %Nonlinear Dynamic System
    properties
        numStates = 8     % Number of states
        numInputs = 3     % Number of inputs
        numOutputs = 2    % Number of outputs
        time = 'c';       % c -> Continuous  ,  d -> Discrete
        qMatrix = [1e0;   % S noise variance percentage
                   1e0;   % E noise variance percentage
                   1e0;   % I noise variance percentage
                   1e0;   % Q noise variance percentage
                   1e0;   % H noise variance percentage
                   1e0;   % R noise variance percentage
                   1e0;   % D noise variance percentage
                   1e0];  % P noise variance percentage
                    
        % Other Variables
        betta = 0.000002;
        alpha = 0.00000172;
        gamma = 0.5;
        delta = 10;
        landa = 0.025;
        kappa = 0.004;
        kissi = 0.92*0.2;
        ettta = 0.08*0.2;
        zetta1 = 0.02; % Recovered to susceptible rate
        zetta2 = 0.5;        
        setta = 60*24*60*60; % 3 month (in second) after vaccina or recovered, people will not safety
        shif = 7*24*60*60;
    end
    
    methods
        %% Internal function that represented internal relation beetwin States and inputs.
        % ~~> dx = f(x,u)
        function dx = dynamics(obj, x, u, t, st)
            sett = ceil(obj.setta/st);
            if t - sett > 0
                Rdelayed = x(1, t-sett)*u(3,t-sett)*obj.zetta2;
            else
                Rdelayed = 0;
            end
            dx(1) = -obj.betta*x(1,t)*x(3,t)*(1 - u(1,t)) - obj.alpha*x(1,t) - u(3,t)*x(1,t) + obj.zetta1*x(6,t) + Rdelayed; % dS
            dx(2) = obj.betta*x(1,t)*x(3,t)*(1 - u(1,t)) - obj.gamma*x(2,t); % dE
            dx(3) = obj.gamma*x(2,t) - obj.delta*x(3,t) - u(2,t)*x(3,t); % dI
            dx(4) = obj.delta*x(3,t) - obj.landa*x(4,t) - obj.kappa*x(4,t); % dQ
            dx(5) = u(2,t)*x(3,t) - obj.kissi*x(5,t) - obj.ettta*x(5,t); % dH
            dx(6) = obj.landa*x(4,t) + u(3,t)*x(1,t) + obj.kissi*x(5,t) - obj.zetta1*x(6,t) - Rdelayed; % dR
            dx(7) = obj.kappa*x(4,t) + obj.ettta*x(5,t); % dD
            dx(8) = obj.alpha*x(1,t); % dP
            dx = (dx + randn(1,8).*obj.qMatrix')/obj.shif; % Shift time and add noise
        end
        %% Output functions ~~> y = g(x,u)
        function y = external(~, x, ~, t, ~)
            y(1) = x(5, t);
            y(2) = x(7, t);
        end
    end
end

