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
#import "SolarSystemModel.h"

@interface ViewController ()
{
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
    
    //container for solarsystem objects
    SolarSystemModel *_solarSystem;
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
    _trackingPlanet = false;
    
    [EAGLContext setCurrentContext:self.context];
    
    _zoomValues = [NSMutableArray arrayWithObjects: @"0.125",@"0.25",@"0.5",@"1",@"2",@"4",@"8", nil];
    _zoomLvl = 3;
    
    _CMData = [[DeviceMotion alloc] initWithController:self];
    [_CMData startMonitoringMotion];
    
    
    _starDate = [[StarDate alloc] init];
    
    _trackedPosition = [[Position alloc] init];
    
    _solarSystem = [[SolarSystemModel alloc] init];
    
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
    float xTrans = -[[translation objectAtIndex:0] floatValue] + _xOffset;
    float yTrans = -[[translation objectAtIndex:1] floatValue] - _yOffset;
    
    //Update tilt speed from device rotation
    float tilt = _accX;
    if(_timePaused)
    {
        //set time to stationary tilt value
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
        PlanetModel* sun = [_solarSystem getPlanetByIndex:0];
        ImageTexture* sunTexture = [_solarSystem getTextureByIndex:0];
        [sun.getPlanetPosition updateTiltSpeedWithSpeed:tilt];
        float sunSize = sun.getPlanetPosition.getRelativeSize * scaleFactor;
        glTranslatef(xTrans, yTrans, 0);
        glScalef(sunSize, sunSize, sunSize);
        glRotatef(90, 1, 0, 0);
        glRotatef([sun.getPlanetPosition.nextRotation floatValue], 0, 1, 0);
        GLfloat sunAmbience[] = {1,1,1};
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, sunAmbience);
        [sunTexture bind];
        [sun drawOpenGLES1];
    }
    glPopMatrix();
    
    
    for(int i = 1; i <= 10; i++)
    {
        glPushMatrix();
        {
            PlanetModel* planet = [_solarSystem getPlanetByIndex:i];
            ImageTexture* texture = [_solarSystem getTextureByIndex:i];
            GLfloat planetAmbience[] = {0.4,0.4,0.4};
            glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, planetAmbience);
            [self updateModel:planet texture:texture size:planet.getPlanetPosition.getRelativeSize*scaleFactor  xTrans:xTrans yTrans:yTrans tilt:tilt];
        }
        glPopMatrix();
    }
    
    for(int i = 1; i <= 10; i++)
    {
        glPushMatrix();
        {
            OrbitTrail* orbit = [_solarSystem getOrbitByIndex:i];
            [orbit updateVerticesWithScale: [[_zoomValues objectAtIndex:_zoomLvl] doubleValue] xTrans:xTrans yTrans:yTrans];
            [orbit drawOpenGLES1];
        }
        glPopMatrix();
    }
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
    if(!_trackingPlanet)
    {
        //Check to see if the event occured within any of the planets
        //if so, set the scale and translation to follow that planet
        
        CGPoint pos = [[touches anyObject] locationInView:self.view];
        
        //convert pixel values to openGL coordinates for default viewport
        float xOpenGlCoord = ((pos.x/_size.width) * (2 * (2 * _size.width / _min))) - (2 * _size.width / _min) - _xOffset;
        float yOpenGlCoord = ((pos.y/_size.height) * (2 * (2 * _size.height / _min))) - (2 * _size.height / _min) - _yOffset;
        
        //checks for touch being near planets
        for(int i = 1; i <= 10; i++)
        {
            PlanetModel* planet = [_solarSystem getPlanetByIndex:i];
            if([planet.getPlanetPosition isNearbyX:xOpenGlCoord Y:yOpenGlCoord])
            {
                [self storeOffsetValues];
                _zoomLvl = 3;
                _trackedPosition = planet.getPlanetPosition;
                _trackingPlanet = true;
                break;
            }
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
            if (_zoomLvl < 6)
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
    for (int i = 0; i <=10; i++)
    {
        PlanetModel* planet = [_solarSystem getPlanetByIndex:i];
        [planet.getPlanetPosition addTimeDifference:[_starDate getTimeDifferenceUpdate]];
    }
}

- (IBAction)playPauseClicked:(UISwitch*)sender
{
    if ([sender isOn]) {
        NSLog(@"Switch is on -> Play Time");
        _timePaused = false;
    } else {
        NSLog(@"Switch is off -> Pause Time");
        _timePaused = true;
    }

}


#pragma mark Shake to reset functions

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
        NSLog(@"Hit shake event -> Return to initial settings");
        _xOffset = 0;
        _yOffset = 0;
        _zoomLvl = 3;
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
        _zoomLvl = 3;
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