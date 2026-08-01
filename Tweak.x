#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <YouTubeHeader/YTPlayerViewController.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayView.h>
#import <YouTubeHeader/YTActionSheetAction.h>
#import <YouTubeHeader/YTDefaultSheetController.h>

extern BOOL IsEnabled(NSString *key);

// --- 1. SHOW END TIME ---
@interface YTInlinePlayerBarContainerView (MyYT)
@property (nonatomic, strong, readwrite) NSString *endTimeString;
@end

void addEndTime(YTPlayerViewController *self, id video, id time) {
    if (!IsEnabled(@"videoEndTime")) return;

    CGFloat rate = [video respondsToSelector:@selector(playbackRate)] ? [video playbackRate] : 1.0;
    if (rate == 0) rate = 1.0;
    
    CGFloat totalMediaTime = [video respondsToSelector:@selector(totalMediaTime)] ? [video totalMediaTime] : 0.0;
    CGFloat currentTime = [time respondsToSelector:@selector(time)] ? [time time] : 0.0;

    NSTimeInterval remainingTime = (lround(totalMediaTime) - lround(currentTime)) / rate;
    NSDate *estimatedEndTime = [NSDate dateWithTimeIntervalSinceNow:remainingTime];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"h:mm a"];

    NSString *formattedEndTime = [dateFormatter stringFromDate:estimatedEndTime];

    UIView *playerView = self.view;
    YTMainAppVideoPlayerOverlayView *overlay = (YTMainAppVideoPlayerOverlayView *)[playerView valueForKey:@"_overlayView"];
    if (![overlay isKindOfClass:%c(YTMainAppVideoPlayerOverlayView)]) return;

    UILabel *durationLabel = [overlay.playerBar valueForKey:@"durationLabel"];
    overlay.playerBar.endTimeString = formattedEndTime;

    if (![durationLabel.text containsString:formattedEndTime]) {
        durationLabel.text = [durationLabel.text stringByAppendingString:[NSString stringWithFormat:@" • %@", formattedEndTime]];
        [durationLabel sizeToFit];
    }
}

%hook YTPlayerViewController
- (void)singleVideo:(id)video currentVideoTimeDidChange:(id)time {
    %orig;
    addEndTime(self, video, time);
}
- (void)potentiallyMutatedSingleVideo:(id)video currentVideoTimeDidChange:(id)time {
    %orig;
    addEndTime(self, video, time);
}
%end

%hook YTInlinePlayerBarContainerView
%property (nonatomic, strong) NSString *endTimeString;
- (void)setPeekableViewVisible:(BOOL)visible {
    %orig;
    if (!IsEnabled(@"videoEndTime")) return;
    
    UILabel *durationLabel = [self valueForKey:@"durationLabel"];
    if (self.endTimeString && ![durationLabel.text containsString:self.endTimeString]) {
        durationLabel.text = [durationLabel.text stringByAppendingString:[NSString stringWithFormat:@" • %@", self.endTimeString]];
        [durationLabel sizeToFit];
    }
}
%end


// --- 2. HIDE CAST BUTTON ---
%hook MDXPlaybackRouteButtonController
- (BOOL)isPersistentCastIconEnabled { 
    if (IsEnabled(@"noCast")) {
        return NO;
    }
    return %orig;
}
- (void)updateRouteButton:(id)arg1 { 
    if (!IsEnabled(@"noCast")) {
        %orig;
    }
}
- (void)updateAllRouteButtons { 
    if (!IsEnabled(@"noCast")) {
        %orig;
    }
}
%end

%hook YTSettings
- (void)setDisableMDXDeviceDiscovery:(BOOL)arg1 {
    if (IsEnabled(@"noCast")) {
        %orig(YES);
    } else {
        %orig;
    }
}
%end

%hook YTRightNavigationButtons
- (void)layoutSubviews {
    %orig;
    for (UIView *subview in self.subviews) {
        if (IsEnabled(@"noCast") && [subview.accessibilityIdentifier isEqualToString:@"id.mdx.playbackroute.button"]) {
            subview.hidden = YES;
        }
    }
}
%end


// --- 3. HIDE CREATE BUTTON ---
%hook YTPivotBarView
- (void)setRenderer:(id)renderer {
    if (IsEnabled(@"removeUploads")) {
        NSMutableArray *items = [renderer performSelector:@selector(itemsArray)];
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            id iconOnlyRenderer = [obj respondsToSelector:@selector(pivotBarIconOnlyItemRenderer)] ? [obj performSelector:@selector(pivotBarIconOnlyItemRenderer)] : nil;
            NSString *pivotIdentifier = [iconOnlyRenderer respondsToSelector:@selector(pivotIdentifier)] ? [iconOnlyRenderer performSelector:@selector(pivotIdentifier)] : nil;
            return [pivotIdentifier isEqualToString:@"FEuploads"];
        }];
        if (index != NSNotFound) {
            [items removeObjectAtIndex:index];
        }
    }
    %orig;
}
%end


// --- 4. TAP TO SEEK ---
%hook YTInlinePlayerBarContainerView
- (BOOL)canTapToSeek {
    if (IsEnabled(@"tapToSeek")) {
        return YES;
    }
    return %orig;
}
%end


// --- 5. MEDIA MANAGERS (PFP, Post, Comment) ---
@interface ASDisplayNode : NSObject
@property (nonatomic, assign, readonly) UIViewController *closestViewController;
@property (atomic, assign, readonly) NSEnumerator *supernodes;
@property (atomic) CALayer *layer;
@end

@interface ELMContainerNode : ASDisplayNode
@property (nonatomic, strong, readwrite) NSString *copiedComment;
@property (nonatomic, strong, readwrite) NSURL *copiedURL;
@end

@interface ASNetworkImageNode : ASDisplayNode
@property (atomic, copy, readwrite) NSURL *URL;
@end

@interface _ASDisplayView : UIView
@property (nonatomic, strong, readwrite) ASDisplayNode *keepalive_node;
- (void)postManager:(UILongPressGestureRecognizer *)sender;
- (void)savePFP:(UILongPressGestureRecognizer *)sender;
- (void)commentManager:(UILongPressGestureRecognizer *)sender;
@end

static void genImageFromLayer(CALayer *layer, UIColor *backgroundColor, void (^completionHandler)(UIImage *)) {
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, layer.frame.size.width, layer.frame.size.height));
    [layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (completionHandler) {
        completionHandler(image);
    }
}

%hook ELMContainerNode
%property (nonatomic, strong) NSString *copiedComment;
%property (nonatomic, strong) NSURL *copiedURL;
%end

%hook ASDisplayNode
- (void)setFrame:(CGRect)frame {
    %orig;
    if (IsEnabled(@"commentManager") && [[self valueForKey:@"_accessibilityIdentifier"] isEqualToString:@"id.comment.content.label"]) {
        NSString *comment = nil;
        if ([self respondsToSelector:@selector(attributedText)]) {
            NSAttributedString *attrText = [self performSelector:@selector(attributedText)];
            comment = attrText.string;
        }
        for (ELMContainerNode *containerNode in [[self performSelector:@selector(supernodes)] allObjects]) {
            if ([containerNode.description containsString:@"id.ui.comment_cell"] && comment) {
                containerNode.copiedComment = comment;
                break;
            }
        }
    }
}
%end

%hook _ASDisplayView
- (void)setKeepalive_node:(id)arg1 {
    %orig;
    NSArray *gesturesInfo = @[
        @{@"selector": @"postManager:", @"text": @"id.ui.backstage.original_post", @"key": @(IsEnabled(@"postManager"))},
        @{@"selector": @"savePFP:", @"text": @"ELMImageNode-View", @"key": @(IsEnabled(@"saveProfilePhoto"))},
        @{@"selector": @"commentManager:", @"text": @"id.ui.comment_cell", @"key": @(IsEnabled(@"commentManager"))}
    ];

    for (NSDictionary *gestureInfo in gesturesInfo) {
        SEL selector = NSSelectorFromString(gestureInfo[@"selector"]);
        if ([gestureInfo[@"key"] boolValue] && [[self description] containsString:gestureInfo[@"text"]]) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:selector];
            longPress.minimumPressDuration = 0.3;
            [self addGestureRecognizer:longPress];
            break;
        }
    }
}

%new
- (void)savePFP:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ASNetworkImageNode *imageNode = (ASNetworkImageNode *)self.keepalive_node;
        NSString *URLString = imageNode.URL.absoluteString;
        if (URLString) {
            NSURL *PFPURL = [NSURL URLWithString:URLString];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:PFPURL]];
            if (image) {
                YTDefaultSheetController *sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
                [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Save Profile Picture" iconImage:nil style:0 handler:^{
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                }]];
                [sheetController presentFromViewController:self.keepalive_node.closestViewController animated:YES completion:nil];
            }
        }
    }
}

%new
- (void)postManager:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
        NSString *text = containerNode.copiedComment;
        CALayer *layer = self.layer;
        UIColor *backgroundColor = containerNode.closestViewController.view.backgroundColor;

        YTDefaultSheetController *sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy Post Text" iconImage:nil style:0 handler:^{
            if (text) [UIPasteboard generalPasteboard].string = text;
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Save Post As Image" iconImage:nil style:0 handler:^{
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            });
        }]];
        [sheetController presentFromViewController:containerNode.closestViewController animated:YES completion:nil];
    }
}

%new
- (void)commentManager:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
        NSString *comment = containerNode.copiedComment;
        CALayer *layer = self.layer;
        UIColor *backgroundColor = containerNode.closestViewController.view.backgroundColor;

        YTDefaultSheetController *sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy Comment Text" iconImage:nil style:0 handler:^{
            if (comment) [UIPasteboard generalPasteboard].string = comment;
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Save Comment As Image" iconImage:nil style:0 handler:^{
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            });
        }]];
        [sheetController presentFromViewController:containerNode.closestViewController animated:YES completion:nil];
    }
}
%end
