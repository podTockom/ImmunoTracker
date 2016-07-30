clear
load ('DCs_tracks.mat');

figure(1)
clf
%plot number of tracked cells at each time point
allData = cell2mat(tracks);
histogram([allData.t], range([allData.t])+1)

deltaTh = deltaTmin / 60;
%sliding window on each track
%look at only initial balistic regeime
tMinIndex = 1;
tMaxIndex = 8;
deltaTIndices = 1:6;
%each entry is a vector of values for a single deltaT
displacementsSq = cell(length(deltaTIndices),1 );
for trackIndex = 1:length(tracks)
% trackIndex = 8;
    track = tracks{trackIndex};
    if track(1).t + 1 > tMaxIndex
        continue; %track starts after window ends
    elseif  track(end).t + 1 < tMinIndex
        continue; %track ends before window starts
    end
    firstTimeIndex = find([track.t] == tMinIndex - 1);
    lastTimeIndex = find([track.t] == tMaxIndex - 1);
    if isempty (firstTimeIndex)
        firstTimeIndex = track(1).t + 1;
    end
    if isempty (lastTimeIndex)
        lastTimeIndex = track(end).t + 1;
    end
    for dt = deltaTIndices
        trackDisplacementsSq = zeros (lastTimeIndex-dt,1);
        for windowStartIndex = firstTimeIndex:lastTimeIndex-dt
            trackDisplacementsSq(windowStartIndex) = sum((track(windowStartIndex).xyz - track(windowStartIndex+dt).xyz).^2);
        end
        displacementsSq{dt} = [displacementsSq{dt}; trackDisplacementsSq];
    end
    
end
deltaTs = deltaTIndices * deltaTh;
avgDisp = cellfun(@mean,displacementsSq);
stdError = cellfun(@std,displacementsSq) ./ sqrt (cellfun(@length,displacementsSq));
errorbar([0 deltaTs], [0 avgDisp'], [0 stdError'], 'ko')
axis tight
%least squares weights based on 
lsWeights = 1./ stdError.^2;
%fit power law
fun = @(b,deltaT) b(1)*deltaT.^b(2);
b0 = [1000,1];

nlm1 = fitnlm(deltaTs,avgDisp',fun,b0,'Weight',lsWeights);
fitXVals = linspace(0,deltaTs(end),1000);
fitYVals = predict(nlm1,fitXVals');
hold on 
plot(fitXVals,fitYVals,'b-')
plot([0 deltaTs(end)],[0 avgDisp(end)],'r--')
hold off
legend('Data','Fit','Linear')
xlabel('\Deltat (h)')
ylabel('Displacement.^2 (\mum^2)')

ci = coefCI(nlm1);
annotation('textbox',[.2 .6 .3 .3],'String',...
    sprintf('Fit: x^2 = %0.0f*\\Deltat^{%0.2f}\n95 CI: %0.2f-%0.2f',...
    nlm1.Coefficients.Estimate(1),nlm1.Coefficients.Estimate(2),ci(2,1),ci(2,2)),'FitBoxToText','on','FontSize',20);

exportPlot('Initial Motility')
