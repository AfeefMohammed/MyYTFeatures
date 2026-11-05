#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ==========================================
// Custom Tweak Interfaces
// ==========================================

@interface YTPillToast : UIView
+ (void)showSuccessWithMessage:(NSString *)message;
+ (void)showErrorWithMessage:(NSString *)message;
+ (void)showImageActionToastWithImage:(UIImage *)image text:(NSString *)text presenter:(UIViewController *)presenter;
@end

@interface YTTranslateManager : NSObject
+ (void)presentTranslationForText:(NSString *)text fromPresenter:(UIViewController *)presenter;
@end

// ==========================================
// YouTube Native Color System
// ==========================================

@interface YTColor : NSObject
+ (UIColor *)black3;
+ (UIColor *)white1;
@end

// ==========================================
// YouTube Native Icon System
// ==========================================

@interface YTIIcon : NSObject
@property (nonatomic, assign) int iconType;
- (UIImage *)iconImageWithColor:(UIColor *)color;
- (UIImage *)iconImageWithSelected:(BOOL)selected;
@end

// ==========================================
// AsyncDisplayKit / Texture Node Interfaces
// ==========================================

@interface ASDisplayNode : NSObject
@property (nonatomic, assign, readonly) UIViewController *closestViewController;
@property (atomic, assign, readonly) NSEnumerator *supernodes;
@property (readonly, copy) NSArray *yogaChildren;
@property (atomic) CALayer *layer;
@end

@interface ASTextNode : ASDisplayNode
@property (nonatomic, copy) NSAttributedString *attributedText;
@end

@interface ELMExpandableTextNode : ASDisplayNode
@property (nonatomic, strong) ASDisplayNode *currentTextNode;
@end

@interface ELMContainerNode : ASDisplayNode
@property (nonatomic, strong) NSString *copiedComment;
@property (nonatomic, strong) NSURL *copiedURL;
@end

@interface _ASDisplayView : UIView
@property (nonatomic, strong, readwrite) ASDisplayNode *keepalive_node;
@end

// ==========================================
// YouTube Player & Overlay Interfaces
// ==========================================

@interface YTInlinePlayerBarContainerView : UIView
@property (nonatomic, weak, readwrite) id delegate;
- (CGFloat)scrubRangeForScrubX:(CGFloat)arg1;
@end

@interface YTMainAppVideoPlayerOverlayViewController : UIViewController
- (CGFloat)totalTime;
@end

@interface YTPlayerViewController : UIViewController
- (void)seekToTime:(CGFloat)time;
- (void)setPlaybackRate:(float)rate;
- (CGFloat)currentVideoMediaTime;
@end

@interface YTLabel : UILabel
@end

// ==========================================
// YouTube Action Sheet & Settings Interfaces
// ==========================================

@interface YTActionSheetAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title iconImage:(UIImage *)image style:(NSInteger)style handler:(void (^)(void))handler;
@end

@interface YTDefaultSheetController : UIViewController
+ (instancetype)sheetControllerWithParentResponder:(id)responder;
- (void)addAction:(YTActionSheetAction *)action;
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion;
@end

// --- NEW/UPDATED SETTINGS INTERFACES ---
@interface YTSettingsSection : NSObject
+ (instancetype)sectionWithItems:(NSArray *)items title:(NSString *)title;
@end

@interface YTSettingsViewController : UINavigationController
- (void)pushViewController:(UIViewController *)viewController;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)setSectionItems:(id)items forCategory:(NSInteger)category title:(NSString *)title icon:(id)icon titleDescription:(NSString *)desc headerHidden:(BOOL)hidden;
- (void)setSectionItems:(id)items forCategory:(NSInteger)category title:(NSString *)title titleDescription:(NSString *)desc headerHidden:(BOOL)hidden;
- (void)setSections:(NSArray *)sections;
@end

@interface YTSettingsSectionItemManager : NSObject
- (void)updateSectionWithEntry:(id)entry;
- (void)updateYtLiteCustomSectionWithEntry:(id)entry;
- (id)parentResponder;
@end
// ---------------------------------------

@interface YTSettingsSectionItem : NSObject
@property (nonatomic, strong) YTIIcon *settingIcon;
+ (instancetype)itemWithTitle:(id)title accessibilityIdentifier:(id)acc detailTextBlock:(id)detail selectBlock:(id)selectBlock;
+ (instancetype)itemWithTitle:(id)title titleDescription:(id)desc accessibilityIdentifier:(id)acc detailTextBlock:(id)detail selectBlock:(id)selectBlock;
+ (instancetype)itemWithTitle:(NSString *)title accessibilityIdentifier:(NSString *)accId detailString:(NSString *)detail selectBlock:(BOOL (^)(YTSettingsViewController *vc, NSUInteger index))selectBlock;
+ (instancetype)itemWithTitle:(NSString *)title titleDescription:(NSString *)desc accessibilityIdentifier:(NSString *)accId detailString:(NSString *)detail selectBlock:(BOOL (^)(YTSettingsViewController *vc, NSUInteger index))selectBlock;
+ (instancetype)switchItemWithTitle:(id)title titleDescription:(id)desc accessibilityIdentifier:(id)acc switchOn:(BOOL)on switchBlock:(id)block settingItemId:(int)itemId;
@end

@interface YTSettingsGroupData : NSObject
@property (nonatomic, assign) int type;
- (NSArray <NSNumber *> *)orderedCategories;
@end

@interface YTAppSettingsPresentationData : NSObject
+ (NSArray <NSNumber *> *)settingsCategoryOrder;
@end

// ==========================================
// YtLite Custom sub-settings pages (YTLCSettings.x)
// ==========================================

@class YTLCSettingsItem;
extern YTLCSettingsItem *YTLCToggle(NSString *title, NSString *subtitle, NSString *key);
extern void YTLCPushSubSettings(NSString *title, NSArray<YTLCSettingsItem *> *items, id settingsVC, id parentResponder);

// ==========================================
// Runtime Helper Functions
// ==========================================

static inline BOOL IsDarkMode(void) {
    Class ytUIUtils = NSClassFromString(@"YTUIUtils");
    if (ytUIUtils && [ytUIUtils respondsToSelector:@selector(isDarkModeEnabled)]) {
        return ((BOOL (*)(id, SEL))objc_msgSend)(ytUIUtils, @selector(isDarkModeEnabled));
    }
    if (@available(iOS 13.0, *)) {
        return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return YES;
}

static inline UIViewController *YTTopViewController(UIViewController *root) {
    if (!root) {
        UIWindow *keyWindow = nil;
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        root = keyWindow.rootViewController;
    }
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }
    if ([root isKindOfClass:[UINavigationController class]]) {
        return YTTopViewController(((UINavigationController *)root).topViewController);
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        return YTTopViewController(((UITabBarController *)root).selectedViewController);
    }
    return root;
}