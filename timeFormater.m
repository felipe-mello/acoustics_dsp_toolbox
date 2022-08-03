%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Essa função recebe um valor em segundos e retorna formatado como
% 00h00m00s. Pode ser útil em certas aplicações.
%
% Felipe Ramos de Mello
%
% 16/07/22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

function timePeriodFormated = timeFormater(timeInSeconds)

seconds = floor(rem(timeInSeconds, 60));
minutes = rem(floor(timeInSeconds/60), 60);
hours = floor(timeInSeconds/3600);

timePeriodFormated = [sprintf('%dh:', hours)...
printDigits(minutes) sprintf('m:')...
printDigits(seconds) sprintf('s')];

function digits = printDigits(time)

if time < 10
    digits = sprintf('0%d', time);
else
    digits = sprintf('%d', time);
end

end

end

