function bbox = detectLicensePlate(image)
    % Detect license plate using internal Morphology and Property Filtering.
    % INPUTS:
    %   image: Input image (color or grayscale)
    % OUTPUT:
    %   bbox: [x, y, width, height] of the detected plate, or [] if none found.
    % --- Tunable Parameters ---
    params = struct();
    % -- Visualization --
    params.enableVisualization = true; % DEBUG SWITCH
    % -- Preprocessing --
    params.imResizeHeight = 480;
    % -- Edge Detection --
    params.edgeMethod = 'sobel';
    % -- Close --
    params.seCloseShape = 'line';
    params.seCloseSize = 7.75;
    % -- Morphology --
    params.seDilateShape = 'disk';
    params.seDilateSize = 1;
    params.seErodeShape = 'disk';
    params.seErodeSize = 2;
    params.minNoiseBlobArea = 180;
    % -- Geometric Filtering --
    params.minArea = 175;
    params.maxArea = 6000;
    params.minAspectRatio = 2;
    params.maxAspectRatio = 6.5;
    params.minExtent = 0.3;
    params.minSolidity = 0.3;
    params.minEccentricity = 0.80;
    params.maxAbsOrientation = 20;
    % -- Geometric Scoring --
    params.targetAspectRatio = 4.5;
    params.geoScoreWeightAR = 0.75;
    params.geoScoreWeightExtent = 1.75;
    params.geoScoreWeightSolidity = 1.75;
    params.geoScoreWeightEccentricity = 0.8;
    params.geoScoreWeightOrientation = 0.5;
     % -- Intermediate Fill Filter Params --
    params.enableIntermediateFilter = true;
    params.intermediateMaxFilledAreaFactor = 10;
    params.intermediateMinFilledSolidity = 0.15;
    params.intermediateMinFilledExtent = 0.15;
    params.intermediateMinFilledAspectRatio = 2.27;
    params.intermediateMaxFilledAspectRatio = 7;
    % --- End of Parameters ---

    bbox = []; 

    % --- Conditional Debug/Display Helper ---
    DISPLAY_DETAIL = params.enableVisualization;

    try
        disp('--- Starting License Plate Detection ---'); 

        % 1. Preprocessing
        disp('1. Preprocessing...');
        im_resized = imresize(image, [params.imResizeHeight NaN]);
        if size(im_resized, 3) == 3; imgray = rgb2gray(im_resized); else; imgray = im_resized; end
        if ~isa(imgray,'uint8'); imgray = im2uint8(imgray); end

        % 2. Edge Detection
        disp(['2. Detecting edges (', params.edgeMethod, ')...']);
        im_edge = edge(imgray, params.edgeMethod);
        if DISPLAY_DETAIL; figure('Name','2. Edge Detection'); imshow(im_edge); title('Edge Detection Output'); end

        % 3. Morphology
        disp('3. Applying morphology...');
        % Close
        se_close = strel(params.seCloseShape, params.seCloseSize, 0);
        im_closed_edge = imclose(im_edge, se_close);
        if DISPLAY_DETAIL; figure('Name','3a. After Close'); imshow(im_closed_edge); title('3a. After Close'); end
        % Dilate
        se_dilate = strel(params.seDilateShape, params.seDilateSize);
        im_dilated = imdilate(im_closed_edge, se_dilate);
        if DISPLAY_DETAIL; figure('Name','3b. After Dilate'); imshow(im_dilated); title('3b. After Dilate');end
        % Fill
        im_filled = imfill(im_dilated, 'holes');
        if DISPLAY_DETAIL; figure('Name','3c. After Fill'); imshow(im_filled); title('3c. After Fill');end
        % Intermediate Filtering
        im_to_erode = im_filled;
        if params.enableIntermediateFilter
            disp('   Applying intermediate filter...');
            stats_filled = regionprops(im_filled, 'Area', 'BoundingBox', 'Solidity', 'Extent', 'PixelIdxList');
            maxFilledArea = params.maxArea * params.intermediateMaxFilledAreaFactor;
            im_filtered_filled = false(size(im_filled));
            valid_filled_count = 0;
            for j = 1:length(stats_filled)
                if stats_filled(j).Area < params.minArea || stats_filled(j).Area > maxFilledArea; continue; end
                bb_filled = stats_filled(j).BoundingBox; width_filled = bb_filled(3); height_filled = bb_filled(4);
                if width_filled <= 0 || height_filled <= 0; continue; end
                aspectRatio_filled = width_filled / height_filled;
                pass_filled = aspectRatio_filled >= params.intermediateMinFilledAspectRatio && ...
                              aspectRatio_filled <= params.intermediateMaxFilledAspectRatio && ...
                              stats_filled(j).Solidity >= params.intermediateMinFilledSolidity && ...
                              stats_filled(j).Extent >= params.intermediateMinFilledExtent;
                if pass_filled; im_filtered_filled(stats_filled(j).PixelIdxList) = true; valid_filled_count = valid_filled_count + 1; end
            end
            disp(['      Found ', num2str(valid_filled_count), ' plausible region(s).']);
            if DISPLAY_DETAIL && valid_filled_count > 0; figure('Name','3d. After Intermediate Filter'); imshow(im_filtered_filled); title('3d. After Intermediate Filter'); end
            im_to_erode = im_filtered_filled;
        else
             disp('   Skipping intermediate filter.');
        end
        % Erosion and Cleaning
        se_erode = strel(params.seErodeShape, params.seErodeSize);
        im_eroded = imerode(im_to_erode, se_erode);
        if DISPLAY_DETAIL; figure('Name','3e. After Erode'); imshow(im_eroded); title('3e. After Erode'); end
        im_cleaned = bwareaopen(im_eroded, params.minNoiseBlobArea);
        if DISPLAY_DETAIL; figure('Name','3f. After Clean'); imshow(im_cleaned); title(sprintf('3f. Morphology Output (Cleaned, Area>%d px)', params.minNoiseBlobArea)); end

        % 4. Region Analysis
        disp('4. Analyzing final regions...');
        stats = regionprops(im_cleaned, 'BoundingBox', 'Area', 'Extent', 'Solidity', 'Eccentricity', 'Orientation');
        if isempty(stats); disp('   No regions found after morphology.'); bbox = []; return; end
        disp(['   Found ', num2str(length(stats)), ' regions for final filtering.']);

        % 5. Filtering Candidates & Geometric Scoring
        disp('5. Filtering regions & calculating geometric scores...');
        candidateBBoxes_scaled = []; candidateGeoScores = []; candidateProps = struct('ID',{},'Area',{},'AspectRatio',{},'Extent',{},'Solidity',{},'Eccentricity', {}, 'Orientation', {});
        candidateIndices = [];
        if DISPLAY_DETAIL; fprintf('   Filtering details:\n'); end
         for i = 1:length(stats)
             bb = stats(i).BoundingBox; width = bb(3); height = bb(4); currentArea = stats(i).Area; extent = stats(i).Extent; solidity = stats(i).Solidity; ecc = stats(i).Eccentricity; orientation = stats(i).Orientation;
             if width <= 0 || height <= 0; aspectRatio = 0; else; aspectRatio = width / height; end
             if DISPLAY_DETAIL; fprintf('  Region %d Props: Area=%.1f, AR=%.2f, Ext=%.3f, Sol=%.3f, Ecc=%.3f, Ori=%.1f\n',i, currentArea, aspectRatio, extent, solidity, ecc, orientation); end
             passed_all_filters = true;
             if currentArea < params.minArea || currentArea > params.maxArea; if DISPLAY_DETAIL; fprintf('    -> FAILED Area Check (%.1f not in [%.1f, %.1f])\n', currentArea, params.minArea, params.maxArea); end; passed_all_filters = false; end
             if aspectRatio < params.minAspectRatio || aspectRatio > params.maxAspectRatio; if DISPLAY_DETAIL; fprintf('    -> FAILED Aspect Ratio Check (%.2f not in [%.2f, %.2f])\n', aspectRatio, params.minAspectRatio, params.maxAspectRatio);end; passed_all_filters = false; end
             if extent < params.minExtent; if DISPLAY_DETAIL; fprintf('    -> FAILED Extent Check (%.3f < %.3f)\n', extent, params.minExtent); end; passed_all_filters = false; end
             if solidity < params.minSolidity; if DISPLAY_DETAIL; fprintf('    -> FAILED Solidity Check (%.3f < %.3f)\n', solidity, params.minSolidity); end; passed_all_filters = false; end
             if ecc < params.minEccentricity; if DISPLAY_DETAIL; fprintf('    -> FAILED Eccentricity Check (%.3f < %.3f)\n', ecc, params.minEccentricity); end; passed_all_filters = false; end
             if abs(orientation) > params.maxAbsOrientation; if DISPLAY_DETAIL; fprintf('    -> FAILED Orientation Check (abs(%.1f) > %.1f)\n', orientation, params.maxAbsOrientation);end; passed_all_filters = false; end
             if passed_all_filters
                 if DISPLAY_DETAIL; fprintf('    -> PASSED All Filters\n'); end
                 candidateBBoxes_scaled = [candidateBBoxes_scaled; bb]; %#ok<AGROW>
                 candidateIndices = [candidateIndices; i]; %#ok<AGROW>
                 props.ID=i; props.Area=currentArea; props.AspectRatio=aspectRatio; props.Extent=extent; props.Solidity=solidity; props.Eccentricity=ecc; props.Orientation=orientation; candidateProps(end+1) = props; %#ok<AGROW>
                 % Calculate Geometric Score
                 score = (1 / (1 + abs(props.AspectRatio - params.targetAspectRatio))) * params.geoScoreWeightAR + ...
                         props.Extent * params.geoScoreWeightExtent + ...
                         props.Solidity * params.geoScoreWeightSolidity + ...
                         props.Eccentricity * params.geoScoreWeightEccentricity + ...
                         (1 - abs(props.Orientation)/90) * params.geoScoreWeightOrientation;
                 candidateGeoScores = [candidateGeoScores; score]; %#ok<AGROW>
             elseif DISPLAY_DETAIL
                  fprintf('    -> REJECTED\n');
             end
         end
         numCandidates = size(candidateBBoxes_scaled, 1);
         disp(['   Found ', num2str(numCandidates), ' geometric candidate(s).']);
         % Visualize Geometric Candidates
         if DISPLAY_DETAIL && numCandidates > 0
              vis_fig_geom = figure('Name','5. Final Geometric Candidates'); imshow(im_resized); title('5. Final Geometric Candidates (Passed Filters)'); hold on;
              colors = lines(numCandidates);
              for k_vis = 1:numCandidates
                  rectangle('Position', candidateBBoxes_scaled(k_vis,:), 'EdgeColor', colors(k_vis,:), 'LineWidth', 2);
                  prop_text = sprintf('GeoScr: %.2f', candidateGeoScores(k_vis)); 
                  prop_text = [prop_text, sprintf(' Ext:%.2f Sol:%.2f', candidateProps(k_vis).Extent, candidateProps(k_vis).Solidity)];
                  text(candidateBBoxes_scaled(k_vis,1), candidateBBoxes_scaled(k_vis,2) - 5, prop_text, ...
                       'Color', colors(k_vis,:), 'FontSize', 8, 'BackgroundColor', 'w', ...
                       'VerticalAlignment','bottom', 'FontWeight', 'bold');
              end
              hold off;
         end


        % 6. Select Best Candidate 
        disp('7. Selecting best candidate based on geometric score...'); 
        if numCandidates > 0
             scoresToUse = candidateGeoScores; 

             if isempty(scoresToUse) 
                 disp('   Error: No geometric scores available for candidates.');
                 bbox = [];
                 return;
             end

             [maxScore, bestIdx] = max(scoresToUse);
             bbox_scaled = fix(candidateBBoxes_scaled(bestIdx, :));

             if bbox_scaled(3) <= 0 || bbox_scaled(4) <= 0
                 disp('   Best candidate has invalid dimensions.');
                 bbox = [];
             else
                 disp(['   Selected Candidate #', num2str(candidateIndices(bestIdx)), ' with Geometric Score: ', num2str(maxScore)]);

                 % Rescale bbox
                 current_h = size(im_resized, 1); original_h = size(image, 1); rescale_factor = original_h / current_h;
                 abs_x = bbox_scaled(1) * rescale_factor; abs_y = bbox_scaled(2) * rescale_factor; abs_w = bbox_scaled(3) * rescale_factor; abs_h = bbox_scaled(4) * rescale_factor;
                 bbox = fix([abs_x, abs_y, abs_w, abs_h]);

                 if isempty(bbox) || bbox(3) <= 0 || bbox(4) <= 0
                      disp('   Rescaled bounding box is invalid.');
                      bbox = [];
                 else
                      disp('   Successfully generated final bounding box.');
                     % Display Final Result Figure
                     if DISPLAY_DETAIL
                         figure('Name','7. Final Result'); imshow(image); title('7. Final Result'); hold on;  
                         rectangle('Position', bbox, 'EdgeColor', 'cyan', 'LineWidth', 2, 'LineStyle','--');
                         final_text_display = sprintf('GeoScore: %.2f', maxScore);
                         text(bbox(1), bbox(2) - 10, final_text_display, 'Color', 'cyan', 'FontSize', 9, 'BackgroundColor', 'w', 'VerticalAlignment','bottom', 'FontWeight', 'bold');
                         hold off;
                     end
                 end
             end
        else
            disp('   No valid geometric candidates found to select.');
            bbox = [];
        end
    catch ME
        warning('An error occurred during detection: %s', ME.message);
        fprintf('Error details: %s\n', ME.getReport('extended'));
        bbox = [];
    end
    % --- Final Output Message ---
     if ~isempty(bbox); disp('--- Finished Detection: Returning valid bounding box ---'); 
     else; disp('--- Finished Detection: Returning empty bounding box ---');
     end
end