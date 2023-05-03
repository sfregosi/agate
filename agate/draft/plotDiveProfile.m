function plotDiveProfile(locCalcT, savePath)

if nargin < 2
    savePath = [];
end

if nargin < 1 % no locCalcT loaded, so select it
    [file, path] = uigetfile('.mat','Select locCalcT_pam.mat file');
    % path_in = uigetdir('G:\', 'Select instruments profiles folder');
    % path_in = [path_in '\'];
    % path_in = ['G:\score\2015\profiles\' gldr '_' lctn '_' dplymnt '\'];
    load([path file]);
end


ylims = [-1050 10];
xlims = datenum([locCalcT.time(1) locCalcT.time(end)]);

pamOFFC = [0.8 0.8 0.8];
pamONC = [0 0 0];
patchColor = [.8 .8 .8];
% LW = .5;
% cd(path_in)
figure

h = color_line3(locCalcT.time,-locCalcT.depth,locCalcT.pam,locCalcT.pam);
colormap([pamOFFC; pamONC]);
xData = [floor(locCalcT.time(1)):2:ceil(locCalcT.time(end))];
set(gca,'xticklabel',{[]},'XTick',xData,'FontSize',14)
dateformat = 'mm/dd';
datetick('x',dateformat,'keepticks')

ylabel('depth (m)')
xlabel('date')
ylim(ylims);
xlim(xlims)

titleString = input('Figure title string: ','s');
title(titleString,'Interpreter','none');
set(gca,'FontSize',14)
pbaspect([4 1 1])
% set this for opening in illustrator

if ~isempty(savePath)
    savefig([savePath titleString '_diveProfile.fig'])
    fprintf(1, 'pause to resize. resize fig and hit spacebar\n');
    pause
    set(gcf,'Renderer','painters')
    print([savePath titleString '_diveProfile.png'],'-dpng')
    savefig([savePath titleString '_diveProfile.fig'])
end

end

