TARGET = iphone:clang:latest:8.1
ARCHS = arm64 armv7
#enable ARC
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include theos/makefiles/common.mk

BUNDLE_NAME = PackageNotifierProvider
PackageNotifierProvider_FILES = PackageNotifierProvider.mm
PackageNotifierProvider_INSTALL_PATH = /System/Library/BulletinBoardPlugins/
PackageNotifierProvider_FRAMEWORKS = UIKit
PackageNotifierProvider_PRIVATE_FRAMEWORKS = BulletinBoard SpringBoardServices
PackageNotifierProvider_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/System/Library/BulletinBoardPlugins/$(ECHO_END)