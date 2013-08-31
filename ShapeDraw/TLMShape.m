//
//  TLMShape.m
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/30/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import "TLMShape.h"
#import "CGPointHelpers.h"

static CGFloat angleWrap(CGFloat angle) {
    while (angle < 0) {
        angle += 360;
    }
    while (angle >= 360) {
        angle -= 360;
    }
    return angle;
}

@implementation TLMShapeSegment

+ (TLMShapeSegment *)length:(CGFloat)length angle:(CGFloat)angle
{
    TLMShapeSegment *segment = [[TLMShapeSegment alloc] init];
    segment.length = length;
    segment.angle = angle;
    return segment;
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface TLMShape ()

@property (nonatomic, strong) NSArray *segments;

@end

@implementation TLMShape

+ (TLMShape *)shapeWithName:(NSString *)name
               withSegments:(TLMShapeSegment *)segment, ...
{
    NSMutableArray *segments = [NSMutableArray array];
    va_list args;
    va_start(args, segment);
    for (TLMShapeSegment *arg = segment;
             arg != nil;
             arg = va_arg(args, TLMShapeSegment *)) {
        [segments addObject:arg];
    }
    va_end(args);
    
    TLMShape *shape = [[TLMShape alloc] initWithSegments:segments];
    shape.name = name;
    return shape;
}

- (id)initWithSegments:(NSArray *)segments
{
    self = [super init];
    if (self) {
        self.segments = segments;
    }
    return self;
}

- (UIBezierPath *)bezierPathFromStartPoint:(CGPoint)startPoint
                  withInitialSegmentLength:(CGFloat)length
                          withInitialAngle:(CGFloat)angle
                               withWinding:(TLMShapeConvexWinding)winding {
    if (winding == kTLMShapeConvexWindingAmbiguous) return nil;
    
    NSArray *points = [self pointsFromStartPoint:startPoint
                        withInitialSegmentLength:length
                                withInitialAngle:angle
                                     withWinding:winding];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    
    int i;
    for (i = 1; i < points.count; i++) {
        CGPoint point = [points[i] CGPointValue];
        [path addLineToPoint:point];
    }
    
    return path;
}

- (NSArray *)pointsFromStartPoint:(CGPoint)startPoint
         withInitialSegmentLength:(CGFloat)length
                 withInitialAngle:(CGFloat)angle
                      withWinding:(TLMShapeConvexWinding)winding {
    NSMutableArray *points = [NSMutableArray array];
    
    [points addObject:[NSValue valueWithCGPoint:startPoint]];
    
    CGFloat angleRads = angle * M_PI / 180;
    CGPoint secondPoint = CGPointByLookingFrom(startPoint, angleRads, length);
    [points addObject:[NSValue valueWithCGPoint:secondPoint]];
    
    CGFloat prevAngle = angle;
    CGFloat prevAngleRads = angleRads;
    CGPoint prevPoint = secondPoint;
    for (TLMShapeSegment *segment in self.segments) {
        CGFloat nextAngleDelta = segment.angle * winding;
        CGFloat nextAngle = angleWrap(prevAngle + 180 + nextAngleDelta);
        CGFloat nextAngleRads = nextAngle * M_PI / 180.f;
        
        CGPoint nextPoint =
            CGPointByLookingFrom(prevPoint,
                                 nextAngleRads,
                                 segment.length * length);
        [points addObject:[NSValue valueWithCGPoint:nextPoint]];
        
        prevAngle = nextAngle;
        prevAngleRads = nextAngleRads;
        prevPoint = nextPoint;
    }
    
    return points;
}

@end
