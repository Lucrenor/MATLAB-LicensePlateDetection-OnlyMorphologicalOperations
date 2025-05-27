# License Plate Detection using MATLAB

A robust MATLAB-based license plate detection system using image processing techniques for automatically locating vehicle license plates in images.

## Features

- Automatic license plate detection in various lighting conditions
- GUI application for interactive usage
- Sophisticated morphological operations for robust detection
- Geometric property-based filtering for accurate results
- Visualization tools for algorithm debugging

## Project Components

- `detectLicensePlate.m` - Core detection algorithm
- `test.m` - Script for testing the detection on single images
- `mainApp.mlapp` - MATLAB App Designer GUI application
- `images/` - Directory containing test images

## Algorithm Overview

The license plate detection algorithm follows these steps:

1. **Preprocessing**: Resize and convert to grayscale
2. **Edge Detection**: Apply Sobel edge detection
3. **Morphological Operations**:
   - Close operation to connect nearby edges
   - Dilation to strengthen plate boundaries
   - Fill holes to create solid regions
   - Erosion to refine shapes
   - Noise removal
4. **Region Analysis**: Extract and analyze connected components
5. **Geometric Filtering**: Filter regions based on:
   - Area
   - Aspect ratio
   - Extent
   - Solidity
   - Eccentricity
   - Orientation
6. **Geometric Scoring**: Select the best candidate based on geometric scores

## Usage

### Testing with a Single Image

1. Run the test file:
   ```matlab
   test
   ```
2. give an imnage input from `images/` ranging from 1 to 50.

### Using the GUI Application

1. Run the MATLAB App Designer application:
   ```matlab
   mainApp
   ```
2. Use the interface to load images and detect license plates

## Requirements

- MATLAB R2019b or newer
- Image Processing Toolbox
- Computer Vision Toolbox

## Parameters

The detection algorithm can be fine-tuned by adjusting parameters in the `detectLicensePlate.m` function:

- Edge detection method
- Morphological structuring elements
- Area thresholds
- Aspect ratio constraints
- Geometric properties thresholds

## Dataset

The project includes a dataset of 50 vehicle images with license plates in various conditions to test the detection algorithm's robustness.

## Application Demonstration
### Image Preprocessing
![Image](https://github.com/user-attachments/assets/3c8c8868-69f9-4de4-a38f-8bb85727a65f)
### Edge Detection
![Image](https://github.com/user-attachments/assets/9c89a05d-d9f5-4f3f-8b5b-9a9760fc59b0)
### Closing Operation
![Image](https://github.com/user-attachments/assets/a496cadd-26bb-4e9e-ba35-48730e972753)
### Dilation Operation
![Image](https://github.com/user-attachments/assets/e9c518e7-0a24-4bc5-a93e-fbe11f924375)
### Hole Fill Operation
![Image](https://github.com/user-attachments/assets/137ff7fb-ab30-48df-a382-311804826f36)
### Intermediate Filtering (Early Pruning)
![Image](https://github.com/user-attachments/assets/fde4327c-d437-412e-9a2e-3a654c5dd9c5)
### Erosion Operation
![Image](https://github.com/user-attachments/assets/c18665fb-df45-46cd-ba60-d1f92d9083a2)
### Area Opening Operation
![Image](https://github.com/user-attachments/assets/b17533b2-3d8a-4d28-bd86-26db2194c605)
### Region Analysis & Candidate Selection
![Image](https://github.com/user-attachments/assets/07b7cc0e-e693-43b3-911b-d894c5f9bb73)
### Geometric Scoring & Bounding Box
![Image](https://github.com/user-attachments/assets/28e1c6a7-92e2-4c93-942a-116eb99a941c)
 
