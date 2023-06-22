classdef linearSystem
    
    properties
        inputSystem
        block
        blockSampleTime
        delay
        numSteps
        numStates
        numOutputs
        numInputs
        A
        B
        C
        D
        states
        inputs
        outputs
        timeLine
        sampleTime
        presentStep
    end
    
    methods
        function obj = linearSystem(inputsystem, sampletime, timeline, initialcondition)
            obj.inputSystem = inputsystem;
            if inputsystem.Ts == sampletime && isStateSpace(inputsystem)
                %input is a discrete-time state-space with same sample time
                obj.block = inputsystem;
            elseif inputsystem.Ts == sampletime && ~isStateSpace(inputsystem)
                %input is a discrete-time transfer fuction with same sample time
                obj.block = minreal(ss(inputsystem));
            elseif isStateSpace(inputsystem)
                if inputsystem.Ts ~= 0
                    %input is a discrete-time state-space with different sample time
                    obj.block = d2d(inputsystem, sampletime);
                else
                    %input is a continuous-time state-space
                    obj.block = c2d(inputsystem, sampletime);
                end
            elseif inputsystem.Ts ~= 0
                %input is a discrete-time transfer fuction with different sample time
                obj.block = d2d(minreal(ss(inputsystem)), sampletime);
            else
                %input is a continuous-time transfer fuction
                obj.block = c2d(minreal(ss(inputsystem)), sampletime);
            end
            
            obj.delay = obj.block.InputDelay;
            obj.timeLine = timeline(:)';
            obj.sampleTime = sampletime;
            obj.blockSampleTime = inputsystem.Ts;
            obj.numSteps = numel(obj.timeLine);
            obj.A = obj.block.A;
            obj.B = obj.block.B;
            obj.C = obj.block.C;
            obj.D = obj.block.D;
            obj.numStates = size(obj.block.A, 1);
            obj.numInputs = size(obj.block.B, 2);
            obj.numOutputs = size(obj.block.C, 1);
            obj.inputs = zeros(obj.numInputs , obj.numSteps);
            obj.outputs = zeros(obj.numOutputs, obj.numSteps);
            obj.presentStep = 0;
            
            if nargin<4
                obj.states = zeros(obj.numStates, obj.numSteps + 1);
            else
                initialcondition = initialcondition(:);
                obj.states = [initialcondition ,zeros(obj.numStates, obj.numSteps)];
            end
        end
        
        function obj = nextstep(obj, u)
            
            x = zeros(obj.numStates , 1);
            y = zeros(obj.numOutputs, 1);
            u = u(:);
            obj.inputs(:, obj.presentStep + 1) = u;
            
            if obj.presentStep - obj.delay >= 0
                delayedInput = obj.inputs(:, obj.presentStep - obj.delay + 1);
            else
                delayedInput = 0.*u;
            end
            
            for i = 1:obj.numStates
                for j = 1:obj.numStates
                    x(i) = x(i) + obj.A(i,j)*obj.states(j, obj.presentStep + 1);
                end
                for j = 1:obj.numInputs
                    x(i) = x(i) + obj.B(i,j)*delayedInput(j);
                end
            end
            
            for i = 1:obj.numOutputs
                for j = 1:obj.numStates
                    y(i) = y(i) + obj.C(i,j)*obj.states(j, obj.presentStep + 1);
                end
                for j = 1:obj.numInputs
                    y(i) = y(i) + obj.D(i,j)*delayedInput(j);
                end
            end
            obj.states(:, obj.presentStep + 2) = x;
            obj.outputs(:, obj.presentStep + 1) = y;
            obj.presentStep = obj.presentStep + 1;
        end
        
        function obj = goAhead(obj, i)
            obj.presentStep = obj.presentStep + i;
        end
        
        % Reset block
        function obj = goFirst(obj)
            obj.presentStep = 0;
        end
        
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

