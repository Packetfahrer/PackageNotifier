TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

TWEAK_NAME = CydiaNotifier
CydiaNotifier_FILES = Tweak.xm
CydiaNotifier_LIBRARIES = substrate atcommon atcommonprefs
CydiaNotifier_FRAMEWORKS = UIKit CoreGraphics
CydiaNotifier_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"

SUBPROJECTS += CydiaNotifierProvider
SUBPROJECTS += CydiaNotifierPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
