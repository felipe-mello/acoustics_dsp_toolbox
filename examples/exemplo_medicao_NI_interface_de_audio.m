%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Rotina para medições utilizando simultaneamente NI + placa de som:
%
%   - NI 9234 + chassi para AQUISIÇÃO (com mic BK, por exemplo)
%   - Interface de áudio para REPRODUÇÃO (usando driver ASIO4ALL, p.ex.)
%
% Informação IMPORTANTE: sem um clock em comum para controlar a NI e
% interface de áudio, torna-se IMPOSSÍVEL realizar aquisição/reprodução em
% sincronia. Todavia, é possível contornar esse problema gerando um sweep
% composto por silêncio -> beep tonal -> silêncio -> sweep -> silêncio. O
% beep é usado para identificar o início da gravação e, com isso, é
% possível sincronizar tudo no pós-processamento (vide função cutSilence,
% descrita abaixo).
%
% Funções customizadas (próprias):
%
%   - runAudioDev: automatiza a reprodução do sinal (mais infos no .m)
%   - cutSilence: reconhece o "beep" de sync e recorta apenas o sweep
%
% Por motivos de organização, as variáveis são iniciadas dentro de structs:
%
%   - config: struct para informações de configuração gerais
%   - msConfig: configuração da medição (taxa de amostragem, por exemplo)
%   - msDevices: objetos p/ controle da aquisição/reprodução
%
% Felipe Ramos de Mello - 03/10/2022

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yoga Nidra

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configurações dos sistemas de aquisição

% Configuração do dispositivo asio (deixar comentado)
% asiosettings

% Lista os dispositivos NI conectados
config.d = daqlist("ni");

% Inicia a conexão com o dispositivo
msDevices.daqObj = daq("ni");

% Configura as propriedades do DAQ
msDevices.daqObj.Rate = 51200;    % Taxa de amostragem
msConfig.daqRate = 51200;          

% Configura o canal de entrada
% ('cDAQ2Mod1' é só exemplo, verifique qual placa estás usando)
msDevices.inChannel = addinput(msDevices.daqObj, 'cDAQ2Mod1', 'ai0', 'Microphone'); % Parâmetros de acordo com o especificado em "deviceInfo"
msDevices.inChannel.Sensitivity = 42.4/1000;    % Ver encarte do mic (V/Pa)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Ajuste da interface de áudio (sistema de reprodução)

% Parâmetros de config. para a interface de áudio
msConfig.audioFs = 44100;
msConfig.nAudioChannels = 1;

% Configuração do objeto para controle da interface
msDevices.audioObj = audioPlayerRecorder('SampleRate', msConfig.audioFs);
msDevices.audioObj.Device = 'ASIO4ALL v2'; % Ajuste para o driver do seu sistema
msDevices.audioObj.BufferSize = 512*4;
msDevices.audioObj.PlayerChannelMapping = [3]; % Ajuste de acordo com o seu sistema
msDevices.audioObj.RecorderChannelMapping = [3]; % Ajuste de acordo com o seu sistema
msDevices.audioObj.SupportVariableSize = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sinais de excitação

% Sweep para medição de resposta impulsiva
msExcitation.fftDeg = 14; % Ajustar de acordo com sua aplicação
msExcitation.sweep = ita_generate_sweep('samplingRate', msDevices.audioObj.SampleRate, 'fftDegree', msExcitation.fftDeg,...
    'freqRange', [20 22050], 'bandwidth', 0);

% Construção do silêncio e beep
msExcitation.silenceDuration = 1; % in seconds
msExcitation.silence = zeros(msExcitation.silenceDuration*msConfig.audioFs, 1);
msExcitation.beepLength = 1/24;
msExcitation.beep = 0.707*sin(2*pi*8000*msExcitation.sweep.timeVector(1:msConfig.audioFs*msExcitation.beepLength));

% Sinal completo: silêncio -> beep -> silêncio -> sweep -> silêncio
msExcitation.excitationSignal =...
    itaAudio([msExcitation.silence; msExcitation.beep; msExcitation.silence; msExcitation.sweep.timeData; msExcitation.sweep.nSamples],...
    msDevices.audioObj.SampleRate, 'time');

% Ajuste de ganho
msExcitation.outputGain = -3; % dBFS (ajuste de acordo com sua aplicação)
msExcitation.excitation = msExcitation.excitationSignal.timeData.*(10.^(msExcitation.outputGain/20));

% Cálculo do número de samples e duração do sinal completo
% (usado no pós-processamento)
msExcitation.nSamples = msExcitation.excitationSignal.nSamples;
msExcitation.duration = msExcitation.excitationSignal.trackLength;

% Sinal para calibração ou medição de ruído de fundo (silêncio)
backgroundAndCalibration = zeros(msExcitation.sweep.nSamples, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Aferição da sensibilidade em 1 kHz (com aferidor 94 dB SPL @ 1 kHz) 

clc;
prompt = 'Insira o microfone no calibrador sonoro e aperte enter para começar\n';
input(prompt);

validate = 'n';

% Aguarda a confirmação
while strcmp(validate, 'n')
    flush(msDevices.daqObj);
    daqData = read(msDevices.daqObj, seconds(10)); % grava por 10 segundos
    msData.sensitivity = itaAudio(resample(daqData.cDAQ2Mod1_ai0, 441, 512), msConfig.audioFs, 'time');
    msData.sensitivity.plot_time;
    msData.sensitivity.plot_freq;
    
    prompt = 'Validar a medição? [y/n]\n';
    validate = input(prompt, 's');
end

clear daqData

% Adicionar rotina para cálculo do fator de correção

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reprodução e gravação do sweep

% Limpa o command window
clc;

prompt = 'Medição de resposta impulsiva (mic REF)... Aperte enter para começar\n';
input(prompt);

% Caso queira fazer mais de uma medição p/ calcular médias
numOfMeans = 3;
msRecord = cell(numOfMeans, 1);
msNumber = 1;

validate = 'n';

while msNumber <= numOfMeans_ref
    fprintf('Medição número %d\n', msNumber);
    while strcmp(validate, 'n')
        
        flush(msDevices.daqObj); % Limpa o buffer da NI
        start(msDevices.daqObj, "continuous"); % Grava de forma contínua
        
        % Inicia a reprodução do sinal
        runAudioDev(msDevices.audioObj, 'excitation', msExcitation.excitation);
        
        % Após reprodução, aguarda 1s antes de encerrar o processo da NI
        pause(1);
        stop(msDevices.daqObj); % Encerra a gravação
        daqData = read(msDevices.daqObj, "all"); % Salva a gravação em um vetor temporário
        
        % Transforma em itaAudio
        msData.recordedData = itaAudio(daqData.cDAQ2Mod1_ai0, msConfig.daqRate, 'time');
        
        % Sincroniza o sinal (cortando o silêncio)
        % O silêncio do fim é usado para o background noise 
        %(com msm duração do sweep)
        [msData.recordedSweep, msData.backgroundNoise] = ...
            cutSilence(msData.recordedData, msExcitation.silenceDuration,...
            msExcitation.beepLength, msExcitation.sweep.trackLength, 0.6);
        
        % Plot pra checar se deu tudo certo (sweep vs ruído de fundo)
        fig = figure();
        fredPlot(fig, 16);
        semilogx(msData.recordedSweep.freqVector, msData.recordedSweep.freqData_dB); hold on;
        semilogx(msData.backgroundNoise.freqVector, msData.backgroundNoise.freqData_dB); hold on;
        title('Sweep gravado vs ruído de fundo (mic REF)')
        xlabel('Frequência');
        ylabel('Nível [dB ref. 1]');
        xlim([20, 22050]); grid on;
        
        prompt = 'Validar a medição? [y/n]\n';
        validate = input(prompt, 's');
        
    end
    
    % Se validou, salva na célula
    msRecord{msNumber}.sweepRecord = msData.recordedSweep;
    msRecord{msNumber}.bkgNoise = msData.backgroundNoise;
    
    msNumber = msNumber + 1;
    validate = 'n';
    
end

clear daqData;
disp('Medição mic REF finalizada!')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Salvar tudo

% Pode selecionar com calma o que desejar salvar, aqui fiz com tudo
save('medicao.mat');
