TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YtLiteCustom

$(TWEAK_NAME)_FILES = Tweak.x Settings.x YTLCSettings.x Player.x YTPill.x TranslateText.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreGraphics Photos AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk