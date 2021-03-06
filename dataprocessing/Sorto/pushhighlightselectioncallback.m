function pushhighlightselectioncallback(~, ~, xImarisApp, xObject, axesGraph, sortomatoGraph)
   
    
    iSelection = xObject.GetSelectedIndices;
    
    xFactory = xImarisApp.GetFactory;
    if xFactory.IsSurfaces(xObject)
        xIDs = 0:xObject.GetNumberOfSurfaces - 1;
    
    else
        xSpotNumber = numel(xObject.GetIndicesT);
        xIDs = 0:xSpotNumber - 1;
        
    end % if
    
    %get statStruct of figure to convert imaris indices to data indices
    statStruct = getappdata(sortomatoGraph,'statStruct');
    xIDs = double(statStruct(1).Ids);
    
    rgnColorMask = ismember(xIDs, iSelection);
    xColor = rgb32bittotriplet(xObject.GetColorRGBA);

    
    hScatter = getappdata(axesGraph, 'hScatter');
    xData = getappdata(axesGraph, 'xData');
    yData = getappdata(axesGraph, 'yData');

    set(hScatter(1), ...
        'MarkerFaceColor', xColor, ...
        'XData', xData(~rgnColorMask), ...
        'YData', yData(~rgnColorMask))

    delete(findobj(axesGraph, 'Tag', 'hScatter2'))
    hScatter(2) = line(...
        'LineStyle', 'none', ...
        'Marker', 'd', ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', 1 - xColor, ...
        'MarkerSize', 3, ...
        'Parent', axesGraph, ...
        'Tag', 'hScatter2', ...
        'XData', xData(rgnColorMask), ...
        'YData', yData(rgnColorMask));
    uistack(hScatter, 'bottom')

    %% Store the region color mask and scatter handle array.
    setappdata(axesGraph, 'rgnColorMask', rgnColorMask)
    setappdata(axesGraph, 'hScatter', hScatter);
end % pushhighlightselectioncallback