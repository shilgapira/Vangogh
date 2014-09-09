
#import "Vangogh.h"
#import <Accelerate/Accelerate.h>



/*******************************************************************************/
#pragma mark - Filters
/*******************************************************************************/

typedef struct {
    __unsafe_unretained NSString *title;
    __unsafe_unretained NSString *subtitle;
    double values[9];
} VGFilter;


static const VGFilter kPauseFilter =
    { @"Paused",            @"---",                     { 1.000, 0.000, 0.000, 0.000, 1.000, 0.000, 0.000, 0.000, 1.000 } };


static const VGFilter kFilters[] = {
    { @"Deuteranomaly",     @"5% M | 0.35% F",          { 0.800, 0.200, 0.000, 0.258, 0.741, 0.000, 0.000, 0.141, 0.858 } },
    { @"Deuteranopia",      @"1.2% M | 0.01% F",        { 0.625, 0.375, 0.000, 0.700, 0.300, 0.000, 0.000, 0.300, 0.700 } },
    { @"Protanomaly",       @"1.3% M | 0.02% F",        { 0.817, 0.183, 0.000, 0.333, 0.667, 0.000, 0.000, 0.123, 0.875 } },
    { @"Protanopia",        @"1.3% M | 0.02% F",        { 0.567, 0.433, 0.000, 0.558, 0.442, 0.000, 0.000, 0.242, 0.758 } },
    { @"Tritanomaly",       @"0.0001% MF",              { 0.967, 0.033, 0.000, 0.000, 0.733, 0.267, 0.000, 0.183, 0.817 } },
    { @"Tritanopia",        @"0.001% M | 0.03% F",      { 0.950, 0.050, 0.000, 0.000, 0.433, 0.567, 0.000, 0.475, 0.525 } },
};

static const NSUInteger kNumFilters = sizeof(kFilters) / sizeof(kFilters[0]);


static UIImage *VGFilterApply(VGFilter filter, UIImage *image) {
    CGImageRef srcImage = image.CGImage;
    CFDataRef srcDataRef = CGDataProviderCopyData(CGImageGetDataProvider(srcImage));
    
    void *srcData = (void *) CFDataGetBytePtr(srcDataRef);
    vImage_Buffer src = {
        .width = CGImageGetWidth(srcImage),
        .height = CGImageGetHeight(srcImage),
        .rowBytes = CGImageGetBytesPerRow(srcImage),
        .data = srcData,
    };
    
    void *destData = malloc(src.height * src.rowBytes);
    vImage_Buffer dest = {
        .width = src.width,
        .height = src.height,
        .rowBytes = src.rowBytes,
        .data = destData,
    };
    
    double *rgb = filter.values;
    double bgra[16] = {
        rgb[8], rgb[5], rgb[2], 0,
        rgb[7], rgb[4], rgb[1], 0,
        rgb[6], rgb[3], rgb[0], 0,
        0,    0,    0,    1,
    };
    
    int32_t divisor = 16384;
    int16_t matrix[16];
    for (NSUInteger i = 0; i < 16; i++) {
        matrix[i] = (int16_t) round(bgra[i] * divisor);
    }
    
    vImage_Error error = vImageMatrixMultiply_ARGB8888(&src, &dest, matrix, divisor, NULL, NULL, kvImageNoFlags);
    if (error) {
        NSLog(@"vImageMatrixMultiply failed: %@", @(error));
        return nil;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(dest.data, dest.width, dest.height, 8, dest.rowBytes, CGImageGetColorSpace(srcImage), CGImageGetBitmapInfo(srcImage));
    
    CGImageRef destImage = CGBitmapContextCreateImage(ctx);
    UIImage *result = [UIImage imageWithCGImage:destImage];
    CGImageRelease(destImage);
    
    CGContextRelease(ctx);
    
    free(destData);
    CFRelease(srcDataRef);
    
    return result;
}



/*******************************************************************************/
#pragma mark - Details View
/*******************************************************************************/

@class VGDetailsView;


@protocol VGDetailsViewDelegate <NSObject>

- (void)detailsViewDidPressPrevious:(VGDetailsView *)detailsView;

- (void)detailsViewDidPressNext:(VGDetailsView *)detailsView;

- (void)detailsView:(VGDetailsView *)detailsView didChangePeek:(CGFloat)peek;

- (void)detailsViewDidTogglePause:(VGDetailsView *)detailsView;

- (void)detailsViewDidDismiss:(VGDetailsView *)detailsView;

@end


@interface VGDetailsView : UIView

@property (nonatomic,weak) id<VGDetailsViewDelegate> delegate;

@property (nonatomic,copy) NSString *title;

@property (nonatomic,copy) NSString *subtitle;

@end


@interface VGDetailsView ()

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *subtitleLabel;

@property (nonatomic,strong) UIButton *prevButton;

@property (nonatomic,strong) UIButton *nextButton;

@end


@implementation VGDetailsView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeSwipe:)];
        swipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:swipe];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizePan:)];
        [pan requireGestureRecognizerToFail:swipe];
        [self addGestureRecognizer:pan];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTap:)];
        [self addGestureRecognizer:tap];
        
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        
        _subtitleLabel = [UILabel new];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_subtitleLabel];
        
        _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _prevButton.showsTouchWhenHighlighted = YES;
        [_prevButton setTitle:@"◀︎" forState:UIControlStateNormal];
        [_prevButton addTarget:self action:@selector(didPressPrevious) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_prevButton];
        
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextButton.showsTouchWhenHighlighted = YES;
        [_nextButton setTitle:@"▶︎" forState:UIControlStateNormal];
        [_nextButton addTarget:self action:@selector(didPressNext) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_nextButton];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    self.titleLabel.text = _title;
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = [subtitle copy];
    self.subtitleLabel.text = _subtitle;
}

- (void)didRecognizeSwipe:(UIGestureRecognizer *)gestureRecognizer {
    [self.delegate detailsViewDidDismiss:self];
}

- (void)didRecognizePan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateChanged) {
        [self.delegate detailsView:self didChangePeek:0];
    } else {
        CGPoint translation = [gestureRecognizer translationInView:self];
        CGFloat factor = (2 * translation.x) / self.bounds.size.width;
        factor = MIN(MAX(factor, -1), 1);
        [self.delegate detailsView:self didChangePeek:factor];
    }
}

- (void)didRecognizeTap:(UIGestureRecognizer *)gestureRecognizer {
    [self.delegate detailsViewDidTogglePause:self];
}

- (void)didPressPrevious {
    [self.delegate detailsViewDidPressPrevious:self];
}

- (void)didPressNext {
    [self.delegate detailsViewDidPressNext:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect b = self.bounds;
    _titleLabel.frame = CGRectMake(0, b.size.height / 2 - 18, b.size.width, 18);
    _subtitleLabel.frame = CGRectMake(0, b.size.height / 2, b.size.width, 18);
    _prevButton.frame = CGRectMake(0, 0, 44, b.size.height);
    _nextButton.frame = CGRectMake(b.size.width - 44, 0, 44, b.size.height);
}

@end



/*******************************************************************************/
#pragma mark - Filter Window
/*******************************************************************************/

@interface VGFilterWindow () <VGDetailsViewDelegate>

@property (nonatomic,strong) UIView *outputView;

@property (nonatomic,strong) VGDetailsView *detailsView;

@property (nonatomic,assign) VGFilter filter;

@property (nonatomic,assign) NSUInteger index;

@property (nonatomic,assign) BOOL paused;

@property (nonatomic,assign) CGFloat peek;

@property (nonatomic,strong) CADisplayLink *displayLink;

@property (nonatomic,assign) CFTimeInterval lastTimestamp;

@end


@implementation VGFilterWindow

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.windowLevel = UIWindowLevelStatusBar - 1;
        self.clipsToBounds = YES;
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        
        _outputView = [UIView new];
        _outputView.userInteractionEnabled = NO;
        [self addSubview:_outputView];
        
        _detailsView = [VGDetailsView new];
        _detailsView.delegate = self;
        [self addSubview:_detailsView];
        
        self.filter = kFilters[self.index];
    }
    return self;
}

#pragma mark Filtering

- (void)start {
    [self updateDetails];
    
    [self refreshIfNeeded];
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshIfNeeded)];
        self.displayLink.frameInterval = 2;
        [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
    self.outputView.layer.contents = nil;
}

- (void)refreshIfNeeded {
    if (!self.hidden) {
        [self refresh];
    }
}

- (void)refresh {
    CFTimeInterval timestamp = CACurrentMediaTime();
    
    __block UIImage *image = [self snapshotImage];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        image = VGFilterApply(self.filter, image);
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (image && !self.hidden && timestamp > self.lastTimestamp) {
                self.lastTimestamp = timestamp;
                self.outputView.layer.contents = (id)image.CGImage;
            }
        });
    });
}

- (void)setFilter:(VGFilter)filter {
    _filter = filter;
    [self updateDetails];
}

- (UIImage *)snapshotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.hidden && window != self) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark Pause

- (void)setPaused:(BOOL)paused {
    if (_paused != paused) {
        _paused = paused;
        if (_paused) {
            self.filter = kPauseFilter;
        } else {
            self.filter = kFilters[self.index];
        }
    }
}

#pragma mark Peek

- (void)setPeek:(CGFloat)peek {
    if (_peek != peek) {
        _peek = peek;
        [self updateMask];
    }
}

- (void)updateMask {
    CAShapeLayer *mask = nil;
    
    if (fabs(self.peek) > 0.1) {
        mask = [CAShapeLayer new];

        CGRect rect = self.outputView.layer.bounds;
        if (self.peek < 0) {
            rect.size.width += self.peek * rect.size.width;
        } else {
            rect.origin.x += self.peek * rect.size.width;
            rect.size.width -= self.peek * rect.size.width;
        }

        CGPathRef path = CGPathCreateWithRect(rect, NULL);
        mask.path = path;
        CGPathRelease(path);
    }

    self.outputView.layer.mask = mask;
}

#pragma mark Info

- (void)updateDetails {
    self.detailsView.hidden = NO;
    self.detailsView.alpha = 1;
    self.detailsView.title = self.filter.title;
    self.detailsView.subtitle = self.filter.subtitle;
}

- (void)detailsViewDidPressPrevious:(VGDetailsView *)detailsView {
    self.index = (self.index + kNumFilters - 1) % kNumFilters;
    self.filter = kFilters[self.index];
}

- (void)detailsViewDidPressNext:(VGDetailsView *)detailsView {
    self.index = (self.index + kNumFilters + 1) % kNumFilters;
    self.filter = kFilters[self.index];
}

- (void)detailsViewDidDismiss:(VGDetailsView *)detailsView {
    if (self.paused) {
        self.paused = NO;
    } else {
        CGRect detailsFrame = self.detailsView.frame;
        [UIView animateWithDuration:0.3 animations:^{
            self.detailsView.alpha = 0;
            self.detailsView.frame = CGRectOffset(detailsFrame, 0, 30);
        } completion:^(BOOL finished) {
            self.detailsView.hidden = YES;
            self.detailsView.frame = detailsFrame;
        }];
    }
}

- (void)detailsView:(VGDetailsView *)detailsView didChangePeek:(CGFloat)peek {
    self.peek = peek;
}

- (void)detailsViewDidTogglePause:(VGDetailsView *)detailsView {
    self.paused = !self.paused;
}

#pragma mark UIView

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    if (hidden) {
        [self stop];
    } else {
        [self start];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect b = self.bounds;
    self.outputView.frame = b;
    self.detailsView.frame = CGRectMake(b.size.width / 2 - 120, b.size.height - 70, 240, 50);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || !self.userInteractionEnabled) {
        return NO;
    }
    
    if (self.clipsToBounds && !CGRectContainsPoint(self.bounds, point)) {
        return NO;
    }
    
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
            return YES;
        }
    }
    
    return NO;
}

@end



/*******************************************************************************/
#pragma mark - Window
/*******************************************************************************/

@interface VGWindow ()

@property (nonatomic,strong) VGFilterWindow *filterWindow;

@property (nonatomic,assign,getter=isActive) BOOL active;

@end


@implementation VGWindow

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _filterWindow = [[VGFilterWindow alloc] initWithFrame:frame];
        _filterWindow.hidden = YES;
    }
    return self;
}

- (void)setActive:(BOOL)active {
    if (_active != active) {
        _active = active;
        self.filterWindow.hidden = !_active;
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [super motionEnded:motion withEvent:event];
    
    if (motion == UIEventSubtypeMotionShake) {
        self.active = !self.active;
    }
}

@end
