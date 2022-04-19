%   Função para realização de medições simultâneas com as placas da NI e
%   uma interface de áudio.
%
%   Versão alternativa da daqAndAudio original
%
%   Hardware:
%       i) NI 9234 (aquisição)
%       iii) Chassi cDAQ 9174 (comunicação com o PC)
%       iv) Interface de áudio (aquisição e geração)
%
%   Entradas da função:
%       - daqObj: objeto do tipo DataAcquisition (já configurado)
%       - audioObj: objeto do tipo audioPlayerRecorder
%       - excitation: vetor com o sinal de excitação
%       - signalType: qual tipo de sinal será utilizado
%           i) 'calibration': tonal de 1kHz para ajuste de sensibilidade
%           (externo)
%           ii) 'backgroundNoise': medição de ruído de fundo
%           iii) 'sweep': medição de resposta impulsiva
%
%
%   Saídas:
%       - daqData: dados capturados pela NI
%       - recordedAudio: áudio capturado pela interface de áudio
%       - totalOR: número de samples perdidos pela interface de áudio (na
%       gravação)
%       - totalUR: número de samples perdidos pela interface de áudio (na
%       reprodução)
%
%   Felipe Ramos de Mello
%       Version log:
%           - v1 - 14/02/22 (first build)
%           - v2 - 09/03/22 (ajustes finos)
%
%% Função

function [daqData, recordedAudio, totalOR, totalUR] =...
    daqAndAudioPlayRec(daqObj, audioObj, excitation, signalType)

% Cálculo do número de samples considerando a taxa de amostragem da
% interface de áudio
nSamplesAudio = length(excitation);
nChannels = length(audioObj.RecorderChannelMapping);
duration = nSamplesAudio/audioObj.SampleRate;

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

% Limpa o buffer do DAQ
flush(daqObj);

% Contadores e configurações da interface de áudio
firstCounter = 1;
lastCounter = audioObj.BufferSize;
totalOR = 0;
totalUR = 0;
recordedAudio = zeros(nSamplesAudio, 1);

% Para evitar overruns (não sei pq, mas funciona!)
for i = 1:6
    while audioObj.isLocked
        [~, ~] = audioObj(zeros(audioObj.BufferSize, nChannels));
    end
end

% Inicia a aquisição via NI (em background)
% disp('começou o daq'); tic
% start(daqObj, "duration", seconds(duration));
% toc
% disp('começou o audio')
% % Captura e reprodução dos samples via interface de áudio
% tic
% i = 0;
while lastCounter <= nSamplesAudio
    [audioRecorded, nUnderruns, nOverruns] = audioObj(excitation(firstCounter:lastCounter));
    recordedAudio(firstCounter:lastCounter, :) = audioRecorded;    
    totalOR = nOverruns + totalOR;
    totalUR = nUnderruns + totalUR;
    
    if firstCounter == 1
        start(daqObj, "duration", seconds(duration));
        disp('começou o daq');
    end
    
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + audioObj.BufferSize;
end

% Caso o sinal não seja divisível pelo tamanho do buffer, alguns samples
% ficarão de fora... Esse if cuida disso.
if nSamplesAudio-firstCounter > 0
    [audioRecorded, nUnderruns, nOverruns] = audioObj(excitation(firstCounter:end, nChannels));
    recordedAudio(firstCounter:end, :) = audioRecorded(1:nSamplesAudio-firstCounter + 1);
    totalOR = nOverruns + totalOR;
    totalUR = nUnderruns + totalUR;
end
release(audioObj);
toc
% Apenas para debug
disp(lastCounter)
disp(totalOR)
disp(nSamplesAudio)
disp(audioObj.BufferSize)

pause(1);
daqData = read(daqObj, "all");

% Mensagem de erro caso role overrun
if totalOR > 0 && totalUR > 0
    fprintf('\nOcorrência de underrun/overrun! Número de samples perdidos: ')
    fprintf('%d samples (underrun)\n', totalUR);
    fprintf('%d samples (overrun)\n\n', totalOR);
    stop(daqObj);
    flush(daqObj);
    error('Ocorrência de underrun/overrun! Aconselho que refaça a medição!')
end

disp("Medição finalizada!")


end
 