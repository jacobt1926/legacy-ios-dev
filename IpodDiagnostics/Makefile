ARCHS := armv7
TARGET := iphone:clang:9.2:9.0

INSTALL_TARGET_PROCESSES = IpodDiagnostics

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = IpodDiagnostics

IpodDiagnostics_FILES = main.m IPDAppDelegate.m IPDRootViewController.m
IpodDiagnostics_FRAMEWORKS = UIKit Foundation CoreGraphics
IpodDiagnostics_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk

