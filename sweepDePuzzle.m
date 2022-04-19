%% Function

function [output] = ...
    sweepDePuzzle(input, silenceDuration, fftDeg, nSweeps)

%% Input parsing

p = inputParser;

check_ita = @(x) isa(x, 'itaAudio');
addRequired(p, 'input', check_ita);
addRequired(p, 'silenceDuration', @isnumeric);
addRequired(p, 'fftDeg', @isnumeric);

parse(p, input, silenceDuration, fftDeg);

%% Function

% Just to save some typing space
input = p.Results.input;
silenceDuration = p.Results.silenceDuration;
fftDeg = p.Results.fftDeg;
fs = input.samplingRate;

% Samples
silenceSamples = fs*silenceDuration;
nSamples = 2^fftDeg;
endSample = zeros(nSweeps, 1);
startSample = zeros(nSweeps, 1);
startSample(1) = 1;
endSample(1) = 2^fftDeg;

firstCounter = 1;
lastCounter = 2^fftDeg;

output = zeros(nSamples*nSweeps, 1);
output(firstCounter:lastCounter, 1) = input.timeData(startSample(1):endSample(1));

firstCounter = lastCounter + 1;
lastCounter = lastCounter + 2^fftDeg;

for i = 2:nSweeps
   startSample(i) = endSample(i-1) + 1 + silenceSamples; 
   endSample(i) = 2^fftDeg + startSample(i) - 1;
   output(firstCounter:lastCounter, 1) = input.timeData(startSample(i):endSample(i));
   firstCounter = lastCounter + 1;
   lastCounter = lastCounter + 2^fftDeg;
end

output = itaAudio(output, fs, 'time');

disp('Enjoy your adjusted data! =]')

end