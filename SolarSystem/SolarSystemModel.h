//
//  SolarSystemModel.h
//  SolarSystem
//
//  Created by Christopher Howse on 2015-04-01.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#ifndef SolarSystem_SolarSystemModel_h
#define SolarSystem_SolarSystemModel_h


#endif
#import "PlanetModel.h"
#import "ImageTexture.h"
#import "OrbitTrail.h"

@interface SolarSystemModel : NSObject

- (SolarSystemModel*) init;

- (PlanetModel*) getPlanetByIndex:(int) index;

- (ImageTexture*) getTextureByIndex:(int)index;

- (OrbitTrail*) getOrbitByIndex:(int)index;

@end