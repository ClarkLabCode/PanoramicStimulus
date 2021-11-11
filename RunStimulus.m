function RunStimulus
    % function executes a psych toolbox stimulus for the flies on the rigs
    path = fileparts(mfilename('fullpath'));
    addpath(genpath(path));
    
    use_lightcrafter = false;
    
    % read in the locations to draw textures in the projectors image
    viewLocs = dlmread(fullfile(path,'view_locs.txt'));
    
    % read in the parameters for the stimulus
    if use_lightcrafter
        paramFileName = 'sin_sweep_lightcrafter.csv';
    else
        paramFileName = 'sin_sweep.csv';
    end
    parameters = GetParamsFromPaths(fullfile(path,paramFileName));
    
    % enable for online anlignment of the location of the windows of
    % the stimulus
    align = false;
   
    % number of frames to run the stimulus for (your monitor is probably at
    % 60 hz)
    Nframes = 600;
    
    % set up initial parameters
    lastFrameChange = 1;
    currEpochNum = 1;
    currParam = parameters(currEpochNum);
    stimulusData = [];
    
    % timing for the graphics card flips
    lastFlipTime = GetSecs();
    
    % initialize OpenGL rendering
    InitializeMatlabOpenGL
    
    % set the window to display the textures on. This should be
    % changed to the monitor number when a projector is attached.
    % You can look that up in display settings or just try out a
    % few. 0 should be all displays attached, 1 the first monitor,
    % and 2 the newly attached projector
    if use_lightcrafter
        windowsScreenId = 2;
    else
        windowsScreenId = 0;
    end
    % set the size of the window (in pixels) to display. This is the size
    % for the projectors we used
    panoRect = [0 0 608 680];
    if use_lightcrafter
        windowId = PsychImaging('OpenWindow',windowsScreenId);
    else
        windowId = PsychImaging('OpenWindow',windowsScreenId,[0 0 0],panoRect);
    end
    Screen('Fillrect',windowId,[0;0;0]);
    
    %% frustrum parameters (position of the fly in the virtual world
    % this function will calculate the view points in the virtual world of
    % the fly. If your fly is above your screens looking down, adjust fly
    % height and head angle accordingly (positive height in mm and positive
    % head angle in degrees). If its in the middle of the screens looking
    % forward, set both to 0
    frustrum = CalculateFrustrum(0,0);
    

    %% clear the screen when it exits
    clearScreen = onCleanup(@() sca);
    
    % keep the flip times to check for dropped frames
    lastFlipTime = 0;
    flipTimeArray = zeros(Nframes,1);
    
    %% giant for loop for every frame
    for frameNum = 1:Nframes
        %% state-machine decides on which parameter set comes next
        framesSinceEpochChange = frameNum - lastFrameChange;
        [currEpochNum,stimChanged] = StateMachine(parameters,currEpochNum,framesSinceEpochChange);

        if stimChanged
            lastFrameChange = frameNum;
            currParam = parameters(currEpochNum);
        end

        %% insert your code for measuring the rotation of the ball here


        %% generate stimuli
        % Generate the texture
        stimFunc = str2func(currParam.stimtype);
        [textureHandle,stimulusData] = stimFunc(currParam,framesSinceEpochChange,stimulusData,windowId);

        % display the texture
        DrawTexture(windowId,textureHandle,frustrum,viewLocs);

        %% align the windows
        % normally this is off, its only used when setting up to make sure
        % you're drawing in the correct region of the image
        if align
            viewLocs = AlignmentAdjust(viewLocs,fullfile(path,'view_locs.txt'));
        end

        %% flip buffers -- v-sync, and across DLPs if possible
        flipTimeArray(frameNum) = Screen('Flip',windowId,lastFlipTime+1/120,[],[],1);
    end
    
    numDroppedFrames = sum(diff(flipTimeArray)>0.02);
    percentDropped = numDroppedFrames/Nframes*100;
    fprintf('\n');
    disp([num2str(percentDropped) '% of frames dropped during presentation']);
end
