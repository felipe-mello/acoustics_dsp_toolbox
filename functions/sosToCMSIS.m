%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This functions receives an SOS matrix (from an IIR filter) and formats it
% to the CMSIS standard (for Teensy implementation)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function

function sosToCMSIS(sosMatrix, scaleValue)

% Aqui realizo uns ajustes para que os coeficientes fiquem de acordo com o
% padrão da biblioteca CMSIS
coeffs = sosMatrix(:, [1:3 5:6]); % Retiro a0 
coeffs(:, 4:5) = -1*coeffs(:, 4:5); % Inverto o sinal de a1 e a2
coeffs(:, 1:3) = coeffs(:, 1:3).*scaleValue(1:end-1); % Aplico o ganho

% Imprimo no command window os coeficientes no formato adequado para
% aplicar diretamente ao objeto de áudio do Teensy
clc;
for i = 1:size(coeffs,1)
    fprintf('%.18f, %.18f, %.18f, %.18f, %.18f,\n', coeffs(i, :));
end

end