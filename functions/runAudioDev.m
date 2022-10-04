% Função para facilitar a gravação e reprodução de sinais de áudio em tempo
% real via Matlab (para minhas medições, depois atualizar essa info)
%
% Entradas:
%   i) audioObj: objeto do tipo audioPlayerRecorder (cerfique-se de que
%   audioObj.SupportVariableSize = true)
%   ii) 'type': opções são 'Rec', 'Play' ou 'PlayRec'
%   iii) 'duration': duração da medição em segundos (não necessário quando
%   excitation for especificado)
%   iv) 'excitation': sinal que será reproduzido
%   v) 'nChannels': quantos canais (melhorar esse parâmetro)
%
% Felipe Ramos de Mello - Março de 2022
%
function recordedAudio = runAudioDev(audioObj, varargin)

%% Input parsing

p = inputParser;

% default_type = 'Rec';
% valid_types = {'Rec', 'Play', 'PlayRec'};
% checkType = @(x) any(validatestring(x, valid_types));

default_duration = 10;
default_nChannels = 1;
default_excitation = zeros(default_duration*audioObj.SampleRate, default_nChannels);

check_audioObj = @(x) isa(audioObj, 'audioPlayerRecorder');

addRequired(p, 'audioObj', check_audioObj);

% addParameter(p, 'type', default_type, checkType);
addParameter(p, 'duration', default_duration, @isnumeric);
addParameter(p, 'excitation', default_excitation, @isnumeric);
addParameter(p, 'nChannels', default_nChannels, @isnumeric);

parse(p, audioObj, varargin{:});

%% Function

release(audioObj);

audioObj = p.Results.audioObj;
excitation = p.Results.excitation;
nChannels = p.Results.nChannels;
bufferSize = p.Results.audioObj.BufferSize;

if max(abs(excitation)) == 0
    excitation = zeros(p.Results.duration*audioObj.SampleRate, nChannels);
end

nSamples = length(excitation);
recordedAudio = zeros(nSamples, nChannels);

% Contadores
firstCounter = 1;
lastCounter = bufferSize;

totalOR = 0;
totalUR = 0;

% Para evitar overruns (não sei pq, mas funciona!)
for i = 1:6
    while audioObj.isLocked
        [~, ~] = audioObj(zeros(audioObj.BufferSize, nChannels));
    end
end

while lastCounter <= nSamples
    [audioRecorded, nUnderruns, nOverruns] = audioObj(excitation(firstCounter:lastCounter));
    recordedAudio(firstCounter:lastCounter, :) = audioRecorded;    
    totalOR = nOverruns + totalOR;
    totalUR = nUnderruns + totalUR;
      
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + bufferSize;
end

% Caso o sinal não seja divisível pelo tamanho do buffer, alguns samples
% ficarão de fora... Esse if cuida disso.
if nSamples-firstCounter > 0
    [audioRecorded, nUnderruns, nOverruns] = audioObj(excitation(firstCounter:end, nChannels));
    recordedAudio(firstCounter:end, :) = audioRecorded(1:nSamples-firstCounter + 1);
    totalOR = nOverruns + totalOR;
    totalUR = nUnderruns + totalUR;
end
release(audioObj);

if totalOR == 0 && totalUR == 0
    disp('Tudo certo!')
else
    disp('Algo deu errado... Verifique as variáveis totalUR, totalOR ou se o sinal clipou!')
end

%%%%%%% EOF
end