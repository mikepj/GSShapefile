//
//  GSShapefileHelper.h
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

#define SHAPEFILE_INT_SIZE (4)
#define SHAPEFILE_DOUBLE_SIZE (8)

typedef enum {
	GSShapefileShapeTypeNull = 0,
	GSShapefileShapeTypePoint = 1,
	GSShapefileShapeTypePolyLine = 3,
	GSShapefileShapeTypePolygon = 5,
	GSShapefileShapeTypeMultiPoint = 8,
	GSShapefileShapeTypePointZ = 11,
	GSShapefileShapeTypePolyLineZ = 13,
	GSShapefileShapeTypePolygonZ = 15,
	GSShapefileShapeTypeMultiPointZ = 18,
	GSShapefileShapeTypePointM = 21,
	GSShapefileShapeTypePolyLineM = 23,
	GSShapefileShapeTypePolygonM = 25,
	GSShapefileShapeTypeMultiPointM = 28,
	GSShapefileShapeTypeMultiPatchT = 31
} GSShapefileShapeType;

@interface GSShapefileHelper : NSObject

#pragma mark Buffer Readers
/*! Uses the given pointer to read a 32 bit integer and return it as an NSInteger.
 *  This does all appropriate casting and endian conversion.
 * \param pointer A location in memory to treat as an integer.
 * \param bigEndian Whether the pointer should be treated as data in big endian format.  If in doubt, pass NO.
 * \returns An NSInteger with the value.
 */
+ (NSInteger)fetchIntegerFromPointer:(const void *)pointer isBigEndian:(BOOL)bigEndian;

/*! Uses the given pointer to read a 64 bit double and return it as an CGFloat.
 * \param pointer A location in memory to treat as a double.
 * \returns An CGFloat with the value.
 */
+ (CGFloat)fetchFloatFromPointer:(const void *)pointer;

#pragma mark Buffer Writers
/*! Casts the given NSInteger into an uint32_t, optionally converts endianness, and writes it to the location specified by pointer.
 * \param i The integer to write.
 * \param pointer The buffer location to write to.  This method assumes at least 4 bytes of memory is allocated at the buffer pointer.
 * \param bigEndian YES if the data should be written in big endian format.
 */
+ (void)writeInteger:(NSInteger)i toBuffer:(void *)pointer useBigEndian:(BOOL)bigEndian;

/*! Casts the given CGFloat as a double and writes it to the location specified by pointer.
 * \param f The CGFloat to write.
 * \param pointer The buffer location to write to.  This method assumes at least 8 bytes of memory is allocated at the buffer pointer.
 */
+ (void)writeFloat:(CGFloat)f toBuffer:(void *)pointer;

@end
