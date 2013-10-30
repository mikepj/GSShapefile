//
//  GSShapefileHelper.m
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

#import "GSShapefileHelper.h"

@implementation GSShapefileHelper

#pragma mark Buffer Readers
+ (NSInteger)fetchIntegerFromPointer:(const void *)pointer isBigEndian:(BOOL)bigEndian {
	uint32_t r;
	memcpy(&r, pointer, sizeof(uint32_t));
	if (bigEndian) r = CFSwapInt32BigToHost(r);
	else r = CFSwapInt32LittleToHost(r);
	return (NSInteger)r;
}

+ (CGFloat)fetchFloatFromPointer:(const void *)pointer {
	double r;
	memcpy(&r, pointer, sizeof(double));
	return (CGFloat)r;
}

@end
