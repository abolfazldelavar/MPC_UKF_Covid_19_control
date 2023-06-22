classdef functionLibrary
    methods (Static)
    %% Default functions - Neccessary and Essential
        function disit(t, n, remi)
            txt = repmat(' ', 1, 30);
            if rem(t, remi) == 0
                t = num2str(t);
                n = num2str(n);
                txt(3 + (1:numel(t))) = t;
                txt(12:14) = '~~>';
                txt(19 + (1:numel(n))) = n;
                disp(txt);
            end
        end
        function sayStart()
            disp('Problem Started!');
            tic;
        end
        function sayEnd()
            disp(['Simulation completed. (', num2str(toc), ' second)']);
        end
        % Delayed in a signal
        function y    = delayed(u, t, pdelay)
            % (import your signal, import current sample time, how many delay do you want?)
            if t - pdelay > 0
                y = u(t - pdelay);
            else
                y = 0.*u(t);
            end
        end
        % Signal Generator
        function output = signalMaker(params, Tline)
            % SETUP -------------------------------------------------------------------------
            % 1) Insert bellow code in 'setParameters.m' to use signal generator:
            %        %% Signal Generator parameters
            %        params.referAddType    = 'onoff';        % 'none', 'square', 'sin', 'onoff', ...                        
            %        params.referAddAmp    = 30;            % Amplitude of additive signal
            %        params.referAddFreq    = 2;            % Signal period at simulation time
            %
            % 2) Use the bellow code to call signal generation in 'modelMaker.m':
            %        signal = func.signalMaker(params, models.Tline);
            % -------------------------------------------------------------------------------
            
            Tline = Tline(1:params.n);
            switch params.referAddType
                case 'none'
                    output    = 0.*Tline;
                case 'square'
                    freq    = params.referAddFreq/params.Tout;
                    output    = square(2*pi*freq*Tline) * params.referAddAmp;
                case 'onoff'
                    freq    = params.referAddFreq/params.Tout;
                    output    = (2 - square(2*pi*freq*Tline) - 1)/2 * params.referAddAmp;
                case 'sin'
                    freq    = params.referAddFreq/params.Tout;
                    output    = sin(2*pi*freq*Tline) * params.referAddAmp;
            end
        end
        % Saturation signal in band [band(1), band(2)]
        function y = satutation(u, band)
            if u > band(2)
                y = band(2);
            elseif u < band(1)
                y = band(1);
            else
                y = u;
            end
        end
        % Mapping a number
        function output = lineMapping(x, from, to)
            % Mapp 'x' from band [w1, v1] to band [w2, v2]
            w1 = from(1);
            v1 = from(2);
            w2 = to(1);
            v2 = to(2);
            output = 2*((x - w1)/(v1 - w1)) - 1;
            output = (output + 1)*(v2 - w2)/2 + w2;
        end
        function output = expinverse(Tline, bias, alph, are)
            output = 1./(1 + exp(-alph*(Tline - bias)));
            output = (are(2) - are(1))*output + are(1);
        end
    %% your functions
        function output = exponen(Tline, para)
            Ss = para(1);        % Start point
            Sf = para(2);        % Final value
            Sr = para(3);        % Rate of unction
            output = (Ss - Sf)*exp(-Sr.*Tline) + Sf;            
        end
        
        % maximum accessable value of input signals
        function output = uMax(func, Tline, typ)
            switch typ
                case 'd'    % Social distancing
                    output = func.expinverse(Tline, 250*24*60*60, 2e-7, [1, 0.8]);
                case 'h'    % Hospitalization
                    output = func.expinverse(Tline, 100*24*60*60, 6e-7, [0.7, 1]);
                case 'v'    % Vaccination
                    output = func.expinverse(Tline, 250*24*60*60, 4e-7, [0, 1]);
            end
        end
        
        % Cost rate of input signals
        function output = uCost(func, Tline, typ)
            switch typ
                case 'd'    % Social distancing
                    output = func.expinverse(Tline, 500*24*60*60, 1e-7, [1, 1])*4;
                case 'h'    % Hospitalization
                    output = func.expinverse(Tline, 500*24*60*60, 1e-7, [1, 1])*1;
                case 'v'    % Vaccination
                    output = func.expinverse(Tline, 500*24*60*60, 1e-7, [1, 1])*1;
            end
        end
        
        % Total allocated price
        function output = allocatedPrice(func, Tline)
            output = func.expinverse(Tline, 500*24*60*60, 1e-7, [1, 1])*5;
        end
    end
end

