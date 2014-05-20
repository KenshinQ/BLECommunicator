//
//  BLEHardwareManager.m
//  HeartRate
//
//  Created by will on 14-4-28.
//  Copyright (c) 2014年 will. All rights reserved.
//

#import "BLEHardwareManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEHardware.h"
@interface BLEHardwareManager ()<CBCentralManagerDelegate>


@property (nonatomic, strong) CBCentralManager * manager;
@property (nonatomic, strong) NSMutableArray * enableServices;
@property (nonatomic, strong) BLEHardware * connectingBLEHardware;
@property (nonatomic, strong) BLEHardware * connectedBLEHardware;
@property (nonatomic, strong) Class hardwareClass;
@property (nonatomic, readwrite) BOOL isBLEEable;
@property (nonatomic, strong) NSTimer * connectingTimer;
@end


@implementation BLEHardwareManager

+(id)shareManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    return [self initWithQueue:nil];
}

- (id)initWithQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _enableServices = [[NSMutableArray alloc] init];
        _hardwareClass = [BLEHardware class];
        _connectingTimeout = 6.0;
        _connectingTimer = [NSTimer scheduledTimerWithTimeInterval:_connectingTimeout target:self selector:@selector(connectTimeoutHandle) userInfo:nil repeats:YES];
        [_connectingTimer setFireDate:[NSDate distantFuture]];
    }
    
    return self;
}

- (BLEHardware *)retriveConnectWithHardwareUUID:(NSString *)uuidString;
{
    NSUUID * hardwareUUID = [[NSUUID alloc] initWithUUIDString:uuidString];
    NSArray * peripherals = [self.manager retrievePeripheralsWithIdentifiers:@[hardwareUUID]];
    BLEHardware *hardware = nil;
    if ([peripherals count]>0) {
        hardware = [[self.hardwareClass alloc] init];
        hardware.peripheral = [peripherals objectAtIndex:0];
    }
    return hardware;
}

- (void)startScan
{
    if (self.manager.state==CBCentralManagerStatePoweredOn) {
        [self.manager stopScan];
    }
    
    self.isScanning = YES;
    [self.manager scanForPeripheralsWithServices:nil options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey]];
}

-(void)stopScan
{
    self.isScanning = NO;
    //[discoverPeripherals removeAllObjects];
    if (self.manager.state==CBCentralManagerStatePoweredOn) {
         [self.manager stopScan];
    }
   
}

- (void)registerBLEHardwareClassForScan:(Class)hardwareClass
{
    self.hardwareClass = hardwareClass;
}

- (void)connectWithBLEHardware:(BLEHardware *)hardware
{
    NSAssert(hardware.peripheral, @"the hardware's peripheral must not be nil");
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnConnectionKey];
    [options setObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey];
    [options setObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    self.connectingBLEHardware = hardware;
    [self.manager connectPeripheral:hardware.peripheral options:options];
    [self.connectingTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.connectingTimeout]];
}

- (void)disconnectWithBLEHardware:(BLEHardware *)hardware
{
    if (hardware.peripheral) {
        [self.manager cancelPeripheralConnection:hardware.peripheral];
    }
}

- (NSArray *)enableServices
{
    return _enableServices;
}

- (void)addBLEService:(NSString *)serviceUUID
{
    if (serviceUUID) {
        
        [_enableServices addObject:[CBUUID UUIDWithString:serviceUUID]];
    }
    
}

- (void)addBLEServices:(NSArray *)serviceUUIDs
{
    if ([serviceUUIDs count]>0) {
        [_enableServices addObjectsFromArray:serviceUUIDs];
    }
}

- (void)removeBLEService:(NSString *)serviceUUID
{
    if (serviceUUID) {
        [_enableServices removeObject:serviceUUID];
    }
}

- (void)connectTimeoutHandle
{
    if (self.connectingBLEHardware) {
        [self.manager cancelPeripheralConnection:self.connectingBLEHardware.peripheral];
    }
    [self.connectingTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"central manager state :%d",[central state]);
    switch ([central state]) {
        case CBCentralManagerStatePoweredOn:
        {
            if (self.isScanning) {
                
                [self startScan];
            }
            self.isBLEEable = YES;
        }
            break;
            
        default:
            self.isBLEEable = NO;
            break;
    }
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"th discover peripheral %@ rssi %@",[advertisementData description],RSSI);
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length]>0&&[localName hasPrefix:@"HRM"]) {
        
        BLEHardware * discoverHardware = [[self.hardwareClass alloc] init];
        //discoverHardware.broadcastName = localName;
        discoverHardware.peripheral = peripheral;
        if ([self.discoverDelegate respondsToSelector:@selector(hardwareManager:didDiscoverHardware:)]) {
            [self.discoverDelegate hardwareManager:self didDiscoverHardware:discoverHardware];
        }
    }
}


-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"connect the peripheral");
    self.connectedBLEHardware = self.connectingBLEHardware;
    self.connectingBLEHardware = nil;
    if ([self.connectDelegate respondsToSelector:@selector(hardwareManager:didConnectHardware:)]) {
        [self.connectDelegate hardwareManager:self didConnectHardware:self.connectedBLEHardware];
    }
    //[peripheral discoverServices:self.enableServices];
    [peripheral discoverServices:nil];
}
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"central manager did disconnect peripheral");
    if (self.connectedBLEHardware) {
        
        if ([self.connectDelegate respondsToSelector:@selector(hardwareManager:didDisConnectHardware:)]) {
            
            [self.connectDelegate hardwareManager:self didDisConnectHardware:self.connectedBLEHardware];
        }
        if (self.connectedBLEHardware.reconnect) {
            [self connectWithBLEHardware:self.connectedBLEHardware];
        }
        self.connectedBLEHardware = nil;
    }else
    {
        if (self.connectingBLEHardware.reconnect) {
            
            [self connectWithBLEHardware:self.connectingBLEHardware];
        }else
        {
            if ([self.connectDelegate respondsToSelector:@selector(hardwareManager:didFailToConnectHardware:)]) {
                
                [self.connectDelegate hardwareManager:self didFailToConnectHardware:self.connectingBLEHardware];
            }
            self.connectingBLEHardware = nil;
        }

    }

}
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([self.connectDelegate respondsToSelector:@selector(hardwareManager:didFailToConnectHardware:)]) {
        
        [self.connectDelegate hardwareManager:self didFailToConnectHardware:self.connectingBLEHardware];
    }
    self.connectingBLEHardware = nil;
}

@end
