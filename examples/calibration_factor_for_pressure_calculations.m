%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Cálculo do fator de correção utilizando três métodos
%   TODO: melhorar essa descrição
%
%   Felipe Ramos de Mello - 22/03/2023
%   felipe.mello@eac.ufsm.br
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cleaning service

clc; close all; clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test signal

fs = 48000;

intendedRMS = 0.4; % in Pa peak
amp = intendedRMS .* sqrt(2); % in Pa RMS

nSamples = 2^18; % Not an exact cycle
freq = 1000;

phase = 0; % arbitrary phase shift
timeVector = (0:nSamples-1)'./fs;
noise = (amp./5) .* randn(size(timeVector));
testSignal = amp .* sin(2*pi*freq*timeVector + phase) + noise;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calibration Factor via RMS in time domain

fc_timeDomain = 1 ./ rms(testSignal);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calibration Factor via RMS in frequency domain with FFT

% First step is to guarantee that we have a test signal with full cycles
nCycles = 100;
nSamplesFullCycle = (1/freq)*fs*nCycles; % Number of samples to retrieve nCycles

% Apply the fft to the chopped signal
testSpectrum = fft(testSignal(1:nSamplesFullCycle));
testSpectrum = testSpectrum(1:nSamplesFullCycle/2+1) / nSamplesFullCycle;
testSpectrum(2:end) = sqrt(2).*testSpectrum(2:end);

% Frequency vector and visualization
freqVector = (0:length(testSpectrum)-1) * (fs/nSamplesFullCycle);
semilogx(freqVector, abs(testSpectrum));

% Calibration Factor (should be equal to time domain)
fc_freqDomain = 1 / max(abs(testSpectrum));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calibration Factor via Goertzel Algorithm (freq domain)