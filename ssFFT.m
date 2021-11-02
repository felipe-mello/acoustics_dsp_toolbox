%   This functions receives a time domain signal and returns its single sided spectrum
%	with amplitude correction.
%
%       Required inputs;
%           i) time domain signal;
%           ii) signal's sampling frequency
%           
%       Optional inputs:
%           i) nfft: number of fft points (should be equal or greater than
%           the signal's length
%
%           ii) amp_mode: defines the amplitude correction. The following
%           options are available -> 'peak', 'rms' and 'power'. They return
%
%           iii) phase_mode: defines if phase is returned in radians or
%           degrees -> arguments: 'degress', 'radians'
%
%       Usage example:
%
%           [Y, phase, freqVec, info] = ssFFT(signal, fs, 'nfft', length(signal)*2, 'amp_mode', 'rms', 'phase_mode', 'radians');
%
%	For more information regarding FFT-based signal analysis, please check out this article from National Instruments:
%		https://www.sjsu.edu/people/burford.furman/docs/me120/FFT_tutorial_NI.pdf
%
%   Felipe Ramos de Mello - 20/10/21
%%

%ssFFT(signal, fs, nfft, amp_mode, phase_mode)

function [spectrum, phase, freqVec, rawSpectrum, info] = ssFFT(signal, fs, varargin)

%% Input parsing

% For more info regarding parsing, see: https://www.mathworks.com/help/matlab/matlab_prog/parse-function-inputs.html

p = inputParser;

defaultAmp_mode = 'rms';
validAmp_modes = {'peak', 'rms', 'power', 'complex'};
checkAmp_mode = @(x) any(validatestring(x, validAmp_modes));

defaultPhase_mode = 'radians';
validPhase_modes = {'radians', 'degrees'};
checkPhase_mode = @(x) any(validatestring(x, validPhase_modes));

defaultNfft = length(signal);

addRequired(p, 'signal', @isnumeric);
addRequired(p, 'fs', @isnumeric);

addParameter(p, 'nfft', defaultNfft, @isnumeric);
addParameter(p, 'amp_mode', defaultAmp_mode, checkAmp_mode);
addParameter(p, 'phase_mode', defaultPhase_mode, checkPhase_mode);

parse(p, signal, fs, varargin{:});

%% Function

nfft = p.Results.nfft;
signal = p.Results.signal;
fs = p.Results.fs;

signalLen = length(signal);

freqVec = (fs/nfft)*(0:nfft/2); % Frequency vector -> (NFFT/fs) is the resolution in frequency domain

rawSpectrum = fft(signal, nfft)./signalLen; % fft calculation

% Phase calculation
phase = angle(rawSpectrum(1:nfft/2+1));

% Info

info.amp_mode = p.Results.amp_mode;
info.phase_mode = p.Results.phase_mode;
info.nfft = nfft;

if strcmp(p.Results.phase_mode, 'degrees')
	
	phase = rad2deg(phase);

end

% Amplitude spectrum (based on peak values)
if strcmp(p.Results.amp_mode, 'peak')
        
    spectrum = abs(rawSpectrum); % amplitude spectrum in peak values
    spectrum = spectrum(1:nfft/2+1); % select only positive frequencies
    spectrum(2:end-1) = 2*spectrum(2:end-1); % amplitude adjustment
    
end
 
% Amplitde spectrum (based on rms values)
if strcmp(p.Results.amp_mode, 'rms')
    
    spectrum = sqrt(rawSpectrum.*conj(rawSpectrum)); % Magnitude calculation (one could simply use abs(spectrum) too)
    spectrum = spectrum(1:nfft/2+1); % Select just the positive frequencies
    spectrum(2:end-1) = sqrt(2).*spectrum(2:end-1); % Amplitude adjustment (rms value)
    
end

% Power spectrum
if strcmp(p.Results.amp_mode, 'power')
    
    spectrum = rawSpectrum*conj(rawSpectrum); % Magnitude calculation (one could simply use abs(spectrum) too)
    spectrum = spectrum(1:nfft/2+1); % Select just the positive frequencies
    
end

% Complex rms spectrum

if strcmp(p.Results.amp_mode, 'complex')
   
    spectrum = rawSpectrum(1:nfft/2+1); % Select just the positive frequencies
    spectrum(2:end-1) = sqrt(2).*spectrum(2:end-1); % Amplitude adjustment (rms value)
    
end

end