% Load an image
imgPath = './images/40.jpg'; 
try
    img = imread(imgPath);
catchparams.seCloseShape
    error('Could Not Read The Image. Check The Path.');
end

disp('--- Running Detection With Preprocessing ---');
bbox = detectLicensePlate(img); 

if isempty(bbox)
    disp('Detection : Failed.');
    figure; imshow(img); title('Original Image - Detection Failed');
else
    disp('Detection: Success! Bbox found');
    disp(bbox);
    detectedImg = insertShape(img, 'Rectangle', bbox, 'Color', 'cyan', 'LineWidth', 2); 
    figure; imshow(detectedImg); title('Detection Result');
end