close all; clear; clc;

%% // --------------------------------------------------------------
%    Creator:    Abolfazl Delavar - Reza Rahimi
%    Email:        abolfazldelavar@outlook.com
%    Field:        Control Engineering
%    Project:    Covid-19-IEEE-Paper
% \\ --------------------------------------------------------------

%% Set parameters
params = setParameters();

%% Run functions
func = functionLibrary();

%% Make models
models = modelMaker(params, func);

%% Simulation file
models = simulationModels(params, models, func);

%% Plot results
plotResults(params, models, func, 'iter');
plotResults(params, models, func, 'final');

% Last edit date: 11/17/2021
