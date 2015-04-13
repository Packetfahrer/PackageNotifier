TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#enable ARC
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

BUNDLE_NAME = CydiaNotifierPreferences
CydiaNotifierPreferences_FILES = CydiaNotifierPreferences.mm CNTimeSelectionCell.mm CydiaNotifierBadgePreferences.mm CydiaNotifierPromotionPreferences.mm CydiaNotifierCreditsPreferences.mm CydiaNotifierAutoRefreshPreferences.mm
CydiaNotifierPreferences_INSTALL_PATH = /Library/PreferenceBundles
CydiaNotifierPreferences_FRAMEWORKS = UIKit CoreGraphics MessageUI Social Twitter
CydiaNotifierPreferences_PRIVATE_FRAMEWORKS = Preferences
CydiaNotifierPreferences_LIBRARIES = atcommonprefs atcommon

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CydiaNotifierPreferences.plist$(ECHO_END)
