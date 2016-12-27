//
//  GetInfo.m
//  MainProject
//
//  Created by cui on 16/11/16.
//  Copyright © 2016年 ZhongRuan. All rights reserved.
//

#import "GetInfo.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <SystemConfiguration/CaptiveNetwork.h>
@implementation GetInfo
+(NSDictionary *)getWifiInfo
{
    //wifi信息
    NSString *ssid ;
    NSString *macIp;
    
    CFArrayRef myArray = CNCopySupportedInterfaces();
    
    NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            ssid = [dict valueForKey:@"SSID"];
            macIp = [dict valueForKey:@"BSSID"];
            if(!ssid){
                ssid = @"Not Found";
            }
            if(!macIp){
                macIp=@"Not Found";
            }
            [dic setObject:ssid forKey:@"SSID"];
            [dic setObject:macIp forKey:@"macIP_BSSID"];
        }
    }
    return dic;
}
+(NSDictionary *)getIphoneInfo
{
    NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *name = device.name;       //获取设备所有者的名称
    NSString *model = device.model;      //获取设备的类别
    NSString *type = device.localizedModel; //获取本地化版本
    NSString *systemName = device.systemName;   //获取当前运行的系统
    NSString *systemVersion = device.systemVersion;//获取当前系统的版本
    [dic setObject:name?name:@"notFound" forKey:@"所有者"];
    [dic setObject:model?model:@"notFound" forKey:@"设备类别"];
    [dic setObject:type?type:@"notFound" forKey:@"本地化版本"];
    [dic setObject:systemName?systemName:@"notFound" forKey:@"系统"];
    [dic setObject:systemVersion?systemVersion:@"notFound" forKey:@"系统版本"];
    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    [dic setObject:mCarrier?mCarrier:@"notFound" forKey:@"运营商"];
    
    NSString *mConnectType = [[NSString alloc] initWithFormat:@"%@",info.currentRadioAccessTechnology];
    NSDictionary *netDic=@{CTRadioAccessTechnologyGPRS:@"介于2G和3G之间，也叫2.5G ,过度技术",
                           CTRadioAccessTechnologyEdge:@"EDGE为GPRS到第三代移动通信的过渡，EDGE俗称2.75G",
                           CTRadioAccessTechnologyWCDMA:@"WCDMA",
                           CTRadioAccessTechnologyHSDPA:@"亦称为3.5G(3?G)",
                           CTRadioAccessTechnologyHSUPA:@"3G到4G的过度技术",
                           CTRadioAccessTechnologyCDMA1x:@"3G",
                           CTRadioAccessTechnologyCDMAEVDORev0:@"3G标准",
                           CTRadioAccessTechnologyCDMAEVDORevA:@"CDMAEVDORevA",
                           CTRadioAccessTechnologyCDMAEVDORevB:@"CDMAEVDORevB",
                           CTRadioAccessTechnologyeHRPD:@"电信使用的一种3G到4G的演进技术， 3.75G",
                           CTRadioAccessTechnologyLTE:@"接近4G"};
    [dic setObject:[netDic objectForKey:mConnectType]?[netDic objectForKey:mConnectType]:@"notFound" forKey:@"网络"];
    
    
    NSUUID *uuid= device.identifierForVendor;
    NSString *uustr = uuid.UUIDString;
    [dic setObject:uustr forKey:@"UUID"];
    return dic;
}
@end
