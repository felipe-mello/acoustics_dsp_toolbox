%   Função para realização de medições simultâneas com as placas da NI e
%   uma interface de áudio. 
%
%   Hardware:
%       i) NI 9234 (aquisição)
%       ii) NI 9263 (geração)
%       iii) Chassi cDAQ 9174 (comunicação com o PC)
%       iv) Interface de áudio (aquisição)
%
%   Entradas da função:
%       - daqObj: objeto do tipo DataAcquisition (já configurado)
%       - audioObj: objeto do tipo audioDeviceReader
%       - outData: vetor com o sinal de excitação
%       - audioSamplingRate: taxa de amostragem da interface de áudio
%       - duration: duração do sinal de excitação em segundos
%
%   Saídas:
%       - recordedAudio: áudio capturado pela interface de áudio
%       - totalOR: número de samples perdidos pela interface de áudio
%
%   Felipe Ramos de Mello - v1 - 14/02/22
%
%% Função

function [daqData, recordedAudio, totalOR] = daqAndAudioRec(daqObj, audioObj, excitation,...
                                    audioSamplingRate, duration, signalType)

% Cálculo do número de samples considerando a taxa de amostragem da
% interface de áudio
nSamplesAudio = floor(duration*audioSamplingRate);
% nChannels = audioObj.

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

% Carrega o sinal de excitação que será reproduzido
flush(daqObj);
preload(daqObj, excitation);

% Contadores e configurações da interface de áudio
firstCounter = 1;
lastCounter = audioObj.SamplesPerFrame;
totalOR = 0;
recordedAudio = zeros(nSamplesAudio, 1);

% Para evitar overruns (não sei pq, mas funciona!)
for i = 1:6
    while audioObj.isLocked
        [~, ~] = audioObj();
    end
end

% Inicia a aquisição/reprodução via NI (em background)
start(daqObj);

% Captura dos samples via interface de áudio
while lastCounter <= nSamplesAudio
    [audioRecorded, nOverruns] = audioObj();
    recordedAudio(firstCounter:lastCounter, :) = audioRecorded;    
    totalOR = nOverruns + totalOR;
    
    
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + audioObj.SamplesPerFrame;
end

% Caso o sinal não seja divisível pelo tamanho do buffer, alguns samples
% ficarão de fora... Esse if cuida disso.
if nSamplesAudio-firstCounter > 0
    [audioRecorded, nOverruns] = audioObj();
    recordedAudio(firstCounter:end, :) = audioRecorded(1:nSamplesAudio-firstCounter + 1);
    totalOR = nOverruns + totalOR;
end
release(audioObj);
% stop(daqObj);

% disp(lastCounter)
% disp(totalOR)
% disp(nSamplesAudio)
% disp(audioObj.SamplesPerFrame)

pause(1);
daqData = read(daqObj, "all");

% Mensagem de erro caso role overrun
if totalOR > 0
    fprintf('\nOcorrência de overrun! Número de samples perdidos: ')
    fprintf('%d samples\n\n', totalOR);
    stop(daqObj);
    flush(daqObj);
    error('Ocorrência de overrun! Aconselho que refaça a medição!')
end

disp("Medição finalizada!")


end
 