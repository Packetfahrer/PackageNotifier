TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#enable ARC
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

BUNDLE_NAME = PackageNotifierPreferences
PackageNotifierPreferences_FILES = PackageNotifierPreferences.mm PNTimeSelectionCell.mm PackageNotifierBadgePreferences.mm PackageNotifierPromotionPreferences.mm PackageNotifierCreditsPreferences.mm PackageNotifierAutoRefreshPreferences.mm
PackageNotifierPreferences_INSTALL_PATH = /Library/PreferenceBundles
PackageNotifierPreferences_FRAMEWORKS = UIKit CoreGraphics MessageUI Social Twitter
PackageNotifierPreferences_PRIVATE_FRAMEWORKS = Preferences
PackageNotifierPreferences_LIBRARIES = atcommonprefs atcommon

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PackageNotifierPreferences.plist$(ECHO_END)
