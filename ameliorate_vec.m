%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ameliorate_vec é uma função para ajustar um vetor para uma amostragem   %
% constante e/ou similar a um outro vetor.                                %
%                                                                         %
% Entradas:                                                               %
%        vec - vetor original (ordenada) com abscissa tvec                %
%              (pode conter uma ou duas colunas).                         %
%        tvec - abscissa de vec.                                          %
%        fs - nova amostragem do vetor.                                   %
%        Opcionais:                                                       %
%           'ConvVec' - 'yes' ou 'no' [padrão], para converter o          %
%                        vetor vec com uma outra amostravem 'Vec2'.       %
%           'Vec2' - vetor 1D com valores a serem utilizados na conversão.%
%           'Interp' - método a ser utilizado na interpolação,            %
%                     padrão 'makima'                                     %
%                                                                         %
% Saídas:   vec_out - vetor ajustado (ordenada)                           %
%           tvec_out - vetor ajustado (abscissa)                          %
%           vec_out_rs - vetor ajustado sem o processo ConvVec (ordenada) %
%                                                                         %
% Exemplos:                                                               %
% [vec_out, tvec_out] = ameliorate_vec(hd450.right, hd450.freq, 10)       %
% [vec_out, tvec_out] = ameliorate_vec(hd450.right, hd450.freq, 10, ...   %
%                    'ConvVec', 'yes', 'Vec2', freq, 'Interp', 'makima'); %
%                                                                         %
%   Autor (Engenharia Acústica - UFSM):                                   %
%   Professor Dr. William D'Andrea Fonseca                                %
%                                                                         %
%   Atualização: 07/02/2021                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vec_out, tvec_out, vec_out_rs] = ameliorate_vec(vec, tvec, fs, varargin)
%% Verifica entradas
narginchk(3,9) % Mínimo de três argumentos 
dfConvVec = 'no'; dfVec2 = []; dfInterp = 'makima'; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parse de valores de entrada
p = inputParser;
addOptional(p,'ConvVec',dfConvVec); addOptional(p,'Vec2',dfVec2); 
addOptional(p,'Interp',dfInterp);   parse(p,varargin{:});
convvec = p.Results.ConvVec; vec2 = p.Results.Vec2; intp = p.Results.Interp;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Verifica entrada, se está na dimensão certa
if isempty(vec) || isempty(tvec) || isempty(fs) 
 error('Oh Lord, I miss the time when the user read the instructions. =]'); 
end
if ~isa(vec,'itaAudio')
    sz_v = size(squeeze(vec));
    if sz_v(2)>sz_v(1); vec = vec.'; end
    sz = size(squeeze(tvec));
    if sz(2)>sz(1); tvec = tvec.'; end
end
%%%%%%%%%%%%%% Processamento %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Processa entrada % Funciona com dois canais também
if strcmp(convvec,'no')
    [vec_out, tvec_out] = resample(vec(:,1),tvec,fs);
    if sz_v(2)==2
    [vec_out(:,2), ~]   = resample(vec(:,2),tvec,fs);
    end
else
    if isempty(vec2); error('Oh Lord, I miss the time when the user read the instructions. =]'); end
    [vec_out_rs, tvec_out] = resample(vec(:,1),tvec,fs);
    vec_out = interp1(tvec_out,vec_out_rs, vec2, intp);
    if sz_v(2)==2
    [vec_out_rs(:,2), ~] = resample(vec(:,2),tvec,fs);
    vec_out(:,2) = interp1(tvec_out,vec_out_rs(:,2), vec2, intp);        
    end    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('ameliorate_vec: I hope you like your new vector. =]')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EOF