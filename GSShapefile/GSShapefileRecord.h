//
//  GSShapefileRecord.h
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

@import Foundation;

#import "GSShapefileBoundingBox.h"
#import "GSShapefileHelper.h"

typedef struct {
	/// The X coordinate.
	CGFloat x;
	/// The Y coordiante.
	CGFloat y;
	/// The Z coordinate (not always populated).
	CGFloat z;
	/// The measured value (not always populated).
	CGFloat m;
} GSShapefilePoint;


@interface GSShapefileRecord : NSObject <NSCopying>

/// The record number defined in the Shapefile.
@property NSInteger recordNumber;

/// The type of shape this record contains.
@property GSShapefileShapeType shapeType;

/// Most records have a bounding box, which define edge coordinates for the data.
@property GSShapefileBoundingBox *boundingBox;

/// GSShapefileShapeTypePoint and GSShapefileShapeTypeMultiPoint:  An array of pointsCount GSShapefilePoints.
@property (readonly) GSShapefilePoint *points;
@property (readonly) NSUInteger pointsCount;

/// An array of NSNumbers.  Each part points to an index in the points array and designates the start of a new part.
@property NSArray *parts;

/*! Init a new record object and call parseRecordData with the given data.
 * \returns The new GSShapefileRecord object.
 */
- (instancetype)initWithRecordData:(NSData *)recordData;

/*! Parse a record from the given data.  This will zero out any previously parsed data.
 * \param recordData An NSData object with the raw bytes of just this single record.
 * \returns YES if record was parsed successfully.
 */
- (BOOL)parseRecordData:(NSData *)recordData;

/*! There may be certain situations where we want to set the points array from outside our class (the RDP category, for example).  This method makes sure that is done properly.  
 *  The points buffer passed in is copied, so the caller retains ownership and must free it properly.
 * \param pArray A new array of GSShapefilePoints.
 * \param pCount The count of how many points are in pArray.
 */
- (void)setPoints:(GSShapefilePoint *)pArray count:(NSUInteger)pCount;

/*! Returns an NSData object with bytes for this record, to save the Shapefile data to a file, for example.
 * \returns The NSData object with bytes just for this record.
 */
- (NSData *)shpData;

@end
