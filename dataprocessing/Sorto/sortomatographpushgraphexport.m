function sortomatographpushgraphexport(~, ~, hSortomatoGraph)
    % SORTOMATOGRAPHPUSHGRAPHEXPORT Export the current graph
    %   Detailed explanation goes here
    %
    %  �2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Get the Imaris source file information.
    xImarisApp = getappdata(hSortomatoGraph, 'xImarisApp');
    [filePath, fileName] = fileparts(char(xImarisApp.GetCurrentFileName));
    
    xObject = getappdata(hSortomatoGraph, 'xObject');
    
    exportName = [fileName ' - ' char(xObject.GetName) ' Graph.eps'];

    %% Have the user specify the file information.
    [graphFile, graphFolder] = uiputfile({
        '*.bmp', 'Bitmap (.bmp)'; 
        '*.emf', 'Windows Metafile (*.emf)'; 
        '*.eps', 'Encapsulated PostScript (*.eps)'; 
        '*.hdf', 'Hierarchical Data Format (*.hdf)'; 
        '*.jpg', 'JPEG (*.jpg)'; 
        '*.pdf', 'Adobe Acrobat File (*.pdf)'; 
        '*.png', 'Portable Network Graphics (*.png)'; 
        '*.pptx', 'Powerpoint (*.pptx)';
        '*.tif', 'TIFF (*.tif)'}, ...
        'Save Graph', fullfile(filePath, exportName));

    %% If the user doesn't cancel, write the file in the requested format.
    if ischar(graphFile)
        % Get the file format.
        [~, ~, fileFormat] = fileparts(graphFile);

        % Write the file to the matching format.
        switch fileFormat(2:end)

            case 'bmp'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dbmp', '-noui', '-painters', '-r300')

            case 'emf'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dmeta', '-noui', '-painters')
                
            case 'eps'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-depsc2', '-noui', '-painters')

            case 'hdf'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dhdf', '-noui', '-painters', '-r300')

            case 'jpg'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-djpeg', '-noui', '-painters', '-r300')

            case 'pdf'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dpdf', '-noui', '-painters')

            case 'pptx'
                % Hide the status bar during export.
                hStatus = statusbar(hSortomatoGraph, '');
                hStatus.setVisible(false)
                
                % Close any open file.
                if ~isempty(exportToPPTX)
                    exportToPPTX('close');
                end % if
                
                % Open or create the file and add a slide for the figure.
                if exist(fullfile(graphFolder, graphFile), 'file')
                    exportToPPTX('open', fullfile(graphFolder, graphFile))
                    
                else
                    exportToPPTX(...
                        'new', ...
                        'Dimensions', [10 7.5], ...
                        'Comments', 'Sortomato graph generating using exportToPPTX', ...
                        'Title', 'Sortomato graph')
                    
                end % if
                
                % Add a slide to the file.
                exportToPPTX('addslide', ...
                    'BackgroundColor', get(hSortomatoGraph, 'Color'));

                % Make sure the figure is at least partially on screen
                % before getting the frame.
                monitorPos = get(0, 'MonitorPositions');
                if size(monitorPos, 1) > 1
                    figPos = get(hSortomatoGraph, 'Position');

                    tempPos = [...
                        monitorPos(1, 3) - figPos(3) - 50
                        monitorPos(1, 4) - figPos(4) - 50
                        figPos(3)
                        figPos(4)];

                    set(hSortomatoGraph, 'Position', tempPos)

                    exportToPPTX(...
                        'addpicture', hSortomatoGraph)                        

                    set(hSortomatoGraph, 'Position', figPos);

                else
                    exportToPPTX(...
                        'addpicture', hSortomatoGraph)                        

                end % if
                                        
                % Save to Powerpoint.
                exportToPPTX('save', fullfile(graphFolder, graphFile))
                exportToPPTX('close')
                    
                % Restore the status bar.
                hStatus.setVisible(true)
                
            case 'png'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dpng', '-noui', '-painters', '-r300')

            case 'tif'
                print(hSortomatoGraph, fullfile(graphFolder, graphFile), ...
                    '-dtiff', '-noui', '-painters', '-r300')

        end % switch
    end % if
end % sortomatographpushgraphexport