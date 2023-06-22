function models = simulationModels(params, models, func)
    
    %% Initial setting
    func.sayStart();
    ControlSignal = [0, 0, 0];
    
    %% Simulation main loop
    for t = 1:params.n
        % Displaing the iteration number in the command window
        func.disit(t, params.n, 10);
        if rem(t,10) == 0
            plotResults(params, models, [], 'iter');
        end
        
        % Creating control signal
        models.inputCovid(:,t) = ControlSignal;
        
        % Updating Plant
        models.covid = models.covid.nextstep(models.inputCovid(:,t));
        
        % Measurement
        models.measurement(:,t) = models.covid.outputs(:,t) + models.measurementNoise(:,t);
        models.measurement(:,t) = models.measurement(:,t).*double(models.measurement(:,t) > 0);
        
        % Updating EKF-UKF
        models.extkf = models.extkf.nextstepEKF(models.inputCovid(:,t), models.measurement(:,t));
        
        % NMPC
        models.extkf = models.extkf.nextstepNMPC(models.const);
        
        % Going to the next step EKFNMPC
        models.extkf = models.extkf.goAhead(1);
        
        if params.filterCntrlorNot == 1
            models.controlFilter = models.controlFilter.nextstep(models.extkf.controlInputs(:, t));
            ControlSignal = models.controlFilter.outputs(:, t);
        else
            ControlSignal = models.extkf.controlInputs(:, t);
        end
        
    end
    
    func.sayEnd();
end
