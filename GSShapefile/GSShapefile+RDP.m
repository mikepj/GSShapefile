//
//  GSShapefile+RDP.m
//
//  Created by Mike Piatek-Jimenez on 10/31/13.
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

#import "GSShapefile+RDP.h"

@implementation GSShapefile (RDP)

- (void)rdpReducePointsWithEpsilon:(CGFloat)epsilon {
	[self rdpReducePointsWithEpsilon:epsilon minimumPointsPerRecord:0];
}

- (void)rdpReducePointsWithEpsilon:(CGFloat)epsilon minimumPointsPerRecord:(NSInteger)minPoints {
	NSMutableArray *newRecords = [NSMutableArray array];
	
	for (GSShapefileRecord *record in self.records) {
		GSShapefileRecord *reducedRecord = [self rdpReducePointsInRecord:record epsilon:epsilon];
		if (!reducedRecord) {
			NSLog(@"Failed to reduce the points in record %ld.", (long)record.recordNumber);
			return;
		}
		
		if (reducedRecord.pointsCount < minPoints)
			[newRecords addObject:record];
		else
			[newRecords addObject:reducedRecord];
	}
	
	self.records = newRecords;
}

- (GSShapefileRecord *)rdpReducePointsInRecord:(GSShapefileRecord *)record epsilon:(CGFloat)epsilon {
	// The first end case of the recursive algorithm.
	if (record.pointsCount < 3) return record;
	
	if (record.parts.count) {
		// If a record has multiple parts, we'll split the single record up into multiple records (one for each part).  Then we'll run the algorithm on each part and combine the results in the end.
		// We allocate newPoints to be the size of our current point array.  We'll never increase size.
		GSShapefilePoint *newPoints = malloc(record.pointsCount * sizeof(GSShapefilePoint));
		NSUInteger numPoints = 0;
		
		// This array will store the start indices for our new parts.
		NSMutableArray *newRecordParts = [NSMutableArray array];
		
		// Now split up the parts int separate records and make recursive calls to run the algorithm.
		for (NSUInteger partNumber = 0; partNumber < record.parts.count; partNumber++) {
			// Calculate the point range for this part.
			NSRange partRange;
			partRange.location = [record.parts[partNumber] integerValue];
			partRange.length = 0;
			if (partNumber == record.parts.count - 1) {
				partRange.length = record.pointsCount - partRange.location;
			}
			else {
				partRange.length = [record.parts[partNumber+1] integerValue] - partRange.location;
			}

			if (partRange.location + partRange.length <= record.pointsCount) {
				// Create the part record with the appropriate points.
				GSShapefileRecord *partRecord = [record copy];
				[partRecord setPoints:&(record.points[partRange.location]) count:partRange.length];
				partRecord.parts = nil;		// Zero this out so the actual algorithm runs.
				
				// Run the algorithm on the part.
				GSShapefileRecord *reducedPartRecord = [self rdpReducePointsInRecord:partRecord epsilon:epsilon];
				
				// Save the new points and part index.
				if (reducedPartRecord.pointsCount) {
					[newRecordParts addObject:@(numPoints)];
					memcpy(&(newPoints[numPoints]), reducedPartRecord.points, reducedPartRecord.pointsCount * sizeof(GSShapefilePoint));
					numPoints += reducedPartRecord.pointsCount;
				}
			}
		}

		// Finally create the new record with the new points and parts.
		GSShapefileRecord *newRecord = [record copy];
		newRecord.parts = newRecordParts;
		[newRecord setPoints:newPoints count:numPoints];
		return newRecord;
	}
	else {
		GSShapefilePoint firstPoint = record.points[0];
		GSShapefilePoint lastPoint = record.points[record.pointsCount - 1];
		
		// Check which point is furthest from the line(firstPoint, lastPoint)
		CGFloat furthestDistance = 0;
		NSUInteger furthestIndex = 1;
		for (NSUInteger i = 1; i < record.pointsCount - 1; i++) {
			CGFloat distance = [self perpendicularDistanceForPoint:record.points[i] inLineBetweenPoint1:firstPoint point2:lastPoint];
			if (distance > furthestDistance) {
				furthestDistance = distance;
				furthestIndex = i;
			}
		}
		
		if (furthestDistance > epsilon) {
			// Split the line into two segments and run the next iteration.
			// Segment 1 is from firstPoint to furthestIndex.
			GSShapefileRecord *segment1 = [record copy];
			[segment1 setPoints:record.points count:furthestIndex + 1];
			
			// Segment 2 is from furthestIndex to lastPoint.
			GSShapefileRecord *segment2 = [record copy];
			[segment2 setPoints:&(record.points[furthestIndex]) count:record.pointsCount - furthestIndex];
					
			// Reduce each segment.
			GSShapefileRecord *reducedSegment1 = [self rdpReducePointsInRecord:segment1 epsilon:epsilon];
			GSShapefileRecord *reducedSegment2 = [self rdpReducePointsInRecord:segment2 epsilon:epsilon];
			
			if ((reducedSegment1.pointsCount < 2) || (reducedSegment2.pointsCount < 2)) {
				// Something went wrong; there should always be a start point and and end point if we get past the initial pointsCount < 3 check above.
				return nil;
			}
			
			// Now recombine the result from reducing each segment.
			// Points count is the sum(points in the two segments) - 1.
			// This is because reducedSegment1.lastPoint is the same as reducedSegment2.firstPoint.
			NSUInteger combinedPointsCount = reducedSegment1.pointsCount + reducedSegment2.pointsCount - 1;
			GSShapefilePoint *combinedPoints = malloc(combinedPointsCount * sizeof(GSShapefilePoint));
			
			memcpy(combinedPoints, reducedSegment1.points, reducedSegment1.pointsCount * sizeof(GSShapefilePoint));
			memcpy(&(combinedPoints[reducedSegment1.pointsCount]), &(reducedSegment2.points[1]), (reducedSegment2.pointsCount - 1) * sizeof(GSShapefilePoint));
			
			GSShapefileRecord *combinedRecord = [record copy];
			[combinedRecord setPoints:combinedPoints count:combinedPointsCount];
			
			free(combinedPoints);
			
			return combinedRecord;
		}
		else {
			// We don't split this line, this is an end case of the recursive algorithm.
			// Create a new GSShapefileRecord with just firstPoint and lastPoint.
			GSShapefileRecord *newRecord = [record copy];
			
			GSShapefilePoint *firstAndLastPoint = malloc(2 * sizeof(GSShapefilePoint));
			firstAndLastPoint[0] = firstPoint;
			firstAndLastPoint[1] = lastPoint;
			[newRecord setPoints:firstAndLastPoint count:2];
			free(firstAndLastPoint);
			
			return newRecord;
		}
	}
}

- (CGFloat)perpendicularDistanceForPoint:(GSShapefilePoint)p inLineBetweenPoint1:(GSShapefilePoint)linePoint1 point2:(GSShapefilePoint)linePoint2 {
	if (linePoint1.x == linePoint2.x) {		// Avoids a divide by 0 later when calculating slope.
		return fabs(p.x - linePoint1.x);
	}
	else {
		CGFloat slope = (linePoint2.y - linePoint1.y) / (linePoint2.x - linePoint1.x);
		CGFloat intercept = linePoint1.y - (slope * linePoint1.x);
		return fabs(slope * p.x - p.y + intercept) / sqrt(pow(slope, 2.) + 1.);
	}
}

@end
