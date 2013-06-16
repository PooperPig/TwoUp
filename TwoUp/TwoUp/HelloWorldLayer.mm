//
//  HelloWorldLayer.mm
//  Fifty50
//
//  Created by Maxxx on 11/06/13.
//  Copyright Maxxx 2013. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "CCPhysicsSprite.h"
#import "AccelerometerSimulation.h"


@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
@end
float timeBetweenFlips = 2.0;
float timeUntilNextFlip = -1;
int numberOfHeads = 0;
int numberOfTails = 0;
float deviceAngle;
int rnd_seed;

CCLabelTTF *resultLabel;

bool paused = false;

@implementation HelloWorldLayer

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[scene addChild: layer];
	return scene;
}

-(id) init
{
	//!! Use braces on same line or next line indiscriminately
	if( (self=[super init])) {
		//!! Make sure we use both dod access and 'traditional' square-bracket access to properties
		self.touchEnabled = YES;
		[self setAccelerometerEnabled: YES];
		CGSize s = [CCDirector sharedDirector].winSize;

		CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"sprites.png" capacity:100];
		spriteTexture_ = [parent texture];
		[self addChild:parent z:0 ];

		[self initPhysics];

		headsLabel = [CCLabelTTF labelWithString:@"Heads:" fontName:@"Marker Felt" fontSize:24];
		[self addChild:headsLabel z:0];
		[headsLabel setColor:ccc3(0,0,255)];
		headsLabel.position = ccp( 60, s.height-30);

		tailsLabel = [CCLabelTTF labelWithString:@"Tails:" fontName:@"Marker Felt" fontSize:24];
		[self addChild:tailsLabel z:0];
		[tailsLabel setColor:ccc3(0,0,255)];
		tailsLabel.position = ccp( s.width - 80, s.height-30);

		[self scheduleUpdate];
		numberOfFlips = 10;



	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;

	delete m_debugDraw;
	m_debugDraw = NULL;

	[super dealloc];
}

-(void) accelerometer:(UIAccelerometer* )accelerometer didAccelerate:(UIAcceleration* )acceleration
{
	deviceAngle = atan2f(acceleration.x, acceleration.y);
	//!! What the hell, get a new seed every time we move the device
	//!! And log it too!
	rnd_seed = (int)(deviceAngle*100);
	NSString* s = [NSString stringWithFormat:@"device angle = %f, %d, %d ", deviceAngle, acceleration.x, acceleration.y];
	//CCLOG(s);
}

-(void) initPhysics
{

	CGSize s = [[CCDirector sharedDirector] winSize];

	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);

	world->SetAllowSleeping(true);

	world->SetContinuousPhysics(true);

	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner

	b2Body* groundBody = world->CreateBody(&groundBodyDef);

	b2EdgeShape groundBox;


	//!! Translate everything from screen coordinates to physics using hard-coded magic number of 32
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/32,0));
	groundBody->CreateFixture(&groundBox,0);

	groundBox.Set(b2Vec2(0,s.height/32), b2Vec2(s.width/32,s.height/32));
	groundBody->CreateFixture(&groundBox,0);

	groundBox.Set(b2Vec2(0,s.height/32), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);

	groundBox.Set(b2Vec2(s.width/32,s.height/32), b2Vec2(s.width/32,0));
	groundBody->CreateFixture(&groundBox,0);

	float top = s.height * 0.75;
	float middle = s.width * 0.5;

	float w = 50;
	float h = 50;

	for (float row = 1; row < 8.0; row++)
	{
		for (float col = 0; col<=row;col++)	{
			float y =    top - (row * h);
			float x = middle - (row * w/2) + (col * w);

			[self CreatePinAtPoint:ccp(x, y)];
		}

	}

}

- (void)CreatePinAtPoint:(CGPoint)p
{
	b2BodyDef bodyDef;
	bodyDef.type = b2_staticBody;
	bodyDef.position.Set(p.y/32, p.x/32);
	b2Body *body = world->CreateBody(&bodyDef);

	b2CircleShape topHalf;
	topHalf.m_radius = 0.16f;

	b2FixtureDef fixture1;
	fixture1.shape = &topHalf;
	fixture1.density = 1.0f;
	fixture1.friction = 0.3f;
	fixture1.restitution = 0.5f;

	body->CreateFixture(&fixture1);

	b2Vec2 v = b2Vec2(p.x/ 32, p.y/ 32);

	body->SetTransform(v, 0);

	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,7,9,8)];
	[self addChild:sprite];

	sprite.PTMRatio = 32;
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x, p.y)];
}

//!! Leave in code from template, complete with warnings to disable it
-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.y/32, p.x/32);
	b2Body *body = world->CreateBody(&bodyDef);

	b2PolygonShape topHalf;
	topHalf.SetAsBox(.5f, .05f, b2Vec2(0,0),0);

	b2PolygonShape bottomHalf;
	bottomHalf.SetAsBox(.5f, .05f, b2Vec2(0,-0.05f),0);

	b2FixtureDef fixture1;
	fixture1.shape = &topHalf;
	fixture1.density = 1.0f;
	fixture1.friction = 0.2f;
	fixture1.restitution = 0.5f;

	b2FixtureDef fixture2;
	fixture2.shape = &bottomHalf;
	fixture2.density = 1.0f;
	fixture2.friction = 0.2f;
	fixture2.restitution = 0.5f;

	body->CreateFixture(&fixture1);
	body->CreateFixture(&fixture2);

	b2Vec2 v = b2Vec2(p.x/ 32, p.y/ 32);

	body->SetTransform(v, 0);


	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,0,31,6)];
	[self addChild:sprite];

	sprite.PTMRatio = 32;
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x, p.y)];


	v =    body->GetWorldCenter();


	unsigned int hi,lo;
	hi = 16807 * rnd_seed >> 16;
	lo = 16807 * rnd_seed & 0xFFFF;
	lo+= (hi & 0x7FFF) <<16;
	lo+= hi >>15;
	if (lo > 2147483647)
		lo -= 2147483647;
	rnd_seed = lo;

	v.x += ((rnd_seed % 2) - 0.99) / 10;

	NSString* s = [NSString stringWithFormat:@"v.x = %f.4 rnd_seed = %d", v.x, rnd_seed];
	CCLOG(s);


	body->ApplyLinearImpulse(b2Vec2(0.85,4.0), v);
	body->SetUserData(sprite);

}

-(void) update: (ccTime) dt
{
	if (!(paused == YES))
	{
		//!! Let's set some local variables to store some constants
		int32 velocityIterations = 8;
		int32 positionIterations = 1;

		world->Step(dt, velocityIterations, positionIterations);

		timeUntilNextFlip -= dt;
		if (timeUntilNextFlip < 0)
		{
			timeUntilNextFlip = timeBetweenFlips;
			[self flipACoin];
		}

		//!! I know it's a small one, but inconsistancy in placing of * for pointers gets right up my schnoz
		for(b2Body *b = world->GetBodyList(); b; b=b->GetNext())
		{
			if (!b->IsAwake())	{
				CCPhysicsSprite* sprite = (CCPhysicsSprite* )b->GetUserData();
				if (sprite)
				{
					[self removeChild:sprite cleanup:true];
					[self addScoreForBody:b];

					world->DestroyBody(b);
				}
			}
		}

		if (numberOfTails + numberOfHeads >= numberOfFlips)
		{
			[self ShowResults];
		}
	}
}

-(void)ShowResults
{
	//!! Keep getting the screen size rather than storing locally - oh, and use a different local variable name each time
	CGSize sz = [[CCDirector sharedDirector] winSize];

	NSString* s;
	if (numberOfHeads > numberOfTails)
	{
		s = @"YES!!!!";
	}
	else{
		s = @"NO!!!!";
	}

	paused = true;


	resultLabel = [CCLabelTTF labelWithString:s fontName:@"Marker Felt" fontSize:200];
	[self addChild:resultLabel z:0];
	[resultLabel setColor:ccc3(50,185,205)];
	resultLabel.position = ccp( sz.width/2, sz.height/2);


}

-(void)addScoreForBody: (b2Body*) body
{

	CGSize w = [CCDirector sharedDirector].winSize;

	int angle = (int)CC_RADIANS_TO_DEGREES(body->GetAngle());


//!! why not use a loop rather than the abs function? Better still, use two loops!	

	while(angle > 360)
	{
		angle -= 360;
	}
	while (angle < -360)
	{
		angle += 360;
	}

	id fadeOut;
	id actionMoveDone;

	CCSprite* sprite;
	CCMoveTo*  actionMove;
	//!! Use some hard-coded angles without explanation
	if (angle < 95 || angle > 265)
	{
		//!! Keep the logging in production just to make sure it's slow and jerky
		//TODO: Remove logging prior to release
		CCLOG(@"Heads");
		//!! Hard code the sprite sizes, animation durations etc.
		sprite = [CCSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,17,98,30)];
		actionMove = [CCMoveTo actionWithDuration:3.0 position:ccp(50,w.height-20)];
		//!! And convert back from physics to screen coordinates using the (hopefully) same magic number
		sprite.position = ccp(body->GetPosition().x* 32, body->GetPosition().y * 32 );
		[self addChild:sprite];
		fadeOut = [CCFadeOut actionWithDuration:3.0];
		actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(headsFinishedMoving:)];
		[sprite runAction:[CCSequence actions:actionMove,  actionMoveDone, nil]]    ;
		[sprite runAction:[CCSequence actions:fadeOut, nil]]    ;
	}
	else
	{
		//TODO: Remove logging prior to release
		CCLOG(@"Tails");
		sprite = [CCSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0, 51, 75, 36)];
		actionMove = [CCMoveTo actionWithDuration:3.0 position:ccp(w.width-101,w.height-20)];
		sprite.position = ccp(body->GetPosition().x* 32, body->GetPosition().y * 32 );
		[self addChild:sprite];
		fadeOut = [CCFadeOut actionWithDuration:3.0];
		actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(tailsFinishedMoving:)];
		[sprite runAction:[CCSequence actions:actionMove,  actionMoveDone, nil]]    ;
		[sprite runAction:[CCSequence actions:fadeOut, nil]]    ;

	}

}

-(void) headsFinishedMoving:(id) sender
{
	[headsLabel setString: [NSString stringWithFormat:@"Heads: %d", ++numberOfHeads]];
	[self removeChild:sender cleanup:YES];

}
-(void) tailsFinishedMoving:(id) sender
{
	[self removeChild:sender cleanup:YES];
	[tailsLabel setString: [NSString stringWithFormat:@"Tails: %d", ++numberOfTails]];

}

-(void)flipACoin
{
	[self addNewSpriteAtPosition:ccp(105,100)];
}



- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	numberOfHeads = 0;
	numberOfTails = 0;
	//!! Use true or YES interchangeably
	[self removeChild:resultLabel cleanup:true];


	//!! Repeat code rather than centralise it
	[headsLabel setString: [NSString stringWithFormat:@"Heads: %d", numberOfHeads]];
	[tailsLabel setString: [NSString stringWithFormat:@"Tails: %d", numberOfTails]];
	paused = false;


}


@end
