close all; clear; clc;

%% // --------------------------------------------------------------
%    Creator:  Abolfazl Delavar - Reza Rahimi
%    Email:    abolfazldelavar@outlook.com
%    Field:    Control Engineering
%    Project:  Covid-19-IEEE-Paper
% \\ --------------------------------------------------------------

%% Configuration
params = setParameters();

%% Running functions
func = functionLibrary();

%% Making models
models = modelMaker(params, func);

%% Simulation file
models = simulationModels(params, models, func);

%% Plotting results
plotResults(params, models, func, 'iter');
plotResults(params, models, func, 'final');
