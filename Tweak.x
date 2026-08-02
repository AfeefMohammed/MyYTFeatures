#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <YouTubeHeader/YTPlayerViewController.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayView.h>
#import <YouTubeHeader/YTDefaultSheetController.h>

extern BOOL IsEnabled(NSString *key);

@interface YTDefaultSheetController (MyYT)
+ (instancetype)sheetControllerWithParentResponder:(id)responder;
- (void)presentFromViewController:(id)vc animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)addAction:(id)action;
@end

// --- 1. SHOW END TIME ---
@interface YTInlinePlayerBarContainerView (MyYT)
@property (nonatomic, strong, readwrite) NSString *endTimeString;
@end

void addEndTime(YTPlayerViewController *self, id video, id time) {
    if (!IsEnabled(@"videoEndTime")) return;

    CGFloat rate = 1.0;
    if ([video respondsToSelector:@selector(playbackRate)]) {
        rate = [[video valueForKey:@"playbackRate"] floatValue];
    }
    if (rate == 0) rate = 1.0;
    
    CGFloat totalMediaTime = 0.0;
    if ([video respondsToSelector:@selector(totalMediaTime)]) {
        totalMediaTime = [[video valueForKey:@"totalMediaTime"] floatValue];
    }
    
    CGFloat currentTime = 0.0;
    if ([time respondsToSelector:@selector(time)]) {
        currentTime = [[time valueForKey:@"time"] floatValue];
    }

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


// --- 2. MEDIA MANAGERS (Post, Comment) ---
@interface ASDisplayNode : NSObject
@property (nonatomic, assign, readonly) UIViewController *closestViewController;
@property (atomic, assign, readonly) NSEnumerator *supernodes;
@property (atomic) CALayer *layer;
@end

@interface ELMContainerNode : ASDisplayNode
@property (nonatomic, strong, readwrite) NSString *copiedComment;
@end

@interface _ASDisplayView : UIView
@property (nonatomic, strong, readwrite) ASDisplayNode *keepalive_node;
- (void)postManager:(UILongPressGestureRecognizer *)sender;
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

static void addSafeActionToSheet(id sheet, NSString *title, void (^handler)(void)) {
    Class actionClass = NSClassFromString(@"YTActionSheetAction");
    id action = nil;
    if ([actionClass respondsToSelector:@selector(actionWithTitle:subtitle:iconImage:handler:)]) {
        action = ((id (*)(Class, SEL, NSString *, NSString *, UIImage *, id))objc_msgSend)(actionClass, @selector(actionWithTitle:subtitle:iconImage:handler:), title, nil, nil, ^(__unused id act) {
            if (handler) handler();
        });
    } else {
        action = ((id (*)(Class, SEL, NSString *, NSInteger, id))objc_msgSend)(actionClass, @selector(actionWithTitle:style:handler:), title, 0, ^(__unused id act) {
            if (handler) handler();
        });
    }
    if (action && [sheet respondsToSelector:@selector(addAction:)]) {
        [sheet performSelector:@selector(addAction:) withObject:action];
    }
}

%hook ELMContainerNode
%property (nonatomic, strong) NSString *copiedComment;
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
- (void)postManager:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
        NSString *text = containerNode.copiedComment;
        CALayer *layer = self.layer;
        UIColor *backgroundColor = containerNode.closestViewController.view.backgroundColor;

        id sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
        
        addSafeActionToSheet(sheetController, @"Copy Post Text", ^{
            if (text) [UIPasteboard generalPasteboard].string = text;
        });
        
        addSafeActionToSheet(sheetController, @"Save Post As Image", ^{
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            });
        });

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

        id sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
        
        addSafeActionToSheet(sheetController, @"Copy Comment Text", ^{
            if (comment) [UIPasteboard generalPasteboard].string = comment;
        });
        
        addSafeActionToSheet(sheetController, @"Save Comment As Image", ^{
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            });
        });

        [sheetController presentFromViewController:containerNode.closestViewController animated:YES completion:nil];
    }
}
%end