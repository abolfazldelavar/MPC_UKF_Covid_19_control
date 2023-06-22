classdef ekfnmpc
    
    properties(SetAccess=private)
        block
        sampleTime
        numSteps
        numStates
        numOutputs
        numInputs
        states
        inputs
        outputs
        timeLine
        presentStep

        % EKF variables
        qMatrix
        rMatrix
        initialstates
        covariance

        % UKF variables
        nUKF    % This is usually = Number of states
        kappa   % A non-negative real number
        alpha   % a \in (0, 1]
        lambda  % Unscented KF parameter
        betta   % Unscented KF parameter
        wm      % Unscented KF weights. Used in state
        wc      % Unscented KF weights. Used in covariance
        
        % NMPC variables
        numPrediction
        controlInputs
        Uopt
        Qx
        Qu
        Qdu
        Qf
        constA
        constB
        constAeq
        constBeq
        fValue
        
    end
    
    methods
    %% Initial function run to set default properties and make initial signals
        function obj = ekfnmpc(inputsystem, sampletime, timeline, initialcondition)
            % system, sample time, number of simulation steps, first state
            obj.block = inputsystem;
            obj.sampleTime = sampletime;
            obj.timeLine = timeline(:)';
            obj.numSteps = numel(obj.timeLine);
            obj.numStates = obj.block.numStates;
            obj.numInputs = obj.block.numInputs;
            obj.numOutputs = obj.block.numOutputs;
            obj.inputs = zeros(obj.numInputs, obj.numSteps);
            obj.controlInputs = zeros(obj.numInputs, obj.numSteps);
            obj.fValue = zeros(1, obj.numSteps);
            obj.outputs = zeros(obj.numOutputs, obj.numSteps);
            obj.presentStep = 0;
            
            % EKF variables
            obj.initialstates = obj.block.initialStates(:);
            obj.covariance = obj.block.covariance;
            obj.qMatrix = obj.block.qMatrix;
            obj.rMatrix = obj.block.rMatrix;
            
            % NMPC variables
            obj.numPrediction = obj.block.numPrediction;
            obj.Uopt = obj.block.Uopt;
            obj.Qx = obj.block.Qx;
            obj.Qu = obj.block.Qu;
            obj.Qdu = obj.block.Qdu;
            obj.Qf = obj.block.Qf;
            obj.constA = obj.block.constA;
            obj.constB = obj.block.constB;
            obj.constAeq = obj.block.constAeq;
            obj.constBeq = obj.block.constBeq;
            

            obj.qMatrix = obj.block.qMatrix;
            obj.rMatrix = obj.block.rMatrix;
            obj.kappa = obj.block.kappa;
            obj.alpha = obj.block.alpha;
            % Dependent variables
            obj.nUKF = obj.numStates;
            obj.lambda = obj.alpha^2*(obj.nUKF + obj.kappa) - obj.nUKF;
            obj.betta = 2;
            % Making weights
            obj.wm = ones(2*obj.nUKF + 1, 1)/(2*(obj.nUKF + obj.lambda));
            obj.wc = obj.wm;
            obj.wc(1) = obj.wm(1) + (1 - obj.alpha^2 + obj.betta);

            if nargin<4
                obj.states = [obj.initialstates ,zeros(obj.numStates, obj.numSteps)];
            else
                initialcondition = initialcondition(:);
                obj.states = [initialcondition ,zeros(obj.numStates, obj.numSteps)];
            end
        end
    %% Next step of extended kalman filter
        function obj = nextstepEKF(obj, u, y)
            u = u(:);
            y = y(:);
            obj.inputs(:, obj.presentStep + 1) = u;
            obj.outputs(:, obj.presentStep + 1) = y;
            % use dynamic of system to calculate Jacobians
            [A, L, H, M] = obj.block.jacobians(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime);
            % Update sm in prediction step
            xm = obj.states(:, obj.presentStep + 1);
            if obj.block.time == 'c'
                xp = xm + obj.sampleTime*obj.block.dynamics(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime)';
            else
                xp = obj.block.dynamics(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime)';
            end
            % Update covariance matrix - prediction step
            Pp = A*obj.covariance*A' + L*obj.qMatrix*L';
            % Recive measurement and posterior step start:
            K = Pp*H'/(H*Pp*H' + M*obj.rMatrix*M'); % Kalman Gain
            xm = xp + K*(y - H*xp);
            Pm = (eye(size(obj.covariance, 1)) - K*H)*Pp;
            % Update internal signals
            obj.states(:, obj.presentStep + 2)  = xm;
            obj.covariance                        = Pm;
        end

    %% Next step of Unscented Kalman Filter (UKF)
        function obj = nextstepUKF(obj, u, y)
            % Preparing and saving inputs and outputs to internal
            u = u(:); y = y(:);
            obj.inputs(:, obj.presentStep + 1) = u;
            obj.outputs(:, obj.presentStep + 1) = y;
            % Using dynamics of system to calculate Jacobians
            [~, L, ~, M] = obj.block.jacobians(obj.states,          ...
                                               obj.inputs,          ...
                                               obj.presentStep + 1, ...
                                               obj.sampleTime);
            % Getting last states prior and its covariance
            xm = obj.states(:, obj.presentStep + 1);
            Pm = obj.covariance;
            
            %% Solving sigma points, STEP 2
            dSigma = sqrt(obj.nUKF + obj.lambda)*chol(Pm)'; % Calculating sqrt
            xmCopy = xm(:, ones(1, numel(xm))); % Putting 'xm' is some column (copy)
            sp = [xm, xmCopy + dSigma, xmCopy - dSigma]; % Obtaining sigma points
            
            %% Prediction states and their covariance, STEP 3
            %  This part tries to obtain a prediction estimate from dynamic
            %  model of your system directly from nonlinear equations
            nSpoints = size(sp, 2);
            xp = zeros(obj.numStates, 1);
            Xp = zeros(obj.numStates, nSpoints);
            for i = 1:nSpoints
                changedFullState = obj.states;
                changedFullState(:, obj.presentStep + 1) = sp(:, i);
                
                % Set before-state-limitations
                xv = changedFullState;
                handleDyn = @(xx) obj.block.dynamics(xx,                  ...
                                                     obj.inputs,          ...
                                                     obj.presentStep + 1, ...
                                                     obj.sampleTime)';
                if obj.block.time == 'c'
                    Xp(:,i) = xm + obj.sampleTime*handleDyn(xv);
                else
                    Xp(:,i) = handleDyn(xv);
                end
                
                xp = xp + obj.wm(i)*Xp(:, i); % Prediction update
            end
            dPp = Xp - xp(:, ones(1, nSpoints));
            Pp = dPp*diag(obj.wc)*dPp' + L*obj.qMatrix*L';  % Updating the covariance of states matrix
            
            %% Updating sigma points, STEP 4
            %dSigma = sqrt(obj.nUKF + obj.lambda)*chol(Pp)';  % Calculating sqrt
            %xmCopy = xp(:, ones(1, numel(xp)));              % Putting 'xp' is some column (copy)
            %sp     = [xp, xmCopy + dSigma, xmCopy - dSigma]; % Updating sigma points
            
            if ~isnan(y)
                %% Solving output estimation using predicted data, STEP 5
                %  This part tries to obtain a prediction output from sigma points
                zb = zeros(obj.numOutputs, 1);
                Zb = zeros(obj.numOutputs, nSpoints);
                for i = 1:nSpoints
                    changedFullState = obj.states;
                    changedFullState(:, obj.presentStep + 1) = Xp(:, i); % Or 'Xp(:, i)' instead of 'sp(:, i)'
                    Zb(:,i) = obj.block.external(changedFullState,      ...
                                                 obj.inputs,            ...
                                                 obj.presentStep + 1,   ...
                                                 obj.sampleTime)';
                    zb = zb + obj.wm(i)*Zb(:, i); % Predicted output
                end
                dSt = Zb - zb(:, ones(1, nSpoints));
                St = dSt*diag(obj.wc)*dSt' + M*obj.rMatrix*M'; % Updating the covariance of output matrix

                %% Solving Kalman gain, STEP 6
                SiG = dPp*diag(obj.wc)*dSt';
                K = SiG*(St^-1); % Kalman Gain
            end
            
            %% Solving posterior using measurement data, STEP 7
            %  If there is not any measurement (y == NaN), posterior won't
            %  calculate and just prediction will be reported.
            if ~isnan(y)
                xm = xp + K*(y - zb); % Update the states
                Pm = Pp - K*SiG'; % Update covariance matrix
            else
                xm = xp;
                Pm = Pp;
            end
            
            %% Update internal signals
            obj.states(:, obj.presentStep + 2) = xm; % To save estimated states
            obj.covariance = Pm; % To save covariance matrix
        end

    %% Next step of nonlinear model predictive control
        function obj = nextstepNMPC(obj, consts)
            if obj.presentStep + obj.numPrediction < obj.numSteps
                horizonInd = (obj.presentStep + 1):(obj.presentStep + obj.numPrediction - 1);
            else
                horizonInd = (obj.presentStep + 1):(obj.numSteps - 1);
                horizonInd = [horizonInd, repmat(obj.numSteps - 1, 1, obj.numPrediction - numel(horizonInd) - 1)];
            end
            
            LB = consts.uMin(:, horizonInd);
            UB = consts.uMax(:, horizonInd);
            constriants = @(U) obj.block.constriants(U, consts, obj.presentStep + 1, obj.numSteps);
            
            % Optimization part
            options = optimset('MaxIter' , 100 , 'Algorithm' , 'sqp', 'Display', 'off'); %  'Display', 'off'
            [obj.Uopt , fval] = fmincon(@(U)obj.costFunction(U, consts.ref), ...  % Cost function
                                        obj.Uopt(:),  ...  % First poist of U
                                        obj.constA,   ...  % A*x < B
                                        obj.constB,   ...  % A*x < B
                                        obj.constAeq, ...  % Aeq*x = Beq
                                        obj.constBeq, ...  % Aeq*x = Beq
                                        LB(:),        ...  % 
                                        UB(:),        ...  %
                                        constriants,  ...  %
                                        options);
            % Save optimized data
            obj.fValue(obj.presentStep + 1) = fval;
            obj.controlInputs(:, obj.presentStep + 1) = obj.Uopt(1:obj.numInputs);
            
        end
    
    %% Cost function of NMPC
        function J = costFunction(obj, U, refers)
            U = reshape(U, obj.numInputs, obj.numPrediction - 1);
            X = zeros(obj.numStates , obj.numPrediction); % Imagine prediction states
            X(: , 1) = obj.states(:, obj.presentStep + 2); % Current states
            imaginState = obj.states; % Imagine last state
            imaginInput = obj.inputs; % Imagine inputs
            J = 0; % Cost value
            dU = U - [obj.inputs(:, obj.presentStep + 1), U(:,1:(end-1))];
            
            for i = 2:obj.numPrediction % Prediction loop
                % Setting inputs into imagine control signal
                imaginInput(:, obj.presentStep + i - 1) = U(:, i - 1);
                
                % use dynamic of model to calculate states
                if obj.block.time == 'c'
                    X(:, i) = X(:, i-1) + obj.sampleTime*obj.block.dynamics(imaginState(:, 2:end),   ...
                                                                            imaginInput,             ...
                                                                            obj.presentStep + i - 1, ...
                                                                            obj.sampleTime)';
                else
                    X(:, i) = obj.block.dynamics(obj.states, obj.inputs, obj.presentStep + i - 1, obj.sampleTime)';
                end
                
                % Update Imagine variables of states
                imaginState(:, obj.presentStep + 1 + i) = X(:, i);
                
                % Update cost cvalue - Intergal terms
                if obj.presentStep + i - 1 < obj.numSteps
                    clearRef = refers(:, obj.presentStep + i - 1);
                else
                    clearRef = refers(:, end);
                end
                ERROR = clearRef - X(:, i);
                J = J + (ERROR'*obj.Qx*ERROR + U(:, i - 1)'*obj.Qu*U(:, i - 1) + dU(:, i - 1)'*obj.Qdu*dU(:, i - 1));
            end
            
            % Calculate cost value - final value cost
            J = J + X(:, i)'*obj.Qf*X(:, i);
        end
    
    %% Other useful functions
        function obj = goAhead(obj, i)
            obj.presentStep = obj.presentStep + i;
        end
        
        % Reset Block
        function obj = goFirst(obj)
            obj.presentStep = 0;
        end
        
    %% Plots function
        function show(obj, sel)
            switch sel
                case 'x'
                    signal = obj.states(:, 1:end-1);
                    h1 = 'states';
                case 'u'
                    signal = obj.inputs;
                    h1 = 'inputs';
                case 'y'
                    signal = obj.outputs;
                    h1 = 'outputs';
                case 'c'
                    signal = obj.controlInputs;
                    h1 = 'control signal';
            end
            figure();
            plot(obj.timeLine, signal');
            xlabel('time');
            ylabel(h1);
            grid on;
            xlim([obj.timeLine(1), obj.timeLine(end)]);
        end
    end
end

