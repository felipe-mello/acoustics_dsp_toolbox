%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates calibrated equivalent continuous SPL in 
% fractional octave bands, considering a defined time interval.
%
% Inputs: 
%   - audioSignal (required): acoustic signal for the calculations
%   - samplingRate (required): according to your audio signal
%   - bandwidth (optional): e.g. '1 Octave', '1/3 Octave' (see octaveFilterBankGenerator) 
%   - frequencyWeighting (optional): default is 'Z-weighting' (A, C, Z or K are valid options)
%   - freqRange (optional): default is [15, 21e3];
%   - timeInterval (optional): time period in seconds for the rms calculation. Default is 1 second
%   - base (optional): default is 10 (options are 2 or 10)
%   - calibrationFactor (optional): a must for a calibrated calculation.
%   Default is 1.
%
% Outputs:
%   - Loct: SPL evaluated every timeInterval seconds;
%   - Loct_accum: SPL for the entire audio signal;
%   - nominalFc: nominal mid band frequencies;
%   - Fc: exact mid band frequencies.
%
% Felipe Ramos de Mello - 19/04/22
%%
function [Loct, Loct_accum, nominalFc, Fc] = octaveSPL(audioSignal, samplingRate, varargin)

%% Input parsing

p = inputParser;

expectedBandwidth = {'1 Octave', '1/2 Octave', '1/3 Octave',...
    '1/6 Octave', '1/12 Octave', '1/24 Octave', '1/48 Octave'};
expectedFreqW = {'A-weighting', 'C-weighting', 'K-weighting', 'Z-weighting'};
checkBase = @(n) (n==10 | n==2);

default_timeInterval = 1.0;
default_calibrationFactor = 1.0;
default_base = 10;
default_freqRange = [15, 21e3];
default_bandwidth = '1 Octave';
default_freqW = 'Z-weighting';

addRequired(p, 'audioSignal', @isnumeric);
addRequired(p, 'samplingRate', @(x) mustBePositive(x));

addParameter(p, 'bandwidth', default_bandwidth, @(x) any(validatestring(x, expectedBandwidth)));
addParameter(p, 'freqRange', default_freqRange, @isnumeric);
addParameter(p, 'base', default_base, checkBase);
addParameter(p, 'frequencyWeighting', default_freqW, @(x) any(validatestring(x, expectedFreqW)));
addParameter(p, 'timeInterval', default_timeInterval, @(x) mustBePositive(x));
addParameter(p, 'calibrationFactor', default_calibrationFactor, @isnumeric);

parse(p, audioSignal, samplingRate, varargin{:});

audioSignal = p.Results.audioSignal;
samplingRate = p.Results.samplingRate;
bandwidth = p.Results.bandwidth;
freqRange = p.Results.freqRange;
base = p.Results.base;
frequencyWeighting = p.Results.frequencyWeighting;
timeInterval = p.Results.timeInterval;
calibrationFactor = p.Results.calibrationFactor;

%% Function

[filterBank, Fc, nominalFc] = octaveFilterBankGenerator('bandwidth', bandwidth,...
    'freqRange', freqRange, 'samplingRate', samplingRate, 'base', base);

switch frequencyWeighting
    case 'A-weighting'
        wFilter = weightingFilter(frequencyWeighting, samplingRate);
        audioSignal = applyWeighting(audioSignal, wFilter);
    case 'C-weighting'
        wFilter = weightingFilter(frequencyWeighting, samplingRate);
        audioSignal = applyWeighting(audioSignal, wFilter);
    case 'K-weighting'
        wFilter = weightingFilter(frequencyWeighting, samplingRate);
        audioSignal = applyWeighting(audioSignal, wFilter);
end


nSamples = length(audioSignal);
samplesPerBlock = timeInterval*samplingRate;
nBlocks = floor(nSamples/samplesPerBlock);
p_ref = 2e-5;

Loct = zeros(nBlocks, length(Fc));

firstCounter = 1;
lastCounter = samplesPerBlock;

h = waitbar(0, 'Calculating the SPL in fractional octave bands...');

for num = 1:nBlocks
    
    slice = audioSignal(firstCounter:lastCounter, :)*calibrationFactor;
    
    for k = 1:length(Fc)
        sliceOct = filterBank{k}(slice);
        Loct(num, k) = rms(sliceOct);
    end
    
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + samplesPerBlock;
    
    waitbar(num/nBlocks, h, 'Calculating the SPL in fractional octave bands...');
end

close(h);

Loct = 20*log10(Loct/p_ref);
Loct_accum = 10*log10(mean(10.^(Loct/10)));

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