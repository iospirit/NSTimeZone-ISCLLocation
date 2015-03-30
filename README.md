# NSTimeZone+ISCLLocation
Category for NSTimeZone that provides Core Location CLLocations and ISO 3166 country codes for named time zones (e.g. "Europe/Berlin") from the IANA Time Zone Database. Provides location data too general to invade the privacy of the user, but sufficient to calculate f.ex. sunrise and sunset times. Includes the database, so it works without GPS and network connection. Works with iOS and OS X.

*by [@felix_schwarz](https://twitter.com/felix_schwarz/)*

## Inspiration
I looked for a way to support day and night modes in an upcoming iOS app I'm working on. It is an integral part of the user experience, so ideally, it should "just work" - without requiring any steps on the part of the user.

Core Location would prompt and require users to share their precise location (whereas an approximation would do). It also would need access to GPS and/or the Internet. That's a lot of moving parts.

Since the time zone set on most devices takes the form of "Continent/City" (f.ex. "Europe/Berlin") *and* is updated by iOS by default, it immediately felt like a better choice. However, NSTimeZone does not provide any location information out of the box.

This category fills that gap, adding CLLocation and ISO 3166 country code accessors to NSTimeZone.

## Adding NSTimeZone+ISCLLocation to your project
* Add NSTimeZone+ISCLLocation.m and NSTimeZone+ISCLLocation.h to your project's sources
* Add zone.tab to your project's resources so that they're included in the same bundle as the object code for NSTimeZone+ISCLLocation.m
* Add the CoreLocation.framework to your project (necessary to use the CLLocation class)

## Usage

### Get approximate location as CLLocation

```objc
#import "NSTimeZone+ISCLLocation.h"

É

NSTimeZone *timeZone = [NSTimeZone localTimeZone];
CLLocation *location;

if ((location = [timeZone approximateLocation]) != nil)
{
	// Location found in database
	NSLog(@"Location of this timezone: %@", location);
}
else
{
	// No location found in database. 
	NSLog(@"No location found for timezone %@", timeZone.name);
}
```

### Get the ISO 3166 country code

```objc
#import "NSTimeZone+ISCLLocation.h"

É

NSTimeZone *timeZone = [NSTimeZone localTimeZone];
NSString *countryCode;

if ((countryCode = [timeZone ISO3166CountryCode]) != nil)
{
	// Location found in database
	NSLog(@"Country of this timezone: %@", countryCode);
}
else
{
	// No location found in database. 
	NSLog(@"No country found for timezone %@", timeZone.name);
}
```

### Caching

* Calls to -[NSTimeZone approximateLocation] and -[NSTimeZone ISO3166CountryCode] will cache results and reuse them on subsequent calls.
* If no previous result can be found in the cache, the entire zone.tab file is loaded and parsed.
* To avoid parsing the zone.tab file more than once, call +[NSTimeZone preloadTimeZoneLocationTable] before using the other methods. That will preload the time zone database and keep it in memory.

### Sunrise and sunset

Pair it with [CLLocation-SunriseSunset](https://github.com/BigZaphod/CLLocation-SunriseSunset) to calculate sunrise and sunset times.

## Data

NSTimeZone+ISCLLocation uses data from the [IANA Time Zone Database](https://www.iana.org/time-zones).

## License

NSTimeZone+ISCLLocation is MIT licensed.
