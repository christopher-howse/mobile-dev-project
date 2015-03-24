//
//  DeviceMotion.h
//  SolarSystem
//
//  Created by Jacob Brown on 2015-03-23.
//  Copyright (c) 2015 Jacob Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

#define kFILTERMODENO       0
#define kFILTERMODELOWPASS  1
#define kFILTERMODEHIGHPASS 2

#define kMOTIONUPDATEINTERVAL 15.0

@interface DeviceMotion : NSObject

- (void)startMonitoringMotion;
- (void)stopMonitoringMotion;
- (DeviceMotion*) initWithController: (ViewController*) controller;

@end
