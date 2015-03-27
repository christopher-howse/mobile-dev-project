//
//  OrbitTrail.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-22.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#ifndef SolarSystem_OrbitTrail_h
#define SolarSystem_OrbitTrail_h


#endif

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "Position.h"

@interface OrbitTrail : NSObject

-(OrbitTrail*) initWithSections:(int)sections amplitude:(float)amplitude relativePosition:(Position*) relativePosition;
-(void) dealloc;
-(void)updateVerticesWithScale:(float)scale xTrans:(float)xTrans yTrans:(float)yTrans;
-(void)drawOpenGLES1;

@end