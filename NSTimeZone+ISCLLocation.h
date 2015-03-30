//
//  NSTimeZone+ISCLLocation.h
//  ISKit
//
//  Created by Felix Schwarz on 30.03.15.
//  Copyright (c) 2015 IOSPIRIT GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface NSTimeZone (ISCLLocation)

/**
 Preloads location/time zone table and keeps it in memory. Use this when you're performing a lot of different location lookups or many ISO 3166 country code lookups.
 */
+ (void)preloadTimeZoneLocationTable;

/**
 Looks up and returns the location for this timezone instance.
 
 @return Location for this timezone. nil if the timezone is not in the database.
 */
- (CLLocation *)approximateLocation;

/**
 Looks up and returns the ISO 3166 country code for this timezone instance.
 
 @return ISO 3166 country code for this timezone. nil if the timezone is not in the database.
 */
- (NSString *)ISO3166CountryCode;

@end
