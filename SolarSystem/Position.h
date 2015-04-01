
//
//  Position.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#ifndef SolarSystem_Position_h
#define SolarSystem_Position_h


#endif

#import <UIKit/UIKit.h>

@interface Position : NSObject

//Initialize for planet with known periods, amplitude, and relative position
-(Position*) initWithRelativePosition:(Position*) relativePosition yearPeriod:(float) yearPeriod amplitude: (float) amplitude dayPeriod: (float) dayPeriod percentOribit:(float) percentOribit relativeSize:(float) relativeSize;

//Default initiallizer
- (Position*) init;

//Returns an array containing floats with the x, y, and z coordinates of the object respectively
- (NSArray*) currentLocation;

//Returns an array containing floats with the next values of the x, y, and z coordinates of the object respectively
- (NSArray*) nextLocation;

//Returns an array containing floats with the next values of the x, y, and z coordinates of the object respectively
- (NSArray*) nextLocationWithScale:(float) scale;

//Returns a NSNumber containing a float with the next value of the object rotation in degrees
- (NSNumber*) nextRotation;

- (float) getRelativeSize;

//Checks if an opengl xy coordinate is near the position _x, _y within a certain tolerance
- (Boolean) isNearbyX:(float) x Y:(float) y;

- (void) updateTiltSpeedWithSpeed:(float) speed;

- (void) addTimeDifference:(float) timeDifference;

@end