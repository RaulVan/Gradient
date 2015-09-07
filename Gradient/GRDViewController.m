//
//  GRDViewController.m
//  Gradient
//
//  Created by Alexander G Edge on 20/11/2013.
//  Copyright (c) 2013 Alexander Edge. All rights reserved.
//

#import "GRDViewController.h"
#import "GRDGradientView.h"
#import "UIView+Screenshot.h"
#import "UIFont+Additions.h"
#import "GRDCircularButton.h"
#import "UIImage+WallPaper.h"

@import AudioToolbox;
@import AssetsLibrary;
@interface GRDViewController () <GRDShakeDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) GRDGradientView *gradientView;
@property (nonatomic, strong) UIScrollView *scrollView;
//  set these properties as weak so that the pointer is set to nil after
//  they are removed from their superview
@property (nonatomic, weak) GRDCircularButton *savingIndicator;
@property (nonatomic, weak) UITextView *creditsTextView;
@property (nonatomic, weak) UIButton *infoButton;

@property (nonatomic, strong) UIRotationGestureRecognizer *rotationGestureRecogniser;

@end

@implementation GRDViewController

static CGFloat const kMaximumZoomScale = 4.f;
static CGFloat const kMinimumZoomScale = .5f;
static CGFloat const kGradientDefaultScale = 2.f;
static CGFloat const kInfoButtonSideLength = 44.f;
static CGFloat const kInfoButtonMargin = 10.f;

static NSURL * GRDTwitterURLForUsername(NSString *username){
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@",username]];
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific://"]]){
        return [NSURL URLWithString:[NSString stringWithFormat:@"twitterrific:///profile?screen_name=%@",username]];
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]){
        return [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@",username]];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@",username]];
}

static CGFloat GRDRandomZoomScale(){
    return arc4random_uniform(1000) / 1000.f * (kMaximumZoomScale - kMinimumZoomScale) + kMinimumZoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.gradientView;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    *targetContentOffset = scrollView.contentOffset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollView];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)]];
    
    UIRotationGestureRecognizer *rotateGR = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecogniserDidChangeState:)];
    rotateGR.delegate = self;
    [self.gradientView addGestureRecognizer:rotateGR];
    self.rotationGestureRecogniser = rotateGR;
    
    [self showInstructions];
    [self.gradientView becomeFirstResponder];
}

- (UIScrollView *)scrollView{
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.bounces = NO;
        scrollView.bouncesZoom = NO;
        scrollView.delegate = self;
        scrollView.maximumZoomScale = kMaximumZoomScale;
        scrollView.minimumZoomScale = kMinimumZoomScale;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        [scrollView addSubview:self.gradientView];
        [scrollView setContentSize:self.gradientView.frame.size];
        scrollView.contentOffset = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        scrollView.zoomScale = kGradientDefaultScale;
        _scrollView = scrollView;
    }
    return _scrollView;
}

- (GRDGradientView *)gradientView{
    if (!_gradientView) {
        CGRect frame = CGRectMake(0, 0, 2*CGRectGetWidth(self.view.bounds), 2*CGRectGetHeight(self.view.bounds));
        GRDGradientView *view = [[GRDGradientView alloc] initWithFrame:frame];
        view.shakeDelegate = self;
        _gradientView = view;
    }
    return _gradientView;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (BOOL)isOutOfBoundsAlongX:(CGRect)frame{
    return CGRectGetMinX(frame) > 0 || CGRectGetMaxX(frame) < CGRectGetWidth(self.view.frame);
}

- (BOOL)isOutOfBoundsAlongY:(CGRect)frame{
    return CGRectGetMinY(frame) > 0 || CGRectGetMaxY(frame) < CGRectGetHeight(self.view.frame);
}

- (void)gestureRecogniserDidChangeState:(UIGestureRecognizer *)recogniser{
    switch ([recogniser state]) {
        case UIGestureRecognizerStateBegan:
        {
            [(UIRotationGestureRecognizer *)recogniser setRotation:self.gradientView.rotation];
        }
        case UIGestureRecognizerStateChanged:
        {
            if (recogniser == self.rotationGestureRecogniser) {
                CGFloat rotation = [(UIRotationGestureRecognizer *)recogniser rotation];
                self.gradientView.rotation = rotation;
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - 'i' button

- (UIButton *)infoButton{
    if (!_infoButton) {
        UIButton *infoButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - kInfoButtonSideLength - kInfoButtonMargin, kInfoButtonMargin, kInfoButtonSideLength, kInfoButtonSideLength)];
        [infoButton addTarget:self action:@selector(toggleCredits) forControlEvents:UIControlEventTouchUpInside];
        [infoButton setImage:[UIImage imageNamed:@"InfoButton"] forState:UIControlStateNormal];
        [self.view addSubview:infoButton];
        self.infoButton = infoButton;
    }
    return _infoButton;
}

- (void)toggleCredits{
    if (_creditsTextView) {
        [self hideCredits];
    }
    else
    {
        [self showCredits];
    }
}

- (void)showInfoButton{
    if (!_infoButton) {
        self.infoButton.alpha = 0.f;
        [UIView animateWithDuration:kSaveIndicatorDuration animations:^{
            self.infoButton.alpha = 1.f;
        }];
    }
}

- (void)hideInfoButton{
    if (_infoButton) {
        [UIView animateWithDuration:kSaveIndicatorDuration animations:^{
            self.infoButton.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self.infoButton removeFromSuperview];
        }];
    }
}

#pragma mark - Credits

- (UITextView *)creditsTextView{
    if (!_creditsTextView) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectInset(self.view.bounds, 30.f, 30.f)];
        textView.scrollEnabled = NO;
        textView.editable = NO;
        textView.backgroundColor = [UIColor blackColor];
        textView.textAlignment = NSTextAlignmentCenter;
        textView.textContainer.lineFragmentPadding = 0;
        textView.textContainerInset = UIEdgeInsetsMake(50.f, 10.f, 50.f, 10.f);
        textView.linkTextAttributes = @{NSFontAttributeName : [UIFont grd_fontOfSize:42.f],NSForegroundColorAttributeName : [UIColor whiteColor], NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName : [UIColor whiteColor]};
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *commonAttributes = @{NSFontAttributeName : [UIFont grd_fontOfSize:42.f],NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName : [UIColor whiteColor]};
        
        NSString *labelString = NSLocalizedString(@"Gradient is a Nitzan Hermon and Alex Edge collaboration", nil);
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:labelString attributes:commonAttributes];
        
        [str setAttributes:@{NSLinkAttributeName : GRDTwitterURLForUsername(@"byedit"),NSFontAttributeName : [UIFont grd_fontOfSize:42.f]} range:[labelString rangeOfString:@"Nitzan Hermon"]];
        [str setAttributes:@{NSLinkAttributeName : GRDTwitterURLForUsername(@"alexedge"),NSFontAttributeName : [UIFont grd_fontOfSize:42.f],} range:[labelString rangeOfString:@"Alex Edge"]];
        textView.attributedText = str;
        [textView sizeToFit];
        textView.center = self.view.center;
        [self.view addSubview:textView];
        self.creditsTextView = textView;
    }
    return _creditsTextView;
}

- (void)showCredits{
    if (!_creditsTextView) {
        self.creditsTextView.alpha = 0.f;
        [UIView animateWithDuration:kSaveIndicatorDuration animations:^{
            self.creditsTextView.alpha = 1.f;
        }];
    }
}

- (void)hideCredits{
    if (_creditsTextView) {
        [UIView animateWithDuration:kSaveIndicatorDuration animations:^{
            self.creditsTextView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.creditsTextView removeFromSuperview];
        }];
    }
}

- (UILabel *)labelWithString:(NSString *)str{
    UIFont *font = [UIFont grd_fontOfSize:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 52.f : 26.f];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), font.lineHeight)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.text = str;
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (void)showInstructions{
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:backgroundView];
    
    NSArray *labels = @[[self labelWithString:NSLocalizedString(@"SWIPE TO EXPLORE", nil)],[self labelWithString:NSLocalizedString(@"TAP TO CAPTURE", nil)],[self labelWithString:NSLocalizedString(@"SHAKE TO RESTART", nil)]];
    
    __block CGFloat cumulativeHeight = 0.f;
    [labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.frame = CGRectMake(0, cumulativeHeight, CGRectGetWidth(self.view.bounds), CGRectGetHeight(label.bounds));
        cumulativeHeight += 2*CGRectGetHeight(label.bounds);
    }];
    
    UIView *labelContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), cumulativeHeight)];
    labelContainer.center = backgroundView.center;
    [backgroundView addSubview:labelContainer];
    
    for (UILabel *label in labels) {
        [labelContainer addSubview:label];
    }
    
    [UIView animateWithDuration:.5f delay:2 options:0 animations:^{
        backgroundView.alpha = 0.f;
    } completion:^(BOOL finished) {
        [backgroundView removeFromSuperview];
    }];
}

- (void)viewDidDetectShake:(UIView *)view{
    DDLogInfo(@"Shaking!");
    [self hideShareButton];
    [self hideInfoButton];
    [self hideCredits];
    [self.gradientView changeGradient:YES];
    self.scrollView.zoomScale = GRDRandomZoomScale();
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)tapped{
    DDLogInfo(@"Tapping!");
    if (!_savingIndicator && !_creditsTextView) {
        UIImage *gradient = [self.view grd_screenshot];
        
        [gradient _saveAsHomeScreen];//Setting Wallpaper
        
//        UIImageWriteToSavedPhotosAlbum(gradient, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        [self showInfoButton];
        [self showShareButtonWithHandler:^{
            UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[gradient,@"#gradient"] applicationActivities:nil];
            vc.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll];
            vc.completionHandler = ^ (NSString *activityType, BOOL completed){
                DDLogInfo(@"Shared %@ - completed %@",activityType, completed ? @"YES" : @"NO");
                [self.gradientView becomeFirstResponder];
            };
            [self presentViewController:vc animated:YES completion:nil];
        }];
    }
    else if (_creditsTextView) {
        [self hideCredits];
    }
    else
    {
        [self hideShareButton];
        [self hideInfoButton];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        DDLogError(@"Could not save gradient to Saved Photos Album: %@",[error localizedDescription]);
        NSString *alertMessage = nil;
        if (error.code == ALAssetsLibraryAccessUserDeniedError || error.code == ALAssetsLibraryAccessGloballyDeniedError) {
            alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Cannot access Saved Photos Album - please check Settings!", nil)];
        }
        else {
            alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Cannot not save gradient - %@", nil),[error localizedDescription]];
        }
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:alertMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil] show];
    }
    else {
        DDLogInfo(@"Saved gradient");
    }
}

static CGFloat const kSavedIndicatorDiameter = 100.f;
static NSTimeInterval const kSaveIndicatorDuration = 0.5f;
static CGFloat const kSaveIndicatorDamping = 0.6f;
static CGFloat const kSaveIndicatorSpringVelocity = 0.2f;
static CGFloat const kSaveIndicatorScale = 0.01f;

- (GRDCircularButton *)savingIndicator{
    if (!_savingIndicator) {
        GRDCircularButton *savingIndicator = [[GRDCircularButton alloc] initWithFrame:CGRectMake(0, 0, kSavedIndicatorDiameter, kSavedIndicatorDiameter)];
        savingIndicator.center = self.view.center;
        [self.view addSubview:savingIndicator];
        _savingIndicator = savingIndicator;
    }
    return _savingIndicator;
}

- (void)showShareButtonWithHandler:(void(^)(void))handler{
    if (!_savingIndicator) {
        self.savingIndicator.transform = CGAffineTransformMakeScale(kSaveIndicatorScale,kSaveIndicatorScale);
        self.savingIndicator.actionBlock = handler;
        [UIView animateWithDuration:kSaveIndicatorDuration delay:0 usingSpringWithDamping:kSaveIndicatorDamping initialSpringVelocity:kSaveIndicatorSpringVelocity options:0 animations:^{
            self.savingIndicator.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)hideShareButton{
    if (_savingIndicator) {
        [UIView animateWithDuration:kSaveIndicatorDuration delay:0 usingSpringWithDamping:kSaveIndicatorDamping initialSpringVelocity:kSaveIndicatorSpringVelocity options:0 animations:^{
            self.savingIndicator.transform = CGAffineTransformMakeScale(kSaveIndicatorScale,kSaveIndicatorScale);
        } completion:^(BOOL finished) {
            [self.savingIndicator removeFromSuperview];
            self.savingIndicator = nil;
        }];
    }
}

@end
