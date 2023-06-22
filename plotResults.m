function plotResults(params, models, ~, mode)
    %% Initial setting and variable definition
    n = params.n;    
    Tline = models.Tline(1:n);
    changeToDay = 1/(24*60*60);
    Tline = Tline*changeToDay; % Change second to day
            
    switch mode
        case 'iter'
        %% Iteration plots
            figure(1);    % controled states
                set(gcf, 'Position', [50, 50, 1000, 350]);
                subplot(311);
                    plot(Tline, models.const.ref(2,1:n)', 'k--'); hold on;
                    plot(Tline, models.covid.states(2,1:n)', 'color', [0 0.4470 0.7410]); hold off;
                    ylabel('E');
                    grid on;
                    xlim([0, Tline(end)]);
                subplot(312);
                    plot(Tline, models.const.ref(3,1:n)', 'k--'); hold on;
                    plot(Tline, models.covid.states(3,1:n)', 'color', [0 0.4470 0.7410]); hold off;
                    ylabel('I');
                    grid on;
                    xlim([0, Tline(end)]);
                subplot(313);
                    plot(Tline, models.const.ref(7,1:n)', 'k--'); hold on;
                    plot(Tline, models.covid.states(7,1:n)', 'color', [0 0.4470 0.7410]); hold off;
                    ylabel('D');
                    grid on;
                    xlabel('Time (days)');
                    xlim([0, Tline(end)]);

            figure(2);    % Input states
                set(gcf, 'Position', [50 , 50 + 350, 1000, 350]);
                subplot(311);
                    plot(Tline, models.const.uMax(1,1:n)', 'k--'); hold on;
                    plot(Tline, models.extkf.controlInputs(1,1:n)', 'color', [0 0.4470 0.7410]); 
                    if params.filterCntrlorNot; plot(Tline, models.controlFilter.outputs(1, 1:n)', 'r'); end
                    hold off;
                    ylim([-0.1, 1.1]);
                    xlim([0, Tline(end)]);
                    ylabel('social distancing');
                    grid on;
                subplot(312);
                    plot(Tline, models.const.uMax(2,1:n)', 'k--'); hold on;
                    plot(Tline, models.extkf.controlInputs(2,1:n)', 'color', [0 0.4470 0.7410]);
                    if params.filterCntrlorNot; plot(Tline, models.controlFilter.outputs(2, 1:n)', 'r'); end
                    hold off;
                    ylim([-0.1, 1.1]);
                    xlim([0, Tline(end)]);
                    ylabel('Hospitalization');
                    grid on;
                subplot(313);
                    plot(Tline, models.const.uMax(3,1:n)', 'k--'); hold on;
                    plot(Tline, models.extkf.controlInputs(3,1:n)', 'color', [0 0.4470 0.7410]);
                    if params.filterCntrlorNot; plot(Tline, models.controlFilter.outputs(3, 1:n)', 'r'); end
                    hold off;
                    ylim([-0.1, 1.1]);
                    xlim([0, Tline(end)]);
                    ylabel('Vaccination');
                    xlabel('Time (days)');
                    grid on;
            pause(0.0001);
        
        case 'final'
        %% Final plot
            ssi(1);
            subplot(421);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(1, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(1, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('S'); grid on;
                xlim([0, Tline(end)]);
            subplot(422);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(2, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(2, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('E'); grid on;
                xlim([0, Tline(end)]);
            subplot(423);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(3, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(3, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('I'); grid on;
                xlim([0, Tline(end)]);
            subplot(424);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(4, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(4, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('Q'); grid on;
                xlim([0, Tline(end)]);
            subplot(425);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(5, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(5, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('H'); grid on;
                xlim([0, Tline(end)]);
            subplot(426);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(6, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(6, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('R'); grid on;
                xlim([0, Tline(end)]);
            subplot(427);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(7, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(7, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('D'); grid on;
                xlim([0, Tline(end)]);
                xlabel('Time (s)');
            subplot(428);
                %yyaxis right;
                hold on;
                plot(Tline, models.covid.states(8, 1:end-2), 'k--');
                plot(Tline, models.extkf.states(8, 1:end-2), 'color', [0 0.4470 0.7410]);
                ylabel('P'); grid on;
                xlim([0, Tline(end)]);
                xlabel('Time (s)');
    end
    
end

function ssi(mode)    % Open a window with srbitrary size and location on screen
    if nargin < 1; mode = 0; end
    switch mode
        case 1
            figure();
            set(gcf, 'Position', [100, 100, 800, 650]);
        case 2
            figure();
            set(gcf, 'Position', [100, 100, 800, 500]);
        case 3
            figure();
            set(gcf, 'Position', [100, 100, 800, 350]);
        case 4
            figure();
            set(gcf, 'Position', [100, 100, 800, 250]);
        otherwise
            figure();
            set(gcf, 'Position', [0, 0, 3000, 3000]);
    end
end