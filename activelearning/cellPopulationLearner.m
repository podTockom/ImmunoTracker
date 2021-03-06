function [  ] = cellPopulationLearner(  )
%ACTIVELEARNINGCLASSIFIER Master function for querying user and classifying surfaces
% This function loads an unlabelled nxp data matrix and prompts the user
% for labeling of examples so that it can learn and generalize to the full
% dataset as fast as possible
%
%
% CONTROLS:
% 1 - Enter active learning mode: begin presenting unlabelled examples at
% current time point
% 2 - Classify and visualize all instances at current time point
% 3 - Activate crosshair selection mode to manually select an instance to
% classify (needed if for example, the active learning struggles with a
% particular cell
% y - Yes the currently presented instance show be laballed as a T cell
% n - No the currently presented instance in not a T cell

%start parallel pool for training NN
% parpool;

dataFile = '/Users/henrypinkard/Google Drive/Research/BIDC/LNImagingProject/data/e670FeaturesAndLabels.mat';
surfaceFile = '/Users/henrypinkard/Desktop/LNData/e670Candidates.mat';
%load features and known labels
featuresAndLabels = matfile(dataFile,'Writable',false);
%Load surface data into virtual memory
surfaceData = matfile(surfaceFile,'Writable',false);

%createLabels for cells of interest

%TODO: create this from scratch or pull from a small labelled subset
coiIndices = featuresAndLabels.labelledTCell + 1;
ncoiIndices = featuresAndLabels.labelledNotTCell + 1;
%pull nxp feature matrix and imaris indices in memory
features = featuresAndLabels.features;
imarisIndices = featuresAndLabels.imarisIndices;

%Connect to Imaris
[ xImarisApp, xPopulationSurface, xSurfaceToClassify ] = xtSetupSurfaceTransfer(  );
xSurpassCam = xImarisApp.GetSurpassCamera;

%make functions for manipulating view
[quatMult,quatRot,rotVect2Q] = makeQuaterionFunctions();

%create figure for key listening
figure(1);
title('Imaris bridge');
set(gcf,'KeyPressFcn',@keyinput);
surfaceClassicationIndex_ = -1;

%train initial classifier
classifier = retrain();


%Controls
    function [] = keyinput(~,~)
        key = get(gcf,'CurrentCharacter');
        if strcmp(key,'1')
            % Enter active learning mode: begin presenting unlabelled examples at current time point
            presentNextExample();
        elseif strcmp(key,'2')
            % 2 - Classify and visualize all instances at current time point
            fprintf('Classifying all surfaces at current time point...\n');
            predictCurrentTP();
            
        elseif strcmp(key,'3')
            % 3 - Activate crosshair selection mode to manually select an instance to classify
            
        elseif strcmp(key,'y')
            %Yes the currently presented instance show be laballed as a T cell
            coiIndices = unique([coiIndices; surfaceClassicationIndex_]);
            classifier = retrain();
            presentNextExample();
        elseif strcmp(key,'n')
            %Yes the currently presented instance show be laballed as a T cell
            ncoiIndices = unique([ncoiIndices; surfaceClassicationIndex_]);
            classifier = retrain();
            presentNextExample();
        end
    end

    function [cls] = retrain()
        %train classifier
        cls = trainClassifier([features(coiIndices,:); features(ncoiIndices,:)],...
            [ones(length(coiIndices),1); zeros(length(ncoiIndices),1)]);
    end

    function [] = predictCurrentTP()
        retrain();
        %delete all predeicted surfaces from imaris
        xPopulationSurface.RemoveAllSurfaces;
        %run classifier on instances at current TP
        currentTPMask = xImarisApp.GetVisibleIndexT == featuresAndLabels.timeIndices;
        currentTPPred = classify( classifier, features, currentTPMask, coiIndices, ncoiIndices);
        
        %generate mask for predicted cells of interest at current TP
        currentTPIndices = find(currentTPMask);
        coiAtCurrentTPIndices = currentTPIndices(currentTPPred);
        %send to Imaris
        func_addsurfacestosurpass(xImarisApp,surfaceData,100, xPopulationSurface,imarisIndices(coiAtCurrentTPIndices));
    end

    function [] = presentNextExample()
        %find most informative example at this time point (that arent
        %already labelled)
        unlabelledAtCurrentTP = xImarisApp.GetVisibleIndexT == featuresAndLabels.timeIndices;
        unlabelledAtCurrentTP([coiIndices; ncoiIndices]) = 0;
        [~, currentTPPredValue] = classify( classifier, features, unlabelledAtCurrentTP, coiIndices, ncoiIndices);
        
        surfaceClassicationIndex_ = nextSampleToClassify( currentTPPredValue, unlabelledAtCurrentTP );
        %remove exisiting surfaces to classify
        xSurfaceToClassify.RemoveAllSurfaces;
        func_addsurfacestosurpass(xImarisApp,surfaceData,1, xSurfaceToClassify,imarisIndices(surfaceClassicationIndex_));
        centerToSurface(xSurfaceToClassify);
    end

    function [] = centerToSurface(surface)
        %surpass camera parameters:
        %height--distance from the object it is centered on, changes with zoom but not with rotation
        %position--camera position, not related to center of rotation
        %focus--seemingly not related to anything... (maybe doesn't matter for orthgraphic)
        %Fit will fit viewing frame around entire image...which will in turn set the center of rotation to the center of image
        
        %get initial height for resetting
        height = xSurpassCam.GetHeight;
        %Oreint top down
        xSurpassCam.SetOrientationQuaternion(quatRot(pi,[1; 0; 0])); %top down view
        %Make center of rotation center of entire image
        xSurpassCam.Fit;
        currentCamPos = xSurpassCam.GetPosition;
        previewPos = surface.GetCenterOfMass(0);
        xSurpassCam.SetPosition([previewPos(1:2), currentCamPos(3) ]); %center camera to position of preview surface
        xSurpassCam.SetHeight(height);
        %make sure preview is visible
        surface.SetVisible(true);
    end

    function [ xImarisApp, xPopulationSurface, xSurfaceToClassify ] = xtSetupSurfaceTransfer(  )
        previewName = 'Preview surface';
        populationName = 'Cells of interest';
        surfaceToClassifyName ='SurfaceToClassify';
        
        xtIndex = 0;
        javaaddpath('../xt/ImarisLib.jar')
        vImarisLib = ImarisLib;
        xImarisApp = vImarisLib.GetApplication(xtIndex);
        if (isempty(xImarisApp))
            error('Wrong imaris index');
        end
        
        xSurpass = xImarisApp.GetSurpassScene;
        %delete old surface preview
        for i = xSurpass.GetNumberOfChildren - 1 :-1: 0
            if (strcmp(char(xSurpass.GetChild(i).GetName),previewName) || strcmp(char(xSurpass.GetChild(i).GetName),populationName)...
                    || strcmp(char(xSurpass.GetChild(i).GetName),surfaceToClassifyName))
                xSurpass.RemoveChild(xSurpass.GetChild(i));
            end
        end
        xPopulationSurface = xImarisApp.GetFactory.CreateSurfaces;
        xPopulationSurface.SetName(populationName);
        xSurpass.AddChild(xPopulationSurface,-1);
        xSurfaceToClassify = xImarisApp.GetFactory.CreateSurfaces;
        xSurfaceToClassify.SetName(surfaceToClassifyName);
        xSurpass.AddChild(xSurfaceToClassify,-1);
        xSurfaceToClassify.SetColorRGBA(16646399); %teal
        xPopulationSurface.SetColorRGBA(16711424); %magenta
    end

    function [quatMult,quatRot,rotVect2Q] = makeQuaterionFunctions()
        % quaternion functions %
        %multiply 2 quaternions
        quatMult = @(q1,q2) [ q1(4).*q2(1:3) + q2(4).*q1(1:3) + cross(q1(1:3),q2(1:3)); q1(4)*q2(4) - dot(q1(1:3),q2(1:3))];
        %generate a rotation quaternion
        quatRot = @(theta,axis) [axis / norm(axis) * sin(theta / 2); cos(theta/2)];
        %Rotate a vector and return a quaternion, which then needs to be subindexed to get a vector again
        rotVect2Q = @(vec,quat) quatMult(quat,quatMult([vec; 0],[-quat(1:3); quat(4)]));
    end

end