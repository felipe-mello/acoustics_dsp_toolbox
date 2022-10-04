%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Rotina para medição simultânea com interface de áudio (aquisição e
%   reprodução) e placa NI (só aquisição)
%
%   Importante pontuar que, por não haver um clock compartilhado, as
%   plataformas de aquisição/reprodução estarão sempre fora de sincronia.
%   A saída é utilizar um sinal de excitação que nos permita sincronizar as
%   gravações no pós-processamento. Nesse caso, utiliza-se um sinal
%   composto por silêncio -> beep -> silêncio -> sweep -> silêncio.
%
%   A partir de uma função customizada (cutSilence) é possível identificar
%   o beep e, conhecendo o tamanho do silêncio, retirar apenas o sweep da
%   gravação. Ademais, é importante atentar-se que a NI possui uma taxa de
%   amostragem de 51200 Hz, não encontrada em placas de som. Portanto, para
%   o processamento final (FRF, por exemplo), será necessário reamostrar o
%   sinal (usar funções nativas do matlab, como a resample).
%
%   A função daqAndAudioPostProcessing automatiza essa etapa de
%   pós-processamento (corte, reamostragem e cálculo da FRF). Por favor,
%   checar na pasta de funções.
%
%   Caso encontre algum bug, por favor avise-me pelo email
%   felipe.mello@eac.ufsm.br, ou envie um pull request pelo github.
%
%   Felipe Ramos de Mello - 04/10/2022
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yoga Nidra

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configurações do DAQ

% Lista os dispositivos NI conectados
config.d = daqlist("ni");

% Inicia a conexão com o dispositivo
msDevices.daqObj = daq("ni");

% Configura as propriedades do DAQ
msDevices.daqObj.Rate = 51200;    % Taxa de amostragem
msConfig.daqRate = 51200;

msDevices.inChannel = addinput(msDevices.daqObj, 'cDAQ2Mod1', 'ai0', 'Microphone'); % Parâmetros de acordo com o especificado em "deviceInfo"
msDevices.inChannel.Sensitivity = 42.4/1000;    % Ver encarte do mic (V/Pa)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configurações da interface de áudio

msConfig.audioFs = 44100;
msDevices.audioObj = audioPlayerRecorder('SampleRate', msConfig.audioFs);
msDevices.audioObj.Device = 'ASIO4ALL v2'; % Ajuste para o driver do seu sistema
msDevices.audioObj.BufferSize = 512*4;
msDevices.nChannels = 1;
msDevices.audioObj.PlayerChannelMapping = [3]; % Ajuste de acordo com o seu sistema
msDevices.audioObj.RecorderChannelMapping = [1]; % Ajuste de acordo com o seu sistema
msDevices.audioObj.SupportVariableSize = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sinal de excitação

% Sweep exponencial
msExcitation.fftDeg = 19;

msExcitation.sweep = ita_generate_sweep('samplingRate', msDevices.audioObj.SampleRate, 'fftDegree', msExcitation.fftDeg,...
    'freqRange', [20 20e3]);

% Silêncio e tonal para sync
msExcitation.silenceDuration = 3; % in seconds
msExcitation.silence = zeros(msExcitation.silenceDuration*msConfig.audioFs, 1);
msExcitation.beepLength = 1/8;
msExcitation.beep = 0.4*sin(2*pi*2000*msExcitation.sweep.timeVector(1:msConfig.audioFs*msExcitation.beepLength));

% Necessário para garantir a integridade da medição
msExcitation.sweepWithSilence =...
    itaAudio([msExcitation.silence; msExcitation.beep; msExcitation.silence; msExcitation.sweep.timeData; msExcitation.silence],...
    msDevices.audioObj.SampleRate, 'time');

msExcitation.outputGain = -3; % dBFS
msExcitation.excitation = msExcitation.sweepWithSilence.timeData.*(10.^(msExcitation.outputGain/20));
msExcitation.nSamples = msExcitation.sweepWithSilence.nSamples;
msExcitation.duration = msExcitation.sweepWithSilence.trackLength;

backgroundAndCalibration = zeros(msExcitation.sweep.nSamples, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Medição da sensibilidade em 1 kHz - mic BK na NI

clc;
prompt = 'Insira o mic BK no calibrador sonoro e aperte enter para começar\n';
input(prompt);

numOfMeans = 1; % com reposição
numOfMeasurement = 1;

msNI = cell(numOfMeans, 1);

validate = 'n';

while numOfMeasurement <= numOfMeans
    
    clc;
    fprintf('Medição número %d\n', numOfMeasurement);
    
    while strcmp(validate, 'n')
        daqData = read(msDevices.daqObj, seconds(10));
        
        msNI{numOfMeasurement}.sensitivity = itaAudio(resample(daqData.cDAQ2Mod1_ai0, 441, 512), msConfig.audioFs, 'time');
        msNI{numOfMeasurement}.sensitivity.plot_time;
        msNI{numOfMeasurement}.sensitivity.plot_freq;
        
        prompt = 'Validar a medição? [y/n]\n';
        validate = input(prompt, 's');
    end
    
    clear daqData

    msNI{numOfMeasurement}.REF_FC =  1 / max(abs(msNI{numOfMeasurement}.sensitivity.freqData));
    
    if numOfMeasurement < numOfMeans
        input('Reinsira o microfone no acoplador e aperte enter para começar:\n');
    end
    
    validate = 'n';
    numOfMeasurement = numOfMeasurement + 1;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Medição da sensibilidade em 1kHz - mic em placa de áudio

clc;
prompt = 'Insira o mic no calibrador sonoro e aperte enter para começar\n';
input(prompt);

numOfMeans = 1;
numOfMeasurement = 1;
msAudioInterface = cell(numOfMeans, 1);

validate = 'n';

while numOfMeasurement <= numOfMeans
    
    clc;
    fprintf('Medição número %d\n', numOfMeasurement);
    
    while strcmp(validate, 'n')
        audioData = runAudioDev(msDevices.audioObj, 'duration', 11);
        
        msAudioInterface{numOfMeasurement}.sensitivity = itaAudio(audioData(22051:msConfig.audioFs*11-22050),...
            msDevices.audioObj.SampleRate, 'time');
        
        msAudioInterface{numOfMeasurement}.sensitivity.plot_time;
        msAudioInterface{numOfMeasurement}.sensitivity.plot_freq;
        
        prompt = 'Validar a medição? [y/n]\n';
        validate = input(prompt, 's');
    end

    msAudioInterface{numOfMeasurement}.MUT_FC = 1 / max(abs(msAudioInterface{numOfMeasurement}.sensitivity.freqData));
    
    if numOfMeasurement < numOfMeans
        input('Reinsira o microfone no acoplador e aperte enter para começar:\n');
    end
    
    validate = 'n';
    numOfMeasurement = numOfMeasurement + 1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Gravação simultânea do sinal de excitação

clc;

prompt = 'Medição de resposta impulsiva... Aperte enter para começar\n';
input(prompt);

numOfMeans = 9;
msNumber = 1;

validate = 'n';

while msNumber <= numOfMeans
    
    fprintf('Medição número %d\n', msNumber);
    
    while strcmp(validate, 'n')
        
        %%%%%%%%%% Gravação BK e AudioInterface %%%%%%%%%%
        
        % Inicia a NI
        flush(msDevices.daqObj);
        start(msDevices.daqObj, "continuous");
        
        % Inicia a interface de áudio
        recordedAudio = runAudioDev(msDevices.audioObj, 'excitation', msExcitation.excitation);
        
        % Salva os dados que estão no buffer da NI
        pause(2);
        stop(msDevices.daqObj);
        daqData = read(msDevices.daqObj, "all");
        
        %%%%%%%%%% Ajuste dos dados NI %%%%%%%%%%
        
        msNI{msNumber}.sweepRecord = itaAudio(daqData.cDAQ2Mod1_ai0, msConfig.daqRate, 'time');
        msNI{msNumber}.sweepInPascal = msNI{msNumber}.sweepRecord  * msNI{1}.REF_FC;
        msNI{msNumber}.sweepInPascal.channelUnits = 'Pa';
        
        [msNI{msNumber}.sweepAdjusted, msNI{msNumber}.bkgNoise] = ...
            cutSilence(msNI{msNumber}.sweepInPascal, msExcitation.silenceDuration,...
            msExcitation.beepLength, msExcitation.sweep.trackLength, 1);
                
        msNI{msNumber}.sweepAdjusted.channelUnits = 'Pa';
        msNI{msNumber}.bkgNoise.channelUnits = 'Pa';
        
        %%%%%%%%%% Ajustes dos dados da interface %%%%%%%%%% 
        
        msAudioInterface{msNumber}.sweepRecord = itaAudio(recordedAudio(22050:end), msConfig.audioFs, 'time');
        msAudioInterface{msNumber}.sweepInPascal = msAudioInterface{msNumber}.sweepRecord * msAudioInterface{1}.MUT_FC;
        msAudioInterface{msNumber}.sweepInPascal.channelUnits = 'Pa';
        
        [msAudioInterface{msNumber}.sweepAdjusted, msAudioInterface{msNumber}.bkgNoise] = ...
            cutSilence(msAudioInterface{msNumber}.sweepInPascal, msExcitation.silenceDuration,...
            msExcitation.beepLength, msExcitation.sweep.trackLength, 1);
                
        msAudioInterface{msNumber}.sweepAdjusted.channelUnits = 'Pa';
        msAudioInterface{msNumber}.bkgNoise.channelUnits = 'Pa';
        
        %%%%%%%%%% Plot para validação tempo %%%%%%%%%%
        
        fig = figure();
        fredPlot(fig, 16);
        plot(msNI{msNumber}.sweepAdjusted.timeVector, msNI{msNumber}.sweepAdjusted.timeData); hold on;
        plot(msAudioInterface{msNumber}.sweepAdjusted.timeVector, msAudioInterface{msNumber}.sweepAdjusted.timeData); hold on;
        
        legend('Sweep REF', 'Sweep MUT', 'numcolumns', 2,...
            'location', 'best');
        
        title('Sweep sincronizados no tempo (MUT e REF)')
        xlabel('Tempo [s]');
        ylabel('Amplitude [Pa]');
        grid on;
        
        %%%%%%%%%% Plot para validação freq %%%%%%%%%%
        
        fig = figure();
        fredPlot(fig, 16);
        semilogx(msNI{msNumber}.sweepAdjusted.freqVector, msNI{msNumber}.sweepAdjusted.freqData_dB); hold on;
        semilogx(msAudioInterface{msNumber}.sweepAdjusted.freqVector, msAudioInterface{msNumber}.sweepAdjusted.freqData_dB); hold on;
        semilogx(msNI{msNumber}.bkgNoise.freqVector, msNI{msNumber}.bkgNoise.freqData_dB); hold on;
        semilogx(msAudioInterface{msNumber}.bkgNoise.freqVector, msAudioInterface{msNumber}.bkgNoise.freqData_dB); hold on;
        
        legend('Sweep REF', 'Sweep MUT', 'Bkg REF', 'Bkg MUT', 'numcolumns', 2,...
            'location', 'best');
        
        title('Sweep gravado vs ruído de fundo (mic REF)')
        xlabel('Frequência [Hz]');
        ylabel('Nível [dB ref. 20 uPa]');
        xlim([20, 22050]); grid on;
        
        %%%%%%%%%% Plot para validação FRF %%%%%%%%%%
        
        FRF = ita_divide_spk(msAudioInterface{msNumber}.sweepAdjusted, msNI{msNumber}.sweepAdjusted,...
            'mode', 'linear');
        
        fig = figure();
        fredPlot(fig, 16);
        semilogx(FRF.freqVector, FRF.freqData_dB);
                
        title('FRF = MUT / REF')
        xlabel('Frequência [Hz]');
        ylabel('Nível [dB ref. 1]');
        xlim([20, 22050]); grid on;
        
        %%%%%%%%%% Prompt para validação %%%%%%%%%%
        
        prompt = 'Validar a medição? [y/n]\n';
        validate = input(prompt, 's');
        
    end
    
    input('Reposicione o mic e aperte enter para retomar!\n');
    msNumber = msNumber + 1;
    validate = 'n';
    
end

clc;
disp('Medições com o mic MUT finalizadas!')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Salvando

fileName = sprintf('ms.mat');
save(fileName, 'msNI', 'msAudioInterface', 'msExcitation');

disp('Tudo salvo!')
