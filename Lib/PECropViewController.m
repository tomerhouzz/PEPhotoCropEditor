//
//  PECropViewController.m
//  PhotoCropEditor
//
//  Created by kishikawa katsumi on 2013/05/19.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "PECropViewController.h"
#import "PECropView.h"
@import HouzzFoundation;

@interface PECropViewController () <UIActionSheetDelegate>

@property (nonatomic) PECropView *cropView;
@property (nonatomic, strong) UIBarButtonItem *constraintButton;

- (void)commonInit;

@end

@implementation PECropViewController
@synthesize rotationEnabled = _rotationEnabled;

+ (NSBundle *)bundle
{
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *bundleURL = [NSBundle.sharedResources URLForResource:@"PEPhotoCropEditor" withExtension:@"bundle"];
        bundle = [[NSBundle alloc] initWithURL:bundleURL];
    });
    
    return bundle;
}

static inline NSString *PELocalizedString(NSString *key, NSString *comment)
{
    return [[NSBundle bundleWithIdentifier:@"com.houzz.HouzzFoundation"] localizedStringForKey:key value:nil table:@"data"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.rotationEnabled = YES;
}

#pragma mark -

- (void)loadView
{
    UIView *contentView = [[UIView alloc] init];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.backgroundColor = [UIColor blackColor];
    self.view = contentView;
    
    self.cropView = [[PECropView alloc] initWithFrame:contentView.bounds];
    [contentView addSubview:self.cropView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];

    if (!self.toolbarItems) {
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                       target:nil
                                                                                       action:nil];
        UIBarButtonItem *constrainButton = [[UIBarButtonItem alloc] initWithTitle:PELocalizedString(@"Square", nil)
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(constrain:)];
        self.constraintButton = constrainButton;
        [constrainButton setPossibleTitles:[NSSet setWithObjects:PELocalizedString(@"Square", nil), PELocalizedString(@"Original", nil), nil]];
        self.toolbarItems = @[flexibleSpace, constrainButton, flexibleSpace];
    }
    self.navigationController.toolbarHidden = self.toolbarHidden;
    
    self.cropView.image = self.image;
    
    self.cropView.rotationGestureRecognizer.enabled = _rotationEnabled;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.cropAspectRatio != 0) {
        self.cropAspectRatio = self.cropAspectRatio;
    }
    if (!CGRectEqualToRect(self.cropRect, CGRectZero)) {
        self.cropRect = self.cropRect;
    }
    if (!CGRectEqualToRect(self.imageCropRect, CGRectZero)) {
        self.imageCropRect = self.imageCropRect;
    }
    
    self.keepingCropAspectRatio = self.keepingCropAspectRatio;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark -

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.cropView.image = image;
}

- (void)setKeepingCropAspectRatio:(BOOL)keepingCropAspectRatio
{
    _keepingCropAspectRatio = keepingCropAspectRatio;
    self.cropView.keepingCropAspectRatio = self.keepingCropAspectRatio;
}

- (void)setCropAspectRatio:(CGFloat)cropAspectRatio
{
    _cropAspectRatio = cropAspectRatio;
    self.cropView.cropAspectRatio = self.cropAspectRatio;
}

- (void)setCropRect:(CGRect)cropRect
{
    _cropRect = cropRect;
    _imageCropRect = CGRectZero;
    
    CGRect cropViewCropRect = self.cropView.cropRect;
    cropViewCropRect.origin.x += cropRect.origin.x;
    cropViewCropRect.origin.y += cropRect.origin.y;
    
    CGSize size = CGSizeMake(fminf(CGRectGetMaxX(cropViewCropRect) - CGRectGetMinX(cropViewCropRect), CGRectGetWidth(cropRect)),
                             fminf(CGRectGetMaxY(cropViewCropRect) - CGRectGetMinY(cropViewCropRect), CGRectGetHeight(cropRect)));
    cropViewCropRect.size = size;
    self.cropView.cropRect = cropViewCropRect;
}

- (void)setImageCropRect:(CGRect)imageCropRect
{
    _imageCropRect = imageCropRect;
    _cropRect = CGRectZero;
    
    self.cropView.imageCropRect = imageCropRect;
}

- (BOOL)isRotationEnabled
{
    return _rotationEnabled;
}

- (void)setRotationEnabled:(BOOL)rotationEnabled
{
    _rotationEnabled = rotationEnabled;
    self.cropView.rotationGestureRecognizer.enabled = _rotationEnabled;
}

- (CGAffineTransform)rotationTransform
{
    return self.cropView.rotation;
}

- (CGRect)zoomedCropRect
{
    return self.cropView.zoomedCropRect;
}

- (void)resetCropRect
{
    [self.cropView resetCropRect];
}

- (void)resetCropRectAnimated:(BOOL)animated
{
    [self.cropView resetCropRectAnimated:animated];
}

#pragma mark -

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cropViewControllerDidCancel:)]) {
        [self.delegate cropViewControllerDidCancel:self];
    }
}

- (void)done:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCroppingImage:transform:cropRect:)]) {
        [self.delegate cropViewController:self didFinishCroppingImage:self.cropView.croppedImage transform: self.cropView.rotation cropRect: self.cropView.zoomedCropRect];
    } else if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCroppingImage:)]) {
        [self.delegate cropViewController:self didFinishCroppingImage:self.cropView.croppedImage];
    }
}

- (void)constrain:(id)sender
{
    if ( self.cropView.cropAspectRatio == 1.0f) {
        CGRect cropRect = self.cropView.cropRect;
        CGSize size = self.cropView.image.size;
        CGFloat width = size.width;
        CGFloat height = size.height;
        CGFloat ratio;
        if (width < height) {
            ratio = width / height;
            cropRect.size = CGSizeMake(CGRectGetHeight(cropRect) * ratio, CGRectGetHeight(cropRect));
        } else {
            ratio = height / width;
            cropRect.size = CGSizeMake(CGRectGetWidth(cropRect), CGRectGetWidth(cropRect) * ratio);
        }
        self.cropView.cropRect = cropRect;
        [_constraintButton setTitle:PELocalizedString(@"Square", nil)];
    } else {
        self.cropView.cropAspectRatio = 1.0f;
        [_constraintButton setTitle:PELocalizedString(@"Original", nil)];
    }
}

#pragma mark -

@end
