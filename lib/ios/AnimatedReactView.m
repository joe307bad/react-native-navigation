#import "AnimatedReactView.h"
#import "UIView+Utils.h"
#import <React/UIView+React.h>

@implementation AnimatedReactView {
    UIView *_originalParent;
    CGRect _originalFrame;
    UIViewContentMode _originalContentMode;
    CGFloat _originalCornerRadius;
    CGRect _originalLayoutBounds;
    CATransform3D _originalTransform;
    UIView *_toElement;
    UIColor *_fromColor;
    NSInteger _zIndex;
    SharedElementTransitionOptions *_transitionOptions;
}

- (instancetype)initElement:(UIView *)element
                  toElement:(UIView *)toElement
          transitionOptions:(SharedElementTransitionOptions *)transitionOptions {
    self.location = [[RNNViewLocation alloc] initWithFromElement:element toElement:toElement];
    self = [super initWithFrame:self.location.fromFrame];
    _transitionOptions = transitionOptions;
    _toElement = toElement;
    _toElement.hidden = YES;
    _fromColor = element.backgroundColor;
    _zIndex = toElement.reactZIndex;
    [self hijackReactElement:element];

    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    _reactView.backgroundColor = backgroundColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    [super setCornerRadius:cornerRadius];
    [_reactView setCornerRadius:cornerRadius];
}

- (NSNumber *)reactZIndex {
    return @(_zIndex);
}

- (void)hijackReactElement:(UIView *)element {
    _reactView = element;
    _originalFrame = _reactView.frame;
    _originalTransform = element.layer.transform;
    _originalLayoutBounds = element.layer.bounds;
    _originalContentMode = element.contentMode;
    self.contentMode = element.contentMode;
    self.frame = self.location.fromFrame;
    
    if ([element isKindOfClass:UIImageView.class]) {
        element.bounds = [self getSizeWithContentMode:(UIImageView *)element contentMode:_toElement.contentMode];
        element.layer.bounds = element.bounds;
        element.contentMode = _toElement.contentMode;
    }
    
    _originalParent = _reactView.superview;
    _originalCornerRadius = element.layer.cornerRadius;
    _reactView.frame = self.bounds;
    _reactView.layer.transform = CATransform3DIdentity;
    _reactView.layer.cornerRadius = self.location.fromCornerRadius;
    [self addSubview:_reactView];
}

- (void)reset {
    _reactView.frame = _originalFrame;
    _reactView.layer.cornerRadius = _originalCornerRadius;
    _reactView.bounds = _originalLayoutBounds;
    _reactView.layer.bounds = _originalLayoutBounds;
    _reactView.layer.transform = _originalTransform;
    _reactView.contentMode = _originalContentMode;
    [_originalParent insertSubview:_reactView atIndex:self.location.index];
    _toElement.hidden = NO;
    _reactView.backgroundColor = _fromColor;
    [self removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _reactView.frame = self.bounds;
}

/**
 Returns a size where the given `element` looks exactly the same with the given `contentMode` as it does currently without it.
 */
- (CGRect)getSizeWithContentMode:(UIImageView *)element
                     contentMode:(UIViewContentMode)contentMode {
    // TODO: We want to run different scaling techniques depending on the resize mode.
    // In general, we want to scale/resize the element/toElement directly, since that
    // is contained in the AnimatedReactView. This means, the AnimatedReactView will
    // manage the bounds animation, and we just want to silently update the contentMode
    // so it still looks the same but has different bounds.
    
    // Example 1: element has resizeMode "cover", so it's image is larger than the view.
    // We want to update element's resizeMode to whatever resizeMode the toElement has,
    // and cancel out the visual change this will result in. So if we change from "cover"
    // to "contain", the image will get smaller so that it exactly fits in the view's bounds.
    // That means we have to know how big the image is, how far it goes beyond the view's bounds
    // right now, and style it the same way with the new resize mode. (Basically make resizeMode
    // "contain" look the same as "cover" by changing the view's frame/bounds)
    
    if (contentMode == element.contentMode) {
        return element.bounds;
    }
    
    // TODO: This is still a bit off. See: https://github.com/vitoziv/VICMAImageView/blob/master/VICMAImageView/VICMAImageView.m#L156-L278
    // TODO: Update center
    
    switch (contentMode) {
        case UIViewContentModeScaleAspectFill: {
            CGSize imageSize = CGSizeMake(element.image.size.width / element.image.scale,
                                              element.image.size.height / element.image.scale);
            CGFloat imageAspectRatio = imageSize.width / imageSize.height;
            
            CGFloat newWidth, newHeight;
            if (imageAspectRatio > 1) {
                // width is longer edge
                newWidth = element.bounds.size.width * imageAspectRatio;
                newHeight = element.bounds.size.height;
            } else {
                // height is longer edge
                newWidth = element.bounds.size.width;
                newHeight = element.bounds.size.height * imageAspectRatio;
            }
            
            return CGRectMake(element.bounds.origin.x - ((newWidth - element.bounds.size.width) / 2),
                              element.bounds.origin.y - ((newHeight - element.bounds.size.height) / 2),
                              newWidth,
                              newHeight);
        }
        case UIViewContentModeScaleAspectFit: {
            CGSize imageSize = CGSizeMake(element.image.size.width / element.image.scale,
                                          element.image.size.height / element.image.scale);
            CGFloat imageAspectRatio = imageSize.width / imageSize.height;
            
            CGFloat newWidth, newHeight;
            if (imageAspectRatio > 1) {
                // width is longer edge
                newWidth = element.bounds.size.width;
                newHeight = element.bounds.size.height * imageAspectRatio;
            } else {
                // height is longer edge
                newWidth = element.bounds.size.width * imageAspectRatio;
                newHeight = element.bounds.size.height;
            }
            
            return CGRectMake(element.bounds.origin.x - ((newWidth - element.bounds.size.width) / 2),
                              element.bounds.origin.y - ((newHeight - element.bounds.size.height) / 2),
                              newWidth,
                              newHeight);
        }
        default: {
            // TODO: Other resizeModes are not yet implemented.
            return element.bounds;
        }
    }
    
    
}

@end
