//
//  TLMShapePredictor.h
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/30/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLMShape.h"

typedef NS_ENUM(NSInteger, TLMShapePredictorState) {
    kTLMShapePredictorStateNew = 0,
    kTLMShapePredictorStateRunning = 1,
    kTLMShapePredictorStateEnded = 2
};

@class TLMShapePredictor;
@protocol TLMShapePredictorDelegate <NSObject>

- (void)shapePredictor:(TLMShapePredictor *)shapePredictor
         didMatchShape:(TLMShape *)shape
          withAccuracy:(float)accuracy;
- (void)shapePredictorDidFail:(TLMShapePredictor *)shapePredictor;
- (void)shapePredictorWillEnd:(TLMShapePredictor *)shapePredictor;

@end

@interface TLMShapePredictor : NSObject

@property (nonatomic, assign, readonly) TLMShapePredictorState state;
@property (nonatomic, strong, readonly) NSArray *shapes;
@property (nonatomic, assign) CGFloat vertexCatchTolerance;
@property (nonatomic, assign) CGFloat slopTolerance;
@property (nonatomic, weak) id<TLMShapePredictorDelegate> delegate;

- (id)initWithShapes:(NSArray *)shapes;
- (void)startWithPoint:(CGPoint)point;
- (void)stagePoint:(CGPoint)point;
- (void)commitPoint;
- (void)end;
- (NSArray *)points;
- (NSArray *)potentialPoints;
- (NSSet *)potentialShapes;
- (CGFloat)initialSegmentLength;
- (CGFloat)initialSegmentAngle;
- (TLMShapeConvexWinding)intendedConvexWinding;
- (NSValue *)stagedPoint;

#pragma mark - Drawing Helpers

- (NSArray *)bezierPathsForAllPotentialShapesInFrame:(CGRect)frame;
- (NSArray *)bezierPathsForNextPossibleSegmentsInFrame:(CGRect)frame;

@end
