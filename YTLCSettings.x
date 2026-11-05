// YTLCSettings.x
// YouMod-style UIKit sub-settings page for YtLite Custom.
// Layout, fonts, colours and the purple pill toggles follow YouMod's
// YMSubSettingsViewController (https://github.com/Tonwalter888/YouMod).
// Only the toggle row type is implemented, and every class/function carries
// the YTLC prefix so it can live next to YouMod inside the same IPA.
#import "Headers.h"

// The "Search" bar at the top of each sub page (as in YouMod). Set to NO to hide it.
static const BOOL kYTLCShowPageSearch = YES;

static UIColor *YTLCAccentColor(void) {
    return [UIColor colorWithRed:0.6 green:0.2 blue:0.9 alpha:1.0];
}

static UIColor *YTLCBackgroundColor(UITraitCollection *traits) {
    if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
        Class ytColor = objc_getClass("YTColor");
        if ([ytColor respondsToSelector:@selector(black3)]) return [ytColor black3];
        return [UIColor colorWithWhite:0.06 alpha:1.0];
    }
    return [UIColor systemBackgroundColor];
}

#pragma mark - Data model

@interface YTLCSettingsItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *key;
@end

@implementation YTLCSettingsItem
@end

YTLCSettingsItem *YTLCToggle(NSString *title, NSString *subtitle, NSString *key) {
    YTLCSettingsItem *item = [[YTLCSettingsItem alloc] init];
    item.title = title;
    item.subtitle = subtitle;
    item.key = key;
    return item;
}

#pragma mark - YTLCSubSettingsViewController

@interface YTLCSubSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
- (UITableView *)tableView;
- (void)setTableView:(UITableView *)tv;
- (UISearchBar *)searchBar;
- (void)setSearchBar:(UISearchBar *)sb;
- (NSString *)navTitle;
- (void)setNavTitle:(NSString *)t;
- (NSArray<YTLCSettingsItem *> *)items;
- (void)setItems:(NSArray<YTLCSettingsItem *> *)items;
- (NSString *)pageFilter;
- (void)setPageFilter:(NSString *)f;
- (NSArray<YTLCSettingsItem *> *)displayedItems;
@end

static const void *kYTLCTableViewKey = &kYTLCTableViewKey;
static const void *kYTLCSearchBarKey = &kYTLCSearchBarKey;
static const void *kYTLCNavTitleKey = &kYTLCNavTitleKey;
static const void *kYTLCItemsKey = &kYTLCItemsKey;
static const void *kYTLCPageFilterKey = &kYTLCPageFilterKey;
static const void *kYTLCSwitchKeyAssoc = &kYTLCSwitchKeyAssoc;

@implementation YTLCSubSettingsViewController

// No ivars: this class's methods are copied onto a runtime subclass of
// YTStyledViewController (see YTLCEnsureStyledClass), so state lives in
// associated objects, exactly like YouMod does.
- (UITableView *)tableView { return objc_getAssociatedObject(self, kYTLCTableViewKey); }
- (void)setTableView:(UITableView *)tv { objc_setAssociatedObject(self, kYTLCTableViewKey, tv, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
- (UISearchBar *)searchBar { return objc_getAssociatedObject(self, kYTLCSearchBarKey); }
- (void)setSearchBar:(UISearchBar *)sb { objc_setAssociatedObject(self, kYTLCSearchBarKey, sb, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
- (NSString *)navTitle { return objc_getAssociatedObject(self, kYTLCNavTitleKey); }
- (void)setNavTitle:(NSString *)t { objc_setAssociatedObject(self, kYTLCNavTitleKey, t, OBJC_ASSOCIATION_COPY_NONATOMIC); }
- (NSArray<YTLCSettingsItem *> *)items { return objc_getAssociatedObject(self, kYTLCItemsKey); }
- (void)setItems:(NSArray<YTLCSettingsItem *> *)items { objc_setAssociatedObject(self, kYTLCItemsKey, items, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
- (NSString *)pageFilter { return objc_getAssociatedObject(self, kYTLCPageFilterKey); }
- (void)setPageFilter:(NSString *)f { objc_setAssociatedObject(self, kYTLCPageFilterKey, f, OBJC_ASSOCIATION_COPY_NONATOMIC); }

- (UIColor *)ytlcTextColor {
    return (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        ? [UIColor whiteColor] : [UIColor labelColor];
}

- (UIColor *)ytlcSecondaryColor {
    return [UIColor colorWithWhite:0.55 alpha:1.0];
}

// All items, or only those whose title/subtitle match the page search text.
- (NSArray<YTLCSettingsItem *> *)displayedItems {
    NSString *q = self.pageFilter;
    if (q.length == 0) return self.items;
    NSMutableArray<YTLCSettingsItem *> *matches = [NSMutableArray array];
    NSStringCompareOptions opts = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    for (YTLCSettingsItem *item in self.items) {
        NSString *hay = [NSString stringWithFormat:@"%@ %@", item.title ?: @"", item.subtitle ?: @""];
        if ([hay rangeOfString:q options:opts].location != NSNotFound) [matches addObject:item];
    }
    return matches;
}

- (void)applyNavigationBarAppearance {
    UIColor *bgColor = YTLCBackgroundColor(self.traitCollection);
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    appearance.backgroundColor = bgColor;
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
}

- (void)updateSearchBarTheme {
    UISearchBar *sb = self.searchBar;
    if (!sb) return;
    UIColor *bgColor = YTLCBackgroundColor(self.traitCollection);
    sb.backgroundColor = bgColor;
    sb.barTintColor = bgColor;
    UITextField *tf = sb.searchTextField;
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        tf.textColor = [UIColor whiteColor];
        tf.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    } else {
        tf.textColor = [UIColor labelColor];
        tf.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    }
}

- (void)viewDidLoad {
    Class ytStyled = objc_getClass("YTStyledViewController");
    struct objc_super superStruct = { self, ytStyled ?: [UIViewController class] };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&superStruct, @selector(viewDidLoad));

    self.title = self.navTitle;

    UIColor *bgColor = YTLCBackgroundColor(self.traitCollection);
    self.view.backgroundColor = bgColor;
    [self applyNavigationBarAppearance];

    UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.delegate = self;
    tv.dataSource = self;
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tv.estimatedRowHeight = 60;
    tv.rowHeight = UITableViewAutomaticDimension;
    tv.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    tv.backgroundColor = bgColor;
    self.tableView = tv;
    [self.view addSubview:tv];

    if (kYTLCShowPageSearch) {
        UISearchBar *sb = [[UISearchBar alloc] initWithFrame:CGRectZero];
        sb.translatesAutoresizingMaskIntoConstraints = NO;
        sb.placeholder = @"Search";
        sb.searchBarStyle = UISearchBarStyleMinimal;
        sb.tintColor = YTLCAccentColor();
        sb.delegate = self;
        sb.backgroundImage = [[UIImage alloc] init];
        [self.view addSubview:sb];
        self.searchBar = sb;
        [self updateSearchBarTheme];

        [NSLayoutConstraint activateConstraints:@[
            [sb.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [sb.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [sb.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

            [tv.topAnchor constraintEqualToAnchor:sb.bottomAnchor],
            [tv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [tv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [tv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [tv.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [tv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [tv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [tv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
        ]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    Class ytStyled = objc_getClass("YTStyledViewController");
    struct objc_super superStruct = { self, ytStyled ?: [UIViewController class] };
    ((void (*)(struct objc_super *, SEL, BOOL))objc_msgSendSuper)(&superStruct, @selector(viewWillAppear:), animated);
    [self applyNavigationBarAppearance];
}

- (void)viewDidLayoutSubviews {
    Class ytStyled = objc_getClass("YTStyledViewController");
    struct objc_super superStruct = { self, ytStyled ?: [UIViewController class] };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&superStruct, @selector(viewDidLayoutSubviews));

    // Keep YouTube's back chevron white in dark mode / black in light mode.
    id backButton = nil;
    @try { backButton = [self valueForKey:@"_backButton"]; } @catch (__unused NSException *e) {}
    if ([backButton respondsToSelector:@selector(setTintColor:)]) {
        [backButton setTintColor:(self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor whiteColor] : [UIColor blackColor]];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        UIColor *bgColor = YTLCBackgroundColor(self.traitCollection);
        self.view.backgroundColor = bgColor;
        self.tableView.backgroundColor = bgColor;
        [self applyNavigationBarAppearance];
        [self updateSearchBarTheme];
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.pageFilter = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    self.pageFilter = @"";
    [searchBar resignFirstResponder];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YTLCSettingsItem *item = self.displayedItems[indexPath.row];

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.text = item.title;
    cell.textLabel.textColor = [self ytlcTextColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    cell.textLabel.numberOfLines = 0;

    if (item.subtitle.length > 0) {
        cell.detailTextLabel.text = item.subtitle;
        cell.detailTextLabel.textColor = [self ytlcSecondaryColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.numberOfLines = 0;
    }

    // Pill-shaped toggle, purple when on.
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:item.key];
    sw.onTintColor = YTLCAccentColor();
    objc_setAssociatedObject(sw, kYTLCSwitchKeyAssoc, item.key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sw addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;

    return cell;
}

- (void)toggleChanged:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, kYTLCSwitchKeyAssoc);
    if (key) [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:key];
}

#pragma mark - Header / Footer spacing (same as YouMod)

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 16; }
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section { return [[UIView alloc] init]; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 0; }
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return [[UIView alloc] init]; }

@end

#pragma mark - Runtime registration

// Builds "YTLCSubSettingsViewControllerStyled": a real subclass of YouTube's
// YTStyledViewController (so it gets YouTube's nav bar, back button and
// -initWithParentResponder:) with this file's methods copied onto it.
static void YTLCEnsureStyledClass(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class ytStyled = objc_getClass("YTStyledViewController");
        if (!ytStyled || objc_getClass("YTLCSubSettingsViewControllerStyled")) return;

        Class newClass = objc_allocateClassPair(ytStyled, "YTLCSubSettingsViewControllerStyled", 0);
        if (!newClass) return;

        Class sourceClass = [YTLCSubSettingsViewController class];
        unsigned int count = 0;
        Method *methods = class_copyMethodList(sourceClass, &count);
        for (unsigned int i = 0; i < count; i++) {
            class_addMethod(newClass, method_getName(methods[i]), method_getImplementation(methods[i]), method_getTypeEncoding(methods[i]));
        }
        free(methods);

        // Delegate / data source protocols so UIKit accepts the controller.
        class_addProtocol(newClass, @protocol(UITableViewDelegate));
        class_addProtocol(newClass, @protocol(UITableViewDataSource));
        class_addProtocol(newClass, @protocol(UISearchBarDelegate));

        objc_registerClassPair(newClass);
    });
}

#pragma mark - Entry point

void YTLCPushSubSettings(NSString *title, NSArray<YTLCSettingsItem *> *items, id settingsVC, id parentResponder) {
    YTLCEnsureStyledClass();

    Class cls = objc_getClass("YTLCSubSettingsViewControllerStyled");
    if (!cls || ![cls instancesRespondToSelector:@selector(initWithParentResponder:)]) return;

    id vc = ((id (*)(id, SEL, id))objc_msgSend)([cls alloc], @selector(initWithParentResponder:), parentResponder);
    if (!vc) return;
    [vc setNavTitle:title];
    [vc setItems:items];

    if ([settingsVC respondsToSelector:@selector(pushViewController:)]) {
        [settingsVC pushViewController:vc];
    } else if ([settingsVC respondsToSelector:@selector(pushViewController:animated:)]) {
        [settingsVC pushViewController:vc animated:YES];
    } else if ([settingsVC respondsToSelector:@selector(navigationController)]) {
        [[settingsVC navigationController] pushViewController:vc animated:YES];
    }
}
