close all;
clear;
clc;

fname = {{'data/scenario1def.mat',     ...
         'data/scenario1filter.mat'},  ...
         {'data/scenario2def.mat',     ...
         'data/scenario2filter.mat'}};

for sc = 1:2
    de = load(fname{sc}{1});
    fi = load(fname{sc}{2});

    n = de.params.n;    
    Tline = de.models.Tline(1:n);
    changeToDay = 1/(24*60*60);
    Tline = Tline*changeToDay; % Change second to day

    %% Iteration plots
    ssi(1);
        subplot(311);
            plot(Tline, de.models.const.ref(2,1:n)', 'k'); hold on;
            plot(Tline, de.models.covid.states(2,1:n)', 'color', [0 0.4470 0.7410]);
            plot(Tline, fi.models.covid.states(2,1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylabel('Exposed');
            grid on;
            xlim([0, Tline(end)]);
            lgd = legend('Desired signal','NMPC','NMPC - Filtered');
            title(lgd,['Scenario ', num2str(sc)]);
        subplot(312);
            plot(Tline, de.models.const.ref(3,1:n)', 'k'); hold on;
            plot(Tline, de.models.covid.states(3,1:n)', 'color', [0 0.4470 0.7410]);
            plot(Tline, fi.models.covid.states(3,1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylabel('Infected');
            grid on;
            xlim([0, Tline(end)]);
        subplot(313);
            plot(Tline, de.models.const.ref(7,1:n)', 'k'); hold on;
            plot(Tline, de.models.covid.states(7,1:n)', 'color', [0 0.4470 0.7410]);
            plot(Tline, fi.models.covid.states(7,1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylabel('Deceased');
            grid on;
            xlabel('Time (days)');
            xlim([0, Tline(end)]);

    ssi(1);
        subplot(311);
            plot(Tline, de.models.const.uMax(1,1:n)', 'k'); hold on;
            plot(Tline, de.models.extkf.controlInputs(1,1:n)', 'color', [0 0.4470 0.7410]); 
            plot(Tline, fi.models.controlFilter.outputs(1, 1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylim([-0.1, 1.1]);
            xlim([0, Tline(end)]);
            ylabel('social distancing');
            grid on;
        subplot(312);
            plot(Tline, de.models.const.uMax(2,1:n)', 'k'); hold on;
            plot(Tline, de.models.extkf.controlInputs(2,1:n)', 'color', [0 0.4470 0.7410]);
            plot(Tline, fi.models.controlFilter.outputs(2, 1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylim([-0.1, 1.1]);
            xlim([0, Tline(end)]);
            ylabel('Hospitalization');
            grid on;
            lgd = legend('Maximum allowable','NMPC','NMPC - Filtered');
            title(lgd,['Scenario ', num2str(sc)]);
        subplot(313);
            plot(Tline, de.models.const.uMax(3,1:n)', 'k'); hold on;
            plot(Tline, de.models.extkf.controlInputs(3,1:n)', 'color', [0 0.4470 0.7410]);
            plot(Tline, fi.models.controlFilter.outputs(3, 1:n)', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
            ylim([-0.1, 1.1]);
            xlim([0, Tline(end)]);
            ylabel('Vaccination');
            xlabel('Time (days)');
            grid on;

    figure(100);
    set(gcf, 'Position', [100, 100, 900, 700]);
    subplot(421);
        hold on;
%         plot(Tline, de.models.covid.states(1, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(1, 1:end-2), 'k--');
        plot(Tline, de.models.extkf.states(1, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(1, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Susceptible');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(422);
        hold on;
%         plot(Tline, de.models.covid.states(2, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(2, 1:end-2), 'k--');
        plot(Tline, de.models.const.ref(2,1:n)', 'k'); hold on;
        plot(Tline, de.models.extkf.states(2, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(2, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Exposed');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(423);
        hold on;
%         plot(Tline, de.models.covid.states(3, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(3, 1:end-2), 'k--');
        plot(Tline, de.models.const.ref(3,1:n)', 'k'); hold on;
        plot(Tline, de.models.extkf.states(3, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(3, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Infected');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(424);
        hold on;
%         plot(Tline, de.models.covid.states(4, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(4, 1:end-2), 'k--');
        plot(Tline, de.models.extkf.states(4, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(4, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Quarantined');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(425);
        %yyaxis right;
        hold on;
%         plot(Tline, de.models.covid.states(5, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(5, 1:end-2), 'k--');
        plot(Tline, de.models.extkf.states(5, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(5, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Hospitalized');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(426);
        hold on;
%         plot(Tline, de.models.covid.states(6, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(6, 1:end-2), 'k--');
        plot(Tline, de.models.extkf.states(6, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(6, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Recovered');
%         grid on;
        xlim([0, Tline(end)]);
    subplot(427);
        hold on;
%         plot(Tline, de.models.covid.states(7, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(7, 1:end-2), 'k--');
        plot(Tline, de.models.const.ref(7,1:n)', 'k'); hold on;
        plot(Tline, de.models.extkf.states(7, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(7, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Deceased');
%         grid on;
        xlim([0, Tline(end)]);
        xlabel('Time (days)');
    subplot(428);
        hold on;
%         plot(Tline, de.models.covid.states(8, 1:end-2), 'k--');
%         plot(Tline, fi.models.covid.states(8, 1:end-2), 'k--');
        plot(Tline, de.models.extkf.states(8, 1:end-2), 'color', [0 0.4470 0.7410]);
        plot(Tline, fi.models.extkf.states(8, 1:end-2), 'color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        ylabel('Unsusceptible');
%         grid on;
        xlim([0, Tline(end)]);
        xlabel('Time (days)');
        
    figure(101);
    set(gcf, 'Position', [100, 100, 900, 700]);
    subplot(421);
        hold on;
        plot(Tline, de.models.extkf.states(1, 1:end-2) - de.models.covid.states(1, 1:end-2));
        plot(Tline, fi.models.extkf.states(1, 1:end-2) - fi.models.covid.states(1, 1:end-2));
        ylabel('Susceptible');
        xlim([0, Tline(end)]);
    subplot(422);
        hold on;
        plot(Tline, de.models.extkf.states(2, 1:end-2) - de.models.covid.states(2, 1:end-2));
        plot(Tline, fi.models.extkf.states(2, 1:end-2) - fi.models.covid.states(2, 1:end-2));
        ylabel('Exposed');
        xlim([0, Tline(end)]);
    subplot(423);
        hold on;
        plot(Tline, de.models.extkf.states(3, 1:end-2) - de.models.covid.states(3, 1:end-2));
        plot(Tline, fi.models.extkf.states(3, 1:end-2) - fi.models.covid.states(3, 1:end-2));
        ylabel('Infected');
        xlim([0, Tline(end)]);
    subplot(424);
        hold on;
        plot(Tline, de.models.extkf.states(4, 1:end-2) - de.models.covid.states(4, 1:end-2));
        plot(Tline, fi.models.extkf.states(4, 1:end-2) - fi.models.covid.states(4, 1:end-2));
        ylabel('Quarantined');
        xlim([0, Tline(end)]);
    subplot(425);
        hold on;
        plot(Tline, de.models.extkf.states(5, 1:end-2) - de.models.covid.states(5, 1:end-2));
        plot(Tline, fi.models.extkf.states(5, 1:end-2) - fi.models.covid.states(5, 1:end-2));
        ylabel('Hospitalized');
        xlim([0, Tline(end)]);
    subplot(426);
        hold on;
        plot(Tline, de.models.extkf.states(6, 1:end-2) - de.models.covid.states(6, 1:end-2));
        plot(Tline, fi.models.extkf.states(6, 1:end-2) - fi.models.covid.states(6, 1:end-2));
        ylabel('Recovered');
        xlim([0, Tline(end)]);
    subplot(427);
        hold on;
        plot(Tline, de.models.extkf.states(7, 1:end-2) - de.models.covid.states(7, 1:end-2));
        plot(Tline, fi.models.extkf.states(7, 1:end-2) - fi.models.covid.states(7, 1:end-2));
        ylabel('Deceased');
        xlim([0, Tline(end)]);
        xlabel('Time (days)');
    subplot(428);
        hold on;
        plot(Tline, de.models.extkf.states(8, 1:end-2) - de.models.covid.states(8, 1:end-2));
        plot(Tline, fi.models.extkf.states(8, 1:end-2) - fi.models.covid.states(8, 1:end-2));
        ylabel('Unsusceptible');
        xlim([0, Tline(end)]);
        xlabel('Time (days)');
end



function ssi(mode)    % Open a window with srbitrary size and location on screen
    if nargin < 1; mode = 0; end
    switch mode
        case 1
            figure();
            set(gcf, 'Position', [100, 100, 550, 550]);
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