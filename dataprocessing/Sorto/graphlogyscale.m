function graphlogyscale(~, ~, menuAxes, axesGraph)
    % GRAPHLOGYSCALE Set the Sortomato axes to y-log scaling
    %   Axes context menus children are:
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'linear', 'YScale', 'log')
    
    %% Update the context menu checkbox.
    menuChildren = get(menuAxes, 'Children');
    set(menuChildren, {'Checked'}, {'on'; 'off'; 'off'; 'off'})
end % graphlogyscale