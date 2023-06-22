classdef nonlinearSystem
    
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
    end
    
    methods
        function obj = nonlinearSystem(inputsystem, sampletime, timeline, initialcondition)
            % system, sample time, number of simulation steps, first state
            obj.block = inputsystem;
            obj.sampleTime = sampletime;
            obj.timeLine = timeline(:)';
            obj.numSteps = numel(obj.timeLine);
            obj.numStates = obj.block.numStates;
            obj.numInputs = obj.block.numInputs;
            obj.numOutputs = obj.block.numOutputs;
            obj.inputs = zeros(obj.numInputs, obj.numSteps);
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
            u = u(:);
            obj.inputs(:, obj.presentStep + 1)  = u;
            % use dynamic of system to calculate states and output
            xo = obj.states(:, obj.presentStep + 1);
            if obj.block.time == 'c'
                x = xo + obj.sampleTime*obj.block.dynamics(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime)';
            else
                x = obj.block.dynamics(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime)';
            end
            y = obj.block.external(obj.states, obj.inputs, obj.presentStep + 1, obj.sampleTime)';
            % Update internal signals
            obj.states(:, obj.presentStep + 2) = x;
            obj.outputs(:, obj.presentStep + 1) = y;
            obj.presentStep = obj.presentStep + 1;
        end
        
        function obj = goAhead(obj, i)
            obj.presentStep = obj.presentStep + i;
        end
        
        % Reset Block
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

