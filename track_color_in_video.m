

clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures if you have the Image Processing Toolbox.
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;


folder = pwd;
baseFileName = 'GreenSharpie.wmv';
fullFileName = fullfile(folder, baseFileName);

% Check if the video file actually exists in the current folder
if ~exist(fullFileName, 'file')
	fullFileNameOnSearchPath = baseFileName; 
	if ~exist(fullFileNameOnSearchPath, 'file')
		errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end

videoObject = VideoReader(fullFileName);
numberOfFrames = videoObject.NumberOfFrame;

%hsv of green
hThresholds = [0.24, 0.44];
sThresholds = [0.8, 1.0];
vThresholds = [20, 125];
	

for k = 1 : numberOfFrames	
	% Read one frame
	thisFrame=read(videoObject,k);
	hImage=subplot(3, 4, 1);
	% Display it.
	imshow(thisFrame);
	axis on;
	caption = sprintf('Original RGB image, frame #%d 0f %d', k, numberOfFrames);
	title(caption, 'FontSize', fontSize);
	drawnow;
	
	hsv = rgb2hsv(double(thisFrame));
	hue=hsv(:,:,1);
	sat=hsv(:,:,2);
	val=hsv(:,:,3);

	subplot(3, 4, 2);
	imshow(hue, []);
	impixelinfo();
	axis on;
	title('Hue', 'FontSize', fontSize);
	subplot(3, 4, 3);
	imshow(sat, []);
	axis on;
	title('Saturation', 'FontSize', fontSize);
	subplot(3, 4, 4);
	imshow(val, []);
	axis on;
	title('Value', 'FontSize', fontSize);
	if k == 1
		% Enlarge figure to full screen.
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
		% Give a name to the title bar.
		set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 
		hCheckbox = uicontrol('Style','checkbox',... 
			'Units', 'Normalized',...
			'String', 'Finish Now',... 
			'Value',0,'Position', [.2 .96 .4 .05], ...
			'FontSize', 14);
	end

	% Compute histograms for H, S, and V channels
	% Let's compute and display the histogram.
	[pixelCount, grayLevels] = imhist(hue);
	subplot(3, 4, 6);
	bar(grayLevels, pixelCount);
	grid on;
	title('Histogram of hue image', 'FontSize', fontSize);
	xlim([0 grayLevels(end)]); % Scale x axis manually.
	% Let's compute and display the histogram.
	[pixelCount, grayLevels] = imhist(sat);
	subplot(3, 4, 7);
	bar(grayLevels, pixelCount);
	grid on;
	title('Histogram of sat image', 'FontSize', fontSize);
	xlim([0 grayLevels(end)]); % Scale x axis manually.
	% Let's compute and display the Value histogram.
	[pixelCount, grayLevels] = imhist(uint8(val));
	subplot(3, 4, 8);
	bar(grayLevels, pixelCount);
	grid on;
	title('Histogram of val image', 'FontSize', fontSize);
	xlim([0 grayLevels(end)]); % Scale x axis manually.
	
	binaryH = hue >= hThresholds(1) & hue <= hThresholds(2);
	binaryS = sat >= sThresholds(1) & sat <= sThresholds(2);
	binaryV = val >= vThresholds(1) & val <= vThresholds(2);
	subplot(3, 4, 10);
	imshow(binaryH, []);
	axis on;
	title('Hue Mask', 'FontSize', fontSize);
	subplot(3, 4, 11);
	imshow(binaryS, []);
	axis on;
	title('Saturation Mask', 'FontSize', fontSize);
	subplot(3, 4, 12);
	imshow(binaryV, []);
	axis on;
	title('Value Mask', 'FontSize', fontSize);
	
	% Overall color mask is the AND of all the masks.
	coloredMask = binaryH & binaryS & binaryV;
	% Filter out small blobs.
	coloredMask = bwareaopen(coloredMask, 500);
	% Fill holes
	coloredMask = imfill(coloredMask, 'holes');
	subplot(3, 4, 9);
	imshow(coloredMask, []);
	axis on;
	title('Colored Blob Mask', 'FontSize', fontSize);
	drawnow;
	
	[labeledImage, numberOfRegions] = bwlabel(coloredMask);
	if numberOfRegions >= 1
		stats = regionprops(labeledImage, 'BoundingBox', 'Centroid');
		% Delete old texts and rectangles
		if exist('hRect', 'var')
			delete(hRect);
		end
		if exist('hText', 'var')
			delete(hText);
		end
		
		% Display the original image again.
		subplot(3, 4, 5); % Switch to original image.
		hImage=subplot(3, 4, 5);
		imshow(thisFrame);
		axis on;
		hold on;
		caption = sprintf('%d blobs found in frame #%d 0f %d', numberOfRegions, k, numberOfFrames);
		title(caption, 'FontSize', fontSize);
		drawnow;
		
		%This is a loop to bound the colored objects in a rectangular box.
		for r = 1 : numberOfRegions
			% Find location for this blob.
			thisBB = stats(r).BoundingBox;
			thisCentroid = stats(r).Centroid;
			hRect(r) = rectangle('Position', thisBB, 'EdgeColor', 'r', 'LineWidth', 2);
			hSpot = plot(thisCentroid(1), thisCentroid(2), 'y+', 'MarkerSize', 10, 'LineWidth', 2)
			hText(r) = text(thisBB(1), thisBB(2)-20, strcat('X: ', num2str(round(thisCentroid(1))), '    Y: ', num2str(round(thisCentroid(2)))));
			set(hText(r), 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
		end
		hold off
		drawnow;
	end
	
	% See if they want to bail out
	if get(hCheckbox, 'Value')
		% Finish now checkbox is checked.
		msgbox('Done with demo.');
		return;
	end
end
msgbox('Done with demo.');




