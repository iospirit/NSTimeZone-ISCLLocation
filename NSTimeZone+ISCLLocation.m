//
//  NSTimeZone+ISCLLocation.m
//  ISKit
//
//  Created by Felix Schwarz on 30.03.15.
//  Copyright (c) 2015 IOSPIRIT GmbH. All rights reserved.
//

#import "NSTimeZone+ISCLLocation.h"

// Keys used in lookup table
static NSString *kISTZCLCountryCodeKey  = @"CountryCode";
static NSString *kISTZCLCoordinatesKey  = @"Coordinates";
static NSString *kISTZCLTimeZoneNameKey = @"TimeZone";

// Global lookup table
static NSDictionary *sISTimeZoneLocationDict = nil;
static NSMutableDictionary *sISTimeZoneLocationCacheDict = nil;
static NSMutableDictionary *sISTimeZoneCountryCodeCacheDict = nil;

// Class to help find the bundle from which this category originates to automatically locate the "zone.tab" file
@interface ISNSTimeZoneCLLocationCategoryFinder : NSObject
@end

@implementation ISNSTimeZoneCLLocationCategoryFinder
@end

// Implementation
@implementation NSTimeZone (ISCLLocation)

#pragma mark - Tools
+ (double)IS_degreesFromISO6709String:(NSString *)isoString
{
	double resultDegrees = 0;
	NSString *plusMinusString=nil, *degreesString=nil, *minutesString=nil, *secondsString=nil;

	/*
	# 2.  Latitude and longitude of the area's principal location
	#     in ISO 6709 sign-degrees-minutes-seconds format,
	#     either +-DDMM+-DDDMM or +-DDMMSS+-DDDMMSS,
	#     first latitude (+ is north), then longitude (+ is east).
	*/
	
	if (isoString.length >= 5)
	{
		plusMinusString = [isoString substringToIndex:1];
		
		switch (isoString.length)
		{
			case 5:
				// +-DDMM
				degreesString = [isoString substringWithRange:NSMakeRange(1, 2)];
				minutesString = [isoString substringWithRange:NSMakeRange(3, 2)];
			break;
			
			case 6:
				// +-DDDMM
				degreesString = [isoString substringWithRange:NSMakeRange(1, 3)];
				minutesString = [isoString substringWithRange:NSMakeRange(4, 2)];
			break;
			
			case 7:
				// +-DDMMSS
				degreesString = [isoString substringWithRange:NSMakeRange(1, 2)];
				minutesString = [isoString substringWithRange:NSMakeRange(3, 2)];
				secondsString = [isoString substringWithRange:NSMakeRange(5, 2)];
			break;

			case 8:
				// +-DDDMMSS
				degreesString = [isoString substringWithRange:NSMakeRange(1, 3)];
				minutesString = [isoString substringWithRange:NSMakeRange(4, 2)];
				secondsString = [isoString substringWithRange:NSMakeRange(6, 2)];
			break;
		}
		
		if (degreesString!=nil)
		{
			resultDegrees += [degreesString doubleValue];
		}

		if (minutesString!=nil)
		{
			resultDegrees += ([minutesString doubleValue]/(double)60.0);
		}

		if (secondsString!=nil)
		{
			resultDegrees += ([secondsString doubleValue]/(double)3600.0);
		}

		if ([plusMinusString isEqual:@"-"])
		{
			resultDegrees *= (double)-1.0;
		}
	}
	
	return (resultDegrees);
}

+ (NSDictionary *)IS_recordsByTimeZoneFromZoneTabFile:(NSURL *)zoneTabURL onlyZoneName:(NSString *)onlyZoneName
{
	NSString *zoneTabContents = nil;
	NSError *error = nil;
	NSMutableDictionary *recordsByTimeZone = nil;
	
	if (zoneTabURL == nil)
	{
		@synchronized(self)
		{
			if (sISTimeZoneLocationDict != nil)
			{
				return ([[sISTimeZoneLocationDict retain] autorelease]);
			}
		}
	
		zoneTabURL = [[NSBundle bundleForClass:[ISNSTimeZoneCLLocationCategoryFinder class]] URLForResource:@"zone" withExtension:@"tab"];
	}

	if ((zoneTabContents = [[NSString alloc] initWithContentsOfURL:zoneTabURL encoding:NSUTF8StringEncoding error:&error]) != nil)
	{
		NSString *tab = [NSString stringWithFormat:@"\t"];
		NSArray *zoneTabLines = nil;

		recordsByTimeZone = [NSMutableDictionary dictionary];
		
		// Split in lines
		zoneTabLines = [zoneTabContents componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
		
		// Parse lines
		for (NSString *zoneTabLine in zoneTabLines)
		{
			// Ignore comments
			if (![zoneTabLine hasPrefix:@"#"])
			{
				NSArray *zoneTabLineColumns;
				
				// Split in columns
				if ((zoneTabLineColumns = [zoneTabLine componentsSeparatedByString:tab]) != nil)
				{
					NSUInteger columnCount = [zoneTabLineColumns count];
				
					// Minimum number of columns
					if (columnCount >= 3)
					{
						BOOL addRecord = YES;
						NSString *countryCode  = zoneTabLineColumns[0]; // f.ex. DE
						NSString *coordinates  = zoneTabLineColumns[1]; // f.ex. +5230+01322
						NSString *timeZoneName = zoneTabLineColumns[2]; // f.ex. Europe/Berlin
						
						if (onlyZoneName != nil)
						{
							addRecord = [timeZoneName isEqual:onlyZoneName];
						}
							
						if (addRecord)
						{
							// Add record
							[recordsByTimeZone setObject:@{
								kISTZCLCountryCodeKey	:	countryCode,
								kISTZCLCoordinatesKey	:	coordinates,
								kISTZCLTimeZoneNameKey	:	timeZoneName
							} forKey:timeZoneName];
							
							if (onlyZoneName != nil)
							{
								// If only this time zone's record was requested, we can skip parsing the rest
								break;
							}
						}
					}
				}
			}
		}
		
		[zoneTabContents release];
	}
	
	return (recordsByTimeZone);
}

+ (CLLocation *)IS_locationFromCoordinatesString:(NSString *)coordinateString
{
	NSUInteger coordinatesLength = [coordinateString length];

	// Extract coordinates
	if (coordinatesLength > 1)
	{
		NSRange signRange;

		signRange = [coordinateString rangeOfString:@"+" options:0 range:NSMakeRange(1, coordinatesLength-1)];
		
		if (signRange.location == NSNotFound)
		{
			signRange = [coordinateString rangeOfString:@"-" options:0 range:NSMakeRange(1, coordinatesLength-1)];
		}
		
		if (signRange.location != NSNotFound)
		{
			double longitude, latitude;
		
			// Convert from ISO6709 to degrees
			longitude = [self IS_degreesFromISO6709String:[coordinateString substringToIndex:signRange.location]];
			latitude  = [self IS_degreesFromISO6709String:[coordinateString substringFromIndex:signRange.location]];
			
			// Create a CLLocation from this
			return ([[[CLLocation alloc] initWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude] autorelease]);
		}
	}
	
	return (nil);
}

+ (NSDictionary *)IS_timeZoneDictForTimeZoneName:(NSString *)timeZoneName
{
	if (timeZoneName != nil)
	{
		NSDictionary *recordsByTimeZoneDict = [[self class] IS_recordsByTimeZoneFromZoneTabFile:nil onlyZoneName:timeZoneName];
		
		if ((timeZoneName!=nil) && (recordsByTimeZoneDict!=nil))
		{
			return ([recordsByTimeZoneDict objectForKey:timeZoneName]);
		}
	}
	
	return (nil);
}

#pragma mark - API
+ (void)preloadTimeZoneLocationTable
{
	@synchronized(self)
	{
		if (sISTimeZoneLocationDict==nil)
		{
			sISTimeZoneLocationDict = [[self IS_recordsByTimeZoneFromZoneTabFile:nil onlyZoneName:nil] retain];
		}
	}
}

- (NSString *)ISO3166CountryCode
{
	NSString *returnCountryCode = nil;
	NSDictionary *timeZoneRecord = nil;
	NSString *tzName = self.name;
	
	if (tzName == nil) { return(nil); }

	@synchronized(self)
	{
		if (sISTimeZoneCountryCodeCacheDict == nil)
		{
			sISTimeZoneCountryCodeCacheDict = [[NSMutableDictionary alloc] init];
		}
		else
		{
			if ((returnCountryCode = [sISTimeZoneCountryCodeCacheDict objectForKey:tzName]) != nil)
			{
				return (returnCountryCode);
			}
		}
	}

	if ((timeZoneRecord = [[self class] IS_timeZoneDictForTimeZoneName:self.name]) != nil)
	{
		if ((returnCountryCode = [timeZoneRecord objectForKey:kISTZCLCountryCodeKey]) != nil)
		{
			@synchronized(self)
			{
				[sISTimeZoneCountryCodeCacheDict setObject:returnCountryCode forKey:tzName];
			}
		}
	}
	
	return (returnCountryCode);
}

- (CLLocation *)approximateLocation
{
	CLLocation *returnLocation = nil;
	NSDictionary *timeZoneRecord = nil;
	NSString *tzName = self.name;
	
	if (tzName == nil) { return(nil); }

	@synchronized(self)
	{
		if (sISTimeZoneLocationCacheDict == nil)
		{
			sISTimeZoneLocationCacheDict = [[NSMutableDictionary alloc] init];
		}
		else
		{
			if ((returnLocation = [sISTimeZoneLocationCacheDict objectForKey:tzName]) != nil)
			{
				return (returnLocation);
			}
		}
	}
	
	if ((timeZoneRecord = [[self class] IS_timeZoneDictForTimeZoneName:tzName]) != nil)
	{
		if ((returnLocation = [[self class] IS_locationFromCoordinatesString:[timeZoneRecord objectForKey:kISTZCLCoordinatesKey]]) != nil)
		{
			@synchronized(self)
			{
				[sISTimeZoneLocationCacheDict setObject:returnLocation forKey:tzName];
			}
		}
	}
	
	return (returnLocation);
}

@end
