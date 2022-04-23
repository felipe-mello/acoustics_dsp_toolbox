%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates calibrated equivalent continuous SPL and 
% time-weighted SPL with frequency weightings A, C, Z or K
%
% Inputs: 
%   - audioSignal (required): acoustic signal for the calculations
%   - samplingRate (required): according to your audio signal
%   - frequencyWeighting (optional): default is 'Z-weighting' (A, C, Z or K are valid options)
%   - timeWeighting (optional): default is 'Fast' ('Fast' or 'Slow' are valid options)
%   - timeInterval (optional): time period in seconds for the rms calculation. Default is 1 second
%   - calibrationFactor (optional): a must for a calibrated calculation.
%   Default is 1.
%
% Outputs:
%   - Leq_accum: accumulated Leq over the entire audio signal;
%   - Leq: Leq evaluated over timeInterval periods;
%   - Lp: time-weighted SPL over the timeInterval period;
%   - Lpmax: maximum Lp for each period.
%   - Lpeak: peak SPL for each period.
%   - timeVector
%
% Felipe Ramos de Mello - 19/04/22
%%

function [Leq_accum, Leq, Lp, Lpmax, Lpeak, timeVector] = splCalculator(signal, fs, varargin)

%% Input parsing

p = inputParser;

default_freqW = 'Z-weighting';
default_timeW = 'Fast';
default_calibrationFactor = 1.0;
default_timeInterval = 1.0;

expectedFreqW = {'A-weighting', 'C-weighting', 'K-weighting', 'Z-weighting'};
expectedTimeW = {'Fast', 'Slow'};

addRequired(p, 'signal', @isnumeric);
addRequired(p, 'fs', @(x) mustBePositive(x));
addParameter(p, 'frequencyWeighting', default_freqW, @(x) any(validatestring(x, expectedFreqW)));
addParameter(p, 'timeInterval', default_timeInterval, @(x) mustBePositive(x));
addParameter(p, 'calibrationFactor', default_calibrationFactor, @isnumeric);
addParameter(p, 'timeWeighting', default_timeW, @(x) any(validatestring(x, expectedTimeW)));

parse(p, signal, fs, varargin{:});

signal = p.Results.signal;
fs = p.Results.fs;
frequencyWeighting = p.Results.frequencyWeighting;
timeWeighting = p.Results.timeWeighting;
timeInterval = p.Results.timeInterval;
calibrationFactor = p.Results.calibrationFactor;

%% Function

switch frequencyWeighting
    case 'A-weighting'
        wFilter = weightingFilter(frequencyWeighting, fs);
        signal = applyWeighting(signal, wFilter);
    case 'C-weighting'
        wFilter = weightingFilter(frequencyWeighting, fs);
        signal = applyWeighting(signal, wFilter);
    case 'K-weighting'
        wFilter = weightingFilter(frequencyWeighting, fs);
        signal = applyWeighting(signal, wFilter);
end

tFilter = timeWeightingFilterGenerator(timeWeighting, fs);

nSamples = length(signal);
samplesPerBlock = timeInterval*fs;
nBlocks = floor(nSamples/samplesPerBlock);
p_ref = 2e-5;

Lp = zeros(nBlocks, 1);
Leq = zeros(nBlocks, 1);
Leq_accum = zeros(nBlocks, 1);
Leq_accum_temp = 0;
Lpmax = zeros(nBlocks, 1);
Lpeak = zeros(nBlocks, 1);
Lpmax(1) = -inf;
Lpeak(1) = -inf;

firstCounter = 1;
lastCounter = samplesPerBlock;

h = waitbar(0, 'Calculating the SPL in fractional octave bands...');

for num = 1:nBlocks
    
    slice = signal(firstCounter:lastCounter, :)*calibrationFactor;
    
    Lpeak(num) = max(max(slice), max(Lpeak));
    Lp_temp = tFilter(slice.^2);
    Lpmax(num) = max(max(Lp_temp), max(Lpmax));
    Lp(num) = Lp_temp(end);
    Leq(num) = rms(slice);
    Leq_accum_temp = (sum(slice.^2) + Leq_accum_temp);
    Leq_accum(num, 1) = Leq_accum_temp/lastCounter;
    
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + samplesPerBlock;
    
    waitbar(num/nBlocks, h, 'Calculating the SPL in fractional octave bands...');
end

close(h); release(tFilter);

timeVector = (1:nBlocks)*timeInterval;

Leq = 20*log10(Leq/p_ref);
Leq_accum = 10*log10(Leq_accum/p_ref.^2);
Lp = 10*log10(Lp/p_ref.^2);
Lpmax = 10*log10(Lpmax/p_ref.^2);
Lpeak = 20*log10(Lpeak/p_ref);

end

%% Support functions

function signal = applyWeighting(signal, wFilter)

blockSize = 2048;
firstCounter = 1;
lastCounter = blockSize;

h = waitbar(0, 'Applying weighting filter...');

while lastCounter <= length(signal)
    signal(firstCounter:lastCounter, :) = wFilter(signal(firstCounter:lastCounter, :));
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + blockSize;
    waitbar(firstCounter/length(signal), h, 'Applying weighting filter...');
end

if firstCounter < length(signal)
    signal(firstCounter:end, :) = wFilter(signal(firstCounter:lastCounter, :));
    waitbar(firstCounter/length(signal), h, 'Applying weighting filter...');
end

close(h);
release(wFilter);

end