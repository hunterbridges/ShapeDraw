//
//  TLMLinearInterpView.m
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/29/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import "TLMLinearInterpView.h"
#import "TLMShapePredictor.h"
#import "TLMShape.h"
#import "UIBezierPath+Smoothing.h"
#import "CGPointHelpers.h"

////////////////////////////////////////////////////////////////////////////////

static CGFloat angleThreshold = 30.f;
static CGFloat distanceThreshold = 25.f;

@interface TLMLinearInterpView () <TLMShapePredictorDelegate>

@property (nonatomic, strong) UIBezierPath *drawPath;
@property (nonatomic, strong) NSValue *tempPoint;
@property (nonatomic, strong) TLMShapePredictor *predictor;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation TLMLinearInterpView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.statusLabel.font = [UIFont boldSystemFontOfSize:24.f];
        self.statusLabel.textColor = [UIColor blackColor];
        self.statusLabel.backgroundColor = [UIColor clearColor];
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.statusLabel];
        
        [self initPredictor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.statusLabel.frame =
        CGRectMake(0, [self.statusLabel.font pointSize],
                   self.bounds.size.width,
                   [self.statusLabel.font pointSize] * 1.5);
}

- (void)initPredictor
{
    NSArray *shapes = @[
        [TLMShape shapeWithName:@"Square"
                   withSegments:[TLMShapeSegment length:1.0 angle:90],
                                [TLMShapeSegment length:1.0 angle:90],
                                [TLMShapeSegment length:1.0 angle:90],
                                nil],
        [TLMShape shapeWithName:@"Equilateral Triangle"
                   withSegments:[TLMShapeSegment length:1.0 angle:60],
                                [TLMShapeSegment length:1.0 angle:60],
                                nil],
        [TLMShape shapeWithName:@"Zig-Zag"
                   withSegments:[TLMShapeSegment length:1.0 angle:30],
                                [TLMShapeSegment length:1.0 angle:-30],
                                [TLMShapeSegment length:1.0 angle:30],
                                [TLMShapeSegment length:1.0 angle:-30],
                                [TLMShapeSegment length:1.0 angle:30],
                                nil],
        [TLMShape shapeWithName:@"Right Triangle"
                   withSegments:[TLMShapeSegment length:1.0 angle:90],
                                [TLMShapeSegment length:sqrtf(2.0) angle:45],
                                nil],
        ];
    
    self.predictor =
        [[TLMShapePredictor alloc] initWithShapes:shapes];
    self.predictor.delegate = self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.statusLabel.text = @"";
    
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self.predictor startWithPoint:p];
    
    self.drawPath = [UIBezierPath bezierPath];
    self.drawPath.lineWidth = 4.0;
    [self.drawPath moveToPoint:p];
}

- (void)tryPoint:(CGPoint)p suppressCommit:(BOOL)suppressCommit
{
    NSValue *tmpVal = nil;
    
    tmpVal = [self.predictor.potentialPoints lastObject];
    CGPoint oneAgo = [tmpVal CGPointValue];
    
    tmpVal = [self.predictor.points lastObject];
    CGPoint twoAgo = [tmpVal CGPointValue];
    
    BOOL distanceOk = NO;
    if (self.predictor.points.count) {
        CGFloat distance = CGPointDistance(p, twoAgo);
        if (distance > distanceThreshold) {
            distanceOk = YES;
        }
    }
    
    BOOL angleOk = NO;
    if (self.predictor.potentialPoints.count >= 2) {
        // Angle between two and one
        CGFloat beforeAngle = CGPointAngle(twoAgo, oneAgo);
        CGFloat thisAngle = CGPointAngle(oneAgo, p);
        CGFloat diff = fabsf(thisAngle - beforeAngle);
        
        if (diff > angleThreshold) {
            angleOk = YES;
        }
    }
    
    if (!suppressCommit && (distanceOk && angleOk)) {
        [self.predictor commitPoint];
    }
    
    // Committing the point could make the shape predictor end.
    if (self.predictor.state == kTLMShapePredictorStateRunning) {
        [self.predictor stagePoint:p];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.predictor.state != kTLMShapePredictorStateRunning) return;
    
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self tryPoint:p suppressCommit:NO];
    
    [self.drawPath addLineToPoint:p];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self tryPoint:p suppressCommit:YES];
    
    [self.predictor end];
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Shape Predictor Delegate

- (void)shapePredictor:(TLMShapePredictor *)shapePredictor
         didMatchShape:(TLMShape *)shape
          withAccuracy:(float)accuracy
{
    self.statusLabel.text = [NSString stringWithFormat:@"%@ (%.02f%%)",
                             shape.name, accuracy * 100];
}

- (void)shapePredictorDidFail:(TLMShapePredictor *)shapePredictor
{
    self.statusLabel.text = @"Ya blew it.";
}

- (void)shapePredictorWillEnd:(TLMShapePredictor *)shapePredictor
{
    if (self.predictor.points.count == 0) {
        return;
    }
    
    NSArray *potentialPoints = self.predictor.potentialPoints;
    NSValue *firstVal = potentialPoints[0];
    NSValue *lastVal = [potentialPoints lastObject];
    CGPoint firstPoint = [firstVal CGPointValue];
    CGPoint lastPoint = [lastVal CGPointValue];
    if (CGPointDistance(lastPoint, firstPoint) <= distanceThreshold) {
        [self.predictor stagePoint:firstPoint];
        [self.predictor commitPoint];
    } else {
        [self.predictor commitPoint];
    }
}

#pragma mark - Drawing

- (void)drawPotentialShapes
{
    [[UIColor colorWithRed:0 green:1 blue:1 alpha:0.25] setStroke];
    for (UIBezierPath *path in
         [self.predictor bezierPathsForAllPotentialShapes]) {
        path.lineWidth = 5.0;
        path.lineCapStyle = kCGLineCapRound;
        [path stroke];
    }
}

- (void)drawNextPossibleSegments
{
    for (UIBezierPath *path in
         [self.predictor bezierPathsForNextPossibleSegments]) {
        [[UIColor colorWithWhite:1 alpha:0.25] setFill];
        CGFloat r = self.predictor.vertexCatchTolerance * self.predictor.initialSegmentLength;
        CGRect catchRect = CGRectMake(path.currentPoint.x - r,
                                      path.currentPoint.y - r,
                                      r * 2, r * 2);
        UIBezierPath *catchRadius =
            [UIBezierPath bezierPathWithOvalInRect:catchRect];
        [catchRadius fill];
        
        [[UIColor colorWithRed:0 green:1 blue:0 alpha:0.5] setStroke];
        path.lineWidth = 5.0;
        path.lineCapStyle = kCGLineCapRound;
        [path stroke];
    }
    
}

- (void)drawUserCrayon
{
    [[UIColor yellowColor] setStroke];
    [self.drawPath stroke];
}

- (void)drawPredictorPath
{
    if (self.predictor.potentialPoints.count) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = 2.0;
        int i = 0;
        [[UIColor blueColor] setFill];
        
        NSArray *points =
            [NSArray arrayWithArray:self.predictor.potentialPoints];
        
        for (NSValue *pVal in points) {
            CGPoint point = [pVal CGPointValue];
            if (i == 0) {
                [path moveToPoint:point];
            } else {
                [path addLineToPoint:point];
            }
            CGFloat r = 5;
            CGRect circleRect = CGRectMake(point.x - r,
                                           point.y - r,
                                           r * 2, r * 2);
            
            UIBezierPath *pointPath =
                [UIBezierPath bezierPathWithOvalInRect:circleRect];
            [pointPath fill];
            i++;
        }
        [[UIColor blackColor] setStroke];
        [path stroke];
    }
}

- (void)drawRect:(CGRect)rect
{
    //[self drawPotentialShapes];
    [self drawNextPossibleSegments];
    
    [self drawUserCrayon];
    
    [self drawPredictorPath];
}

@end
