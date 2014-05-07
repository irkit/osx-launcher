//
//  ILUSBWatcher.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/18.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//
//  based on USBPrivateDataSample.c
/*
   File:			USBPrivateDataSample.c

   Description:	This sample demonstrates how to use IOKitLib and IOUSBLib to set up asynchronous
   callbacks when a USB device is attached to or removed from the system.
   It also shows how to associate arbitrary data with each device instance.

   Copyright:		ｩ Copyright 2001-2006 Apple Computer, Inc. All rights reserved.

   Disclaimer:		IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
   ("Apple") in consideration of your agreement to the following terms, and your
   use, installation, modification or redistribution of this Apple software
   constitutes acceptance of these terms.  If you do not agree with these terms,
   please do not use, install, modify or redistribute this Apple software.

   In consideration of your agreement to abide by the following terms, and subject
   to these terms, Apple grants you a personal, non-exclusive license, under Appleﾕs
   copyrights in this original Apple software (the "Apple Software"), to use,
   reproduce, modify and redistribute the Apple Software, with or without
   modifications, in source and/or binary forms; provided that if you redistribute
   the Apple Software in its entirety and without modifications, you must retain
   this notice and the following text and disclaimers in all such redistributions of
   the Apple Software.  Neither the name, trademarks, service marks or logos of
   Apple Computer, Inc. may be used to endorse or promote products derived from the
   Apple Software without specific prior written permission from Apple.  Except as
   expressly stated in this notice, no other rights or licenses, express or implied,
   are granted by Apple herein, including but not limited to any patent rights that
   may be infringed by your derivative works or by other works in which the Apple
   Software may be incorporated.

   The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
   WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
   WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
   COMBINATION WITH YOUR PRODUCTS.

   IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
   OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
   (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   Change History (most recent first):

   1.2	    10/04/2006			Updated to produce a universal binary. Now requires Xcode 2.2.1 or
   later to build. Modernized and incorporated bug fixes.

   1.1		04/24/2002			Added comments, release of interface object, use of USB location ID

   1.0	    10/30/2001			New sample.

 */

#import "ILUSBWatcher.h"
#import "ILLog.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/serial/IOSerialKeys.h>

NSString * const kILUSBWatcherNotificationAdded           = @"ILUSBWatcherAdded";
NSString * const kILUSBWatcherNotificationRemoved         = @"ILUSBWatcherRemoved";
NSString * const kILUSBWatcherNotificationDeviceNameKey   = @"devicename";
NSString * const kILUSBWatcherNotificationLocationIDKey   = @"locationid";
NSString * const kILUSBWatcherNotificationVendorIDKey     = @"vendorid";
NSString * const kILUSBWatcherNotificationProductIDKey    = @"productid";
NSString * const kILUSBWatcherNotificationDialinDeviceKey = @"dialindevice";

typedef struct ILUSBData {
    io_object_t notification;
    IOUSBDeviceInterface **deviceInterface;
    CFStringRef deviceName;
    UInt32 locationID;
    UInt16 vendorID;
    UInt16 productID;
} ILUSBData;

static IONotificationPortRef gNotifyPort;
static io_iterator_t gAddedIter;
static CFRunLoopRef gRunLoop;

static NSDictionary* scanAndCreatePropertiesForServicesMatchingClassName( io_registry_entry_t service,
                                                                          NSString *expectedClassName );

//================================================================================================
//
//	DeviceNotification
//
//	This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//	interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//	messages are defined in IOMessage.h.
//
//================================================================================================
void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument){
    kern_return_t kr;
    ILUSBData *privateDataRef = (ILUSBData *) refCon;

    if (messageType == kIOMessageServiceIsTerminated) {
        // ILLOG( @"Device removed." );

        // Dump our private data to stderr just to see what it looks like.
        // ILLOG( @"->deviceName: %@", privateDataRef->deviceName );
        // ILLOG( @"->locationID: 0x%x", (unsigned int)privateDataRef->locationID );

        NSString *deviceName = (__bridge_transfer NSString*)privateDataRef->deviceName;
        NSNumber *locationID = [NSNumber numberWithUnsignedInt: privateDataRef->locationID];
        NSNumber *vendorID   = [NSNumber numberWithUnsignedInt: privateDataRef->vendorID];
        NSNumber *productID  = [NSNumber numberWithUnsignedInt: privateDataRef->productID];
        dispatch_async(dispatch_get_main_queue(),^() {
            [[NSNotificationCenter defaultCenter] postNotificationName: kILUSBWatcherNotificationRemoved
                                                                object: nil
                                                              userInfo: @{
                 kILUSBWatcherNotificationDeviceNameKey: deviceName,
                 kILUSBWatcherNotificationLocationIDKey: locationID,
                 kILUSBWatcherNotificationVendorIDKey:   vendorID,
                 kILUSBWatcherNotificationProductIDKey:  productID,
             }];
        });

        if (privateDataRef->deviceInterface) {
            kr = (*privateDataRef->deviceInterface)->Release(privateDataRef->deviceInterface);
        }

        kr = IOObjectRelease(privateDataRef->notification);

        free(privateDataRef);
    }
}

//================================================================================================
//
//	DeviceAdded
//
//	This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//	we will look at all the devices that were added and we will:
//
//	1.  Create some private data to relate to each device (in this case we use the service's name
//	    and the location ID of the device
//	2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//	    using the refCon field to store a pointer to our private data.  When we get called with
//	    this interest notification, we can grab the refCon and access our private data.
//
//================================================================================================
void DeviceAdded(void *refCon, io_iterator_t iterator){
    io_service_t usbDevice;

    while ((usbDevice = IOIteratorNext(iterator))) {
        // ILLOG(@"Device added.");

        // Add some app-specific information about this device.
        // Create a buffer to hold the data.
        ILUSBData *privateDataRef = malloc(sizeof(ILUSBData));
        bzero(privateDataRef, sizeof(ILUSBData));

        // Get the USB device's name.
        io_name_t deviceName;
        kern_return_t kr = IORegistryEntryGetName(usbDevice, deviceName);
        if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }

        CFStringRef deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault,
                                                                     deviceName,
                                                                     kCFStringEncodingASCII);

        // Dump our data to stderr just to see what it looks like.
        // ILLOG( @"deviceName: %@", deviceNameAsCFString );

        // Save the device's name to our private data.
        privateDataRef->deviceName = deviceNameAsCFString;

        // Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface
        // for our device. This will create the necessary connections between our userland application and the
        // kernel object for the USB Device.
        SInt32 score;
        IOCFPlugInInterface **plugInInterface = NULL;
        kr = IOCreatePlugInInterfaceForService(usbDevice,
                                               kIOUSBDeviceUserClientTypeID,
                                               kIOCFPlugInInterfaceID,
                                               &plugInInterface,
                                               &score);

        if ((kIOReturnSuccess != kr) || !plugInInterface) {
            ILLOG( @"IOCreatePlugInInterfaceForService returned 0x%08x.\n", kr);
            continue;
        }

        // Use the plugin interface to retrieve the device interface.
        HRESULT res = (*plugInInterface)->QueryInterface(plugInInterface,
                                                         CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                         (LPVOID*) &privateDataRef->deviceInterface);

        // Now done with the plugin interface.
        (*plugInInterface)->Release(plugInInterface);

        if (res || privateDataRef->deviceInterface == NULL) {
            ILLOG( @"QueryInterface returned %d.\n", (int) res);
            continue;
        }

        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.

        UInt32 locationID;
        kr = (*privateDataRef->deviceInterface)->GetLocationID(privateDataRef->deviceInterface, &locationID);
        if (KERN_SUCCESS != kr) {
            ILLOG( @"GetLocationID returned 0x%08x.\n", kr);
            continue;
        }
        // ILLOG( @"Location ID: 0x%x\n\n", (unsigned int)locationID);
        privateDataRef->locationID = locationID;

        UInt16 vendorID;
        kr = (*privateDataRef->deviceInterface)->GetDeviceVendor(privateDataRef->deviceInterface, &vendorID);
        if (KERN_SUCCESS != kr) {
            ILLOG( @"GetDeviceVendor returned 0x%08x.\n", kr);
            continue;
        }
        // ILLOG( @"Vendor ID: 0x%x\n\n", (unsigned int)vendorID);
        privateDataRef->vendorID = vendorID;

        UInt16 productID;
        kr = (*privateDataRef->deviceInterface)->GetDeviceProduct(privateDataRef->deviceInterface, &productID);
        if (KERN_SUCCESS != kr) {
            ILLOG( @"GetDeviceProduct returned 0x%08x.\n", kr);
            continue;
        }
        // ILLOG( @"Product ID: 0x%x\n\n", (unsigned int)productID);
        privateDataRef->productID = productID;

        // Register for an interest notification of this device being removed. Use a reference to our
        // private data as the refCon which will be passed to the notification callback.
        kr = IOServiceAddInterestNotification(gNotifyPort,                      // notifyPort
                                              usbDevice,                        // service
                                              kIOGeneralInterest,               // interestType
                                              DeviceNotification,               // callback
                                              privateDataRef,                   // refCon
                                              &(privateDataRef->notification)   // notification
                                              );
        if (KERN_SUCCESS != kr) {
            ILLOG( @"IOServiceAddInterestNotification returned 0x%08x.\n", kr);
        }

        NSDictionary *properties = scanAndCreatePropertiesForServicesMatchingClassName( usbDevice, @"IOModemSerialStreamSync" );
        ILLOG( @" properties: %@", properties );

        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *dialindevice = properties[ @kIODialinDeviceKey ];
            [[NSNotificationCenter defaultCenter] postNotificationName: kILUSBWatcherNotificationAdded
                                                                object: nil
                                                              userInfo: @{
                 kILUSBWatcherNotificationDeviceNameKey: (__bridge NSString*)privateDataRef->deviceName,
                 kILUSBWatcherNotificationLocationIDKey: [NSNumber numberWithUnsignedInt: privateDataRef->locationID],
                 kILUSBWatcherNotificationVendorIDKey:   [NSNumber numberWithUnsignedInt: privateDataRef->vendorID],
                 kILUSBWatcherNotificationProductIDKey:  [NSNumber numberWithUnsignedInt: privateDataRef->productID],
                 kILUSBWatcherNotificationDialinDeviceKey: dialindevice ? dialindevice : [NSNull null],
             }];
        });

        // Done with this USB device; release the reference added by IOIteratorNext
        kr = IOObjectRelease(usbDevice);
    }
}

static NSDictionary* scanAndCreatePropertiesForServicesMatchingClassName( io_registry_entry_t service,
                                                                          NSString *expectedClassName ) {

    io_registry_entry_t child       = 0;
    io_registry_entry_t childUpNext = 0;
    io_iterator_t children          = 0;
    kern_return_t status;
    NSDictionary *ret;

    status = IORegistryEntryGetChildIterator(service, kIOServicePlane, &children);
    if (status != KERN_SUCCESS) {
        return nil;
    }

    childUpNext = IOIteratorNext(children);

    io_name_t class_;
    status = IOObjectGetClass(service, class_);
    NSString *classname = [NSString stringWithCString: class_ encoding: NSUTF8StringEncoding];
    // ILLOG( @"classname: %@", classname );

    if ([classname isEqualToString: expectedClassName]) {
        CFMutableDictionaryRef properties;
        status = IORegistryEntryCreateCFProperties( childUpNext,
                                                    &properties,
                                                    kCFAllocatorDefault,
                                                    kNilOptions );
        if (status == KERN_SUCCESS) {
            ret = (__bridge_transfer NSDictionary*)properties;
        }
    }
    else {
        // Traverse over the children of this service, til scan returns SUCCESS
        while (childUpNext && !ret) {
            child       = childUpNext;
            childUpNext = IOIteratorNext(children);
            ret         = scanAndCreatePropertiesForServicesMatchingClassName( child, expectedClassName );
            IOObjectRelease(child);
        }
        if (childUpNext) {
            IOObjectRelease(childUpNext);
        }
    }
    IOObjectRelease(children);
    return ret;
}

@interface ILUSBWatcher ()

@property (nonatomic) BOOL isStopped;

@end

@implementation ILUSBWatcher

+ (instancetype) sharedInstance {
    static ILUSBWatcher *queue = nil;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        queue = [[ILUSBWatcher alloc] init];
    });
    return queue;
}

- (void) startWatchingUSB {
    ILLOG_CURRENT_METHOD;

    if (self.isRunning) {
        // TODO synchronize?
        return;
    }

    self.isRunning = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Set up the matching criteria for the devices we're interested in. The matching criteria needs to follow
        // the same rules as kernel drivers: mainly it needs to follow the USB Common Class Specification, pp. 6-7.
        // See also Technical Q&A QA1076 "Tips on USB driver matching on Mac OS X"
        // <http://developer.apple.com/qa/qa2001/qa1076.html>.
        // One exception is that you can use the matching dictionary "as is", i.e. without adding any matching
        // criteria to it and it will match every IOUSBDevice in the system. IOServiceAddMatchingNotification will
        // consume this dictionary reference, so there is no need to release it later on.

        CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName); // Interested in instances of class
        // IOUSBDevice and its subclasses
        if (matchingDict == NULL) {
            ILLOG( @"IOServiceMatching returned NULL." );
            self.isRunning = NO;
            return;
        }

        // We are interested in all USB devices (as opposed to USB interfaces).  The Common Class Specification
        // tells us that we need to specify the idVendor, idProduct, and bcdDevice fields, or, if we're not interested
        // in particular bcdDevices, just the idVendor and idProduct.  Note that if we were trying to match an
        // IOUSBInterface, we would need to set more values in the matching dictionary (e.g. idVendor, idProduct,
        // bInterfaceNumber and bConfigurationValue.

        // Create a notification port and add its run loop event source to our run loop
        // This is how async notifications get set up.

        gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);

        gRunLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);

        // Now set up a notification to be called when a device is first matched by I/O Kit.
        kern_return_t kr = IOServiceAddMatchingNotification(gNotifyPort,              // notifyPort
                                                            kIOFirstMatchNotification, // notificationType
                                                            matchingDict, // matching
                                                            DeviceAdded, // callback
                                                            NULL,       // refCon
                                                            &gAddedIter // notification
                                                            );
        if (kr) {
            ILLOG( @"error code: %d", kr );
            self.isRunning = NO;
            return;
        }

        // Iterate once to get already-present devices and arm the notification
        DeviceAdded(NULL, gAddedIter);

        // Start the run loop. Now we'll receive notifications.
        do {
            [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
        } while (!self.isStopped);

        self.isRunning = NO;
    });
    return;
}

- (void) stopWatchingUSB {
    ILLOG_CURRENT_METHOD;

    self.isStopped = YES;
}

@end
