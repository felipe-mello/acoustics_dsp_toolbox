% Essa função recebe um itaAudio e calcula o Leq em broadband para um
% período de integração definido pelo usuário
%
%
%   To do:
%       - Adicionar ponderação temporal e em frequência
%       - Organizar a descrição
%       - Input parsing
%
%% Função

function [output, timeVector] = itaSPL(input, timePeriod, plotYorN)

samplesPerBlock = input.samplingRate * timePeriod;
nBlocks = floor(input.nSamples / samplesPerBlock);
output = zeros(nBlocks + 1, input.nChannels);

firstCounter = 1;
lastCounter = samplesPerBlock;

timeVector = 0:timePeriod:nBlocks * timePeriod';

h = waitbar(0, 'Calculating the Leq per blocks...');

for num = 2:nBlocks + 1
    slice = input.timeData(firstCounter:lastCounter, 1);
    output(num, 1) = 20*log10(rms(slice)/2e-5);
    firstCounter = lastCounter + 1;
    lastCounter = lastCounter + samplesPerBlock;
    
    waitbar(num/nBlocks, h, 'Calculando LAeq por blocos...');
end

close(h);

if plotYorN
    fig = figure();
    fredPlot(fig, 16);
   
    plot(timeVector, output, 'linewidth', 2);
    title(sprintf('Leq integrado por %d segundos', timePeriod));
    
    xlabel('Tempo [s]');
    ylabel('SPL [dB ref. 20uPa]');
    grid on;
end
    
end