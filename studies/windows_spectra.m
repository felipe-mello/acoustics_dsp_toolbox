%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Compreender que um janelamento temporal implica em convoluir o espectro
%   do sinal original com o espectro da janela ajuda a entender pq existe o
%   efeito de espalhamento e vazamento. Em suma, é como se "vestíssemos"
%   cada componente de frequência do sinal original com a "roupa" da
%   janela. Assim, quão mais estreito for o lóbulo central do espectro da
%   janela, menor será o efeito de espalhamento (ou seja, será possível
%   identificar cada frequência com mais precisão). Agora, quão menores
%   forem os lóbulos laterais, menor será o vazamento.
%
%   Nessa rotina eu ploto o espectro de algumas janelas comuns. É possível
%   verificar que a retangular possui o lóbulo central mais estreito, porém
%   é o que possui os maiores lóbulos laterais. As demais sempre buscam um
%   compromisso entre essas duas características, mas nunca chegando num
%   lóbulo central tão estreito quanto à retangular.
%
%   Cabe lembrar que TODO sinal digital, em essência, foi janelado
%   temporalmente e também na frequência (pois observamos-o por uma parcela
%   de tempo e, para evitar aliasing, ele foi filtrado com um
%   passa-baixas).
%
%   Felipe Ramos de Mello - 24/05/22
%
%% Deep meditation

clear all; clc; close all;

%% Espectro de algumas janelas

nfft = 2.^21;
N = 8192;
w = hann(N);
w2 = blackman(N);
w3 = bartlett(N);
ret = rectwin(N);

W = fftshift(fft(w, nfft)); W = W./max(abs(W));
W2 = fftshift(fft(w2, nfft)); W2 = W2./max(abs(W2));
W3 = fftshift(fft(w3, nfft)); W3 = W3./max(abs(W3));
RET = fftshift(fft(ret, nfft)); RET = RET./max(abs(RET));

f = linspace(-1, 1, nfft);

fig = figure(1);
fredPlot(fig, 16);
plot(f, RET); hold on;
plot(f, W); hold on;
plot(f, W2); hold on;
plot(f, W3); hold on;
xlim([-0.004, 0.004]);

legend('ret', 'hann', 'blackman', 'bartlett');
