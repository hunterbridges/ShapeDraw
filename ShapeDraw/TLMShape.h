//
//  TLMShape.h
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/30/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TLMShapeSegment : NSObject

@property (nonatomic, assign) CGFloat length;
@property (nonatomic, assign) CGFloat angle;

+ (TLMShapeSegment *)length:(CGFloat)length angle:(CGFloat)angle;

@end

////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSInteger, TLMShapeConvexWinding) {
    // If the polygon winding is counterclockwise, then subsequent shape angles
    // need to be calculated in a clockwise (positive) direction.
    kTLMShapeConvexWindingCounterclockwise = 1,
    kTLMShapeConvexWindingAmbiguous = 0,
    kTLMShapeConvexWindingClockwise = -1
};

@interface TLMShape : NSObject

@property (nonatomic, readonly) NSArray *segments;
@property (nonatomic, copy) NSString *name;

+ (TLMShape *)shapeWithName:(NSString *)name
               withSegments:(TLMShapeSegment *)segment, ... NS_REQUIRES_NIL_TERMINATION;

- (id)initWithSegments:(NSArray *)segments;
- (UIBezierPath *)bezierPathFromStartPoint:(CGPoint)startPoint
                  withInitialSegmentLength:(CGFloat)length
                          withInitialAngle:(CGFloat)angle
                               withWinding:(TLMShapeConvexWinding)winding
                             farthestPoint:(CGPoint *)farthestPoint;
- (NSArray *)pointsFromStartPoint:(CGPoint)startPoint
         withInitialSegmentLength:(CGFloat)length
                 withInitialAngle:(CGFloat)angle
                      withWinding:(TLMShapeConvexWinding)winding
                    farthestPoint:(CGPoint *)farthestPoint;

@end
