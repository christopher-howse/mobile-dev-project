//
//  StarDate.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-28.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StarDate.h"

@interface StarDate()
{
    NSDate *_date;
    float _timeDifference;
}
@end

@implementation StarDate

- (StarDate*) init
{
    self = [super init];
    
    if(self)
    {
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSGregorianCalendar];
        
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        dateComponents.year = 2000;
        dateComponents.month = 1;
        dateComponents.day = 1;
        dateComponents.hour = 0;
        dateComponents.minute = 0;
        dateComponents.second = 0;
        
        _date = [gregorian dateFromComponents: dateComponents];
        _timeDifference = 0;
    }
    
    return self;
}

- (void) updateTimeWithDate: (NSDate*) date
{
    NSTimeInterval secondsBetween = [_date timeIntervalSinceDate:date];
    _date = [_date dateByAddingTimeInterval:-secondsBetween];

    //convert seconds into number of earth years
    _timeDifference = (-secondsBetween/31540000)*365.25636;
}


- (void) updateTimeWithTilt: (float) tilt
{
     float translatedTilt = MAX(0, tilt + 1);
    //convert tilt value into time
    //how much of a year has passed = tilt/365.25636
    //number of seconds in a year = 3.154*10^7
    NSTimeInterval increment = (translatedTilt/365.25636)*31540000;
    
    _date = [_date dateByAddingTimeInterval:increment];
}


- (float) getTimeDifferenceUpdate
{
    return _timeDifference;
}


- (NSString*) getDisplayTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy MMM dd"];
    return [formatter stringFromDate:_date];
}

@end