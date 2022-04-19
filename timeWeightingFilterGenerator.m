% Função para gerar os filtros de ponderação temporal 'Fast' ou 'Slow'
%
% Felipe Ramos de Mello - 10/08/21

%%
% Filtro de ponderação temporal
%   type: string 'Fast' ou 'Slow'
%   fs: taxa de amostragem
function timeFilter = timeWeightingFilterGenerator(type, fs)

if strcmp(type, 'Fast')
    
    timeConstant = 0.125; % Fast
    b = 1/(timeConstant*fs); % Filter coeficients
    a = [1 -exp(-1/(timeConstant*fs))]; % Filter coeficients
    [sos, g] = tf2sos(b, a); % SOS matrix for the biquad filter
    
    timeFilter = dsp.BiquadFilter; % Generate a biquad filter
    timeFilter.SOSMatrix = sos; % Sets the filter's SOS matrix
    timeFilter.ScaleValues = [1 g]; % Adjusts the filter's gain
    
elseif strcmp(type, 'Slow')
    
    timeConstant = 1; % Slow
    b = 1/(timeConstant*fs); % Filter coeficients
    a = [1 -exp(-1/(timeConstant*fs))]; % Filter coeficients
    [sos, g] = tf2sos(b, a); % SOS matrix for the biquad filter
    
    timeFilter = dsp.BiquadFilter; % Generate a biquad filter
    timeFilter.SOSMatrix = sos; % Sets the filter's SOS matrix
    timeFilter.ScaleValues = [1 g]; % Adjusts the filter's gain
    
end

end