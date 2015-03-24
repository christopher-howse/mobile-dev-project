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
    
    //the position of the planet being followed
    Position *_trackedPosition;
    //whether or not we are following a planet
    Boolean _trackingPlanet;
    
    OrbitTrail *_earthOrbit;
    
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
    float earthPeriod = 365;
    float earthDayPeriod = 1;
    
    [EAGLContext setCurrentContext:self.context];
    
    _trackedPosition = [[Position alloc] init];
    
    //Initialize the positions of the planets relative to one another
    //year and day lengths set relative to earth
    //distance to sun set relative to earth's distance to the sun
    Position* sunPosition = [[Position alloc] initWithRelativePosition:nil yearPeriod:0 amplitude:0 dayPeriod:25.379*earthDayPeriod];
    Position* earthPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:earthPeriod amplitude:astronomicalUnit dayPeriod:0.9972*earthDayPeriod];
    Position* moonPosition = [[Position alloc] initWithRelativePosition:earthPosition yearPeriod:0.0748*earthPeriod amplitude:0.15 dayPeriod:27.321*earthDayPeriod];
    Position* marsPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:1.881*earthPeriod amplitude:1.524*astronomicalUnit dayPeriod:1.0259*earthDayPeriod];
    Position* mercuryPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.240*earthPeriod amplitude:0.387*astronomicalUnit dayPeriod:58.649*earthDayPeriod];
    Position* venusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:0.615*earthPeriod amplitude:0.723*astronomicalUnit dayPeriod:243.019*earthDayPeriod];
    
    //Outer Planet Positions
    Position* jupiterPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:11.9*earthPeriod amplitude:5.2*astronomicalUnit dayPeriod:0.41007*earthDayPeriod];
    Position* saturnPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:29.7*earthPeriod amplitude:9.58*astronomicalUnit dayPeriod:0.426*earthDayPeriod];
    Position* uranusPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:84.3*earthPeriod amplitude:19.2*astronomicalUnit dayPeriod:0.71833*earthDayPeriod];
    Position* neptunePosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:164.8*earthPeriod amplitude:30.1*astronomicalUnit dayPeriod:0.67125*earthDayPeriod];
    Position* plutoPosition = [[Position alloc] initWithRelativePosition:sunPosition yearPeriod:247.68*earthPeriod amplitude:39.5*astronomicalUnit dayPeriod:6.38718*earthDayPeriod];
    
    //Initialize the models and textures of each planet with it's image and position
    _earthModel = [[PlanetModel alloc] initWithSections:16 position:earthPosition];
    _earthTexture = [[ImageTexture alloc] initFrom:@"earth.png"];
    _earthOrbit = [[OrbitTrail alloc] initWithSections:32 amplitude:astronomicalUnit];
    
    _moonModel = [[PlanetModel alloc] initWithSections:16 position:moonPosition];
    _moonTexture = [[ImageTexture alloc] initFrom:@"Moon.png"];
    
    _sunModel = [[PlanetModel alloc] initWithSections:16 position:sunPosition];
    _sunTexture = [[ImageTexture alloc] initFrom:@"Sun.png"];
    
    _marsModel = [[PlanetModel alloc] initWithSections:16 position:marsPosition];
    _marsTexture = [[ImageTexture alloc] initFrom:@"Mars.png"];
    
    _mercuryModel = [[PlanetModel alloc] initWithSections:16 position:mercuryPosition];
    _mercuryTexture = [[ImageTexture alloc] initFrom:@"Mercury.png"];
    
    _venusModel = [[PlanetModel alloc] initWithSections:16 position:venusPosition];
    _venusTexture = [[ImageTexture alloc] initFrom:@"Venus.png"];
    
    _jupiterModel = [[PlanetModel alloc] initWithSections:16 position:jupiterPosition];
    _jupiterTexture = [[ImageTexture alloc] initFrom:@"Jupiter.png"];
    
    _saturnModel = [[PlanetModel alloc] initWithSections:16 position:saturnPosition];
    _saturnTexture = [[ImageTexture alloc] initFrom:@"Saturn.png"];
    
    _uranusModel = [[PlanetModel alloc] initWithSections:16 position:uranusPosition];
    _uranusTexture = [[ImageTexture alloc] initFrom:@"Uranus.png"];
    
    _neptuneModel = [[PlanetModel alloc] initWithSections:16 position:neptunePosition];
    _neptuneTexture = [[ImageTexture alloc] initFrom:@"Neptune.jpg"];
    
    _plutoModel = [[PlanetModel alloc] initWithSections:16 position:plutoPosition];
    _plutoTexture = [[ImageTexture alloc] initFrom:@"Pluto.jpg"];
    
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
    float scaleFactor = 0.1 * _scale;
    NSArray* translation = _trackedPosition.currentLocation;
    float xTrans = -[[translation objectAtIndex:0] floatValue];//_moveDistance.x/100;
    float yTrans = -[[translation objectAtIndex:1] floatValue];//-_moveDistance.y/100;
    
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
        [self updateModel:_earthModel texture:_earthTexture size:earthSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float moonSize = 0.273 * scaleFactor;
        [self updateModel:_moonModel texture:_moonTexture size:moonSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float marsSize = 0.532 * scaleFactor;
        [self updateModel:_marsModel texture:_marsTexture size:marsSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float mercurySize = 0.383 * scaleFactor;
        [self updateModel:_mercuryModel texture:_mercuryTexture size:mercurySize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float venusSize = 0.95 * scaleFactor;
        [self updateModel:_venusModel texture:_venusTexture size:venusSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float jupiterSize = 10.97 * scaleFactor;
        [self updateModel:_jupiterModel texture:_jupiterTexture size:jupiterSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float saturnSize = 9.14 * scaleFactor;
        [self updateModel:_saturnModel texture:_saturnTexture size:saturnSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float uranusSize = 3.98 * scaleFactor;
        [self updateModel:_uranusModel texture:_uranusTexture size:uranusSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float neptuneSize = 3.86 * scaleFactor;
        [self updateModel:_neptuneModel texture:_neptuneTexture size:neptuneSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        float plutoSize = 0.185 * scaleFactor;
        [self updateModel:_plutoModel texture:_plutoTexture size:plutoSize xTrans:xTrans yTrans:yTrans];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
        glTranslatef(xTrans, yTrans, 0);
//        glScalef(size, size, size);
        [_earthOrbit drawOpenGLES1];
    }
    glPopMatrix();
}

//updates the model's position, rotation, and texture
- (void) updateModel:(PlanetModel*) model texture:(ImageTexture*) texture size:(float) size xTrans:(float) xTrans yTrans:(float) yTrans
{
    NSArray* nextLocation = [model.getPlanetPosition nextLocationWithScale:_scale];
    float nextX = [[nextLocation objectAtIndex:0] floatValue];
    float nextY = [[nextLocation objectAtIndex:1] floatValue];
    glTranslatef(nextX + xTrans, nextY + yTrans, 0);
    glScalef(size, size, size);
    glRotatef(90, 1, 0, 0);
    glRotatef(360 - [model.getPlanetPosition.nextRotation floatValue], 0, 1, 0);
    
    [texture bind];
    [model drawOpenGLES1];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //if we are already tracking a planet
    //a touch will revert the view to default
    if(_trackingPlanet)
    {
        _trackingPlanet = false;
        _scale = 1;
        _trackedPosition = [[Position alloc] init];
    }
    else
    {
        //Check to see if the event occured within any of the planets
        //if so, set the scale and translation to follow that planet
        
        CGPoint pos = [[touches anyObject] locationInView:self.view];
        
        //convert pixel values to openGL coordinates for default viewport
        float xOpenGlCoord = ((pos.x/_size.width) * (2 * (2 * _size.width / _min))) - (2 * _size.width / _min);
        float yOpenGlCoord = ((pos.y/_size.height) * (2 * (2 * _size.height / _min))) - (2 * _size.height / _min);
        
        //checks for touch being near planets
        if([_earthModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            _scale = 5;
            _trackedPosition = _earthModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_moonModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            _scale = 8;
            _trackedPosition = _moonModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_marsModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            _scale = 8;
            _trackedPosition = _marsModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_venusModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
        {
            _scale = 5;
            _trackedPosition = _venusModel.getPlanetPosition;
            _trackingPlanet = true;
        }
        else if([_mercuryModel.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord
                 ])
        {
            _scale = 5.5;
            _trackedPosition = _mercuryModel.getPlanetPosition;
            _trackingPlanet = true;
        }
    }
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)sender
{
    //if pinch has just began set comparitor previous scale
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        _previousScale = sender.scale;
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        //once pinch starts changing if scale is less then zoom out else zoom in, only if not in zoomPlanet mode
        if (_previousScale > sender.scale)
        {
            if (_scale+0.1*sender.velocity > 0)
            {
                _scale += 0.1*sender.velocity;
            }
            
        }
        else
        {
            _scale += 0.1*sender.velocity;
        }
        _previousScale = sender.scale;
    }
}
@end