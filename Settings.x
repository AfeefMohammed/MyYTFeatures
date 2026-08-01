#import <UIKit/UIKit.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSettingsViewController.h>
#import <YouTubeHeader/YTSettingsGroupData.h>
#import <YouTubeHeader/YTIIcon.h>

// Use the exact section ID that YTLite uses to avoid array sorting conflicts
static const NSInteger TweakSection = 789;

BOOL IsEnabled(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

@interface YTSettingsSectionItemManager (MyYTFeatures)
- (void)updateMyYTFeaturesSectionWithEntry:(id)entry;
@end

// Inject ONLY into the presentation data to prevent duplication
%hook YTAppSettingsPresentationData
+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];
    NSUInteger insertIndex = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound) {
        [mutableOrder insertObject:@(TweakSection) atIndex:insertIndex + 1];
    }
    return mutableOrder.copy;
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
    
    // Attempting ID 211 for Sliders/Tune. (If it fails, change this to 255 for a Settings Gear)
    YTIIcon *icon = [%c(YTIIcon) new];
    if ([icon respondsToSelector:@selector(setIconType:)]) {
        icon.iconType = 211; 
    }

    if ([settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) {
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