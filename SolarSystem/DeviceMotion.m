//
//  DeviceMotion.m
//  SolarSystem
//
//  Created by Jacob Brown on 2015-03-23.
//  Copyright (c) 2015 Jacob Brown. All rights reserved.
//

#import "DeviceMotion.h"
#import "ViewController.h"
#import <CoreMotion/CMMotionManager.h>


@interface DeviceMotion ()
{
    int _filterMode;
    float _avgX, _avgY, _avgZ;
    float _varX, _varY, _varZ;
    ViewController* _controller;
    
}

@property (nonatomic, strong) CMMotionManager *motman;
@property (nonatomic, strong) NSTimer *timer;

- (void)addAcceleration:(CMAcceleration)acc;

@end

@implementation DeviceMotion

@synthesize motman, timer;

//Add a controller to which motion will be passed too
- (DeviceMotion*) initWithController:(ViewController *)controller
{
    self = [super init];
    _controller = controller;
    self.motman = [CMMotionManager new];
    if ((self.motman.accelerometerAvailable)&&(self.motman.gyroAvailable))
        // alternative: self.motman.deviceMotionAvailable == YES iff both accelerometer and gyros are available.
    {
        [self startMonitoringMotion];
    }
    else
    {
        NSLog(@"get a better phone as yours does not have a accelerometer or gyro...");
    }
    return self;
    
}

//Called by the view controller to start polling for motion data
- (void)startMonitoringMotion
{
    self.motman.accelerometerUpdateInterval = 1.0/kMOTIONUPDATEINTERVAL;
    self.motman.gyroUpdateInterval = 1.0/kMOTIONUPDATEINTERVAL;
    self.motman.showsDeviceMovementDisplay = YES;
    [self.motman startAccelerometerUpdates];
    [self.motman startGyroUpdates];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.motman.accelerometerUpdateInterval
                                                  target:self selector:@selector(pollMotion:)
                                                userInfo:nil
                                                 repeats:YES];
}

//Called by the view controller to stop polling mtion data
- (void)stopMonitoringMotion
{
    [self.motman stopAccelerometerUpdates];
    [self.motman stopGyroUpdates];
}

//Actual polling call
- (void)pollMotion:(NSTimer *)timer
{
    CMAcceleration acc = self.motman.accelerometerData.acceleration;
    CMRotationRate rot = self.motman.gyroData.rotationRate;
    float x, y, z;
    [self addAcceleration:acc];
    x = _avgX;
    y = _avgY;
    z = _avgZ;
    [_controller updateCMDataWithX:x y:y z:z pitch:rot.x roll:rot.y yaw:rot.z];
}

#pragma mark - helpers
//used to create low pass filter
- (void)addAcceleration:(CMAcceleration)acc
{
    float alpha = 0.1;
    _avgX = alpha*acc.x + (1-alpha)*_avgX;
    _avgY = alpha*acc.y + (1-alpha)*_avgY;
    _avgZ = alpha*acc.z + (1-alpha)*_avgZ;
    _varX = acc.x - _avgX;
    _varY = acc.y - _avgY;
    _varZ = acc.z - _avgZ;
}



@end
