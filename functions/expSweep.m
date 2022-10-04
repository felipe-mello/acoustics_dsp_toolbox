% Esta função permite a geração de sweeps exponenciais com três opções de
% resposta em frequência:
%
%   1 - White: todas as frequências possuem a mesma amplitude.
%   2 - Pink: ênfase nas baixas frequências. Decaimento de -3 dB/oct.
%   3 - Blue: ênfase nas altas frequências. Acréscimo de + 3dB/oct.
%
%   Entradas:
%       i) 'samplingRate': taxa de amostragem. O default é 44100;
%       ii) 'fftDegree': define o número de samples do sinal (2^fftDegree).
%       O default é 18;
%       iii) 'freqRange': vetor com as frequências mínima e máxima. O
%       default é [16, 22000];
%       iv) 'sweepSlope': define a resposta em frequência. As opções são 
%       'pink', 'white' e 'blue'. O padrão é 'pink'.
%       v) 'outputGain': valor em dBFS. Ex: -3
%
%   Saídas:
%       i) sweep: vetor com o sweep normalizado;
%       ii) timeVector: vetor de tempo.
%
%   Exemplo de uso:
%
%       [sweep, timeVector] = expSweep('samplingRate', 44100,...
%       'fftDegree', 18, 'freqRange', [16, 22000], 'sweepSlope', 'pink');
%
%   Baseado no artigo "Impulse response measurement with sine sweeps and
%   amplitude modulation schemes" de Q. Meng, D. Sen, S. Wang e L. Hayes
%
%   Existe um ringing quando se muda o slope da frequência. Aparentemente,
%   há uma forma de melhorar essa resposta (descrita no artigo do
%   Massarani), todavia ainda não foi implementada.
%
%   Felipe Ramos de Mello - 01/11/21
%
%% Função

function [sweep, timeVector] = expSweep(varargin)

%% Input parsing

p = inputParser;

default_samplingRate = 44100;
default_fftDegree = 18;
default_frequencyRange = [5, 20000];
default_outputGain = 0;

default_sweepSlope = 'pink';
valid_sweepSlope = {'pink', 'white', 'blue'};
check_sweepSlope = @(x) any(validatestring(x, valid_sweepSlope));

addParameter(p, 'samplingRate', default_samplingRate, @isnumeric);
addParameter(p, 'fftDegree', default_fftDegree, @isnumeric);
addParameter(p, 'freqRange', default_frequencyRange, @isnumeric);
addParameter(p, 'sweepSlope', default_sweepSlope, check_sweepSlope);
addParameter(p, 'outputGain', default_outputGain, @isnumeric);

parse(p, varargin{:});

%% Função

% Inputs após o parsing

samplingRate = p.Results.samplingRate;
fftDegree = p.Results.fftDegree;
freqRange = p.Results.freqRange;
sweepSlope = p.Results.sweepSlope;
outputGain = p.Results.outputGain;

% Configurações inciais

T = (2^fftDegree)/samplingRate; % Duration of the signal in seconds
timeVector = (0:1/samplingRate:T-1/samplingRate)'; % Time vector

f1 = freqRange(1)*2^(-2/12); % First frequency extended by 2/12 bandwidth
f2 = min(freqRange(2)*2^(2/12), samplingRate/2); % Last frequency extended by 2/12 bandwidth

% Angelo Farina's exponential sweep equation constants
L = T/(log(f2/f1)); % cte 1
K = (T*2*pi*f1)/(log(f2/f1)); % cte 2

% Ajustando o slope do sweep
if strcmp(sweepSlope, 'pink')
    m = 1;
elseif strcmp(sweepSlope, 'white')
    n = 2;
    % Exponential function for the amplitude modulation
    m = exp(timeVector./(n*L)); % exp. function
else
    n = 1;
    % Exponential function for the amplitude modulation
    m = exp(timeVector./(n*L)); % exp. function
end

% Building the exponential sweep
s = sin(K.*(exp(timeVector/L) - 1)); % "original" exponential sweep
sweep = s.*m; % exponential sweep with amplitude modulation

%% Pós-processamento

% PEQUENO fade in e fade out
nSamples = 2^(fftDegree);
fade_samples = [-round(100*samplingRate/f2 + 2), 0] + nSamples;
windowLength = (fade_samples(2) - fade_samples(1))*2;

n = 0:windowLength;

w = 0.5*(1 - cos(2*pi*(n/windowLength)))'; % hanning window

middle = floor(length(n)/2) + 1;

sweep(1:middle-1) = sweep(1:middle-1).*w(1:middle-1);
sweep(fade_samples(1):end) = sweep(fade_samples(1):end).*w(middle:end);

% Filtro para suavizar a resposta nas altíssimas frequências
[b, a] = butter(4, f2*2^(-2/128)/(samplingRate/2));
sweep = filter(b, a, sweep);

% Normalization
sweep = sweep./max(abs(sweep))*10^(outputGain/20);


end