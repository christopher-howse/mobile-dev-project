//
//  OrbitTrail.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-22.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrbitTrail.h"

@interface OrbitTrail()
{
    int _numSeg, _numIndex;
    float _amplitude;
    
    GLfloat *_vertices;
    GLfloat *_colors;
    Position *_relativePosition;
}
@end

@implementation OrbitTrail

-(OrbitTrail*) initWithSections:(int)sections amplitude:(float)amplitude relativePosition:(Position*) relativePosition
{
    self = [super init];
    
    if(self)
    {
        _relativePosition = relativePosition;
        //find the relative offsets based on the object's object of gravitational pull
        NSArray* relativeLocation = [_relativePosition currentLocation];
        float relativeX = [[relativeLocation objectAtIndex:0] floatValue];
        float relativeY = [[relativeLocation objectAtIndex:1] floatValue];
        
        _numSeg = sections;
        _amplitude = amplitude;
        
        _vertices = (GLfloat*)malloc(3*sections*sizeof(GLfloat));
        _colors = (GLfloat*)malloc(4*sections*sizeof(GLfloat));
        
        for(int i=0; i<sections*3; i+=3)
        {
            _vertices[i] = _amplitude * cos(2*M_PI*i/(3*sections)) + relativeX;
            _vertices[i+1] = _amplitude * sin(2*M_PI*i/(3*sections)) + relativeY;
            _vertices[i+2] = 0;
        }
        
        for(int j=0; j < sections*4; j+=4)
        {
            _colors[j] = 1;
            _colors[j+1] = 1;
            _colors[j+2] = 1;
            _colors[j+3] = 1;
        }
    }
    
    return self;
}

-(void)dealloc
{
    free(_vertices);
}

-(void)updateVerticesWithScale:(float)scale xTrans:(float)xTrans yTrans:(float)yTrans
{
    //find the relative offsets based on the object's object of gravitational pull
    NSArray* relativeLocation = [_relativePosition currentLocation];
    float relativeX = [[relativeLocation objectAtIndex:0] floatValue];
    float relativeY = [[relativeLocation objectAtIndex:1] floatValue];
    
    for(int i=0; i<_numSeg*3; i+=3)
    {
        _vertices[i] = ((_amplitude*scale) * cos(2*M_PI*i/(3*_numSeg))) + xTrans + relativeX;
        _vertices[i+1] = ((_amplitude*scale) * sin(2*M_PI*i/(3*_numSeg))) + yTrans + relativeY;
        //maybe need third for skewing
    }
}

-(void)drawOpenGLES1
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, _vertices);
    glNormalPointer(GL_FLOAT, 0, _vertices);
    glColorPointer(4, GL_FLOAT, 0, _colors);
    glLineWidth(5);
    
    glDrawArrays(GL_LINE_LOOP, 0, _numSeg);
    
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
}

@end

