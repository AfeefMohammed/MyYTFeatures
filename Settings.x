#import <UIKit/UIKit.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSettingsViewController.h>
#import <YouTubeHeader/YTSettingsGroupData.h>
#import <YouTubeHeader/YTIIcon.h>

// Use a unique char code to prevent duplication bugs across the settings menu
static const NSInteger TweakSection = 'myyt';

BOOL IsEnabled(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

@interface YTSettingsSectionItemManager (MyYTFeatures)
- (void)updateMyYTFeaturesSectionWithEntry:(id)entry;
@end

%hook YTSettingsGroupData
- (NSArray <NSNumber *> *)orderedCategories {
    NSArray *categories = %orig;
    if ([categories containsObject:@(TweakSection)]) return categories;
    NSMutableArray *mutableCategories = categories.mutableCopy;
    [mutableCategories insertObject:@(TweakSection) atIndex:0];
    return mutableCategories.copy;
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
        return mutableOrder.copy;
    }
    return order;
}
%end

%hook YTSettingsSectionItemManager
%new
- (void)updateMyYTFeaturesSectionWithEntry:(id)entry {
    NSMutableArray *sectionItems = [NSMutableArray array];
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
    
    NSArray *tweakKeys = @[
        @{@"key": @"videoEndTime", @"title": @"Show End Time"},
        @{@"key": @"noCast", @"title": @"Hide Cast Button"},
        @{@"key": @"removeUploads", @"title": @"Hide Create (+) Button"},
        @{@"key": @"postManager", @"title": @"Post Manager"},
        @{@"key": @"commentManager", @"title": @"Comment Manager"}
    ];
    
    for (NSDictionary *dict in tweakKeys) {
        NSString *key = dict[@"key"];
        YTSettingsSectionItem *item = [YTSettingsSectionItemClass switchItemWithTitle:dict[@"title"]
            titleDescription:nil
            accessibilityIdentifier:nil
            switchOn:IsEnabled(key)
            switchBlock:^BOOL (id cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:key];
                return YES;
            }
            settingItemId:0];
        [sectionItems addObject:item];
    }
    
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];
    
    // Add the native YouTube "Tune/Sliders" icon (Type 102)
    YTIIcon *icon = [%c(YTIIcon) new];
    if ([icon respondsToSelector:@selector(setIconType:)]) {
        icon.iconType = 102; 
    }

    if ([settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) {
        // Updated title to "YtLite Custom"
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:@"YtLite Custom" icon:icon titleDescription:nil headerHidden:NO];
    } else {
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:@"YtLite Custom" titleDescription:nil headerHidden:NO];
    }
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == TweakSection) {
        [self updateMyYTFeaturesSectionWithEntry:entry];
        return;
    }
    %orig;
}
%end