TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

TWEAK_NAME = PackageNotifier
PackageNotifier_FILES = Tweak.xm
PackageNotifier_LIBRARIES = substrate atcommon atcommonprefs
PackageNotifier_FRAMEWORKS = UIKit CoreGraphics
PackageNotifier_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"

SUBPROJECTS += PackageNotifierProvider
SUBPROJECTS += PackageNotifierPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
