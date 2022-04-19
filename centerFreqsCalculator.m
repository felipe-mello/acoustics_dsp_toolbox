% Center frequencies calculator according to ANSI S1.11-2004
%
% Inputs:
%   i) bandwidth (required): any positive integer (usually 1, 3, 6, 12...)
%   ii) base (optional, default = 10): base for the operations (2 or 10)
%   iii) freqRange (optional, default = [15, 21e3])
%
% Outputs:
%   i) centerFreqs: calculated center frequencies
%   ii) edgeFreqs: edge frequencies for each of the center frequencies
%
% Written by Felipe Ramos de Mello - 19/04/22
%
% For more info, check the ANSI S1.11-2004 standard
%%
function [centerFreqs, edgeFreqs, nominalFc] = centerFreqsCalculator(bandwidth, varargin)

%% Input parsing

p = inputParser;

default_base = 10;
default_freqRange = [15, 21e3];

isPositiveInteger = @(n) (rem(n,1) == 0) & (n > 0);
checkBase = @(n) (n==10 | n==2);

addRequired(p, 'bandwidth', isPositiveInteger);
addParameter(p, 'base', default_base, checkBase);
addParameter(p, 'freqRange', default_freqRange, @isnumeric);

parse(p, bandwidth, varargin{:});

%% Function

bandwidth = p.Results.bandwidth;
base = p.Results.base;
freqRange = p.Results.freqRange;

switch base
    case 2
        G = 2;
    case 10
        G = 10^(3/10);
end


Fmax = 0;
centerFreqs = zeros(500, 1);

% Based on ANSI
if rem(bandwidth, 2)~=0
    
    k = round(bandwidth*log(freqRange(1)/1000)/log(G) + 59/2);
    
    while Fmax < freqRange(2)
        centerFreqs(k) = 1000*(G^((k-30)/bandwidth));
        k = k+1;
        Fmax = max(centerFreqs);
    end
    
else
    
    k = round(30 + (bandwidth*log(freqRange(1)/1000))/log(G));
    
    while Fmax < freqRange(2)
        centerFreqs(k) = 1000*(G^((2*k-59)/(2*bandwidth)));
        k = k+1;
        Fmax = max(centerFreqs);
    end
end

centerFreqs(centerFreqs < freqRange(1)) = [];
centerFreqs(centerFreqs > freqRange(2)) = [];

nominalFc_1 = ita_sd_round(centerFreqs, 5);
nominalFc_2 = ita_sd_round(centerFreqs, 100);

idx = find(abs(100*(1-nominalFc_1./nominalFc_2)) < 4);

nominalFc = nominalFc_1;
nominalFc(idx) = nominalFc_2(idx);

edgeFreqs = zeros(length(centerFreqs), 2);
edgeFreqs(:, 1) = centerFreqs * G^(-1/(2*bandwidth));
edgeFreqs(:, 2) = centerFreqs * G^(1/(2*bandwidth));

%% Nominal center freqs

% From ita_ANSI_center_frequencies function (ITA Toolbox)
function A2 = ita_sd_round(A,mult)
N = 3;

% Digit furthest to the left of the decimal point
D1   = ceil(log10(abs(A)));
buf1 = D1( abs(A)-10.^D1 == 0)+1;
D1( abs(A)-10.^D1 == 0) = buf1;

% rounding factor
dec=10.^(N-D1);

% Rounding Computation
buf=dec./mult;
A2=1./buf.*round(buf.*A);
A2(A==0)=0;
end

end