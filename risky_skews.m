% Copyright (c) 2012 Aaron Roth
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
%

function risky_skews(monkeysInitial)
    % ---------------------------------------------- %
    % -------------- Global variables -------------- %
    % ---------------------------------------------- %
    
    % Colors.
    colorBackground = [0 0 0];
    colorCyan       = [0 255 255];
    colorGrey       = [128 128 128];
    colorYellow     = [255 255 0];
    colorWhite      = [255 255 255];
    
    % Coordinates.
    centerX         = 512;                  % X pixel coordinate for the screen center.
    centerY         = 384;                  % Y pixel coordinate for the screen center.
    endsBoundAdj    = 384;                  % Coordinate adjustment.
    hfWidth         = 88;                   % Half the width of the fixation boxes.
    imageWidth      = 300;                  % The width of the presented images.
    imageHeight     = 400;                  % The height of the presented images.
    sideBoundAdj    = 211;                  % Coordinate adjustment.
    
    % Fixation boundaries for the fixation dot.
    fixBoundXMax    = centerX + hfWidth;
    fixBoundXMin    = centerX - hfWidth;
    fixBoundYMax    = centerY + hfWidth;
    fixBoundYMin    = centerY - hfWidth;
    
    % Fixation bondaries for the left stimulus.
    leftBoundXMax   = 2 * centerX - 4 * hfWidth - imageWidth;
    leftBoundXMin   = centerX - imageWidth - sideBoundAdj;
    leftBoundYMax   = centerY + endsBoundAdj;
    leftBoundYMin   = centerY - endsBoundAdj;
    
    % Fixation boundaries for the right stimulus.
    rightBoundXMax  = centerX + imageWidth + sideBoundAdj;
    rightBoundXMin  = 4 * hfWidth + imageWidth;
    rightBoundYMax  = centerY + endsBoundAdj;
    rightBoundYMin  = centerY - endsBoundAdj;
    
    % Coordinates for drawing the left stimulus image. 
    leftStimXMax    = centerX - 2 * hfWidth;
    leftStimXMin    = centerX - 2 * hfWidth - imageWidth;
    leftStimYMax    = centerY + imageHeight / 2;
    leftStimYMin    = centerY - imageHeight / 2;
    
    % Coordinates for drawing the right stimulus image.
    rightStimXMax   = centerX + 2 * hfWidth + imageWidth;
    rightStimXMin   = centerX + 2 * hfWidth;
    rightStimYMax   = centerY + imageHeight / 2;
    rightStimYMin   = centerY - imageHeight / 2;
    
    % Coordinates for drawing the left grey bar.
    leftGreyXMax    = centerX - 2 * hfWidth - imageWidth / 3;
    leftGreyXMin    = centerX - 2 * hfWidth - imageWidth + imageWidth / 3;
    leftGreyYMax    = centerY + imageHeight / 2;
    leftGreyYMin    = centerY - imageHeight / 2;
    
    % Coordinates for drawing the right grey bar.
    rightGreyXMax   = centerX + 2 * hfWidth + imageWidth - imageWidth / 3;
    rightGreyXMin   = centerX + 2 * hfWidth + imageWidth / 3;
    rightGreyYMax   = centerY + imageHeight / 2;
    rightGreyYMin   = centerY - imageHeight / 2;
    
    % References.
    monkeyScreen    = 1;                    % Number of the screen the monkey sees.
    trackedEye      = 2;                    % Values: 1 (left eye), 2 (right eye).
    
    % Rewards.
    r40             = 0.03;
    r60             = 0.05;
    r80             = 0.07;
    r110            = 0.09;
    r160            = 0.11;
    r170            = 0.12;
    r180            = 0.13;
    
    % Reward distributions.
    distA           = [r40, r60, r80, r80, r170, r170, r180];
    distB           = [r40, r60, r60, r160, r160, r170, r180];
    
    % Saving.
    data            = struct([]);           % Workspace variable where trial data is saved.
    riskySkewsData  = '/Data/RiskySkews';   % Directory where .mat files are saved.
    saveCommand     = NaN;                  % Command string that will save .mat files.
    varName         = 'data';               % Name of the variable to save in the workspace.
    
    % Stimuli.
    feedThick       = 10;                   % Thickness of the feedback border.
    dotRadius       = 10;                   % Radius of the fixation dot.
    fixAdj          = 1;                    % Adjustment made to fixation dot size.
    
    % Times.
    chooseFixTime   = 0.5;                  % Time needed to look at option to select it.
    successDispTime = 0.2;                  % Time that successful selection feedback is given.
    holdFixTime     = 0.100;                % Time fixation must be held with options present.
    ITI             = 2;                    % Intertrial interval.
    minFixTime      = 0.1;                  % Minimum time monkey must fixate to start trial.
    timeToFix       = intmax;               % Amount of time monkey is given to fixate.
    
    % Trial.
    currTrial       = 0;                    % Current trial.
    currTrialType   = '';                   % Whether the trial is AB, AC, or BC.
    inHoldingState  = true;                 % Whether or not in holding fixation state.
    repeatTrial     = false;                % Determines whether a trial has to be repeated.
    rewardOnLeft    = 0;                    % Reward duration given for a left choice.
    rewardOnRight   = 0;                    % Reward duration given for a right choice.
    screenFlip      = true;                 % Whether or not the screen should be "flipped."
    stimOnLeft      = '';                   % What stimulus is presented on the left.
    stimOnRight     = '';                   % What stimulus is presented on the right.
    
    % ---------------------------------------------- %
    % ------------------- Setup -------------------- %
    % ---------------------------------------------- %
    
    % Saving.
    %prepare_for_saving;
    
    % Window.
    window = setup_window;
    
    % Eyelink.
    setup_eyelink;
    
    % Load images.
    imgForest = imread('images/forest.jpg', 'jpg');
    imgMounts = imread('images/mountains.jpg', 'jpg');
    
    % ---------------------------------------------- %
    % ------------ Main experiment loop ------------ %
    % ---------------------------------------------- %
    
    running = true;
    while running
        run_single_trial;
        
        % print_stats();
        
        % Check for pausing or quitting during ITI.
        startingTime = GetSecs;
        while ITI > (GetSecs - startingTime)
            key = key_check;
            
            % Pause experiment.
            if key.pause == 1
                pause(key);
            end
            
            % Exit experiment.
            if key.escape == 1
                running = false;
            end
        end
    end
    
    Screen('CloseAll');
    
    % ---------------------------------------------- %
    % ----------------- Functions ------------------ %
    % ---------------------------------------------- %
    
    % Determines if the eye has fixated within the given bounds
    % for the given duration before the given timeout occurs.
    function [fixation, area] = check_fixation(type, duration, timeout)
        startTime = GetSecs;
        
        % Keep checking for fixation until timeout occurs.
        while timeout > (GetSecs - startTime)
            [xCoord, yCoord] = get_eye_coords;
            
            % Determine if one, two, or three locations are being tracked.
            if strcmp(type, 'single')
                % Determine if eye is within the fixation boundary.
                if xCoord >= fixBoundXMin && xCoord <= fixBoundXMax && ...
                   yCoord >= fixBoundYMin && yCoord <= fixBoundYMax
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(fixBoundXMin, fixBoundXMax, ...
                                                    fixBoundYMin, fixBoundYMax, ...
                                                    duration);
                    
                    if checkFixBreak == false
                        % Fixation was obtained for desired duration.
                        fixation = true;
                        area = 'single';
                        
                        return;
                    end
                end
            elseif strcmp(type, 'double')
                % Determine if eye is within the left option boundary.
                if xCoord >= leftBoundXMin && xCoord <= leftBoundXMax && ...
                   yCoord >= leftBoundYMin && yCoord <= leftBoundYMax
                    draw_feedback('left', colorWhite);
                    
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(leftBoundXMin, leftBoundXMax, ...
                                                    leftBoundYMin, leftBoundYMax, ...
                                                    duration);
                    
                    if checkFixBreak == false
                        % Fixation was obtained for desired duration.
                        fixation = true;
                        area = 'left';
                        
                        return;
                    else
                        draw_stimuli;
                    end
                % Determine if eye is within the right option boundary.
                elseif xCoord >= rightBoundXMin && xCoord <= rightBoundXMax && ...
                       yCoord >= rightBoundYMin && yCoord <= rightBoundYMax
                    draw_feedback('right', colorWhite);
                    
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(rightBoundXMin, rightBoundXMax, ...
                                                    rightBoundYMin, rightBoundYMax, ...
                                                    duration);
                    
                    if checkFixBreak == false
                        % Fixation was obtained for desired duration.
                        fixation = true;
                        area = 'right';
                        
                        return;
                    else
                        draw_stimuli;
                    end
                end
            else
                disp('Fixation being checked with an illegal value for the "type" parameter.');
            end
        end
        
        % Timeout reached.
        fixation = false;
        area = 'none';
    end
    
    % Draw colored outlines around options for feedback.
    function draw_feedback(location, color)
        if strcmp(location, 'left')
            if strcmp(stimOnLeft, 'A') || strcmp(stimOnLeft, 'B')
                screenFlip = false;
                draw_stimuli;
                Screen('FrameRect', window, color, [leftStimXMin, leftStimYMin, ...
                                                    leftStimXMax, leftStimYMax], feedThick);
                Screen('Flip', window);
            elseif strcmp(stimOnLeft, 'C')
                screenFlip = false;
                draw_stimuli;
                Screen('FrameRect', window, color, [leftGreyXMin, leftGreyYMin, ...
                                                    leftGreyXMax, leftGreyYMax], feedThick);
                Screen('Flip', window);
            end
        elseif strcmp(location, 'right')
            if strcmp(stimOnRight, 'A') || strcmp(stimOnRight, 'B')
                screenFlip = false;
                draw_stimuli;
                Screen('FrameRect', window, color, [rightStimXMin, rightStimYMin, ...
                                                    rightStimXMax, rightStimYMax], feedThick);
                Screen('Flip', window);
            elseif strcmp(stimOnRight, 'C')
                screenFlip = false;
                draw_stimuli;
                Screen('FrameRect', window, color, [rightGreyXMin, rightGreyYMin, ...
                                                    rightGreyXMax, rightGreyYMax], feedThick);
                Screen('Flip', window);
            end
        end
        
        screenFlip = true;
    end
    
    % Draws a thin line on top of the invisible fixation boundaries.
    function draw_fixation_bounds()
        Screen('FrameRect', window, colorYellow, [fixBoundXMin fixBoundYMin ...
                                                  fixBoundXMax fixBoundYMax], 1);
        Screen('FrameRect', window, colorYellow, [leftBoundXMin leftBoundYMin ...
                                                  leftBoundXMax leftBoundYMax], 1);
        Screen('FrameRect', window, colorYellow, [rightBoundXMin rightBoundYMin ...
                                                  rightBoundXMax rightBoundYMax], 1);
    end
    
    % Draws the fixation point on the screen.
    function draw_fixation_point(color)
        Screen('FillOval', window, color, [centerX - dotRadius + fixAdj; ...
                                           centerY - dotRadius; ...
                                           centerX + dotRadius - fixAdj; ...
                                           centerY + dotRadius]);
        Screen('Flip', window);
    end
    
    % Draws the stimuli on the screen depending on the trial type.
    function draw_stimuli()
        if inHoldingState
            Screen('FillOval', window, colorYellow, [centerX - dotRadius + fixAdj; ...
                                                     centerY - dotRadius; ...
                                                     centerX + dotRadius - fixAdj; ...
                                                     centerY + dotRadius]);
        else
            Screen('FillOval', window, colorBackground, [centerX - dotRadius + fixAdj; ...
                                                         centerY - dotRadius; ...
                                                         centerX + dotRadius - fixAdj; ...
                                                         centerY + dotRadius]);
        end
        
        if strcmp(stimOnLeft, 'A')
            Screen('PutImage', window, imgForest, [leftStimXMin, leftStimYMin, ...
                                                   leftStimXMax, leftStimYMax]);
        elseif strcmp(stimOnLeft, 'B')
            Screen('PutImage', window, imgMounts, [leftStimXMin, leftStimYMin, ...
                                                   leftStimXMax, leftStimYMax]);
        elseif strcmp(stimOnLeft, 'C')
            Screen('FillRect', window, colorGrey, [leftGreyXMin leftGreyYMin ...
                                                   leftGreyXMax leftGreyYMax]);
        end
        
        if strcmp(stimOnRight, 'A')
            Screen('PutImage', window, imgForest, [rightStimXMin, rightStimYMin, ...
                                                   rightStimXMax, rightStimYMax]);
        elseif strcmp(stimOnRight, 'B')
            Screen('PutImage', window, imgMounts, [rightStimXMin, rightStimYMin, ...
                                                   rightStimXMax, rightStimYMax]);
        elseif strcmp(stimOnRight, 'C')
            Screen('FillRect', window, colorGrey, [rightGreyXMin rightGreyYMin ...
                                                   rightGreyXMax rightGreyYMax]);
        end
        
        if screenFlip
            Screen('Flip', window);
        end
    end
    
    % Checks if the eye breaks fixation bounds before end of duration.
    function fixationBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                             yBoundMin, yBoundMax, ...
                                             duration)
        fixStartTime = GetSecs;
        
        % Keep checking for fixation breaks for the entire duration.
        while duration > (GetSecs - fixStartTime)
            [xCoord, yCoord] = get_eye_coords;
            
            % Determine if the eye has left the fixation boundaries.
            if xCoord < xBoundMin || xCoord > xBoundMax || ...
               yCoord < yBoundMin || yCoord > yBoundMax
                % Eye broke fixation before end of duration.
                fixationBreak = true;
                
                return;
            end
        end
        
        % Eye maintained fixation for entire duration.
        fixationBreak = false;
    end

    % Creates the values for a stimulus presentation.
    function generate_stimuli()
        % Determine what trial type it will be.
        possibleTrials = [{'AB'}, {'AC'}, {'BC'}];
        randIndex = rand_int(2);
        currTrialType = char(possibleTrials(randIndex));
        
        % Determine positioning.
        randIndex = rand_int(1);
        stimOnLeft = currTrialType(randIndex);
        tempCurrType = currTrialType;
        tempCurrType(randIndex) = [];
        stimOnRight = tempCurrType(1);
        
        % Determine distribution lengths.
        [~, distALen] = size(distA);
        [~, distBLen] = size(distB);
        
        % Determine reward amount for the left option.
        if strcmp(stimOnLeft, 'A')
            randIndex = rand_int(distALen - 1);
            rewardOnLeft = distA(randIndex);
        elseif strcmp(stimOnLeft, 'B')
            randIndex = rand_int(distALen - 1);
            rewardOnLeft = distA(randIndex);
        elseif strcmp(stimOnLeft, 'C')
            rewardOnLeft = r110;
        end
        
        % Determine the reward amount for the right option.
        if strcmp(stimOnRight, 'A')
            randIndex = rand_int(distBLen - 1);
            rewardOnRight = distB(randIndex);
        elseif strcmp(stimOnRight, 'B')
            randIndex = rand_int(distBLen - 1);
            rewardOnRight = distB(randIndex);
        elseif strcmp(stimOnRight, 'C')
            rewardOnRight = r110;
        end
    end
    
    % Returns the current x and y coordinants of the given eye.
    function [xCoord, yCoord] = get_eye_coords()
        sampledPosition = Eyelink('NewestFloatSample');
        
        xCoord = sampledPosition.gx(trackedEye);
        yCoord = sampledPosition.gy(trackedEye);
    end
    
    % Checks to see what key was pressed.
    function key = key_check()
        % Assign key codes to some variables.
        stopKey = KbName('ESCAPE');
        pauseKey = KbName('RightControl');
        
        % Make sure default values of key are zero.
        key.pressed = 0;
        key.escape = 0;
        key.pause = 0;
        
        % Get info about any key that was just pressed.
        [~, ~, keyCode] = KbCheck;
        
        % Check pressed key against the keyCode array of 256 key codes.
        if keyCode(stopKey)
            key.escape = 1;
            key.pressed = 1;
        end
        
        if keyCode(pauseKey)
            key.pause = 1;
            key.pressed = 1;
        end
    end
    
    % Makes a folder and file where data will be saved.
    function prepare_for_saving()
        cd(riskySkewsData);
        
        % Check if cell ID was passed in with monkey's initial.
        if numel(monkeysInitial) == 1
            initial = monkeysInitial;
            cell = '';
        else
            initial = monkeysInitial(1);
            cell = monkeysInitial(2);
        end
        
        dateStr = datestr(now, 'yymmdd');
        filename = [initial dateStr '.' cell '1.RS.mat'];
        folderNameDay = [initial dateStr];
        
        % Make and/or enter a folder where .mat files will be saved.
        if exist(folderNameDay, 'dir') == 7
            cd(folderNameDay);
        else
            mkdir(folderNameDay);
            cd(folderNameDay);
        end
        
        % Make sure the filename for the .mat file is not already used.
        fileNum = 1;
        while fileNum ~= 0
            if exist(filename, 'file') == 2
                fileNum = fileNum + 1;
                filename = [initial dateStr '.' cell num2str(fileNum) '.RS.mat'];
            else
                fileNum = 0;
            end
        end
        
        saveCommand = ['save ' filename ' ' varName];
    end

    % Prints current trial stats.
    function print_stats()
        % MAKE SURE TO CHANGE THIS FUNCTION FOR EACH EXPERIMENT.
        % Convert percentages to strings.
        blockPercentCorrStr  = strcat(num2str(blockPercentCorr), '%');
        totalPercentCorrStr  = strcat(num2str(totalPercentCorr), '%');
        currBlockTrialStr    = num2str(currBlockTrial);
        trialCountStr        = num2str(trialCount);
        
        home;
        disp('             ');
        disp('****************************************');
        disp('             ');
        fprintf('Block trials: % s', currBlockTrialStr);
        disp('             ');
        fprintf('Total trials: % s', trialCountStr);
        disp('             ');
        disp('             ');
        disp('----------------------------------------');
        disp('             ');
        fprintf('Block correct: % s', blockPercentCorrStr);
        disp('             ');
        fprintf('Total correct: % s', totalPercentCorrStr);
        disp('             ');
        disp('             ');
        disp('****************************************');
    end
    
    function k = pause(k)
        disp('             ');
        disp('\\\\\\\\\\\\\\\\\\\\\\\\\\\\          /////////////////////////////');
        disp(' \\\\\\\\\\\\\\\\\\\\\\\\\\\\ PAUSED /////////////////////////////');
        disp('  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||');
        
        while k.pressed == 1
            k = key_check;
        end
        
        pause = 1;
        while pause == 1 && k.escape ~= 1
            k = key_check;
            
            if k.pause == 1
                pause = 0;
            end
        end
        
        while k.pressed == 1
            k = key_check;
        end
        
        disp('             ');
        disp('  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||');
        disp(' /////////////////////////// UNPAUSED \\\\\\\\\\\\\\\\\\\\\\\\\\\');
        disp('///////////////////////////            \\\\\\\\\\\\\\\\\\\\\\\\\\\');
        disp('             ');
    end

    % Returns a random int between 1 (inclusive) and integer + 1 (inclusive).
    function randInt = rand_int(integer)
        randInt = round(rand(1) * integer + 1);
    end
    
    % Rewards monkey using the juicer with the passed duration.
    function reward(rewardDuration)
        if rewardDuration ~= 0
            % Get a reference the juicer device and set reward duration.
            daq = DaqDeviceIndex;
            
            % Open juicer.
            DaqAOut(daq, 0, .6);
            
            startTime = GetSecs;
            
            % Keep looping to keep juicer open until reward end.
            while (GetSecs - startTime) < rewardDuration
            end
            
            % Close juicer.
            DaqAOut(daq, 0, 0);
        end
    end
    
    % Does exactly what you freakin' think it does.
    function run_single_trial()
        if ~repeatTrial
            currTrial = currTrial + 1;
            generate_stimuli;
        end
        
        draw_fixation_point(colorYellow);
        
        % Check for fixation.
        [fixating, ~] = check_fixation('single', minFixTime, timeToFix);
        
        if fixating
            draw_stimuli;
            
            % Make sure fixation is held before a target is chosen.
            fixationBreak = fix_break_check(fixBoundXMin, fixBoundXMax, ...
                                            fixBoundYMin, fixBoundYMax, ...
                                            holdFixTime);
            
            if fixationBreak
                % Start trial over because fixation wasn't held.
                repeatTrial = true;
                run_single_trial;
                return;
            else
                repeatTrial = false;
                inHoldingState = false;
                draw_stimuli;
            end
            
            fixatingOnTarget = false;
            while ~fixatingOnTarget
                % Check for fixation on either targets.
                [fixatingOnTarget, area] = check_fixation('double', chooseFixTime, timeToFix);
                
                if fixatingOnTarget
                    if strcmp(area, 'left')
                        % Display feedback stimuli.
                        draw_feedback('left', colorCyan);
                        WaitSecs(successDispTime);
                        
                        % Give appropriate reward.
                        reward(rewardOnLeft);
                        
                        % Clear screen.
                        Screen('FillRect', window, colorBackground, ...
                               [0 0 (centerX * 2) (centerY * 2)]);
                        Screen('Flip', window);
                        
                        % Update variables.
                        
                        % Calculate trial percentages.
                        
                        % Save trial data.
                    elseif strcmp(area, 'right')
                        % Display feedback stimuli.
                        draw_feedback('right', colorCyan);
                        WaitSecs(successDispTime);
                        
                        % Give appropriate reward.
                        reward(rewardOnRight);
                        
                        % Clear screen.
                        Screen('FillRect', window, colorBackground, ...
                               [0 0 (centerX * 2) (centerY * 2)]);
                        Screen('Flip', window);
                        
                        % Update variables.
                        
                        % Calculate trial percentages.
                        
                        % Save trial data.
                    end
                end
            end
        else
            % Redo this trial since monkey failed to start it.
            repeatTrial = true;
            run_single_trial;
        end
    end

    % Saves trial data to a .mat file.
    function send_and_save()
        % Save variables to a .mat file.
        data(currTrial).trial = currTrial;  % The trial number for this trial.
        
        eval(saveCommand);
    end
    
    % Sets up the Eyelink system.
    function setup_eyelink()
        abortSetup = false;
        setupMode = 2;
        
        % Connect Eyelink to computer if unconnected.
        if ~Eyelink('IsConnected')
            Eyelink('Initialize');
        end
        
        % Start recording eye position.
        Eyelink('StartRecording');
        
        % Set some preferences.
        Eyelink('Command', 'randomize_calibration_order = NO');
        Eyelink('Command', 'force_manual_accept = YES');
        
        Eyelink('StartSetup');
        
        % Wait until Eyelink actually enters setup mode.
        while ~abortSetup && Eyelink('CurrentMode') ~= setupMode
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown && keyCode(KbName('ESCAPE'))
                abortSetup = true;
                disp('Aborted while waiting for Eyelink!');
            end
        end
        
        % Put Eyelink in output mode.
        Eyelink('SendKeyButton', double('o'), 0, 10);
        
        % Start recording.
        Eyelink('SendKeyButton', double('o'), 0, 10);
    end
    
    % Sets up a new window and sets preferences for it.
    function window = setup_window()
        % Print only PTB errors.
        Screen('Preference', 'VisualDebugLevel', 1);
        
        % Suppress the print out of all PTB warnings.
        Screen('Preference', 'Verbosity', 0);
        
        % Setup a screen for displaying stimuli for this session.
        window = Screen('OpenWindow', monkeyScreen, colorBackground);
    end
end