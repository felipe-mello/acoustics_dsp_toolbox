%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Essa função realiza o pós-processamento dos sinais gravados via NI e
%   interface de áudio (em paralelo). Infelizmente, não há como sincronizar
%   ambas as gravações sem um clock compartilhado. Assim, para viabilizar o
%   processo, utilizo um sinal especial:
%       i) 1 segundo de silêncio + beep (1/8 de segundo) + 1 s de silêncio
%       ii) Sweep
%       ii) 2 segundos de silêncio
%
%   O beep eu utilizo para conseguir sincronizar os sinais (nessa função).
%   Conhecendo o início do beep, consigo utilizar as taxas de amostragem e
%   tamanho do sweep para cortar as partes (i) e (iii) do sinal de
%   excitação.
%
%   Ademais, aqui também já faço o downsample do sinal capturado pela NI
%   (de 51200 para 44100) e calculo a FRF entre os sinais:
%       - FRF = MUT/REF
%
%   Rotina desenvolvida como parte do TCC em Eng. Acústica por Felipe Ramos
%   de Mello
%
%   Orientador: William D'Andrea Fonseca
%
%   Version log:
%       - 10/03/22: first build
%
%% 

% Entradas:
%   - audioObj: objeto utilizado para gravação/reprodução do sinal pela
%   interface de áudio
%   - daqObj: objeto para aquisição de dados via NI
%   - preSilence: tamanho do silêncio inicial e final (em segundos)
%   - sweep: ITA audio com o sweep original (entre os silêncios)
%   - beepLenght: tamanho do beep (em segundos)
%   - audioData: objeto ITA audio com a gravação feita pela interface de
%   áudio
%   - daqData: objeto ITA audio com a gravação feita pelo DAQ

function [daq, audio, FRF] = daqAndAudioPostProcessing(audioObj, audioData, daqObj, daqData,...
    preSilence, beepLength, sweep, calculateFRF)

% Preparando o terreno
sweepStart = preSilence + beepLength;
duration = sweep.trackLength;

% Processando o sinal da NI
daq.threshold = 0.45; % Pode ser interessante alterar de acordo com a situação
[~, idx] = findpeaks(abs(daqData.timeData), 'MinPeakHeight', daq.threshold);
daq.startSample = floor(sweepStart*daqObj.Rate) + idx(1);
daq.endSample = floor(duration*daqObj.Rate) + daq.startSample - 1;

daq.daqData_corr = daqData.timeData(daq.startSample:daq.endSample);
daq.daqData_corr = itaAudio(resample(daq.daqData_corr, 441, 512),...
    audioObj.SampleRate, 'time');

daq.backgroundNoise = daqData.timeData(idx(1)+beepLength*daqObj.Rate:daq.startSample - 1);
daq.backbroundNoise = itaAudio(resample(daq.backgroundNoise, 441, 512),...
    audioObj.SampleRate, 'time');

% Processando o sinal de áudio
audio.threshold = 0.01; % Pode ser interessante alterar de acordo com a situação
[~, idx] = findpeaks(abs(audioData.timeData), 'MinPeakHeight', audio.threshold);
audio.startSample = floor(sweepStart*audioObj.SampleRate) + idx(1);
audio.endSample = floor(duration*audioObj.SampleRate) + audio.startSample - 1;

audio.audioData_corr = itaAudio(audioData.timeData(audio.startSample:audio.endSample),...
    audioObj.SampleRate, 'time');

audio.backgroundNoise = audioData.timeData(idx(1)+beepLength*audioObj.SampleRate:audio.startSample - 1);
audio.backbroundNoise = itaAudio(audio.backgroundNoise,...
    audioObj.SampleRate, 'time');

% Plot dos sinais de áudio sincronizados
fig = figure(1);
fredPlot(fig, 16);

plot(daq.daqData_corr.timeVector,...
    daq.daqData_corr.timeData/max(abs(daq.daqData_corr.timeData))); hold on;
plot(audio.audioData_corr.timeVector,...
    audio.audioData_corr.timeData/max(abs(audio.audioData_corr.timeData)));

grid on;

xlabel('Tempo [s]'); ylabel('Amplitude [-]')
title('Sinais sincronizados e normalizados no tempo');
legend('daqData (resampled)', 'audioData', 'location', 'best')

if calculateFRF
    % FRF
    FRF.FRF = ita_divide_spk(audio.audioData_corr, daq.daqData_corr, 'mode', 'linear');
    FRF.FRF_smooth = ita_smooth_frequency(FRF.FRF, 'bandwidth', 1/12);

    fig = figure(2);
    fredPlot(fig, 16)

    semilogx(FRF.FRF.freqVector, 20*log10(abs(FRF.FRF_smooth.freqData/FRF.FRF_smooth.freq2value(1000))),...
        'linewidth', 2);
    grid on;

    xlim([20 20e3])
    xlabel('Frequência [Hz]'); ylabel('Nível [dB ref. 1]');
    title('FRF = MUT / REF (alisado - 1/12 por oitava)');
end

end