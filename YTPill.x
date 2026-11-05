#import "Headers.h"
#import <Photos/Photos.h>

@interface YTPassthroughWindow : UIWindow
@end

@implementation YTPassthroughWindow
- (BOOL)_canBecomeKeyWindow { return NO; }
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self || hit == self.rootViewController.view) ? nil : hit;
}
@end

static YTPassthroughWindow *ytToastWindow = nil;

UIView *ytGetToastParentView(void) {
    if (!ytToastWindow) {
        UIWindowScene *activeScene = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) { 
                activeScene = scene; 
                break; 
            }
        }
        if (!activeScene) activeScene = (UIWindowScene *)[[[UIApplication sharedApplication].connectedScenes allObjects] firstObject];
        if (!activeScene) return nil;

        ytToastWindow = [[YTPassthroughWindow alloc] initWithWindowScene:activeScene];
        ytToastWindow.frame = activeScene.coordinateSpace.bounds;
        ytToastWindow.windowLevel = UIWindowLevelAlert - 1;
        ytToastWindow.backgroundColor = [UIColor clearColor];
        ytToastWindow.hidden = NO;
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        ytToastWindow.rootViewController = rootVC;
    }
    return ytToastWindow.rootViewController.view;
}

@implementation YTPillToast

+ (void)showToastWithMessage:(NSString *)message iconName:(NSString *)iconName iconColor:(UIColor *)iconColor {
    UIView *parent = ytGetToastParentView();
    if (!parent) return;

    for (UIView *sub in parent.subviews) {
        if ([sub isKindOfClass:[YTPillToast class]]) {
            [sub removeFromSuperview];
        }
    }

    YTPillToast *pill = [[YTPillToast alloc] init];
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    // BASE: Lighter background
    pill.backgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.27 alpha:0.96]; 
    pill.layer.cornerRadius = 24.0;
    pill.clipsToBounds = YES;

    // WIPE: Darker animated overlay
    UIView *progressWipeView = [[UIView alloc] init];
    progressWipeView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.13 alpha:0.98]; 
    progressWipeView.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:progressWipeView];

    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName withConfiguration:config]];
    icon.tintColor = iconColor;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:icon];

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightMedium];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [parent addSubview:pill];

    // ANIMATION FIX: Anchor to the Right (Trailing) and start at Width = 0
    NSLayoutConstraint *wipeWidth = [progressWipeView.widthAnchor constraintEqualToConstant:0];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor],
        [pill.bottomAnchor constraintEqualToAnchor:parent.safeAreaLayoutGuide.bottomAnchor constant:-60],
        [pill.heightAnchor constraintEqualToConstant:48],
        [pill.widthAnchor constraintGreaterThanOrEqualToConstant:170],
        [pill.widthAnchor constraintLessThanOrEqualToAnchor:parent.widthAnchor constant:-40],

        [progressWipeView.topAnchor constraintEqualToAnchor:pill.topAnchor],
        [progressWipeView.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor],
        [progressWipeView.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor],
        wipeWidth,

        [icon.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:16],
        [icon.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        
        [label.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18],
        [label.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor]
    ]];

    [parent layoutIfNeeded];

    pill.transform = CGAffineTransformMakeTranslation(0, 80);
    pill.alpha = 0.0;
    
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        pill.transform = CGAffineTransformIdentity;
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        // ANIMATION WIPE: Expands width to 100%, moving Dark color from Right to Left
        wipeWidth.constant = pill.bounds.size.width;
        [UIView animateWithDuration:3.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [pill layoutIfNeeded];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                pill.transform = CGAffineTransformMakeTranslation(0, 80);
                pill.alpha = 0.0;
            } completion:^(BOOL finished) {
                [pill removeFromSuperview];
            }];
        }];
    }];
}

+ (void)showImageActionToastWithImage:(UIImage *)image text:(NSString *)text presenter:(UIViewController *)presenter {
    UIView *parent = ytGetToastParentView();
    if (!parent || !image) return;

    for (UIView *sub in parent.subviews) {
        if ([sub isKindOfClass:[YTPillToast class]]) {
            [sub removeFromSuperview];
        }
    }

    YTPillToast *pill = [[YTPillToast alloc] init];
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    // BASE: Lighter background
    pill.backgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.27 alpha:0.96];
    pill.layer.cornerRadius = 24.0;
    pill.clipsToBounds = YES;

    // WIPE: Darker animated overlay
    UIView *progressWipeView = [[UIView alloc] init];
    progressWipeView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.13 alpha:0.98];
    progressWipeView.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:progressWipeView];

    UILabel *label = [[UILabel alloc] init];
    label.text = text ?: @"Download completed";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightMedium];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    UIImageSymbolConfiguration *btnConfig = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightMedium];

    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadBtn setImage:[UIImage systemImageNamed:@"arrow.down.to.line" withConfiguration:btnConfig] forState:UIControlStateNormal];
    downloadBtn.tintColor = [UIColor whiteColor];
    downloadBtn.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.6]; 
    downloadBtn.layer.cornerRadius = 17.0;
    downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:downloadBtn];

    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:btnConfig] forState:UIControlStateNormal];
    shareBtn.tintColor = [UIColor whiteColor];
    shareBtn.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.6];
    shareBtn.layer.cornerRadius = 17.0;
    shareBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:shareBtn];

    [parent addSubview:pill];

    // ANIMATION FIX: Anchor to the Right (Trailing) and start at Width = 0
    NSLayoutConstraint *wipeWidth = [progressWipeView.widthAnchor constraintEqualToConstant:0];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor],
        [pill.bottomAnchor constraintEqualToAnchor:parent.safeAreaLayoutGuide.bottomAnchor constant:-60],
        [pill.heightAnchor constraintEqualToConstant:48],
        [pill.leadingAnchor constraintEqualToAnchor:label.leadingAnchor constant:-18],
        [pill.trailingAnchor constraintEqualToAnchor:shareBtn.trailingAnchor constant:10],

        [progressWipeView.topAnchor constraintEqualToAnchor:pill.topAnchor],
        [progressWipeView.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor],
        [progressWipeView.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor],
        wipeWidth,

        [label.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],

        [downloadBtn.leadingAnchor constraintEqualToAnchor:label.trailingAnchor constant:14],
        [downloadBtn.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [downloadBtn.widthAnchor constraintEqualToConstant:34],
        [downloadBtn.heightAnchor constraintEqualToConstant:34],

        [shareBtn.leadingAnchor constraintEqualToAnchor:downloadBtn.trailingAnchor constant:8],
        [shareBtn.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [shareBtn.widthAnchor constraintEqualToConstant:34],
        [shareBtn.heightAnchor constraintEqualToConstant:34]
    ]];

    [parent layoutIfNeeded];

    __weak typeof(pill) weakPill = pill;
    [downloadBtn addAction:[UIAction actionWithHandler:^(UIAction *action) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCreationRequest creationRequestForAssetFromImage:image];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [YTPillToast showSuccessWithMessage:@"Saved to Photos"];
                } else {
                    [YTPillToast showErrorWithMessage:@"Failed to save"];
                }
            });
        }];
        [weakPill removeFromSuperview];
    }] forControlEvents:UIControlEventTouchUpInside];

    [shareBtn addAction:[UIAction actionWithHandler:^(UIAction *action) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
        [YTTopViewController(presenter) presentViewController:activityVC animated:YES completion:nil];
        [weakPill removeFromSuperview];
    }] forControlEvents:UIControlEventTouchUpInside];

    pill.transform = CGAffineTransformMakeTranslation(0, 80);
    pill.alpha = 0.0;
    
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        pill.transform = CGAffineTransformIdentity;
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        // ANIMATION WIPE: Expands width to 100%, moving Dark color from Right to Left
        wipeWidth.constant = pill.bounds.size.width;
        [UIView animateWithDuration:4.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [pill layoutIfNeeded];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                pill.transform = CGAffineTransformMakeTranslation(0, 80);
                pill.alpha = 0.0;
            } completion:^(BOOL finished) {
                [pill removeFromSuperview];
            }];
        }];
    }];
}

+ (void)showSuccessWithMessage:(NSString *)message {
    [self showToastWithMessage:message iconName:@"checkmark.circle.fill" iconColor:[UIColor systemGreenColor]];
}

+ (void)showErrorWithMessage:(NSString *)message {
    [self showToastWithMessage:message iconName:@"xmark.circle.fill" iconColor:[UIColor systemRedColor]];
}

@end