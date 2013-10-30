//
//  GSShapefileRecord.m
//
//  Created by Mike Piatek-Jimenez on 10/29/13.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2013 Mike Piatek-Jimenez and Gaucho Software, LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GSShapefileRecord.h"

@interface GSShapefileRecord ()
@end

@implementation GSShapefileRecord

- (instancetype)initWithRecordData:(NSData *)recordData {
	self = [super init];
	if (self) {
		_pointsCount = 0;
		BOOL success = [self parseRecordData:recordData];
		if (!success) self = nil;
	}
	return self;
}

- (void)dealloc {
	if (_pointsCount) {
		free(_points);
		_points = NULL;
		_pointsCount = 0;
	}
}

- (BOOL)parseRecordData:(NSData *)recordData {
	const unsigned char *fileStart = recordData.bytes;		// Get a pointer to the buffer in our NSData object.  This is read-only.
	NSUInteger fileIndex = 0;

	// Check if we are going to read beyond EOF.
	if (fileIndex + (3 * SHAPEFILE_INT_SIZE) > recordData.length) return NO;
	self.recordNumber = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:YES] * 2;
	self.shapeType = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex + (2 * SHAPEFILE_INT_SIZE) isBigEndian:NO];
	fileIndex += 3 * SHAPEFILE_INT_SIZE;

	if (self.shapeType == GSShapefileShapeTypePoint) {
		// Allocate the points
		_points = malloc(1 * sizeof(GSShapefilePoint));
		_pointsCount = 1;
		
		// Parse the X and Y values
		if (fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) return NO;
		_points[0].x = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
		fileIndex += SHAPEFILE_DOUBLE_SIZE;
		_points[0].y = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
		fileIndex += SHAPEFILE_DOUBLE_SIZE;
	}
	else if ((self.shapeType == GSShapefileShapeTypePolyLine) || (self.shapeType == GSShapefileShapeTypePolygon)) {
		// Parse the bounding box.
		GSShapefileBoundingBox *b;
		if (fileIndex + (4 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) return NO;
		b.xMin = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (0 * SHAPEFILE_DOUBLE_SIZE)];
		b.yMin = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (1 * SHAPEFILE_DOUBLE_SIZE)];
		b.xMax = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE)];
		b.yMax = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (3 * SHAPEFILE_DOUBLE_SIZE)];
		fileIndex += 4 * SHAPEFILE_DOUBLE_SIZE;

		// Read the number of parts.
		if (fileIndex + SHAPEFILE_INT_SIZE > recordData.length) return NO;
		NSInteger numParts = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:NO];
		fileIndex += SHAPEFILE_INT_SIZE;
		
		// Read the number of points.
		if (fileIndex + SHAPEFILE_INT_SIZE > recordData.length) return NO;
		NSInteger numPoints = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:NO];
		fileIndex += SHAPEFILE_INT_SIZE;
		
		// Read the parts.
		NSMutableArray *newParts = [NSMutableArray array];
		for (NSInteger i = 0; i < numParts; i++) {
			if (fileIndex + SHAPEFILE_INT_SIZE > recordData.length) return NO;
			NSInteger pointIndex = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:NO];
			fileIndex += SHAPEFILE_INT_SIZE;
			
			[newParts addObject:@(pointIndex)];
		}
		self.parts = newParts;
		
		// Allocate the points.
		GSShapefilePoint *newPoints = malloc(numPoints * sizeof(GSShapefilePoint));
		
		// Read the points.
		NSUInteger newPointsIndex = 0;
		for (NSInteger i = 0; i < numPoints; i++) {
			if (fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) return NO;
			newPoints[newPointsIndex].x = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
			fileIndex += SHAPEFILE_DOUBLE_SIZE;
			newPoints[newPointsIndex].y = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
			fileIndex += SHAPEFILE_DOUBLE_SIZE;

			newPointsIndex++;
		}
		
		if (_pointsCount) {
			free(_points);
			_points = NULL;
			_pointsCount = 0;
		}
		_points = newPoints;
		_pointsCount = numPoints;
	}
	
	return YES;
}

@end
