%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Sinal digital e seu espectro (via DFT)
%
%   Para minha apostila de PDS
%
%   Felipe Ramos de Mello - 25/05/22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Deep meditation

clear all; clc; close all;

%% Impulso com decaimento exponencial (transiente)

% O fator de escala para um sinal transiente (que possui energia FINITA) é
% diferente do fator de escala para um sinal periódico (energia INFINITA).
% Para um sinal transiente, desde que a janela de tempo não ofereça muita
% perda energética, o fator de escala é simplesmente o período de
% amostragem (T), uma vez que não há truncamento do sinal (a janela
% temporal não influencia).

% No tempo
fs = 5;
T = 1/fs;
dur = 5;
t = (-dur:1/fs:dur)';
N = length(t);
nfft = N;
idx = find(t==0);

% Espera-se um espectro com pico em f=0 e amplitude 1/alpha
alpha = 1;
x = [zeros(idx-1, 1); ones(N - idx + 1, 1).*exp(-alpha*t(idx:end))];

% Na frequência
X = fftshift(fft(x, nfft))*T;
f = linspace(-0.5, 0.5, nfft);

% Visualização
close all;
plot(f, abs(X), '--'); hold on;
stem(f, abs(X), 'linewidth', 1.3);

%% Sinal senoidal

% O escalonamento de um sinal periódico (e, em verdade, qualquer sinal
% estacionário) está relacionado aos efeitos do truncamento (janelamento
% temporal) e amostragem. No domínio contínuo, a CTFT retorna um espectro
% com duas componentes (conjugadas) com amplitude A/2, sendo A a amplitude
% de pico do sinal senoidal temporal. Para um sinal digital analisado via
% DFT:
%
% i) Janelamento temporal = convolução do espectro do sinal original com a
% sinc function. A amplitude da sinc function é dada por N/fs (sua
% duração) e, com isso, a amplitude do espectro convoluído será A*N/(2*fs)
%
% ii) Amostragem: como para o sinal transiente, o fator de escala neste
% caso é o próprio período de amostragem T = 1/fs
%
% Com isso, a amplitude do espectro retornado pela DFT é dada por
% (A*fs*N)/(2*fs) e o fator de escala é final é 2/N 
% (para todas as freqs exceto a DC e fs/2).

% No tempo
fs = 500;
T = 1/fs;
dur = 10;
t = (-5:1/fs:5)';
N = length(t);
nfft = N;

w = 2*pi*2;
A = 1.4;
x = A.*sin(w*t);

% Na frequência
X = fftshift(fft(x, nfft))*(2/N);
f = linspace(-fs/2, fs/2, nfft);

% Visualização
close all;
plot(f, abs(X), '--'); hold on;
stem(f, abs(X), 'linewidth', 1.3);

