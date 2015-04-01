//
//  SolarSystemModel.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-04-01.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SolarSystemModel.h"
#import "Position.h"

@interface SolarSystemModel()
{
    OrbitTrail *_earthOrbit, *_moonOrbit, *_marsOrbit, *_venusOrbit, *_mercuryOrbit, *_jupiterOrbit, *_saturnOrbit, *_uranusOrbit, *_neptuneOrbit, *_plutoOrbit;
    
    //the planet models
    PlanetModel *_earthModel, *_moonModel, *_sunModel, *_marsModel, *_venusModel, *_mercuryModel;
    //outer planet models
    PlanetModel *_jupiterModel, *_saturnModel, *_uranusModel, *_neptuneModel, *_plutoModel;
    //the planet textures
    ImageTexture *_earthTexture, *_moonTexture, *_sunTexture, *_marsTexture, *_venusTexture, *_mercuryTexture;
    //outer planet textures
    ImageTexture *_jupiterTexture, *_saturnTexture, *_uranusTexture, *_neptuneTexture, *_plutoTexture;
}
@end

@implementation SolarSystemModel

- (SolarSystemModel*) init
{
    self = [super init];
    
    if(self)
    {
        float astronomicalScaleFactor = 1.25; //for ease of change
        float astronomicalUnit = 1 * astronomicalScaleFactor;
        
        //Reference frame for each planets year and day
        float earthPeriod = 365.25636; //accounts for leap years etc
        float earthDayPeriod = 1;
        
        //Initialize the positions of the planets relative to one another
        //year and day lengths set relative to earth
        //distance to sun set relative to earth's distance to the sun
        Position* sunPosition = [[Position alloc] initWithRelativePosition:nil yearPeriod:0 amplitude:0 dayPeriod:25.379*earthDayPeriod percentOribit:0 relativeSize:3.5];
        Position* earthPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:earthPeriod amplitude:astronomicalUnit dayPeriod:0.9972*earthDayPeriod percentOribit:0 relativeSize:1];
        Position* moonPosition = [[Position alloc] initWithRelativePosition:earthPosition yearPeriod:0.0748*earthPeriod amplitude:0.15 dayPeriod:27.321*earthDayPeriod percentOribit:0 relativeSize:0.273];
        Position* marsPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:1.881*earthPeriod amplitude:1.524*astronomicalUnit dayPeriod:1.0259*earthDayPeriod percentOribit:72.22 relativeSize:0.532];
        Position* mercuryPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.240846*earthPeriod amplitude:0.387*astronomicalUnit dayPeriod:58.649*earthDayPeriod percentOribit:41.94 relativeSize:0.383];
        Position* venusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.615*earthPeriod amplitude:0.723*astronomicalUnit dayPeriod:243.019*earthDayPeriod percentOribit:23.61 relativeSize:0.95];
        
        //Outer Planet Positions
        Position* jupiterPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:11.9*earthPeriod amplitude:5.2*astronomicalUnit dayPeriod:0.41007*earthDayPeriod percentOribit:82.5 relativeSize:10.97];
        Position* saturnPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:29.7*earthPeriod amplitude:9.58*astronomicalUnit dayPeriod:0.426*earthDayPeriod percentOribit:85 relativeSize:9.14];
        Position* uranusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:84.3*earthPeriod amplitude:19.2*astronomicalUnit dayPeriod:0.71833*earthDayPeriod percentOribit:60.56 relativeSize:3.98];
        Position* neptunePosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:164.8*earthPeriod amplitude:30.1*astronomicalUnit dayPeriod:0.67125*earthDayPeriod percentOribit:57.22 relativeSize:3.86];
        Position* plutoPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:247.68*earthPeriod amplitude:39.5*astronomicalUnit dayPeriod:6.38718*earthDayPeriod percentOribit:41.94 relativeSize:0.185];
        
        //Initialize the models and textures of each planet with it's image and position
        _earthModel = [[PlanetModel alloc] initWithSections:16 position:earthPosition];
        _earthTexture = [[ImageTexture alloc] initFrom:@"earth.png"];
        _earthOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:astronomicalUnit relativePosition:sunPosition];
        
        _moonModel = [[PlanetModel alloc] initWithSections:16 position:moonPosition];
        _moonTexture = [[ImageTexture alloc] initFrom:@"Moon.png"];
        _moonOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:0.15 relativePosition:earthPosition];
        
        _sunModel = [[PlanetModel alloc] initWithSections:16 position:sunPosition];
        _sunTexture = [[ImageTexture alloc] initFrom:@"Sun.png"];
        
        _marsModel = [[PlanetModel alloc] initWithSections:16 position:marsPosition];
        _marsTexture = [[ImageTexture alloc] initFrom:@"Mars.png"];
        _marsOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:1.524*astronomicalUnit relativePosition:sunPosition];
        
        _mercuryModel = [[PlanetModel alloc] initWithSections:16 position:mercuryPosition];
        _mercuryTexture = [[ImageTexture alloc] initFrom:@"Mercury.png"];
        _mercuryOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:0.387*astronomicalUnit relativePosition:sunPosition];
        
        _venusModel = [[PlanetModel alloc] initWithSections:16 position:venusPosition];
        _venusTexture = [[ImageTexture alloc] initFrom:@"Venus.png"];
        _venusOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:0.723*astronomicalUnit relativePosition:sunPosition];
        
        _jupiterModel = [[PlanetModel alloc] initWithSections:16 position:jupiterPosition];
        _jupiterTexture = [[ImageTexture alloc] initFrom:@"Jupiter.png"];
        _jupiterOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:5.2*astronomicalUnit relativePosition:sunPosition];
        
        _saturnModel = [[PlanetModel alloc] initWithSections:16 position:saturnPosition];
        _saturnTexture = [[ImageTexture alloc] initFrom:@"Saturn.png"];
        _saturnOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:9.58*astronomicalUnit relativePosition:sunPosition];
        
        _uranusModel = [[PlanetModel alloc] initWithSections:16 position:uranusPosition];
        _uranusTexture = [[ImageTexture alloc] initFrom:@"Uranus.png"];
        _uranusOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:19.2*astronomicalUnit relativePosition:sunPosition];
        
        _neptuneModel = [[PlanetModel alloc] initWithSections:16 position:neptunePosition];
        _neptuneTexture = [[ImageTexture alloc] initFrom:@"Neptune.png"];
        _neptuneOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:30.1*astronomicalUnit relativePosition:sunPosition];
        
        _plutoModel = [[PlanetModel alloc] initWithSections:16 position:plutoPosition];
        _plutoTexture = [[ImageTexture alloc] initFrom:@"Pluto.jpg"];
        _plutoOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:39.5*astronomicalUnit relativePosition:sunPosition];
    }
    
    return self;
}

- (PlanetModel*) getPlanetByIndex:(int)index
{
    switch (index) {
        case 0:
            return _sunModel;
            break;
        case 1:
            return _mercuryModel;
            break;
        case 2:
            return _venusModel;
            break;
        case 3:
            return _earthModel;
            break;
        case 4:
            return _moonModel;
            break;
        case 5:
            return _marsModel;
            break;
        case 6:
            return _jupiterModel;
            break;
        case 7:
            return _saturnModel;
            break;
        case 8:
            return _uranusModel;
            break;
        case 9:
            return _neptuneModel;
            break;
        case 10:
            return _plutoModel;
            break;
        default:
            NSLog(@"Index out of bounds");
            return nil;
            break;
    }
}

- (ImageTexture*) getTextureByIndex:(int)index
{
    switch (index) {
        case 0:
            return _sunTexture;
            break;
        case 1:
            return _mercuryTexture;
            break;
        case 2:
            return _venusTexture;
            break;
        case 3:
            return _earthTexture;
            break;
        case 4:
            return _moonTexture;
            break;
        case 5:
            return _marsTexture;
            break;
        case 6:
            return _jupiterTexture;
            break;
        case 7:
            return _saturnTexture;
            break;
        case 8:
            return _uranusTexture;
            break;
        case 9:
            return _neptuneTexture;
            break;
        case 10:
            return _plutoTexture;
            break;
        default:
            NSLog(@"Index out of bounds");
            return nil;
            break;
    }
}

- (OrbitTrail*) getOrbitByIndex:(int)index
{
    switch (index) {
        case 1:
            return _mercuryOrbit;
            break;
        case 2:
            return _venusOrbit;
            break;
        case 3:
            return _earthOrbit;
            break;
        case 4:
            return _moonOrbit;
            break;
        case 5:
            return _marsOrbit;
            break;
        case 6:
            return _jupiterOrbit;
            break;
        case 7:
            return _saturnOrbit;
            break;
        case 8:
            return _uranusOrbit;
            break;
        case 9:
            return _neptuneOrbit;
            break;
        case 10:
            return _plutoOrbit;
            break;
        default:
            NSLog(@"Index out of bounds");
            return nil;
            break;
    }
}
@end