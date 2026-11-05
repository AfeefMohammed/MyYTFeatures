#import "Headers.h"

// --- COMPILER FIX ---
@interface YTIIcon (CompilerFix)
- (UIImage *)iconImageWithColor:(UIColor *)color;
@end
// --------------------

#define IsEnabled(key) [[NSUserDefaults standardUserDefaults] boolForKey:key]

// 1. The Integer-Based Icon Generator
static UIImage *GetImageForYTInteger(int iconId) {
    YTIIcon *icon = [%c(YTIIcon) new];
    if ([icon respondsToSelector:@selector(setIconType:)]) {
        icon.iconType = iconId;
        if ([icon respondsToSelector:@selector(iconImageWithColor:)]) {
            // Using labelColor ensures the integer icon adapts perfectly to Light/Dark mode
            return [[icon iconImageWithColor:[UIColor labelColor]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
    }
    return nil;
}

static void genImageFromLayer(CALayer *layer, UIColor *backgroundColor, void (^completionHandler)(UIImage *)) {
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (backgroundColor) {
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, layer.frame.size.width, layer.frame.size.height));
    }
    [layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (completionHandler) {
        completionHandler(image);
    }
}

// ==========================================
// Text Capture Hooks
// ==========================================

%hook ELMContainerNode
%property (nonatomic, strong) NSString *copiedComment;
%property (nonatomic, strong) NSURL *copiedURL;
%end

%hook ASDisplayNode
- (void)setFrame:(CGRect)frame {
    %orig;
    if (IsEnabled(@"commentManager") && [[self valueForKey:@"_accessibilityIdentifier"] isEqualToString:@"id.comment.content.label"]) {
        if ([self isKindOfClass:NSClassFromString(@"ASTextNode")]) {
            ASTextNode *textNode = (ASTextNode *)self;
            NSString *comment = textNode.attributedText ? textNode.attributedText.string : nil;
            for (ELMContainerNode *containerNode in self.supernodes.allObjects) {
                if ([containerNode.description containsString:@"id.ui.comment_cell"] && comment) {
                    containerNode.copiedComment = comment;
                    break;
                }
            }
        }
    }
    if (IsEnabled(@"postManager") && [self isKindOfClass:NSClassFromString(@"ELMExpandableTextNode")]) {
        ELMExpandableTextNode *expandableTextNode = (ELMExpandableTextNode *)self;
        if ([expandableTextNode.currentTextNode isKindOfClass:NSClassFromString(@"ASTextNode")]) {
            ASTextNode *textNode = (ASTextNode *)expandableTextNode.currentTextNode;
            NSString *text = textNode.attributedText ? textNode.attributedText.string : nil;
            for (ELMContainerNode *containerNode in self.supernodes.allObjects) {
                if ([containerNode.description containsString:@"id.ui.backstage.original_post"] && text) {
                    containerNode.copiedComment = text;
                    break;
                }
            }
        }
    }
}
%end

// ==========================================
// Gesture & Action Sheet Hooks
// ==========================================

%hook _ASDisplayView
- (void)setKeepalive_node:(id)arg1 {
    %orig;
    if (IsEnabled(@"postManager") && [[self description] containsString:@"id.ui.backstage.original_post"]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePostManager:)];
        longPress.minimumPressDuration = 0.3;
        [self addGestureRecognizer:longPress];
    }
    if (IsEnabled(@"commentManager") && [[self description] containsString:@"id.ui.comment_cell"]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCommentManager:)];
        longPress.minimumPressDuration = 0.3;
        [self addGestureRecognizer:longPress];
    }
}

%new
- (void)handlePostManager:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
        NSString *text = containerNode.copiedComment;
        CALayer *layer = self.layer;
        UIViewController *closestVC = containerNode.closestViewController;
        UIColor *backgroundColor = closestVC.view.backgroundColor;
        YTDefaultSheetController *sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];
        
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Translate post" iconImage:GetImageForYTInteger(897) style:0 handler:^ {
            [YTTranslateManager presentTranslationForText:text fromPresenter:closestVC];
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy post text" iconImage:GetImageForYTInteger(243) style:0 handler:^ {
            if (text) {
                [UIPasteboard generalPasteboard].string = text;
                [YTPillToast showSuccessWithMessage:@"Copied to clipboard"];
            } else {
                [YTPillToast showErrorWithMessage:@"No text found to copy"];
            }
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Save post as image" iconImage:GetImageForYTInteger(367) style:0 handler:^ {
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [YTPillToast showImageActionToastWithImage:image text:@"Download completed" presenter:closestVC];
                });
            });
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy post as image" iconImage:GetImageForYTInteger(208) style:0 handler:^ {
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                if (image) {
                    [UIPasteboard generalPasteboard].image = image;
                    [YTPillToast showSuccessWithMessage:@"Copied to clipboard"];
                }
            });
        }]];
        [sheetController presentFromViewController:closestVC animated:YES completion:nil];
    }
}

%new
- (void)handleCommentManager:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
        NSString *comment = containerNode.copiedComment;
        CALayer *layer = self.layer;
        UIViewController *closestVC = containerNode.closestViewController;
        UIColor *backgroundColor = closestVC.view.backgroundColor;
        YTDefaultSheetController *sheetController = [%c(YTDefaultSheetController) sheetControllerWithParentResponder:nil];

        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Translate comment" iconImage:GetImageForYTInteger(897) style:0 handler:^ {
            [YTTranslateManager presentTranslationForText:comment fromPresenter:closestVC];
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy comment text" iconImage:GetImageForYTInteger(243) style:0 handler:^ {
            if (comment) {
                [UIPasteboard generalPasteboard].string = comment;
                [YTPillToast showSuccessWithMessage:@"Copied to clipboard"];
            } else {
                [YTPillToast showErrorWithMessage:@"No text found to copy"];
            }
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Save comment as image" iconImage:GetImageForYTInteger(367) style:0 handler:^ {
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [YTPillToast showImageActionToastWithImage:image text:@"Download completed" presenter:closestVC];
                });
            });
        }]];
        [sheetController addAction:[%c(YTActionSheetAction) actionWithTitle:@"Copy comment as image" iconImage:GetImageForYTInteger(208) style:0 handler:^ {
            genImageFromLayer(layer, backgroundColor, ^(UIImage *image) {
                if (image) {
                    [UIPasteboard generalPasteboard].image = image;
                    [YTPillToast showSuccessWithMessage:@"Copied to clipboard"];
                }
            });
        }]];
        [sheetController presentFromViewController:closestVC animated:YES completion:nil];
    }
}
%end