ARCHS := armv7
TARGET := iphone:clang:9.2:9.0

INSTALL_TARGET_PROCESSES = JacobsApp

THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = JacobsApp

JacobsApp_FILES = main.m JAAppDelegate.m JARootViewController.m
JacobsApp_FRAMEWORKS = UIKit CoreGraphics
JacobsApp_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
