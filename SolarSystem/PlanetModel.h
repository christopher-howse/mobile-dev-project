//
//  PlanetModel.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#ifndef SolarSystem_PlanetModel_h
#define SolarSystem_PlanetModel_h


#endif

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "Position.h"

// VBO attribute index
enum
{
    ATTRIB_POSITION,
    ATTRIB_NORMAL,
    ATTRIB_COLOR,
    ATTRIB_TEXCOORD,
    ATTRIB_TANGENT,
    ATTRIB_BITANGENT,
    
    NUM_ATTRIB
};

@interface PlanetModel : NSObject

-(PlanetModel*) initWithSections:(int)sections position:(Position*) position;
- (void)dealloc;
- (void)drawOpenGLES1;
- (void)drawOpenGLES2;
- (void)createVertexBufferObject;
- (void)createTangentVBO;
- (Position*)getPlanetPosition;

@end
