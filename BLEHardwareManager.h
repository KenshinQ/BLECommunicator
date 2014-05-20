//
//  BLEHardwareManager.h
//  HeartRate
//
//  Created by will on 14-4-28.
//  Copyright (c) 2014年 will. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLEHardware;
@protocol BLEHardwareManagerConnectDelegate;
@protocol BLEHardwareManagerDiscoverDelegate;

@interface BLEHardwareManager : NSObject

@property (nonatomic,assign)BOOL isScanning;
@property (nonatomic,readonly)BOOL isBLEEable;
@property (nonatomic,assign) NSTimeInterval connectingTimeout;
@property (nonatomic,weak)id <BLEHardwareManagerConnectDelegate> connectDelegate;
@property (nonatomic,weak)id <BLEHardwareManagerDiscoverDelegate> discoverDelegate;

+(id)shareManager;
- (void)registerBLEHardwareClassForScan:(Class)hardwareClass;
- (void)addBLEService:(NSString *)serviceUUID;
- (BLEHardware *)retriveConnectWithHardwareUUID:(NSString *)uuidString;
- (void)connectWithBLEHardware:(BLEHardware *)hardware;
- (void)disconnectWithBLEHardware:(BLEHardware *)hardware;
- (NSArray *)enableServices;
- (void)startScan;
- (void)stopScan;
@end

@protocol BLEHardwareManagerDiscoverDelegate <NSObject>

-(void)hardwareManager:(BLEHardwareManager*)manager didDiscoverHardware:(BLEHardware *)discoveredHardware;

@end
@protocol BLEHardwareManagerConnectDelegate <NSObject>

-(void)hardwareManager:(BLEHardwareManager*)manager didConnectHardware:(BLEHardware *)connectedHardware;
-(void)hardwareManager:(BLEHardwareManager *)manager didFailToConnectHardware:(BLEHardware *)failConnectedHardware;
-(void)hardwareManager:(BLEHardwareManager *)manager didDisConnectHardware:(BLEHardware *)disconnectedHardware;
@end