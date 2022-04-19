% Testando a sequência de sweeps
%

function excitation = chirpSequence(fftDeg, silenceDuration)

%% Calculo das frequências centrais

centerFreqs = [16 250 500 1000 2000 4000 8000 16000 20000];
gainAdjust = [5.5 2.5 2.85 3.6 15 25 44 50];
% gainAdjust = [0.5 0.5 0.85 1.6 7.94 25 44 50];
%% Sequência de sweeps

clc;
nSamples = 2^fftDeg;
sweepSeq = zeros(nSamples, length(centerFreqs)-1);

for i = 1:length(centerFreqs) - 2
    sweep = ita_generate_sweep('fftDegree', fftDeg,...
        'freqRange', [centerFreqs(i) (centerFreqs(i+1) + (centerFreqs(i+2)))/2],...
        'bandwidth', 1/8 , 'stopMargin', 0, 'mode', 'linear');
    
    sweepSeq(:, i) = gainAdjust(i)*easyWindow(sweep.timeData, [0 sweep.trackLength],...
        'windowSize', 8096);
end

%%%% Silêncio

silence = zeros(silenceDuration*44100, 1);

%%%% Montando o sinal completo

excitation = [];
for i = 1:length(centerFreqs) - 1
    sweepPlusSilence = [sweepSeq(:, i); silence];
    excitation = [excitation; sweepPlusSilence];
end

excitation = ita_normalize_dat(itaAudio(excitation, 44100, 'time'));

