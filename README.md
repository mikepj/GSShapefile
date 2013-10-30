GSShapefile
===========

These Objective-C classes will read and parse ESRI Shapefiles.  This code follows the Shapefile specification found at http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf.

Requirements:
  ARC memory management

Currently supported shape types include:
  Point
  Polygon
  PolyLine

Sample code:
```
  NSData *filedata = [[NSData alloc] initWithContentsOfFile:@"somefile.shp"];
  GSShapefile *shapefile = [[GSShapefile alloc] initWithData:fileData];
  if (!shapefile) return NO;
	
  // Count the number of points in the shapefile.
  NSInteger totalPoints = 0;
  for (GSShapefileRecord *record in shapefile.records) {
    totalPoints += record.pointsCount;
	// Can access point data using record.points[index].x and record.points[index].y
  }
  NSLog(@"Total point count: %d (%d records)", totalPoints, shapefile.records.count);
```