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

- (id)copyWithZone:(NSZone *)zone {
	GSShapefileRecord *c = [[[self class] allocWithZone:zone] init];
	c.recordNumber = self.recordNumber;
	c.shapeType = self.shapeType;
	c.boundingBox = [self.boundingBox copy];
	c.parts = [[NSArray alloc] initWithArray:self.parts copyItems:YES];
	[c setPoints:self.points count:self.pointsCount];
	return c;
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

	GSShapefilePoint *newPoints = NULL;
	NSUInteger numPoints = 0;
	
	if (self.shapeType == GSShapefileShapeTypePoint) {
		// Allocate the points
		newPoints = malloc(1 * sizeof(GSShapefilePoint));
		numPoints = 1;
		
		// Parse the X and Y values
		if (fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) {
			free(newPoints);
			return NO;
		}
		newPoints[0].x = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
		fileIndex += SHAPEFILE_DOUBLE_SIZE;
		newPoints[0].y = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
		fileIndex += SHAPEFILE_DOUBLE_SIZE;
		
		GSShapefileBoundingBox *b = [[GSShapefileBoundingBox alloc] init];
		b.xMin = b.xMax = newPoints[0].x;
		b.yMin = b.yMax = newPoints[0].y;
	}
	else if ((self.shapeType == GSShapefileShapeTypePolyLine) || (self.shapeType == GSShapefileShapeTypePolygon)) {
		// Parse the bounding box.
		GSShapefileBoundingBox *b = [[GSShapefileBoundingBox alloc] init];
		if (fileIndex + (4 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) return NO;
		b.xMin = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (0 * SHAPEFILE_DOUBLE_SIZE)];
		b.yMin = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (1 * SHAPEFILE_DOUBLE_SIZE)];
		b.xMax = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE)];
		b.yMax = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex + (3 * SHAPEFILE_DOUBLE_SIZE)];
		self.boundingBox = b;
		fileIndex += 4 * SHAPEFILE_DOUBLE_SIZE;

		// Read the number of parts.
		if (fileIndex + SHAPEFILE_INT_SIZE > recordData.length) return NO;
		NSInteger numParts = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:NO];
		fileIndex += SHAPEFILE_INT_SIZE;
		
		// Read the number of points.
		if (fileIndex + SHAPEFILE_INT_SIZE > recordData.length) return NO;
		numPoints = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex isBigEndian:NO];
		if (numPoints < 1) return NO;
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
		newPoints = malloc(numPoints * sizeof(GSShapefilePoint));
		
		// Read the points.
		NSUInteger newPointsIndex = 0;
		for (NSInteger i = 0; i < numPoints; i++) {
			if (fileIndex + (2 * SHAPEFILE_DOUBLE_SIZE) > recordData.length) {
				free(newPoints);
				return NO;
			}
			newPoints[newPointsIndex].x = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
			fileIndex += SHAPEFILE_DOUBLE_SIZE;
			newPoints[newPointsIndex].y = [GSShapefileHelper fetchFloatFromPointer:fileStart + fileIndex];
			fileIndex += SHAPEFILE_DOUBLE_SIZE;

			newPointsIndex++;
		}
	}
	else {
		return NO;
	}

	// Parsing is done, set our points.
	[self setPoints:newPoints count:numPoints];
	
	if (newPoints) free(newPoints);

	return YES;
}

- (void)setPoints:(GSShapefilePoint *)pArray count:(NSUInteger)pCount {
	if (_pointsCount) {
		free(_points);
		_points = NULL;
		_pointsCount = 0;
	}
	
	if ((pCount > 0) && (pArray != NULL)) {
		GSShapefilePoint *pointsCopy = malloc(pCount * sizeof(GSShapefilePoint));
		memcpy(pointsCopy, pArray, pCount * sizeof(GSShapefilePoint));
		
		_points = pointsCopy;
		_pointsCount = pCount;
	}
}

- (NSData *)shpData {
	if (self.shapeType == GSShapefileShapeTypePoint) {
		// header + shape type + 1 point.
		NSUInteger bufferSize = (3 * SHAPEFILE_INT_SIZE) + (2 * SHAPEFILE_DOUBLE_SIZE);
		unsigned char *buffer = malloc(bufferSize);
		NSUInteger index = 0;
		
		// Write the record number.
		[GSShapefileHelper writeInteger:self.recordNumber toBuffer:buffer + index useBigEndian:YES];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the content length (20 bytes total, 10 16 bit words)
		[GSShapefileHelper writeInteger:10 toBuffer:buffer + index useBigEndian:YES];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the shape type.
		[GSShapefileHelper writeInteger:self.shapeType toBuffer:buffer + index useBigEndian:NO];
		index += SHAPEFILE_INT_SIZE;
		
		if (self.pointsCount > 0) {
			// Write the X value.
			[GSShapefileHelper writeFloat:self.points[0].x toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
			
			// Write the Y value.
			[GSShapefileHelper writeFloat:self.points[0].y toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
		}
		
		// Create the NSData object and free the buffer.
		NSData *retData = [[NSData alloc] initWithBytes:buffer length:bufferSize];
		free(buffer);
		
		return retData;
	}
	else if ((self.shapeType == GSShapefileShapeTypePolyLine) || (self.shapeType == GSShapefileShapeTypePolygon)) {
		// header + shape type + bounding box + num parts and num points + parts + points.
		NSUInteger bufferSize = (3 * SHAPEFILE_INT_SIZE) + (4 * SHAPEFILE_DOUBLE_SIZE) + (2 * SHAPEFILE_INT_SIZE) + (self.parts.count * SHAPEFILE_INT_SIZE) + (self.pointsCount * 2 * SHAPEFILE_DOUBLE_SIZE);
		unsigned char *buffer = malloc(bufferSize);
		NSUInteger index = 0;
		
		// Write the record number.
		[GSShapefileHelper writeInteger:self.recordNumber toBuffer:buffer + index useBigEndian:YES];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the content length (in 16 bit words)
		[GSShapefileHelper writeInteger:(bufferSize - (2 * SHAPEFILE_INT_SIZE)) / 2 toBuffer:buffer + index useBigEndian:YES];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the shape type.
		[GSShapefileHelper writeInteger:self.shapeType toBuffer:buffer + index useBigEndian:NO];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the bounding box.
		if (self.boundingBox) {
			[GSShapefileHelper writeFloat:self.boundingBox.xMin toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
			[GSShapefileHelper writeFloat:self.boundingBox.yMin toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
			[GSShapefileHelper writeFloat:self.boundingBox.xMax toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
			[GSShapefileHelper writeFloat:self.boundingBox.yMax toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
		}
		else {
			index += 4 * SHAPEFILE_DOUBLE_SIZE;
		}
		
		// Write the number of parts.
		[GSShapefileHelper writeInteger:self.parts.count toBuffer:buffer + index useBigEndian:NO];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the number of points.
		[GSShapefileHelper writeInteger:self.pointsCount toBuffer:buffer + index useBigEndian:NO];
		index += SHAPEFILE_INT_SIZE;
		
		// Write the parts.
		for (NSNumber *partNumber in self.parts) {
			[GSShapefileHelper writeInteger:[partNumber integerValue] toBuffer:buffer + index useBigEndian:NO];
			index += SHAPEFILE_INT_SIZE;
		}
		
		// Write the points.
		for (NSUInteger i = 0; i < self.pointsCount; i++) {
			// Write the X value.
			[GSShapefileHelper writeFloat:self.points[i].x toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
			
			// Write the Y value.
			[GSShapefileHelper writeFloat:self.points[i].y toBuffer:buffer + index];
			index += SHAPEFILE_DOUBLE_SIZE;
		}
		
		// Create the NSData object and free the buffer.
		NSData *retData = [[NSData alloc] initWithBytes:buffer length:bufferSize];
		free(buffer);
		
		return retData;
	}
	
	return nil;
}

@end
