//
//  BLEHardware.m
//  HeartRate
//
//  Created by will on 14-4-28.
//  Copyright (c) 2014年 will. All rights reserved.
//

#import "BLEHardware.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface BLEHardware ()<CBPeripheralDelegate>

@property (nonatomic, readwrite ,strong) NSNumber * rssi;
@property (nonatomic, strong) NSMutableDictionary * servicesConfig;
@property (nonatomic, strong) NSMutableDictionary * characteristicsConfig;
@property (nonatomic, strong) NSMutableDictionary * characteisticHandleMap;
@end

@implementation BLEHardware


- (id)init
{
    self = [super init];
    if (self) {
    
        self.servicesConfig = [NSMutableDictionary dictionary];
        self.characteristicsConfig = [NSMutableDictionary dictionary];
        self.characteisticHandleMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)setPeripheral:(CBPeripheral *)peripheral
{
    _peripheral = peripheral;
    self.rssi = peripheral.RSSI;
    _peripheral.delegate = self;
}

- (NSString *)broadcastName
{
    return self.peripheral.name;
}

- (NSString *)hardwareUUIDString
{
    return [self.peripheral.identifier UUIDString];
}

- (void)addCharacteristic:(NSString *)characteristicUUID forService:(NSString *)serviceUUID withOption:(BLEHardwareCharacteristicOption)option
{
    NSMutableArray * characteristics = [self.servicesConfig objectForKey:serviceUUID];
    if (!characteristics) {
        characteristics = [NSMutableArray array];
    }
    if (![characteristics containsObject:characteristicUUID]) {
        [characteristics addObject:characteristicUUID];
        [self.servicesConfig setObject:characteristics forKey:serviceUUID];
        [self.characteristicsConfig setObject:@(option) forKey:characteristicUUID];
    }
}

- (uint16_t)uintValueFromCBUUID:(CBUUID*)cbuuid
{
    uint8_t *byte = (uint8_t *)[cbuuid.data bytes];
    uint16_t result = 0;
    result = *byte;
    byte++;
    result = result<<8;
    result = result |(*byte);
    return result;
}

- (NSString *)stringFromCBUUID:(CBUUID *)uuid
{
    uint16_t value = [self uintValueFromCBUUID:uuid];
    return [NSString stringWithFormat:@"%x",value];
}


- (void)hardwareDidReceiveData:(NSData *)data forCharacteristic:(NSString *)characteristicUUID
{
    NSLog(@"The data of characteristic %@ is :%@",characteristicUUID,data);
}

- (BOOL)hardwareSendData:(NSData *)data forCharacteristic:(NSString *)characteristicUUID
{
    BOOL result = NO;
    CBCharacteristic * handle = [self.characteisticHandleMap objectForKey:characteristicUUID];
    NSNumber * option = [self.characteristicsConfig objectForKey:characteristicUUID];
    if ([option integerValue]&BLEHardwareCharacteristicOptionWrite) {
        result = YES;
        [self.peripheral writeValue:data forCharacteristic:handle type:CBCharacteristicWriteWithoutResponse];
    }
    return result;
}

#pragma mark CBPeripheral delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{

    [peripheral.services enumerateObjectsUsingBlock:^(CBService * service, NSUInteger idx, BOOL *stop) {
        NSString * uuidString = [self stringFromCBUUID:service.UUID];
        NSArray * characteristicUUIDs = [self.servicesConfig objectForKey:uuidString];
        if ([characteristicUUIDs count]>0) {
            
            NSMutableArray * cbuuids = [NSMutableArray array];
            for (NSString * characteristicUUID in characteristicUUIDs) {
                [cbuuids addObject:[CBUUID UUIDWithString:characteristicUUID]];
            }
            [peripheral discoverCharacteristics:cbuuids forService:service];
        }
        
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * characteristic, NSUInteger idx, BOOL *stop) {
       
        NSString * uuidString = [self stringFromCBUUID:characteristic.UUID];
        NSNumber * option = [self.characteristicsConfig objectForKey:uuidString];
        if (option) {
            
            [self.characteisticHandleMap setObject:characteristic forKey:uuidString];
            if ([option integerValue]&BLEHardwareCharacteristicOptionNotify) {
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
        }
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString * characteristicUUID = [self stringFromCBUUID:characteristic.UUID];
    [self hardwareDidReceiveData:characteristic.value forCharacteristic:characteristicUUID];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"peripheral did write value with error %@ for UUID %@",error,characteristic.UUID);
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!error) {
        self.rssi = peripheral.RSSI;
    }
}
@end
