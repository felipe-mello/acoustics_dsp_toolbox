% Function to adjust figures to my taste (feel free to tweak it to your taste)
%
% 	Input: 'fig' object to be modified
%	Output: N/A
%
% Felipe Mello - 06/10/21
%
%%

function fredPlot(fig, fontSize)

fig.set('DefaultAxesFontSize', fontSize);
fig.set('OuterPosition', [100 100 1200 675]);

end