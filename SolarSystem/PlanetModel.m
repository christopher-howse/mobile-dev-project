//
//  PlanetModel.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//
//  Adapted from Minglun Gong's SphereModel.m in the Modeling Demo
//

#import "PlanetModel.h"

@interface PlanetModel()
{
    int _numSeg, _numIndex, _numVertex;
    
    GLfloat *_vertices;
    GLushort *_indices;
    
    GLuint _vertexBuff, _indexBuff, _tangetBuff;
    
    //Each planet has a position associated with it
    Position* _position;
}
@end

@implementation PlanetModel

-(PlanetModel*) initWithSections:(int)sections position:(Position*) position
{
    self = [super init];
    
    if(self)
    {
        _vertexBuff = _indexBuff = _tangetBuff = 0;
        
        _numSeg = sections, _numVertex = (sections*2+1)*(sections+1), _numIndex = (sections*2+1)*sections*2;
        _vertices = (GLfloat *)malloc(_numVertex*5*sizeof(GLfloat));
        _indices = (GLushort *)malloc(_numIndex*sizeof(GLushort));
        
        for ( int j=0, c=0; j<=sections; j++ ) {
            float y = cos(M_PI*j/sections), xz = sin(M_PI*j/sections), v = (float)j/sections;
            for ( int i=0; i<=sections*2; i++, c+=5 )
                _vertices[c] = cos(M_PI*i/sections) * xz,
                _vertices[c+1] = y,
                _vertices[c+2] = - sin(M_PI*i/sections) * xz,
                _vertices[c+3] = (float)i/sections/2, _vertices[c+4] = v;
        }
        
        for ( int j=0, k=0, c=0; j<sections; j++ )
            for ( int i=0; i<=sections*2; i++, k++, c+=2 )
                _indices[c] = k, _indices[c+1] = k+sections*2+1;
        
        //Set the position for the sphere
        _position = position;
    }
    
    return self;
}

-(void)dealloc
{
    glDeleteBuffers(1, &_vertexBuff);
    glDeleteVertexArraysOES(1, &_indexBuff);
    free(_vertices);
    free(_indices);
}

- (void)createVertexBufferObject
{
    glGenBuffers(1, &_vertexBuff);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuff);
    glBufferData(GL_ARRAY_BUFFER, _numVertex*5*sizeof(GLfloat), _vertices, GL_STATIC_DRAW);
    glGenBuffers(1, &_indexBuff);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuff);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numIndex*sizeof(GLushort), _indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), 0);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), 0);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), ((float*)0)+3);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void)createTangentVBO
{
    GLfloat* tangets = (GLfloat *)malloc(_numVertex*6*sizeof(GLfloat));
    
    for ( int j=0, c=0; j<=_numSeg; j++ ) {
        float y = cos(M_PI*j/_numSeg), xz = sin(M_PI*j/_numSeg);
        for ( int i=0; i<=_numSeg*2; i++, c+=6 )
            tangets[c] = -sin(M_PI*i/_numSeg), tangets[c+1] = 0, tangets[c+2] = cos(M_PI*i/_numSeg),
            tangets[c+3] = cos(M_PI*i/_numSeg)*y, tangets[c+4] = -xz, tangets[c+5] = sin(M_PI*i/_numSeg)*y;
    }
    
    glGenBuffers(1, &_tangetBuff);
    glBindBuffer(GL_ARRAY_BUFFER, _tangetBuff);
    glBufferData(GL_ARRAY_BUFFER, _numVertex*6*sizeof(GLfloat), tangets, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TANGENT);
    glVertexAttribPointer(ATTRIB_TANGENT, 2, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), 0);
    glEnableVertexAttribArray(ATTRIB_BITANGENT);
    glVertexAttribPointer(ATTRIB_BITANGENT, 2, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), ((float*)0)+3);
    
    free(tangets);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void)drawOpenGLES1
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, sizeof(GLfloat)*5, _vertices);
    glNormalPointer(GL_FLOAT, sizeof(GLfloat)*5, _vertices);
    glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat)*5, _vertices+3);
    
    for ( int j=0, c=0; j<_numSeg; j++, c+=(_numSeg*2+1)*2 )
        glDrawElements(GL_TRIANGLE_STRIP, (_numSeg*2+1)*2, GL_UNSIGNED_SHORT, _indices+c);
    
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)drawOpenGLES2
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuff);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuff);
    
    for ( int j=0, c=0; j<_numSeg; j++, c+=(_numSeg*2+1)*2 )
        glDrawElements(GL_TRIANGLE_STRIP, (_numSeg*2+1)*2, GL_UNSIGNED_SHORT, (short*)0+c);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (Position*) getPlanetPosition
{
    return _position;
}

@end