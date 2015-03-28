//
//  StarDate.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-28.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#ifndef SolarSystem_StarDate_h
#define SolarSystem_StarDate_h


#endif

@interface StarDate : NSObject

- (StarDate*) init;

//Used to update time with interface inputs
- (void) updateTimeWithDate: (NSDate*) date;

//Used to update time with standard frame update
- (void) updateTimeWithTilt: (float) tilt;

- (float) getTimeDifferenceUpdate;

- (NSString*) getDisplayTime;

@end