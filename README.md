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
 