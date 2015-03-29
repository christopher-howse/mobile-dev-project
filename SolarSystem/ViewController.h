//
//  ViewController.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

- (void) updateCMDataWithX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z pitch:(double)pitch roll:(double)roll yaw:(double)yaw;

@end

