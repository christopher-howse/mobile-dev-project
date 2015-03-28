//
//  Position.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Position.h"
#import <math.h>

@interface Position ()
{
    float _x, _y, _z; //the location coordinates for the object
    float _yearPeriod; //the time it takes the object to rotate around it's object of gravitational pull
    float _amplitude; //the distance from the center of the object to the center of it's object of gravitational pull
    float _dayPeriod; //the time it takes the object to rotate around it's central axis
    float _rotation; //the number of degrees the object has been rotated
    float _locFrameNum, _rotFrameNum; //values to track location and rotation progress
    float _tiltSpeed; //rate at which time passes based on the tilt of the device
    Position *_relativePosition; //the position of the object's object of gravitational pull. ie. For the earth -> the sun, for the moon -> the earth
}
@end

@implementation Position

//Initialize for planet with known periods, amplitude, and relative position
-(Position*) initWithRelativePosition:(Position*) relativePosition yearPeriod:(float) yearPeriod amplitude: (float) amplitude dayPeriod: (float) dayPeriod percentOribit:(float) percentOribit
{
    //initialize with the default initializer first
    self = [self init];
    
    if(self)
    {
        _yearPeriod = yearPeriod;
        _amplitude = amplitude;
        _dayPeriod = dayPeriod;
        _relativePosition = relativePosition;
        
        NSArray* relativeLocation = [_relativePosition currentLocation];
        float relativeX = [[relativeLocation objectAtIndex:0] floatValue];
        float relativeY = [[relativeLocation objectAtIndex:1] floatValue];
        
        //percentOrbit to radians
        float radians = (percentOribit/100) * (2*M_PI);
        
        //set the initial location
        _x = (_amplitude * cos(radians)) + relativeX;
        _y = (_amplitude * sin(radians)) + relativeY;
        
        //set locFrameNum based on radians
        _locFrameNum = ((percentOribit/100) * _yearPeriod);
    }
    
    return self;
}

//Default initiallizer
-(Position*) init
{
    self = [super init];
    
    if(self)
    {
        //initially set everything to 0/nil
        _locFrameNum = 0;
        _rotFrameNum = 0;
        _yearPeriod = 0;
        _x = 0;
        _y = 0;
        _z = 0;
        _amplitude = 0;
        _dayPeriod = 0;
        _rotation = 0;
        _tiltSpeed = 0.1;
        _relativePosition = nil;
    }
    
    return self;
}

//Returns an array containing floats with the x, y, and z coordinates of the object respectively
- (NSArray*) currentLocation
{
    //format x, y, z coordinates into an NSArray object
    return [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:_x], [NSNumber numberWithFloat:_y], [NSNumber numberWithFloat:_z], nil];
}

//Returns an array containing floats with the next values of the x, y, and z coordinates of the object respectively
- (NSArray*) nextLocation
{
    return [self nextLocationWithScale:1];
}

- (NSArray*) nextLocationWithScale:(float) scale
{
    //find the relative offsets based on the object's object of gravitational pull
    NSArray* relativeLocation = [_relativePosition currentLocation];
    float relativeX = [[relativeLocation objectAtIndex:0] floatValue];
    float relativeY = [[relativeLocation objectAtIndex:1] floatValue];
    
    //simple equation for sinusoidal x and y coordinates
    _x = ((_amplitude*scale) * cosf((2*M_PI*_locFrameNum)/_yearPeriod)) + relativeX;
    _y = ((_amplitude*scale) * sinf((2*M_PI*_locFrameNum)/_yearPeriod)) + relativeY;
    _z = 0;
    
    //update the progression of the orbit
    _locFrameNum += _tiltSpeed;
    
    //if the orbit has completed, reset
    //this avoids overflowing max float value (however unlikely)
    if(_locFrameNum >= _yearPeriod)
    {
        _locFrameNum = fmodf(_locFrameNum, _yearPeriod);
    }
    
    //return the new location formatted as an NSArray
    return [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:_x], [NSNumber numberWithFloat:_y], [NSNumber numberWithFloat:_z], nil];
}

//Returns a NSNumber containing a float with the next value of the object rotation in degrees
- (NSNumber*) nextRotation
{
    //simple equation to convert rotation progression into degrees
    _rotation = (360 * _rotFrameNum) /_dayPeriod;
    
    //update the progression of the rotation
    _rotFrameNum += _tiltSpeed;
    
    //if the rotation has completed, reset
    //this avoids overflowing max float value
    if(_rotFrameNum >= _dayPeriod)
    {
        _rotFrameNum = fmodf(_rotFrameNum, _dayPeriod);
    }
    
    //return the new rotation value as a NSNumber
    return [[NSNumber alloc] initWithFloat:_rotation];
}

//Checks if an opengl xy coordinate is near the position _x, _y within a certain tolerance
- (Boolean) isNearbyX:(float) x Y:(float) y
{
    float tolerance = 0.08;
    if (fabsf(x - _x) < tolerance && fabsf(y + _y) < tolerance)
    {
        return true;
    }
    else return false;
}

- (void) updateTiltSpeedWithSpeed:(float) speed
{
    _tiltSpeed = MAX(0.01, speed + 1);
}

- (void) addTimeDifference:(float) timeDifference
{
    _locFrameNum += timeDifference;
    _locFrameNum = fmodf(_locFrameNum, _yearPeriod);
    _rotFrameNum += timeDifference;
    _rotFrameNum = fmodf(_rotFrameNum, _dayPeriod);
}

@end