TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#enable ARC
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

BUNDLE_NAME = CydiaNotifierProvider
CydiaNotifierProvider_FILES = CydiaNotifierProvider.mm
CydiaNotifierProvider_INSTALL_PATH = /System/Library/BulletinBoardPlugins/
CydiaNotifierProvider_FRAMEWORKS = UIKit
CydiaNotifierProvider_PRIVATE_FRAMEWORKS = BulletinBoard SpringBoardServices
CydiaNotifierProvider_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/System/Library/BulletinBoardPlugins/$(ECHO_END)