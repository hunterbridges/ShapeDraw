//
//  TLMShapePredictor.m
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/30/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import "TLMShapePredictor.h"
#import "CGPointHelpers.h"

@interface TLMShapePredictor ()

@property (nonatomic, assign) TLMShapePredictorState state;
@property (nonatomic, strong) NSArray *shapes;
@property (nonatomic, strong) NSMutableArray *points;

@property (nonatomic, assign) CGFloat initialSegmentLength;
@property (nonatomic, assign) CGFloat initialSegmentAngle;
@property (nonatomic, assign) TLMShapeConvexWinding intendedConvexWinding;

@property (nonatomic, strong) NSMutableSet *potentialShapes;
@property (nonatomic, strong) NSValue *stagedPoint;
@property (nonatomic, strong) NSMutableDictionary *pointsToMatch;
@property (nonatomic, strong) NSMutableDictionary *matchedPoints;

@end

@implementation TLMShapePredictor

- (id)initWithShapes:(NSArray *)shapes
{
    self = [super init];
    if (self) {
        self.shapes = shapes;
        self.vertexCatchTolerance = 0.2;
        self.slopTolerance = 1.1;
    }
    return self;
}

- (void)startWithPoint:(CGPoint)point
{
    NSAssert(self.state != kTLMShapePredictorStateRunning,
             @"Predictor should not be running");
    
    self.initialSegmentLength = 0;
    self.initialSegmentAngle = 0;
    self.intendedConvexWinding = kTLMShapeConvexWindingAmbiguous;
    self.stagedPoint = nil;
    self.pointsToMatch = nil;
    self.potentialShapes = [NSMutableSet setWithArray:self.shapes];
    
    self.matchedPoints = [NSMutableDictionary dictionary];
    for (TLMShape *shape in self.shapes) {
        // First two points implicitly match.
        NSMutableArray *matchedPoints =
        [NSMutableArray arrayWithObjects:@{@"index":@(0), @"distance":@(0)},
                                         @{@"index":@(1), @"distance":@(0)}, nil];
        [self.matchedPoints setObject:matchedPoints forKey:shape.name];
    }
    
    self.state = kTLMShapePredictorStateRunning;
    NSValue *pointVal = [NSValue valueWithCGPoint:point];
    self.points = [NSMutableArray arrayWithObject:pointVal];
}

- (void)stagePoint:(CGPoint)point
{
    NSAssert(self.state == kTLMShapePredictorStateRunning,
             @"Predictor should be running");
    
    NSValue *lastPointVal = [self.points lastObject];
    CGPoint lastPoint = [lastPointVal CGPointValue];
    
    NSValue *pointVal = [NSValue valueWithCGPoint:point];
    self.stagedPoint = pointVal;
    
    NSArray *potentialPoints = self.potentialPoints;
    
    if (potentialPoints.count == 2) {
        self.initialSegmentAngle = CGPointAngle(lastPoint, point);
        self.initialSegmentLength = CGPointDistance(lastPoint, point);
    } else if (potentialPoints.count == 3) {
        [self calculateWinding];
        [self prepareToMatchPoints];
    }
}

- (void)commitPoint
{
    if (self.stagedPoint == nil) return;
    
    [_points addObject:self.stagedPoint];
    self.stagedPoint = nil;
    
    if (self.intendedConvexWinding == kTLMShapeConvexWindingAmbiguous) return;
    
    NSArray *shapes = self.potentialShapes.allObjects;
    for (TLMShape *shape in shapes) {
        NSMutableArray *matchedPoints =
            [self.matchedPoints objectForKey:shape.name];
        NSArray *pointsToMatch = [self.pointsToMatch objectForKey:shape.name];
        
        if (pointsToMatch.count > matchedPoints.count) {
            NSValue *nextPointVal = pointsToMatch[matchedPoints.count];
            CGPoint nextPoint = [nextPointVal CGPointValue];
            
            // See if we are close enough to match the point.
            CGFloat absDist = self.vertexCatchTolerance * self.initialSegmentLength;
            CGFloat pDist =
                CGPointDistance([[self.points lastObject] CGPointValue], nextPoint);
            if (pDist <= absDist) {
                // Save the path index of the point that matches.
                [matchedPoints addObject:@{@"index": @(self.points.count - 1),
                                           @"distance": @(pDist)}];
                
                if (matchedPoints.count == pointsToMatch.count) {
                    NSLog(@"Matched %@!", shape.name);
                    
                    if (self.potentialShapes.count == 1) {
                        NSLog(@"IT HAS TO BE %@!!!", [shape.name uppercaseString]);
                        [self end];
                    }
                }
            } else {
                // If we are not, we need to check the slop in our approach.
                NSInteger segmentIdx = matchedPoints.count - 2;
                TLMShapeSegment *segment = shape.segments[segmentIdx];
                CGFloat idealLength =
                    segment.length * self.initialSegmentLength;
                CGFloat maxLength = idealLength * self.slopTolerance;
                
                // Calculate the length starting from the last matching point,
                // through the rest of our points, to the target point.
                CGFloat runLength = 0;
                NSInteger ourPointIdx =
                    [[matchedPoints lastObject][@"index"] integerValue];
                int i;
                CGPoint lastPointChecked =
                    [self.points[ourPointIdx] CGPointValue];
                for (i = ourPointIdx + 1; i < self.points.count; i++) {
                    CGPoint runPoint = [self.points[i] CGPointValue];
                    runLength += CGPointDistance(lastPointChecked, runPoint);
                    lastPointChecked = runPoint;
                }
                runLength += CGPointDistance(lastPointChecked, nextPoint);
                
                if (runLength > maxLength) {
                    // Too sloppy! Throw it out!
                    NSLog(@"Too sloppy for %@", shape.name);
                    [_potentialShapes removeObject:shape];
                    
                    if (self.potentialShapes.count == 0) {
                        [self end];
                    }
                }
            }
        }
    }
}

- (NSArray *)potentialPoints
{
    if (self.stagedPoint) {
        return [self.points arrayByAddingObject:self.stagedPoint];
    } else {
        return [NSArray arrayWithArray:self.points];
    }
}

- (void)end
{
    if (self.state == kTLMShapePredictorStateEnded) return;
    NSAssert(self.state == kTLMShapePredictorStateRunning,
             @"Predictor should be running");
    if ([self.delegate respondsToSelector:@selector(shapePredictorWillEnd:)]) {
        [self.delegate shapePredictorWillEnd:self];
    }
    
    self.state = kTLMShapePredictorStateEnded;
    
    if (self.potentialShapes.count) {
        for (TLMShape *shape in self.potentialShapes.allObjects) {
            // If we matched all the points for this shape, that's the one.
            if ([self.matchedPoints[shape.name] count] ==
                    [self.pointsToMatch[shape.name] count]) {
                if ([self.delegate respondsToSelector:@selector(shapePredictor:didMatchShape:withAccuracy:)]) {
                    // TODO: Determine accuracy
                    CGFloat absDist = self.vertexCatchTolerance * self.initialSegmentLength;
                    float distSum = 0.f;
                    for (NSDictionary *matchedPoint in self.matchedPoints[shape.name]) {
                        distSum += [[matchedPoint objectForKey:@"distance"] floatValue];
                    }
                        
                    CGFloat maxDist = absDist * ([self.matchedPoints[shape.name] count] - 2);
                    float accuracy = 1.f - distSum / maxDist;
                    
                    [self.delegate shapePredictor:self
                                    didMatchShape:shape
                                     withAccuracy:accuracy];
                }
                break;
            }
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(shapePredictorDidFail:)]) {
            [self.delegate shapePredictorDidFail:self];
        }
    }
}

- (CGPoint)startPoint
{
    if (self.points.count == 0) return CGPointZero;
    NSValue *pointVal = self.points[0];
    return [pointVal CGPointValue];
}

- (void)calculateWinding
{
    NSArray *potentialPoints = self.potentialPoints;
    int num_points = potentialPoints.count;
    if (num_points < 2) return;
    
    int i = 0;
    
    CGFloat xavg = 0;
    CGFloat yavg = 0;
    for (i = 0; i < num_points; i++) {
        xavg += [potentialPoints[i] CGPointValue].x;
        yavg += [potentialPoints[i] CGPointValue].y;
    }
    xavg /= potentialPoints.count;
    yavg /= potentialPoints.count;
    
    CGPoint corr = CGPointMake(-xavg, -yavg);
    // NSLog(@"%@", NSStringFromCGPoint(corr));
    
    float sum = 0;
    for (i = 0; i < num_points; i++) {
        CGPoint p1 = [potentialPoints[i] CGPointValue];
        int next_i = (i + 1) % num_points;
        CGPoint p2 = [potentialPoints[next_i] CGPointValue];
        
        CGPoint p1corr = CGPointMake(p1.x + corr.x, p1.y + corr.y);
        CGPoint p2corr = CGPointMake(p2.x + corr.x, p2.y + corr.y);
        
        // NSLog(@"p1: %@, p2: %@", NSStringFromCGPoint(p1corr), NSStringFromCGPoint(p2corr));
        float edge = p1corr.x * p2corr.y - p2corr.x * p1corr.y;
        sum += edge;
    }

    self.intendedConvexWinding = (sum > 0 ?
                                  kTLMShapeConvexWindingClockwise :
                                  kTLMShapeConvexWindingCounterclockwise);
}

- (void)prepareToMatchPoints {
    self.pointsToMatch = [NSMutableDictionary dictionary];
    
    for (TLMShape *shape in self.shapes) {
        NSArray *points =
            [shape pointsFromStartPoint:[self.points[0] CGPointValue]
               withInitialSegmentLength:self.initialSegmentLength
                       withInitialAngle:self.initialSegmentAngle
                            withWinding:self.intendedConvexWinding];
        [self.pointsToMatch setObject:points forKey:shape.name];
    }
}

#pragma mark - Drawing Helpers

- (NSArray *)bezierPathsForAllPotentialShapes
{
    if (self.initialSegmentLength == 0) return nil;
    
    NSMutableArray *paths = [NSMutableArray array];
    for (TLMShape *shape in [self.potentialShapes allObjects]) {
        if (self.intendedConvexWinding == kTLMShapeConvexWindingAmbiguous) {
            UIBezierPath *cwPath =
                [shape bezierPathFromStartPoint:[self startPoint]
                       withInitialSegmentLength:self.initialSegmentLength
                               withInitialAngle:self.initialSegmentAngle
                                    withWinding:kTLMShapeConvexWindingClockwise];
            UIBezierPath *ccwPath =
                [shape bezierPathFromStartPoint:[self startPoint]
                       withInitialSegmentLength:self.initialSegmentLength
                               withInitialAngle:self.initialSegmentAngle
                                    withWinding:kTLMShapeConvexWindingCounterclockwise];
            [paths addObject:cwPath];
            [paths addObject:ccwPath];
        } else {
            TLMShapeConvexWinding winding = self.intendedConvexWinding;
            UIBezierPath *path =
                [shape bezierPathFromStartPoint:[self startPoint]
                       withInitialSegmentLength:self.initialSegmentLength
                               withInitialAngle:self.initialSegmentAngle
                                    withWinding:winding];
            [paths addObject:path];
        }
    }
    return paths;
}

- (NSArray *)bezierPathsForNextPossibleSegments
{
    if (self.initialSegmentLength == 0) return nil;
    
    NSMutableArray *paths = [NSMutableArray array];
    for (TLMShape *shape in [self.potentialShapes allObjects]) {
        if (self.intendedConvexWinding == kTLMShapeConvexWindingAmbiguous) {
            // TODO: This is probably brutal
            
            NSArray *cwPoints =
                [shape pointsFromStartPoint:[self startPoint]
                   withInitialSegmentLength:self.initialSegmentLength
                           withInitialAngle:self.initialSegmentAngle
                                withWinding:kTLMShapeConvexWindingClockwise];
            NSArray *ccwPoints =
                [shape pointsFromStartPoint:[self startPoint]
                   withInitialSegmentLength:self.initialSegmentLength
                           withInitialAngle:self.initialSegmentAngle
                                withWinding:kTLMShapeConvexWindingCounterclockwise];
            
            NSMutableArray *matchedPoints =
                [self.matchedPoints objectForKey:shape.name];
            
            for (NSArray *points in @[cwPoints, ccwPoints]) {
                if (points.count > matchedPoints.count) {
                    UIBezierPath *path = [UIBezierPath bezierPath];
                    [path moveToPoint:[points[matchedPoints.count - 1] CGPointValue]];
                    [path addLineToPoint:[points[matchedPoints.count] CGPointValue]];
                    [paths addObject:path];
                }
            }
        } else {
            NSArray *points = self.pointsToMatch[shape.name];
            NSMutableArray *matchedPoints =
                [self.matchedPoints objectForKey:shape.name];
            
            // See if we are close enough to match the point. If so,
            // be predictive.
            if (points.count > matchedPoints.count + 1) {
                NSValue *nextPointVal = points[matchedPoints.count];
                CGPoint nextPoint = [nextPointVal CGPointValue];
                CGFloat absDist = self.vertexCatchTolerance * self.initialSegmentLength;
                if (CGPointDistance([[self.potentialPoints lastObject] CGPointValue], nextPoint) <= absDist) {
                    UIBezierPath *path = [UIBezierPath bezierPath];
                    [path moveToPoint:[points[matchedPoints.count] CGPointValue]];
                    [path addLineToPoint:[points[matchedPoints.count + 1] CGPointValue]];
                    [paths addObject:path];
                }
            }
            
            if (points.count > matchedPoints.count) {
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path moveToPoint:[points[matchedPoints.count - 1] CGPointValue]];
                [path addLineToPoint:[points[matchedPoints.count] CGPointValue]];
                [paths addObject:path];
            }
        }
    }
    return paths;
}

@end
