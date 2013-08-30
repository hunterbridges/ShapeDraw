//
//  UIBezierPath+Smoothing.h
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/29/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Smoothing)

- (UIBezierPath*)smoothedPathWithGranularity:(NSInteger)granularity;

@end
