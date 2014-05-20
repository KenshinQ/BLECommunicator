//
//  BLEHardware.h
//  HeartRate
//
//  Created by will on 14-4-28.
//  Copyright (c) 2014年 will. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, BLEHardwareCharacteristicOption)
{
    BLEHardwareCharacteristicOptionRead = 1<<0,
    BLEHardwareCharacteristicOptionWrite = 1<<1,
    BLEHardwareCharacteristicOptionNotify = 1<<2
};


@class CBPeripheral;
@interface BLEHardware : NSObject

@property (nonatomic, strong) CBPeripheral * peripheral;
@property (nonatomic, readonly , strong)NSNumber *rssi;
@property (nonatomic, assign) BOOL reconnect;

- (NSString *)broadcastName;
- (NSString *)hardwareUUIDString;

- (void)addCharacteristic:(NSString *)characteristicUUID forService:(NSString *)serviceUUID withOption:(BLEHardwareCharacteristicOption)option ;
- (void)hardwareDidReceiveData:(NSData *)data forCharacteristic:(NSString *)characteristicUUID;
- (BOOL)hardwareSendData:(NSData *)data forCharacteristic:(NSString *)characteristicUUID;
@end
