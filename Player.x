#import "Headers.h"

#define IsEnabled(key) [[NSUserDefaults standardUserDefaults] boolForKey:key]

// ==========================================
// 1. SHOW VIDEO END TIME
// ==========================================

static float myyt_playbackRate = 1.0;
static NSString *myyt_globalEndTime = nil;

static void updateGlobalEndTime(id video, id time) {
    if (!IsEnabled(@"videoEndTime")) {
        myyt_globalEndTime = nil;
        return;
    }

    CGFloat rate = myyt_playbackRate > 0.0 ? myyt_playbackRate : 1.0;
    CGFloat totalMediaTime = [video respondsToSelector:@selector(totalMediaTime)] ? [[video valueForKey:@"totalMediaTime"] floatValue] : 0.0;
    CGFloat currentTime = [time respondsToSelector:@selector(time)] ? [[time valueForKey:@"time"] floatValue] : 0.0;

    if (totalMediaTime <= 0) {
        myyt_globalEndTime = nil;
        return;
    }

    NSTimeInterval remainingTime = (lround(totalMediaTime) - lround(currentTime)) / rate;
    NSDate *estimatedEndTime = [NSDate dateWithTimeIntervalSinceNow:remainingTime];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"h:mm a"];

    myyt_globalEndTime = [dateFormatter stringFromDate:estimatedEndTime];
}

%hook YTPlayerViewController

- (void)setPlaybackRate:(float)rate {
    myyt_playbackRate = rate;
    %orig;
}

- (void)singleVideo:(id)video currentVideoTimeDidChange:(id)time {
    %orig;
    updateGlobalEndTime(video, time);
}

- (void)potentiallyMutatedSingleVideo:(id)video currentVideoTimeDidChange:(id)time {
    %orig;
    updateGlobalEndTime(video, time);
}

%end

static NSString *interceptTimeText(NSString *text) {
    if (!IsEnabled(@"videoEndTime") || !text || !myyt_globalEndTime) return text;
    if (text.length < 30 && [text containsString:@"/"] && [text containsString:@":"]) {
        if (![text containsString:myyt_globalEndTime]) {
            return [text stringByAppendingFormat:@" • %@", myyt_globalEndTime];
        }
    }
    return text;
}

static NSAttributedString *interceptTimeAttributedText(NSAttributedString *attributedText) {
    if (!IsEnabled(@"videoEndTime") || !attributedText || !myyt_globalEndTime) return attributedText;
    NSString *text = attributedText.string;
    if (text.length < 30 && [text containsString:@"/"] && [text containsString:@":"]) {
        if (![text containsString:myyt_globalEndTime]) {
            NSMutableAttributedString *newAttr = [attributedText mutableCopy];
            NSDictionary *attrs = [attributedText length] > 0 ? [attributedText attributesAtIndex:attributedText.length - 1 effectiveRange:NULL] : nil;
            NSAttributedString *appendAttr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" • %@", myyt_globalEndTime] attributes:attrs];
            [newAttr appendAttributedString:appendAttr];
            return newAttr;
        }
    }
    return attributedText;
}

%hook UILabel
- (void)setText:(NSString *)text {
    %orig(interceptTimeText(text));
}
- (void)setAttributedText:(NSAttributedString *)attributedText {
    %orig(interceptTimeAttributedText(attributedText));
}
%end

%hook YTLabel
- (void)setText:(NSString *)text {
    %orig(interceptTimeText(text));
}
- (void)setAttributedText:(NSAttributedString *)attributedText {
    %orig(interceptTimeAttributedText(attributedText));
}
%end

// ==========================================
// 2. TAP TO SEEK
// ==========================================

%hook YTInlinePlayerBarContainerView

- (void)didPressScrubber:(id)arg1 {
    %orig;
    if (!IsEnabled(@"tapToSeek")) return;

    YTMainAppVideoPlayerOverlayViewController *mainAppController = [self.delegate valueForKey:@"_delegate"];
    if (mainAppController == nil) return;

    YTPlayerViewController *playerViewController = [mainAppController valueForKey:@"parentViewController"];

    if ([arg1 isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)arg1;
        CGPoint location = [gestureRecognizer locationInView:self];
        CGFloat x = location.x;

        if ([self respondsToSelector:@selector(scrubRangeForScrubX:)] &&
            [mainAppController respondsToSelector:@selector(totalTime)] &&
            [playerViewController respondsToSelector:@selector(seekToTime:)]) {
            
            double timestampFraction = [self scrubRangeForScrubX:x];
            double timestamp = [mainAppController totalTime] * timestampFraction;
            [playerViewController seekToTime:timestamp];
        }
    }
}

%end