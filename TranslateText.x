#import "Headers.h"

// ---------------------------------------------------------
// 1. Helper: Language Data
// ---------------------------------------------------------
static NSArray* GetLangTitles(void) {
    return @[@"English", @"Malayalam", @"Spanish", @"French", @"German", @"Hindi", @"Tamil", @"Greek"];
}

static NSArray* GetLangCodes(void) {
    return @[@"en", @"ml", @"es", @"fr", @"de", @"hi", @"ta", @"el"];
}

// ---------------------------------------------------------
// 2. Custom Language Picker Modal (Purple Cancel Button)
// ---------------------------------------------------------
@interface YTLiteLanguagePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *codes;
@property (nonatomic, copy) NSString *selectedLangCode;
@property (nonatomic, copy) void (^onSelectLanguage)(NSString *code, NSString *title);
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation YTLiteLanguagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Liquid glass background overlay
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPicker)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor systemGray6Color];
    self.containerView.layer.cornerRadius = 20.0;
    self.containerView.layer.borderWidth = 1.0;
    self.containerView.layer.borderColor = [UIColor separatorColor].CGColor;
    self.containerView.clipsToBounds = YES;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
    
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.text = @"Language";
    headerLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    headerLabel.textColor = [UIColor systemGrayColor];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:headerLabel];
    
    UIView *headerDivider = [[UIView alloc] init];
    headerDivider.backgroundColor = [UIColor separatorColor];
    headerDivider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:headerDivider];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.tableView];
    
    // Purple Cancel Button
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor systemPurpleColor]; // Accent Color
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    cancelButton.layer.cornerRadius = 14.0;
    cancelButton.clipsToBounds = YES;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(dismissPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelButton];
    
    NSLayoutConstraint *widthConstraint = [self.containerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.8];
    widthConstraint.priority = UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *heightConstraint = [self.containerView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.65];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        widthConstraint,
        [self.containerView.widthAnchor constraintLessThanOrEqualToConstant:320.0],
        heightConstraint,
        [self.containerView.heightAnchor constraintLessThanOrEqualToConstant:500.0],
        
        [headerLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:14],
        [headerLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [headerLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        
        [headerDivider.topAnchor constraintEqualToAnchor:headerLabel.bottomAnchor constant:12],
        [headerDivider.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [headerDivider.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [headerDivider.heightAnchor constraintEqualToConstant:0.5],
        
        [self.tableView.topAnchor constraintEqualToAnchor:headerDivider.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:cancelButton.topAnchor constant:-10],
        
        [cancelButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [cancelButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [cancelButton.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-14],
        [cancelButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSUInteger selectedIndex = [self.codes indexOfObject:self.selectedLangCode];
    if (selectedIndex != NSNotFound && selectedIndex < self.titles.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isDescendantOfView:self.containerView];
}

- (void)dismissPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"LangCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    NSString *name = self.titles[indexPath.row];
    NSString *code = self.codes[indexPath.row];
    cell.textLabel.text = name;
    
    if ([code isEqualToString:self.selectedLangCode]) {
        cell.textLabel.textColor = [UIColor systemPurpleColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        UIImage *checkImg = [UIImage systemImageNamed:@"checkmark"];
        cell.imageView.image = [checkImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = [UIColor systemPurpleColor];
    } else {
        cell.textLabel.textColor = [UIColor labelColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        cell.imageView.image = nil;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.onSelectLanguage) {
        self.onSelectLanguage(self.codes[indexPath.row], self.titles[indexPath.row]);
    }
    [self dismissPicker];
}

@end

// ---------------------------------------------------------
// 3. Main Translation Sheet
// ---------------------------------------------------------
@interface YTTranslationViewController : UIViewController
@property (nonatomic, copy) NSString *originalText;
@property (nonatomic, copy) NSString *selectedLangName;
@property (nonatomic, copy) NSString *selectedLangCode;
@property (nonatomic, strong) UILabel *langValueLabel;
@property (nonatomic, strong) UITextView *resultTextView;
@end

@implementation YTTranslationViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedLangName = @"English";
        _selectedLangCode = @"en";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Translation";
    
    // Adaptive Native Backgrounds
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    if (self.navigationController) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor systemBackgroundColor];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor labelColor],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:17]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIFontWeightMedium];
    
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark" withConfiguration:config] style:UIBarButtonItemStylePlain target:self action:@selector(closeTapped)];
    closeItem.tintColor = [UIColor labelColor];

    UIBarButtonItem *copyItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc" withConfiguration:config] style:UIBarButtonItemStylePlain target:self action:@selector(copyTapped)];
    copyItem.tintColor = [UIColor labelColor];

    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:config] style:UIBarButtonItemStylePlain target:self action:@selector(shareTapped:)];
    shareItem.tintColor = [UIColor labelColor];

    self.navigationItem.rightBarButtonItems = @[closeItem, copyItem, shareItem];

    // Language Row
    UIView *langRowView = [[UIView alloc] init];
    langRowView.translatesAutoresizingMaskIntoConstraints = NO;
    langRowView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    langRowView.layer.cornerRadius = 12;
    [self.view addSubview:langRowView];

    UILabel *langTitleLabel = [[UILabel alloc] init];
    langTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    langTitleLabel.text = @"Language";
    langTitleLabel.textColor = [UIColor labelColor];
    langTitleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [langRowView addSubview:langTitleLabel];

    self.langValueLabel = [[UILabel alloc] init];
    self.langValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.langValueLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *langTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectLanguageTapped:)];
    [self.langValueLabel addGestureRecognizer:langTap];
    [langRowView addSubview:self.langValueLabel];
    
    [self updateLanguageLabelText];

    // Spacious Text View
    self.resultTextView = [[UITextView alloc] init];
    self.resultTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultTextView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.resultTextView.layer.cornerRadius = 12;
    self.resultTextView.textColor = [UIColor labelColor];
    self.resultTextView.font = [UIFont systemFontOfSize:16];
    self.resultTextView.editable = NO;
    self.resultTextView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    [self.view addSubview:self.resultTextView];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [langRowView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [langRowView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [langRowView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [langRowView.heightAnchor constraintEqualToConstant:48],

        [langTitleLabel.leadingAnchor constraintEqualToAnchor:langRowView.leadingAnchor constant:16],
        [langTitleLabel.centerYAnchor constraintEqualToAnchor:langRowView.centerYAnchor],

        [self.langValueLabel.trailingAnchor constraintEqualToAnchor:langRowView.trailingAnchor constant:-16],
        [self.langValueLabel.centerYAnchor constraintEqualToAnchor:langRowView.centerYAnchor],

        [self.resultTextView.topAnchor constraintEqualToAnchor:langRowView.bottomAnchor constant:12],
        [self.resultTextView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [self.resultTextView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [self.resultTextView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-16]
    ]];

    [self performTranslation];
}

// Chevron Arrow Implementation
- (void)updateLanguageLabelText {
    UIColor *purpleColor = [UIColor systemPurpleColor];
    UIFont *labelFont = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", self.selectedLangName] attributes:@{
        NSFontAttributeName: labelFont,
        NSForegroundColorAttributeName: purpleColor
    }];
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithFont:labelFont];
    UIImage *symbol = [UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:config];
    
    if (symbol) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [symbol imageWithTintColor:purpleColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        CGFloat fontCapHeight = labelFont.capHeight;
        CGFloat iconHeight = symbol.size.height;
        attachment.bounds = CGRectMake(0, (fontCapHeight - iconHeight) / 2.0, symbol.size.width, iconHeight);
        [attrString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    }
    
    self.langValueLabel.attributedText = attrString;
}

- (void)selectLanguageTapped:(UITapGestureRecognizer *)gesture {
    YTLiteLanguagePickerViewController *pickerVC = [[YTLiteLanguagePickerViewController alloc] init];
    pickerVC.titles = GetLangTitles();
    pickerVC.codes = GetLangCodes();
    pickerVC.selectedLangCode = self.selectedLangCode;
    
    __weak typeof(self) weakSelf = self;
    pickerVC.onSelectLanguage = ^(NSString *code, NSString *title) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.selectedLangCode = code;
        strongSelf.selectedLangName = title;
        [strongSelf updateLanguageLabelText];
        [strongSelf performTranslation];
    };
    
    pickerVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    pickerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:pickerVC animated:YES completion:nil];
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)copyTapped {
    if (self.resultTextView.text.length > 0) {
        UIPasteboard.generalPasteboard.string = self.resultTextView.text;
        [YTPillToast showSuccessWithMessage:@"Copied to clipboard"];
    }
}

- (void)shareTapped:(id)sender {
    if (self.resultTextView.text.length > 0) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.resultTextView.text] applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

- (void)performTranslation {
    if (!self.originalText || self.originalText.length == 0) {
        self.resultTextView.text = @"No text to translate.";
        return;
    }

    self.resultTextView.text = @"Translating...";
    self.resultTextView.textColor = [UIColor systemPurpleColor];
    
    // URL Encoding fix to prevent JSON array breakage
    NSString *encodedText = [self.originalText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=%@&dt=t&q=%@", self.selectedLangCode, encodedText];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                self.resultTextView.text = @"Translation failed. Please try again.";
                self.resultTextView.textColor = [UIColor systemRedColor];
                return;
            }
            @try {
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSArray class]] && [json count] > 0) {
                    NSArray *sentences = json[0];
                    NSMutableString *result = [NSMutableString string];
                    for (id sentence in sentences) {
                        if ([sentence isKindOfClass:[NSArray class]] && [sentence count] > 0) {
                            [result appendString:sentence[0]];
                        }
                    }
                    self.resultTextView.text = result;
                    self.resultTextView.textColor = [UIColor labelColor];
                } else {
                    self.resultTextView.text = @"Unexpected format received.";
                    self.resultTextView.textColor = [UIColor systemRedColor];
                }
            } @catch (NSException *e) {
                self.resultTextView.text = @"Parsing error.";
                self.resultTextView.textColor = [UIColor systemRedColor];
            }
        });
    }];
    [task resume];
}

@end

// ---------------------------------------------------------
// 4. API Manager
// ---------------------------------------------------------
@implementation YTTranslateManager
+ (void)presentTranslationForText:(NSString *)text fromPresenter:(UIViewController *)presenter {
    if (!text || text.length == 0) {
        [YTPillToast showErrorWithMessage:@"No text to translate"];
        return;
    }
    YTTranslationViewController *vc = [[YTTranslationViewController alloc] init];
    vc.originalText = text;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[[UISheetPresentationControllerDetent mediumDetent], [UISheetPresentationControllerDetent largeDetent]];
            sheet.prefersGrabberVisible = YES;
            sheet.preferredCornerRadius = 24.0;
        }
    } else {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    UIViewController *topPresenter = YTTopViewController(presenter);
    [topPresenter presentViewController:nav animated:YES completion:nil];
}
@end