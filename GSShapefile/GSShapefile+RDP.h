//
//  GSShapefile+RDP.h
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

// This category implements the Ramer–Douglas–Peucker (RDP) algorithm to reduce the number
// of points in our Shapefile records.  I used the Javascript code by Marius Karthaus
// (http://karthaus.nl/rdp/js/rdp.js) as a guide while writing this.

// Note: this algorithm currently only takes into account 2-dimensions of the points.  The Z coordinates are ignored.

#import "GSShapefile.h"

@interface GSShapefile (RDP)

/*! Reduces the number of points in our Shapefile records.  It will run the algorithm on each of the records.
 *  This method doesn't return anything, but it will reset the records array of the GSShapefile.
 * \param epsilon This determines how close the new line should be to the original.  Higher values of epsilon will further reduce the number of points, while low values of epsilon will retain more points.  Epsilon can be thought of as the precision you would like your points to have.  If you want your points drawn to the nearest 0.1 X/Y, then epsilon should be 0.1.
 */
- (void)rdpReducePointsWithEpsilon:(CGFloat)epsilon;

/*! Reduces the number of points in our Shapefile records.  It will run the algorithm on each of the records.
 *  This method doesn't return anything, but it will reset the records array of the GSShapefile.
 * \param epsilon This determines how close the new line should be to the original.  Higher values of epsilon will further reduce the number of points, while low values of epsilon will retain more points.  Epsilon can be thought of as the precision you would like your points to have.  If you want your points drawn to the nearest 0.1 X/Y, then epsilon should be 0.1.
 * \param minPoints Don't run the algorithm if a record already has less than minPoints points associated with it.  Setting this allows you to specify a minimum amount of data you would like each shape to have.
 */
- (void)rdpReducePointsWithEpsilon:(CGFloat)epsilon minimumPointsPerRecord:(NSInteger)minPoints;

/*! Reduces the number of points in a single record of our Shapefile.
 * If a record has multiple parts, then each part will be analyzed separately.
 * \param record The record to reduce.
 * \param epsilon This determines how close the new line should be to the original.  Higher values of epsilon will further reduce the number of points, while low values of epsilon will retain more points.  Epsilon can be thought of as the precision you would like your points to have.  If you want your points drawn to the nearest 0.1 X/Y, then epsilon should be 0.1.
 * \returns A new GSShapefileRecord.
 */
- (GSShapefileRecord *)rdpReducePointsInRecord:(GSShapefileRecord *)record epsilon:(CGFloat)epsilon;

/*! When drawing a line between linePoint1 and linePoint2, this method will calculate the distance point p is away from the line.
 * \param p The point to use while calculating the distance from the line.
 * \param linePoint1 The first point component of the line we are calculating the distance from.
 * \param linePoint2 The second point component of the line we are calculating the distance from.
 * \returns The distance p is from the line(linePoint1, linePoint2).
 */
- (CGFloat)perpendicularDistanceForPoint:(GSShapefilePoint)p inLineBetweenPoint1:(GSShapefilePoint)linePoint1 point2:(GSShapefilePoint)linePoint2;

@end
