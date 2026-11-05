#import "Headers.h"

static const NSInteger TweakSection = 789;
#define TweakName @"YtLite Custom"

#define kPostManager @"postManager"
#define kCommentManager @"commentManager"
#define kTapToSeek @"tapToSeek"
#define kVideoEndTime @"videoEndTime"

// YouTube icon types (same ones YouMod uses)
#define kIconTune 530      // YT_TUNE  – entry in the Tweaks list
#define kIconDownload 57   // Downloading
#define kIconPlayer 658    // Player

%hook YTSettingsGroupData
- (NSArray <NSNumber *> *)orderedCategories {
    if (class_getClassMethod(objc_getClass("YTSettingsGroupData"), @selector(tweaks))) {
        NSMutableArray *tweaksArray = [%c(YTSettingsGroupData) performSelector:@selector(tweaks)];
        if (![tweaksArray containsObject:@(TweakSection)]) {
            [tweaksArray insertObject:@(TweakSection) atIndex:0]; 
        }
        return %orig;
    }
    if (self.type != 1) return %orig;
    
    NSArray *categories = %orig;
    NSMutableArray *mutableCategories = [categories mutableCopy];
    if (![mutableCategories containsObject:@(TweakSection)]) {
        [mutableCategories insertObject:@(TweakSection) atIndex:0];
    }
    return [mutableCategories copy];
}
%end

%hook YTAppSettingsPresentationData
+ (NSArray <NSNumber *> *)settingsCategoryOrder {
    NSArray <NSNumber *> *order = %orig;
    if ([order containsObject:@(TweakSection)]) return order;
    
    NSUInteger insertIndex = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound) {
        NSMutableArray <NSNumber *> *mutableOrder = [order mutableCopy];
        [mutableOrder insertObject:@(TweakSection) atIndex:insertIndex + 1];
        return [mutableOrder copy];
    }
    return order;
}
%end

%hook YTSettingsSectionItemManager
%new
- (void)updateYtLiteCustomSectionWithEntry:(id)entry {
    NSMutableArray *sectionItems = [NSMutableArray array];
    Class itemClass = %c(YTSettingsSectionItem);
    id settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];

    // ---------- Downloading ----------
    NSArray *downloadItems = @[
        YTLCToggle(@"Save post information",
                   @"Allows to copy post text and save post as image by long tap.",
                   kPostManager),
        YTLCToggle(@"Save comment information",
                   @"Allows to copy comment text and save comment as image by long tap on the three dots button.",
                   kCommentManager),
    ];
    YTSettingsSectionItem *downloadGroup = [itemClass itemWithTitle:@"Downloading"
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (id cell, NSUInteger arg1) {
            YTLCPushSubSettings(@"Downloading", downloadItems, settingsViewController, [self parentResponder]);
            return YES;
        }];
    YTIIcon *downloadIcon = [%c(YTIIcon) new];
    downloadIcon.iconType = kIconDownload;
    downloadGroup.settingIcon = downloadIcon;
    [sectionItems addObject:downloadGroup];

    // ---------- Player ----------
    NSArray *playerItems = @[
        YTLCToggle(@"Show end time",
                   @"Adds the estimated finish time to the label in the video overlay.",
                   kVideoEndTime),
        YTLCToggle(@"Tap to seek",
                   @"Quickly jump to any point by tapping the progress bar.",
                   kTapToSeek),
    ];
    YTSettingsSectionItem *playerGroup = [itemClass itemWithTitle:@"Player"
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (id cell, NSUInteger arg1) {
            YTLCPushSubSettings(@"Player", playerItems, settingsViewController, [self parentResponder]);
            return YES;
        }];
    YTIIcon *playerIcon = [%c(YTIIcon) new];
    playerIcon.iconType = kIconPlayer;
    playerGroup.settingIcon = playerIcon;
    [sectionItems addObject:playerGroup];

    // ---------- Entry in YouTube's Tweaks list (tune icon) ----------
    YTIIcon *tuneIcon = [%c(YTIIcon) new];
    tuneIcon.iconType = kIconTune;

    if ([settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) {
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:TweakName icon:tuneIcon titleDescription:nil headerHidden:NO];
    } else if ([settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:titleDescription:headerHidden:)]) {
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:TweakName titleDescription:nil headerHidden:NO];
    }
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == TweakSection) {
        [self updateYtLiteCustomSectionWithEntry:entry];
        return;
    }
    %orig;
}
%end

%ctor {
    NSDictionary *defaults = @{
        kPostManager: @YES,
        kCommentManager: @YES,
        kVideoEndTime: @NO,
        kTapToSeek: @YES
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    %init;
}
