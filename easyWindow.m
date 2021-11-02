% Função para facilitar o janelamento durante o processamento dos dados
% para o trabalho de medição da resposta combinada de alto-falantes.
%
%   Entradas:
%       i) 'input': sinal de entrada (resposta impulsiva - domínio do tempo)
%       ii) 'timeInvertal': [inicio final] da janela em segundos
%       iii) 'windowSize': default é 256 (samples)
%       iv) 'samplingRate': default é 44100
%
%   Saída:
%       output: sinal janelado
%       windowEnvelop: envelope da janela (para plots)
%
%   Felipe Ramos de Mello - 02/11/21 (v1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [output, windowEnvelop] = easyWindow(input, timeInterval, varargin)

%% Input parsing

p = inputParser;

default_windowSize = 256; % samples
default_samplingRate = 44100;

addRequired(p, 'input', @isnumeric);
addRequired(p, 'timeInterval', @isnumeric);

addParameter(p, 'windowSize', default_windowSize, @isnumeric);
addParameter(p, 'samplingRate', default_samplingRate, @isnumeric);

parse(p, input, timeInterval, varargin{:});

%% Checking if input parameters make sense

output = p.Results.input;
windowEnvelop = ones(length(output), 1);

win = hann(p.Results.windowSize);
winStart = p.Results.timeInterval(1);
winStop = p.Results.timeInterval(2);

if (winStop - winStart)*p.Results.samplingRate <= p.Results.windowSize
    error('Window too large for the specified period!!!');
end

if winStop*p.Results.samplingRate > length(input)
    error('Upper time interval exceeds the signal range!!!');
end

%% Window first half

if winStart == 0
    startSample = 1;
else
    startSample = floor(winStart*p.Results.samplingRate);
end

if startSample == 1
    % Janela a RI
    output(startSample:(startSample + p.Results.windowSize/2 - 1)) =...
        output(startSample:(startSample + p.Results.windowSize/2 - 1)).*...
        win(1:p.Results.windowSize/2);
    
    % Prepara o envelope
    windowEnvelop(startSample:(startSample + p.Results.windowSize/2 - 1)) =...
        windowEnvelop(startSample:(startSample + p.Results.windowSize/2 - 1)).*...
        win(1:p.Results.windowSize/2);
else
    % Janela a RI
    output(1:startSample - 1) = 0;
    
    output(startSample:(startSample + p.Results.windowSize/2 - 1)) =...
        output(startSample:(startSample + p.Results.windowSize/2 - 1)).*...
        win(1:p.Results.windowSize/2);
    
    % Prepara o envelope
    windowEnvelop(1:startSample - 1) = 0;
    
    windowEnvelop(startSample:(startSample + p.Results.windowSize/2 - 1)) =...
        windowEnvelop(startSample:(startSample + p.Results.windowSize/2 - 1)).*...
        win(1:p.Results.windowSize/2);
end

%% Window last half

stopSample = floor(winStop*p.Results.samplingRate);

if stopSample == length(input)
    % Janela a RI
    output((stopSample-p.Results.windowSize/2):stopSample) = ...
         output(stopSample-p.Results.windowSize/2:stopSample).*...
         win(p.Results.windowSize/2:end);
     
     % Prepara o envelope
     windowEnvelop((stopSample-p.Results.windowSize/2):stopSample) = ...
         windowEnvelop(stopSample-p.Results.windowSize/2:stopSample).*...
         win(p.Results.windowSize/2:end);
else
    % Janela a RI
    output((stopSample-p.Results.windowSize/2):stopSample) = ...
         output(stopSample-p.Results.windowSize/2:stopSample).*...
         win(p.Results.windowSize/2:end);
     
    output(stopSample+1:end) = 0;
    
    % Prepara o envelope
    windowEnvelop((stopSample-p.Results.windowSize/2):stopSample) = ...
         windowEnvelop(stopSample-p.Results.windowSize/2:stopSample).*...
         win(p.Results.windowSize/2:end);
     
    windowEnvelop(stopSample+1:end) = 0;
    
end


%% EOF

end