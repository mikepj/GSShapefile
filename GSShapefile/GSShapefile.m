//
//  GSShapefile.m
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

#import "GSShapefile.h"
#import "GSShapefileHelper.h"

@interface GSShapefile ()
#pragma mark Parse Helpers
/*! Checks that the magic number and version of the shapefile is valid.
 * \returns YES if the file data is valid.
 */
- (BOOL)shapefileIsValid:(NSData *)shapefileData;

/*! Parses the shapefile data and returns a set of ranges where each record resides with respect to the start of the data file.
 * \param shapefileData The NSData object with the shapefile content.
 * \returns An NSArray of NSValue objects.  Each NSValue object contains NSRange data.
 */
- (NSArray *)parseShapefileRecords:(NSData *)shapefileData;
@end

@implementation GSShapefile

- (instancetype)initWithData:(NSData *)shpData {
	self = [super init];
	if (self) {
		BOOL success = [self parseSHPData:shpData];
		if (!success) self = nil;
	}
	return self;
}

- (BOOL)parseSHPData:(NSData *)shpData {
	// Check to make sure the data passed in is a valid Shapefile.
	if (![self shapefileIsValid:shpData]) return NO;

	// Parse our header.  We know the file is long enough to have a header because shapefileIsValid returned YES.
	const unsigned char *fileIndex = shpData.bytes;		// Get a pointer to the buffer in our NSData object.  This is read-only.
	GSShapefileBoundingBox *b = [[GSShapefileBoundingBox alloc] init];
	b.xMin = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[36]];
	b.yMin = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[44]];
	b.xMax = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[52]];
	b.yMax = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[60]];
	b.zMin = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[68]];
	b.zMax = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[76]];
	b.mMin = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[84]];
	b.mMax = [GSShapefileHelper fetchFloatFromPointer:&fileIndex[92]];
	self.boundingBox = b;
	
	self.records = [self parseShapefileRecords:shpData];
	
	return (self.records != nil);
}

- (NSUInteger)totalPointCount {
	NSUInteger vertexCount = 0;
	for (GSShapefileRecord *record in self.records) vertexCount += record.pointsCount;
	return vertexCount;
}

#pragma mark Parse Helpers
- (BOOL)shapefileIsValid:(NSData *)shapefileData {
	if (!shapefileData) return NO;
	if (shapefileData.length < 100) return NO;
	
	const unsigned char *fileIndex = shapefileData.bytes;		// Get a pointer to the buffer in our NSData object.  This is read-only.
	
	// Check that the magic number of the header block matches 9994.
	if ([GSShapefileHelper fetchIntegerFromPointer:fileIndex isBigEndian:YES] != 0x270a) return NO;
	
	// Read the version and check that it matches 1000.
	if ([GSShapefileHelper fetchIntegerFromPointer:fileIndex + 28 isBigEndian:NO] != 0x03e8) return NO;
	
	return YES;
}

- (NSArray *)parseShapefileRecords:(NSData *)shapefileData {
	if (!shapefileData) return nil;
	
	const unsigned char *fileStart = shapefileData.bytes;		// Get a pointer to the buffer in our NSData object.  This is read-only.
	NSUInteger fileIndex = 0;
	
	// Skip past the header.
	fileIndex = 100;
	
	NSMutableArray *records = [NSMutableArray array];
	
	while (fileIndex < shapefileData.length) {
		// Check if we are going to read beyond EOF.
		if (fileIndex + (2 * SHAPEFILE_INT_SIZE) > shapefileData.length) break;
		NSInteger contentLength = [GSShapefileHelper fetchIntegerFromPointer:fileStart + fileIndex + SHAPEFILE_INT_SIZE isBigEndian:YES] * 2;
		NSUInteger totalRecordSize = contentLength + (2 * SHAPEFILE_INT_SIZE);
		
		// Check if we are going to return an NSRange beyond EOF
		if (fileIndex + totalRecordSize > shapefileData.length) break;
		
		GSShapefileRecord *newRecord = [[GSShapefileRecord alloc] initWithRecordData:[shapefileData subdataWithRange:NSMakeRange(fileIndex, totalRecordSize)]];
		if (newRecord) [records addObject:newRecord];
		
		fileIndex += totalRecordSize;
	}
	
	if (records.count == 0) return nil;
	else return records;
}

- (NSData *)saveData {
	// Get NSData objects for all our records.
	NSMutableArray *recordData = [NSMutableArray array];
	
	NSUInteger totalRecordSize = 0;
	for (GSShapefileRecord *record in self.records) {
		NSData *d = [record saveData];
		if (d) {
			[recordData addObject:d];
			totalRecordSize += d.length;
		}
	}
	
	// 100 byte header + records
	NSUInteger headerSize = 100;
	NSUInteger bufferSize = headerSize + totalRecordSize;
	unsigned char *headerBuffer = malloc(headerSize);
	NSUInteger index = 0;
	
	// Write the file magic number.
	[GSShapefileHelper writeInteger:0x270a toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	
	// Bunch of unused fields.
	[GSShapefileHelper writeInteger:0x0000 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	[GSShapefileHelper writeInteger:0x0000 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	[GSShapefileHelper writeInteger:0x0000 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	[GSShapefileHelper writeInteger:0x0000 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	[GSShapefileHelper writeInteger:0x0000 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;
	
	// Write the file length in 16 bit words.
	[GSShapefileHelper writeInteger:bufferSize / 2 toBuffer:headerBuffer + index useBigEndian:YES];
	index += SHAPEFILE_INT_SIZE;

	// Write the file version.
	[GSShapefileHelper writeInteger:0x03e8 toBuffer:headerBuffer + index useBigEndian:NO];
	index += SHAPEFILE_INT_SIZE;
	
	// Write the first record's shape type.
	if (self.records.count) {
		[GSShapefileHelper writeInteger:((GSShapefileRecord *)self.records[0]).shapeType toBuffer:headerBuffer + index useBigEndian:NO];
	}
	else {
		[GSShapefileHelper writeInteger:GSShapefileShapeTypeNull toBuffer:headerBuffer + index useBigEndian:NO];
	}
	index += SHAPEFILE_INT_SIZE;
	
	// Write the bounding box.
	if (self.boundingBox) {
		[GSShapefileHelper writeFloat:self.boundingBox.xMin toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.yMin toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.xMax toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.yMax toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.zMin toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.zMax toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.mMin toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
		[GSShapefileHelper writeFloat:self.boundingBox.mMax toBuffer:headerBuffer + index];
		index += SHAPEFILE_DOUBLE_SIZE;
	}
	else {
		index += 8 * SHAPEFILE_DOUBLE_SIZE;
	}
	
	// Create an NSData object with the header.
	NSMutableData *fileData = [[NSMutableData alloc] initWithBytes:headerBuffer length:headerSize];
	free(headerBuffer);

	// Append all the record data.
	for (NSData *d in recordData) {
		[fileData appendData:d];
	}
	
	return fileData;
}

@end
