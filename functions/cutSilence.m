% This function is useful for when you need to measure acoustic data with
% two systems that have different data rates (e.g., NI Daq and audio
% interface). For that to work, you must use an excitation signal
% comprising of an initial silence, followed by a brief beep, then silence
% again, the sweep and a final silence.
%
% This function will cut the silences and leave just the sweep part, so you
% can calculate FRFs or compare the signals in other ways.
%
% Inputs (mandatory):
%   i) input: audio or daq data to be adjusted (must be itaAudio)
%   ii) silenceDuration: silence duration in seconds
%   iii) beepDuration: beep duration in seconds
%   iv) sweepDuration: duration, in seconds, of the sweep used for the measurement
%
% Input (optional)
%   - samplingRate (in case data have different sampling rates, they will
%   be resampled to match this parameter; Default is 44100).
%
% Outputs:
%   i) output: adjusted audio or daq data
%   ii) bkgNoise: background noise from the final silence period
%
% Usage examples:
%   [out, bkg] = cutSilence(input, silence, beep, sweep, 'samplingRate', fs)
%   [out, bkg] = cutSilence(input, silence, beep, sweep)
%
% Author: Felipe Ramos de Mello
% Advisor: Prof. William D'Andrea Fonseca
% Date: 16/03/22
%
%% Function

function [output, bkgNoise] = ...
    cutSilence(input, silenceDuration, beepDuration, sweepDuration, threshold, varargin)

%% Input parsing

p = inputParser;

default_samplingRate = 44100;

check_ita = @(x) isa(x, 'itaAudio');

addRequired(p, 'input', check_ita);
addRequired(p, 'silenceDuration', @isnumeric);
addRequired(p, 'beepDuration', @isnumeric);
addRequired(p, 'sweepDuration', @isnumeric);
addRequired(p, 'threshold', @isnumeric);
addParameter(p, 'samplingRate', default_samplingRate, @isnumeric);

parse(p, input, silenceDuration, beepDuration, sweepDuration, threshold,...
    varargin{:});

%% Function

% Just to save some typing space
input = p.Results.input;
silenceDuration = p.Results.silenceDuration;
beepDuration = p.Results.beepDuration;
sweepDuration = p.Results.sweepDuration;
threshold = p.Results.threshold;
samplingRate = p.Results.samplingRate;

% Some time calculations
sweepStart = silenceDuration + beepDuration; % in seconds

% Check if need resampling
if input.samplingRate ~= samplingRate
    disp('I will need to resample the input data!')
    factor = gcd(input.samplingRate, samplingRate);
    p = samplingRate/factor;
    q = input.samplingRate/factor;
    input = itaAudio(resample(input.timeData, p, q), samplingRate, 'time');
    disp('Done =]')
end

% Processing data
[~, idx] = findpeaks(abs(input.timeData), 'MinPeakHeight', threshold);
startSample = floor(sweepStart*samplingRate) + idx(1);
endSample = floor(sweepDuration*samplingRate) + startSample - 1;

output = input.timeData(startSample:endSample);
output = itaAudio(output, samplingRate, 'time');

bkgNoise = input.timeData(endSample+1:end);
bkgNoise = itaAudio(bkgNoise, 44100, 'time');

disp('Enjoy your adjusted data! =]')

end