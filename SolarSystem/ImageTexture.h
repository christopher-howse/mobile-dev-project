//
//  ImageTextures.h
//  Modeling
//
//  Created by Minglun Gong on 20/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <CoreGraphics/CGImage.h>
#import <UIKit/UIImage.h>
@interface ImageTexture : NSObject
- (ImageTexture*) initFrom: (NSString *)file;
- (void)dealloc;
- (void)reloadFrom: (NSString *)file;
- (void)bind;
- (void)bindToUnit: (int)unit;
@end