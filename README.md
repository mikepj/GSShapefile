GSShapefile
===========

These Objective-C classes will read and parse ESRI Shapefiles.  This code follows the Shapefile specification found at http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf.

Note:  I have not included this code in a production app yet.  I will remove this note once it has been tested enough to release.

Requirements:
- ARC memory management

Currently supported shape types include:
- Point
- Polygon
- PolyLine

Possible features to add down the line:
- [ ] Support of additional shape types.
- [ ] Support parsing meta data from related files (.shx, .dbf, etc).

Sample code:
```
  #import "GSShapefile.h"


  NSData *filedata = [[NSData alloc] initWithContentsOfFile:@"somefile.shp"];
  GSShapefile *shapefile = [[GSShapefile alloc] initWithData:fileData];
  if (!shapefile) return NO;
	
  // Count the number of points in the shapefile.
  NSInteger totalPoints = 0;
  for (GSShapefileRecord *record in shapefile.records) {
    totalPoints += record.pointsCount;

	// Get the shape type of this record using record.shapeType
	// Access point data using record.points[index].x and record.points[index].y where index is between 0 and record.pointsCount-1
	// Some shape types have "parts" associated with them.  You can find the parts listed as an array of NSNumbers in record.parts.
  }
  NSLog(@"Total point count: %d (%d records)", totalPoints, shapefile.records.count);
```

If you are planning to reduce the number of points in your Shapefile before working with it, you can use the built-in Ramer–Douglas–Peucker algorithm
```
  #import "GSShapefile.h"
  #import "GSShapefile+RDP.h"

  NSData *filedata = [[NSData alloc] initWithContentsOfFile:@"somefile.shp"];
  GSShapefile *shapefile = [[GSShapefile alloc] initWithData:fileData];
  if (!shapefile) return NO;

  NSUInteger originalNumPoints = [shapefile totalPointCount];
  [shapefile rdpReducePointsWithEpsilon:1];
  NSUInteger newNumPoints = [shapefile totalPointCount];
  NSLog(@"Reduced the number of points from %d to %d.", originalNumPoints, newNumPoints);
```
