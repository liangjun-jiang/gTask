/*
     File: SSSmallButton.m
 Abstract: A button subclass for small buttons to ensure ease of tapping.
  Version: 1.0
 
 
 
 */

#import "SSSmallButton.h"

@implementation SSSmallButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect bounds = [self bounds];
    CGFloat widthDelta = 44.0 - bounds.size.width;
    CGFloat heightDelta = 44.0 - bounds.size.height;
    // Enlarge the effective bounds to be 44 x 44 pt
    bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
    return CGRectContainsPoint(bounds, point);
}

@end
