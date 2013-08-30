//
//  TLMLinearInterpView.m
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/29/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import "TLMLinearInterpView.h"
#import "UIBezierPath+Smoothing.h"

static CGFloat angleThreshold = 20.f;
static CGFloat distanceThreshold = 50.f;

static CGFloat CGPointAngle(CGPoint a, CGPoint b) {
    CGFloat bearingRadians = atan2f(b.y - a.y, b.x - a.x);
    CGFloat bearingDegrees = bearingRadians * (180. / M_PI);
    return bearingDegrees;
}

static CGFloat CGPointDistance(CGPoint a, CGPoint b) {
    CGFloat distance = sqrtf(powf(b.y - a.y, 2.f) +
                             powf(b.x - a.x, 2.f));
    return distance;
}

@interface TLMLinearInterpView ()

@property (nonatomic, strong) UIBezierPath *drawPath;
@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSValue *tempPoint;

@end

@implementation TLMLinearInterpView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [[UIColor yellowColor] setStroke];
    [self.drawPath stroke];
    
    if (self.points) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = 2.0;
        int i = 0;
        [[UIColor blueColor] setFill];
        
        NSArray *points = [NSArray arrayWithArray:self.points];
        if (self.tempPoint) {
            points = [points arrayByAddingObject:self.tempPoint];
        }
        
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    self.points = [NSMutableArray array];
    
    self.drawPath = [UIBezierPath bezierPath];
    self.drawPath.lineWidth = 4.0;
    [self.drawPath moveToPoint:p];
    
    NSValue *pVal = [NSValue valueWithCGPoint:p];
    [self.points addObject:pVal];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    NSValue *pVal = [NSValue valueWithCGPoint:p];
    
    if (self.tempPoint) {
        self.tempPoint = nil;
    }
    
    NSUInteger lastIdx = self.points.count - 1;
    
    NSValue *tmpVal = nil;
    CGPoint oneAgo = CGPointZero;
    if (self.points.count) {
        tmpVal = self.points[lastIdx];
        oneAgo = [tmpVal CGPointValue];
        
        CGFloat distance = CGPointDistance(p, oneAgo);
        // Too close? Temp it
        if (distance < distanceThreshold) {
            self.tempPoint = pVal;
        }
    }
    
    if (self.points.count >= 2) {
        tmpVal = self.points[lastIdx - 1];
        CGPoint twoAgo = [tmpVal CGPointValue];
        
        // Angle between two and one
        CGFloat beforeAngle = CGPointAngle(twoAgo, oneAgo);
        CGFloat thisAngle = CGPointAngle(oneAgo, p);
        CGFloat diff = fabsf(thisAngle - beforeAngle);
        
        if (diff <= angleThreshold) {
            // Pop the last point
            [self.points removeLastObject];
        }
    }
    
    if (!self.tempPoint) {
        [self.points addObject:pVal];
    }
    
    [self.drawPath addLineToPoint:p];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
    self.tempPoint = NO;
    if (self.points.count == 0) return;
    
    NSValue *firstVal = self.points[0];
    NSValue *lastVal = [self.points lastObject];
    CGPoint firstPoint = [firstVal CGPointValue];
    CGPoint lastPoint = [lastVal CGPointValue];
    if (CGPointDistance(lastPoint, firstPoint) <= distanceThreshold) {
        // Close the shape off nicely
        [self.points removeLastObject];
        [self.points addObject:firstVal];
    }
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

@end
