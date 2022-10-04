%   Função para realização de medições simultâneas com as placas da NI e
%   uma interface de áudio. 
%
%   Hardware:
%       i) Interface de áudio USB (pode ser mais de uma) - ASIO4ALL
%
%   Entradas da função:
%       - playRec: objeto do tipo audioPlayerRecorder
%       - excitation: vetor com o sinal de excitação
%       - samplingRate: taxa de amostragem da interface de áudio
%
%   Saídas:
%       - recordedAudio: áudio capturado pela interface de áudio
%       - totalOR: número de samples perdidos pela interface de áudio na
%       gravação
%       - totalUR: número de samples perdidos durante a reprodução
%       
%   Felipe Ramos de Mello - v1 - 07/03/22
%
%% Função

function [recordedAudio, totalOR, totalUR] = audioPlayRecMS(audioObj, excitation, nChannels, signalType)

nSamples = length(excitation);
recordedAudio = zeros(nSamples, nChannels); % Pré-alocação da variável que irá guardar o sinal gravado

% Contadores
firstCounter = 1;
lastCounter = audioObj.BufferSize;

totalOR = 0;
totalUR = 0;

% Prompt para controle da medição
if strcmp(signalType, 'backgroundNoise')
    fprintf('Medição de ruído de fundo\n');
elseif strcmp(signalType, 'sweep') 
    fprintf('Medição de resposta impulsiva\n');
elseif strcmp(signalType, 'calibration')
    fprintf('Calibração via sinal de 1 kHz\n');
end
prompt = '    Aperte enter para começar\n';
input(prompt);

while lastCounter <= nSamples
    
    [audioRecorded, nUnderruns, nOverruns] = audioObj(excitation(firstCounter:lastCounter, 1));
    recordedAudio(firstCounter:lastCounter, :) = audioRecorded(:, [1:nChannels]);
    
    totalUR = nUnderruns + totalUR;
    totalOR = nOverruns + totalOR;
    
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + audioObj.BufferSize;
        
end

release(audioObj); % muito importante

% Checando se deu tudo certo

if totalOR == 0 && totalUR == 0

else
    disp('Algo deu errado... Verifique as variáveis totalUR, totalOR ou se o sinal clipou!')
end


end