//
//  GSShapefile.h
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

#import <Foundation/Foundation.h>

#import "GSShapefileRecord.h"

@interface GSShapefile : NSObject

/// The bounding box covered by this shapefile.
@property GSShapefileBoundingBox *boundingBox;

/// An array of GSShapefileRecord objects that we have parsed.
@property NSArray *records;

/*! Allocate a GSShapefile object and call parseFileData with the data passed in.
 * \param shpData The Shapefile data to parse.
 * \returns A new GSShapefile object.
 */
- (instancetype)initWithSHPData:(NSData *)shpData;

/*! Sets up our object with the passed in data.  This will release any past parsed data before it starts.
 * \param shpData The Shapefile data to parse (read from an .SHP file).
 * \returns YES if parsing completed successfully.
 */
- (BOOL)parseSHPData:(NSData *)shpData;

/*! A convenience method to get the total number of points parsed from the Shapefile.
 * \returns The point count.
 */
- (NSUInteger)totalPointCount;

/*! Returns an NSData object with bytes for this Shapefile, to save it to a file, for example.
 * This can be used to either build your own Shapefile from the ground up, or to take an existing Shapefile and process it (reduce points using the RDP code, for example).
 * \returns The NSData object with our file data.
 */
- (NSData *)shpData;

@end
