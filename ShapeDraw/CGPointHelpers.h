//
//  CGPointHelpers.h
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/30/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#ifndef ShapeDraw_CGPointHelpers_h
#define ShapeDraw_CGPointHelpers_h

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

static CGPoint CGPointMid(CGPoint a, CGPoint b) {
    return CGPointMake((b.x + a.x) / 2.0, (b.y + a.y) / 2.0);
}

static CGPoint CGPointByLookingFrom(CGPoint startPoint,
                                    CGFloat angleRads,
                                    CGFloat magnitude) {
    CGPoint translation = CGPointMake(cosf(angleRads) * magnitude,
                                      sinf(angleRads) * magnitude);
    CGPoint next = CGPointMake(startPoint.x + translation.x,
                               startPoint.y + translation.y);
    /*
    NSLog(@"start: %@, angle: %f, mag: %f, trans: %@, next: %@",
          NSStringFromCGPoint(startPoint),
          angleRads * 180.f / M_PI,
          magnitude,
          NSStringFromCGPoint(translation),
          NSStringFromCGPoint(next));
     */
    return next;
}

static CGFloat CGPointCross(CGPoint a, CGPoint b) {
    return a.x * b.x - a.y * b.y;
}

#endif
