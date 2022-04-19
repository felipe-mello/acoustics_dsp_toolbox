% Fractional octave filter bank generator
%
% This functions doesn't implement the filters. It just uses the
% octaveFilter object to retrieve each band filter and save all on a cell.
%
% Inputs (all optional):
%   - bandwidth: '1 Octave', '1/2 Octave', '1/3 Octave'... See
%   expectedBandwidth below. Default is '1 Octave'.
%
%   - freqRange: vector = [freqMin, freqMax]. Default is [15, 21e3]
%
%   - base: 10 or 2. Default is 10.
%
%   - samplingRate: default is 44100;
%
% Output:
%   - filterBank: cell with all the filters
%   - Fc: exact center frequencies
%   - nominalFc: nominal center frequencies
%
%   Felipe Ramos de Mello - 10/06/21
%%

function [filterBank, Fc, nominalFc] = octaveFilterBankGenerator(varargin)

%% Input parser

p = inputParser;

default_bandwidth = '1 Octave';
default_freqRange = [20 20e3];
default_base = 10;
default_samplingRate = 44100;

expectedBandwidth = {'1 Octave', '1/2 Octave', '1/3 Octave',...
    '1/6 Octave', '1/12 Octave', '1/24 Octave', '1/48 Octave'};

checkBase = @(n) (n==10 | n==2);

addParameter(p, 'bandwidth', default_bandwidth, @(x) any(validatestring(x, expectedBandwidth)));
addParameter(p, 'freqRange', default_freqRange, @isnumeric);
addParameter(p, 'base', default_base, checkBase);
addParameter(p, 'samplingRate', default_samplingRate, @isnumeric);

parse(p, varargin{:});

%% Function

bandwidth = p.Results.bandwidth;
base = p.Results.base;
fs = p.Results.samplingRate;
freqRange = p.Results.freqRange;

% Guarantees that filters comply with the class 1 standard
switch bandwidth
    case '1 Octave'
        N = 10; b = 1;
    case '1/2 Octave'
        N = 10; b = 2;
    case '1/3 Octave'
        N = 10; b = 3;
    case '1/6 Octave'
        N = 10; b = 6;
    case '1/12 Octave'
        N = 8; b = 12;
    case '1/24 Octave'
        N = 6; b = 24;
    case '1/48 Octave'
        N = 6; b = 48;
end

[Fc, ~, nominalFc] = centerFreqsCalculator(b, 'base', base, 'freqRange', freqRange);  

Nfc = length(Fc);
filterBank = cell(1,Nfc);

for i = 1:Nfc   
    if Fc(i) < 16e3 
        filterBank{i} = octaveFilter('FilterOrder', N,...
            'CenterFrequency', Fc(i), 'Bandwidth', bandwidth, ...
            'SampleRate', fs);
    else
        filterBank{i} = octaveFilter('FilterOrder', N,...
            'CenterFrequency', Fc(i), 'Bandwidth', bandwidth, ...
            'SampleRate', fs);
        filterBank{i}.Oversample = true;
    end    
end

end