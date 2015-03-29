//
//  ViewController.m
//  SolarSystem
//
//  Created by Christopher Howse on 2015-03-11.
//  Copyright (c) 2015 Christopher Howse. All rights reserved.
//
//  Adapted from Minglun Gong's ViewController.m in the Modelling Demo
//

#import "ViewController.h"
#import "PlanetModel.h"
#import "ImageTexture.h"
#import "Position.h"
#import "OrbitTrail.h"
#import "DeviceMotion.h"
#import "StarDate.h"

@interface ViewController ()
{
    //the level of zoom
    CGFloat _scale;
    //the size of the screen
    CGSize _size;
    //the min of the width and height of the screen
    float _min;
    //the scale of the previous pinch movement, used to determine zoom in or out
    float _previousScale;
    float _initalScale;
    //zoom level
    int _zoomLvl;
    int _zoomLvlStore;
    NSMutableArray *_zoomValues;
    
    //translation offset
    float _xOffset;
    float _yOffset;
    float _xOffsetStore;
    float _yOffsetStore;
    float _xStart;
    float _yStart;
    
    //montion values
    CGFloat _accX, _accY, _accZ;
    double _rotPitch, _rotRoll, _rotYaw;
    DeviceMotion* _CMData;
    
    //Star date
    StarDate *_starDate;
    
    //Label IO
    IBOutlet UILabel *_currentDateLabel;
    //whether or not the date has been manually set
    Boolean _dateUpdated;
    Boolean _timePaused;
    
    //the position of the planet being followed
    Position *_trackedPosition;
    //whether or not we are following a planet
    Boolean _trackingPlanet;
    
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
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;
- (void)setupOrthographicView: (CGSize)size;
- (void) storeOffsetValues;
- (void) restoreOffsetValues;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [view addGestureRecognizer:pinchGesture];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [view addGestureRecognizer:doubleTap];
    
    [self setupGL];
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context)
        {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (void)update
{
    [self setupOrthographicView: self.view.bounds.size];
}

- (void)setupLightSource
{
    //initialize the lighting sources
    //diffusion light at center of sun
    GLfloat diffuse[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat position[] = {0,0,0,1};
    //ambient light so the rest of the planets can be viewed
    GLfloat ambient[] = {0.9, 0.9, 0.9};
    
    glEnable(GL_LIGHTING);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
    glLightfv(GL_LIGHT0, GL_POSITION, position);
    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    
    glEnable(GL_LIGHT0);
}

- (void)setupGL
{
    _scale = 1;
    _trackingPlanet = false;
    
    float astronomicalScaleFactor = 1.25; //for ease of change
    float astronomicalUnit = 1 * astronomicalScaleFactor;
    
    //Reference frame for each planets year and day
    float earthPeriod = 365.25636; //accounts for leap years etc
    float earthDayPeriod = 1;
    
    [EAGLContext setCurrentContext:self.context];
    
    _zoomValues = [NSMutableArray arrayWithObjects: @"0.1",@"1",@"5",@"10", nil];
    _zoomLvl = 1;
    
    _CMData = [[DeviceMotion alloc] initWithController:self];
    [_CMData startMonitoringMotion];
    
    
    _starDate = [[StarDate alloc] init];
    
    _trackedPosition = [[Position alloc] init];
    
    //Initialize the positions of the planets relative to one another
    //year and day lengths set relative to earth
    //distance to sun set relative to earth's distance to the sun
    Position* sunPosition = [[Position alloc] initWithRelativePosition:nil yearPeriod:0 amplitude:0 dayPeriod:25.379*earthDayPeriod percentOribit:0];
    Position* earthPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:earthPeriod amplitude:astronomicalUnit dayPeriod:0.9972*earthDayPeriod percentOribit:0];
    Position* moonPosition = [[Position alloc] initWithRelativePosition:earthPosition yearPeriod:0.0748*earthPeriod amplitude:0.15 dayPeriod:27.321*earthDayPeriod percentOribit:0];
    Position* marsPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:1.881*earthPeriod amplitude:1.524*astronomicalUnit dayPeriod:1.0259*earthDayPeriod percentOribit:72.22];
    Position* mercuryPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.240*earthPeriod amplitude:0.387*astronomicalUnit dayPeriod:58.649*earthDayPeriod percentOribit:41.94];
    Position* venusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.615*earthPeriod amplitude:0.723*astronomicalUnit dayPeriod:243.019*earthDayPeriod percentOribit:23.61];
    
    //Outer Planet Positions
    Position* jupiterPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:11.9*earthPeriod amplitude:5.2*astronomicalUnit dayPeriod:0.41007*earthDayPeriod percentOribit:82.5];
    Position* saturnPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:29.7*earthPeriod amplitude:9.58*astronomicalUnit dayPeriod:0.426*earthDayPeriod percentOribit:85];
    Position* uranusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:84.3*earthPeriod amplitude:19.2*astronomicalUnit dayPeriod:0.71833*earthDayPeriod percentOribit:60.56];
    Position* neptunePosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:164.8*earthPeriod amplitude:30.1*astronomicalUnit dayPeriod:0.67125*earthDayPeriod percentOribit:57.22];
    Position* plutoPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:247.68*earthPeriod amplitude:39.5*astronomicalUnit dayPeriod:6.38718*earthDayPeriod percentOribit:41.94];
    
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
    _neptuneTexture = [[ImageTexture alloc] initFrom:@"Neptune.jpg"];
    _neptuneOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:30.1*astronomicalUnit relativePosition:sunPosition];
    
    _plutoModel = [[PlanetModel alloc] initWithSections:16 position:plutoPosition];
    _plutoTexture = [[ImageTexture alloc] initFrom:@"Pluto.jpg"];
    _plutoOrbit = [[OrbitTrail alloc] initWithSections:64 amplitude:39.5*astronomicalUnit relativePosition:sunPosition];
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glClearColor(0, 0, 0, 0);
    glClearDepthf(1);
    
    [self setupLightSource];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

- (void)setupOrthographicView: (CGSize)size
{
    _size = size;
    // set viewport based on display size
    glViewport(0, 0, size.width, size.height);
    _min = MIN(size.width, size.height);
    float width = 2 * size.width / _min;
    float height = 2 * size.height / _min;
    
    // set up orthographic projection
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-width, width, -height, height, -2, 2);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float scaleFactor = 0.1 * [[_zoomValues objectAtIndex:_zoomLvl] doubleValue];
    NSArray* translation = _trackedPosition.currentLocation;
    float xTrans = -[[translation objectAtIndex:0] floatValue] + _xOffset;//_moveDistance.x/100;
    float yTrans = -[[translation objectAtIndex:1] floatValue] - _yOffset;//-_moveDistance.y/100;
    
    //Update tilt speed from device rotation
    float tilt = _accX;
    if(_timePaused)
    {
        tilt = -1;
    }

    //Update stardate based on tilt value;
    [_starDate updateTimeWithTilt:tilt];
    [self updateCurrentTimeLabel];
    
    if(_dateUpdated)
    {
        _dateUpdated = false;
        [self jumpPlanetPositions];
    }
    
    GLfloat position[] = {xTrans,yTrans,0,1};
    glEnable(GL_LIGHTING);
    glLightfv(GL_LIGHT0, GL_POSITION, position);
    glEnable(GL_LIGHT0);
    
    // clear the rendering buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // set up the transformation for models
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glPushMatrix();
    {
        [_sunModel.getPlanetPosition updateTiltSpeedWithSpeed:tilt];
        float sunSize = 3.5 * scaleFactor;
        glTranslatef(xTrans, yTrans, 0);
        glScalef(sunSize, sunSize, sunSize);
        glRotatef(90, 1, 0, 0);
        glRotatef([_sunModel.getPlanetPosition.nextRotation floatValue], 0, 1, 0);
        GLfloat sunAmbience[] = {1,1,1};
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, sunAmbience);
        [_sunTexture bind];
        [_sunModel drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float earthSize = 1 * scaleFactor;
        GLfloat planetAmbience[] = {0.4,0.4,0.4};
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, planetAmbience);
        [self updateModel:_earthModel texture:_earthTexture size:earthSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float moonSize = 0.273 * scaleFactor;
        [self updateModel:_moonModel texture:_moonTexture size:moonSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float marsSize = 0.532 * scaleFactor;
        [self updateModel:_marsModel texture:_marsTexture size:marsSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float mercurySize = 0.383 * scaleFactor;
        [self updateModel:_mercuryModel texture:_mercuryTexture size:mercurySize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float venusSize = 0.95 * scaleFactor;
        [self updateModel:_venusModel texture:_venusTexture size:venusSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float jupiterSize = 10.97 * scaleFactor;
        [self updateModel:_jupiterModel texture:_jupiterTexture size:jupiterSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float saturnSize = 9.14 * scaleFactor;
        [self updateModel:_saturnModel texture:_saturnTexture size:saturnSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float uranusSize = 3.98 * scaleFactor;
        [self updateModel:_uranusModel texture:_uranusTexture size:uranusSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float neptuneSize = 3.86 * scaleFactor;
        [self updateModel:_neptuneModel texture:_neptuneTexture size:neptuneSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float plutoSize = 0.185 * scaleFactor;
        [self updateModel:_plutoModel texture:_plutoTexture size:plutoSize xTrans:xTrans yTrans:yTrans tilt:tilt];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_earthOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_earthOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_moonOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_moonOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_marsOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_marsOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_mercuryOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_mercuryOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_venusOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_venusOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_jupiterOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_jupiterOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_saturnOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_saturnOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_neptuneOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_neptuneOrbit drawOpenGLES1];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        [_uranusOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_uranusOrbit drawOpenGLES1];
    }
    glPopMatrix();

    glPushMatrix();
    {
        [_plutoOrbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
        [_plutoOrbit drawOpenGLES1];
    }
    glPopMatrix();

}

//updates the model's position, rotation, and texture
- (void) updateModel:(PlanetModel*) model texture:(ImageTexture*) texture size:(float) size xTrans:(float) xTrans yTrans:(float) yTrans tilt:(float) tilt;
{
    [model.getPlanetPosition updateTiltSpeedWithSpeed:tilt];
    NSArray* nextLocation = [model.getPlanetPosition nextLocationWithScale:[[_zoomValues objectAtIndex:_zoomLvl] doubleValue]];
    float nextX = [[nextLocation objectAtIndex:0] floatValue];
    float nextY = [[nextLocation objectAtIndex:1] floatValue];
    glTranslatef(nextX + xTrans, nextY + yTrans, 0);
    glScalef(size, size, size);
    glRotatef(90, 1, 0, 0);
    glRotatef(360 - [model.getPlanetPosition.nextRotation floatValue], 0, 1, 0);
    
    [texture bind];
    [model drawOpenGLES1];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    // get touch location & iPhone display size
    CGPoint pos = [[touches anyObject] locationInView:self.view];
    
    //convert pixel values to openGL coordinates for default viewport
    _xStart = (((pos.x/_size.width) * (2 * (2 * _size.width / _min))) - (2 * _size.width / _min)) - _xOffset;
    _yStart = (((pos.y/_size.height) * (2 * (2 * _size.height / _min))) - (2 * _size.height / _min)) - _yOffset;
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // get touch location & iPhone display size
    CGPoint pos = [[touches anyObject] locationInView:self.view];
    
    _xOffset += (((pos.x/_size.width) * (2 * (2 * _size.width / _min))) - (2 * _size.width / _min)) - _xOffset - _xStart;
    _yOffset += (((pos.y/_size.height) * (2 * (2 * _size.height / _min))) - (2 * _size.height / _min)) - _yOffset - _yStart;
}


- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //if we are already tracking a planet
    //a touch will revert the view to default
    if(!_trackingPlanet)
    {
        //Check to see if the event occured within any of the planets
        //if so, set the scale and translation to follow that planet
        
        CGPoint pos = [[touches anyObject] locationInView:self.view];
        
        //convert pixel values to openGL coordinates for default viewport
        float xOpenGlCoord = ((pos.x/_size.width) * (2 * (2 * _size.width / _min))) - (2 * _size.width / _min) - _xOffset;
        float yOpenGlCoord = ((pos.y/_size.height) * (2 * (2 * _size.height / _min))) - (2 * _size.height / _min) - _yOffset;
        
        //checks for touch being near planets
        if([_earthModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 5;
            [_zoomValues setObject:@"5" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _earthModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_moonModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 8;
            [_zoomValues setObject:@"8" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _moonModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_marsModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 8;
            [_zoomValues setObject:@"8" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _marsModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_venusModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 5;
            [_zoomValues setObject:@"5" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _venusModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_mercuryModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 5.5;
            [_zoomValues setObject:@"5.5" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _mercuryModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_jupiterModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 1;
            [_zoomValues setObject:@"1" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _jupiterModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_saturnModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 1;
            [_zoomValues setObject:@"1" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _saturnModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_neptuneModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 1.5;
            [_zoomValues setObject:@"1.5" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _neptuneModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_uranusModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 2;
            [_zoomValues setObject:@"2" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _uranusModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_plutoModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            [self storeOffsetValues];
            _scale = 8;
            [_zoomValues setObject:@"8" atIndexedSubscript:2];
            _zoomLvl = 2;
            _trackedPosition = _plutoModel.getPlanetPosition;
            _trackingPlanet = true;
        }
    }
}

-(void) handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer {
    //if pinch has just began set comparitor previous scale
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        _previousScale = [gestureRecognizer scale];
        _initalScale = 0;
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        NSLog(@"pinching");
        //once pinch starts changing if scale is less then zoom in else zoom out
        if (_previousScale < [gestureRecognizer scale])
        {
            if (_zoomLvl < 3)
            {
                _initalScale += [gestureRecognizer velocity];
                if( 40 < _initalScale)
                {
                    _zoomLvl += 1;
                        _xOffset = _xOffset*([[_zoomValues objectAtIndex:_zoomLvl] doubleValue]/[[_zoomValues objectAtIndex:_zoomLvl-1] doubleValue]);
                        _yOffset = _yOffset*([[_zoomValues objectAtIndex:_zoomLvl] doubleValue]/[[_zoomValues objectAtIndex:_zoomLvl-1] doubleValue]);
                    _initalScale = 0;
                }
            }
            
        }
        //zoom out
        else
        {
            if (_zoomLvl > 0)
            {
                _initalScale += [gestureRecognizer velocity];
                if(-10 > _initalScale)
                {
                    _zoomLvl -= 1;
                        _xOffset = _xOffset*([[_zoomValues objectAtIndex:_zoomLvl] doubleValue]/[[_zoomValues objectAtIndex:_zoomLvl+1] doubleValue]);
                        _yOffset = _yOffset*([[_zoomValues objectAtIndex:_zoomLvl] doubleValue]/[[_zoomValues objectAtIndex:_zoomLvl+1] doubleValue]);
                    _initalScale = 0;
                }
            }
        }
        NSLog(@"X value:%f Y value:%f",_xOffset,_yOffset);
        _previousScale = [gestureRecognizer scale];
    }
}

- (void) updateCMDataWithX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z pitch:(double)pitch roll:(double)roll yaw:(double)yaw
{
    _accX = x;
    _accY = y;
    _accZ = z;
    _rotPitch = pitch;
    _rotRoll = roll;
    _rotYaw = yaw;
}


#pragma mark Label IO functions
- (void)updateCurrentTimeLabel
{
    _currentDateLabel.text = [_starDate getDisplayTime];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSDateFormatter *dateFormatterForGettingDate = [[NSDateFormatter alloc] init];
    [dateFormatterForGettingDate setDateFormat:@"yyyy MMM dd"];
    NSDate *dateFromStr = [dateFormatterForGettingDate dateFromString:textField.text];
    
    if(dateFromStr != nil)
    {
        [_starDate updateTimeWithDate:dateFromStr];
        _dateUpdated = true;
    }
    
    textField.text = nil;
    [self.view endEditing:YES];
    return true;
}

- (void) jumpPlanetPositions
{
    //update positions with timeDifference
    [_earthModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_sunModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_moonModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_mercuryModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_venusModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_marsModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_jupiterModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_saturnModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_uranusModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_neptuneModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    [_plutoModel.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
}

- (IBAction)playPauseClicked:(UISwitch*)sender
{
    if ([sender isOn]) {
        NSLog(@"Switch is on");
        _timePaused = false;
    } else {
        NSLog(@"Switch is off");
        _timePaused = true;
    }

}


#pragma mark Shake to reset functions

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
        // Put in code here to handle shake
        NSLog(@"Hit shake event");
        _xOffset = 0;
        _yOffset = 0;
        [_zoomValues setObject:@"5" atIndexedSubscript:2];
        _zoomLvl = 1;
        _trackingPlanet = false;
        _trackedPosition = [[Position alloc] init];
    }
    
    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] )
        [super motionEnded:motion withEvent:event];
}


- (void)doDoubleTap
{
    if(_trackingPlanet)
    {
        _trackingPlanet = false;
        _scale = 1;
        [_zoomValues setObject:@"5" atIndexedSubscript:2];
        _zoomLvl = 1;
        _trackedPosition = [[Position alloc] init];
        [self restoreOffsetValues];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void) storeOffsetValues
{
    _xOffsetStore = _xOffset;
    _yOffsetStore = _yOffset;
    _zoomLvlStore = _zoomLvl;
    _xOffset = 0;
    _yOffset = 0;
    
}

- (void) restoreOffsetValues
{
    _xOffset = _xOffsetStore;
    _yOffset = _yOffsetStore;
    _zoomLvl = _zoomLvlStore;
}


@end