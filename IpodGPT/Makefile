ARCHS := armv7
TARGET := iphone:clang:9.2:9.0
INSTALL_TARGET_PROCESSES = IpodGPT

THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = IpodGPT

IpodGPT_FILES = main.m IGPTAppDelegate.m IGPTRootViewController.m
IpodGPT_FRAMEWORKS = UIKit CoreGraphics QuartzCore
IpodGPT_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
