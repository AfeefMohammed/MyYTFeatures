TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyYTFeatures

$(TWEAK_NAME)_FILES = Tweak.x Settings.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk