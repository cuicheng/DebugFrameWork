//
//  UncaughtExceptionHandler.m
//  CrashHandler
//
//  Created by kuangbiao on 13-12-19.
//  Copyright (c) 2013年 kuangbiao. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <AudioToolbox/AudioToolbox.h>
#define MODULETAG @"UncaughtExceptionHandler"
#define ENABLELOG true
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#define USER_LOG_LEN 1000 //保存异常信息时补充的用户打印log长度

//http://www.cocoachina.com/newbie/tutorial/2012/0829/4672.html
NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

NSString * const kLastUncaughtException = @"kLastUncaughtException";
NSString * const kLastUncaughtExceptionName = @"kLastUncaughtExceptionName";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation UncaughtExceptionHandler
-(NSString *)getInfo
{
    NSMutableString *infoStr=[[NSMutableString alloc] init];
    UIDevice *device = [[UIDevice alloc] init];
    NSString *name = device.name;       //获取设备所有者的名称
    NSString *model = device.model;      //获取设备的类别
    NSString *type = device.localizedModel; //获取本地化版本
    NSString *systemName = device.systemName;   //获取当前运行的系统
    NSString *systemVersion = device.systemVersion;//获取当前系统的版本
    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [infoStr appendFormat:@"所有者:%@,类别:%@,版本:%@,系统:%@,系统版本:%@,UUID:%@",name,model,type,systemName,systemVersion,identifier];
    
   CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    [infoStr appendFormat:@",运营商:%@",mCarrier];
//
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
    [infoStr appendFormat:@",网络:%@",[netDic objectForKey:mConnectType]];
    return infoStr;
}
+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

+(void)registCrash
{
    InstallUncaughtExceptionHandler();
}
- (void)validateAndSaveCriticalApplicationData
{
	
}
-(NSString*)getSaveExceptionPath
{
    NSString *saveExceptionName = [NSString stringWithFormat:@"UncaughtException%@",[NSDate date].description];
    NSString *saveExceptionPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[saveExceptionName stringByAppendingString:@".log"]];
    [[NSUserDefaults standardUserDefaults] setObject:saveExceptionName forKey:kLastUncaughtExceptionName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return saveExceptionPath;
}
- (void)handleException:(NSException *)exception
{
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate) ;
    
	[self validateAndSaveCriticalApplicationData];
    
    NSArray* symbols = [exception callStackSymbols];
    NSMutableString *strSymbols = [[NSMutableString alloc]init];
    for (NSString*item in symbols)
    {
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
    NSString *strException = [NSString stringWithFormat:@"异常原因如下:\n%@\n%@\n%@",
                              [exception reason],
                              [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey],strSymbols];
    NSLog(@"%@",strException);
    NSString *saveExceptionPath = [self getSaveExceptionPath];
    //NSLog(@"strSymbols:%@",strSymbols);
    [strException writeToFile:saveExceptionPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [[NSUserDefaults standardUserDefaults] setValue:saveExceptionPath forKey:kLastUncaughtException];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIAlertController *avc=[UIAlertController alertControllerWithTitle:@"程序出现异常" message:[NSString stringWithFormat:@"%@%@",strException,[self getInfo]] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *sure=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dismissed=YES;
    }];
    [avc addAction:sure];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:avc animated:YES completion:nil];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    while (!dismissed)
    {
        for (NSString *mode in (__bridge NSArray *)allModes)
        {
            CFRunLoopRunInMode((__bridge CFStringRef)mode, 0.001, false);
        }
        
    }
    
    CFRelease(allModes);
    
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
   // signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

+(NSString*)getLastUncaughtException
{
    NSString *exceptionPath =  [[NSUserDefaults standardUserDefaults] stringForKey:kLastUncaughtException];
    return [NSString stringWithContentsOfFile:exceptionPath encoding:NSUTF8StringEncoding error:nil];
}

@end

void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	NSArray *callStack = [UncaughtExceptionHandler backtrace];
	NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[UncaughtExceptionHandler alloc] init]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:[exception name]
      reason:[exception reason]
      userInfo:userInfo]
     waitUntilDone:YES];
}

void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo =
    [NSMutableDictionary
     dictionaryWithObject:[NSNumber numberWithInt:signal]
     forKey:UncaughtExceptionHandlerSignalKey];
    
	NSArray *callStack = [UncaughtExceptionHandler backtrace];
	[userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[UncaughtExceptionHandler alloc] init]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
      reason:
      [NSString stringWithFormat:
       NSLocalizedString(@"Signal %d was raised.", nil),
       signal]
      userInfo:
      [NSDictionary
       dictionaryWithObject:[NSNumber numberWithInt:signal]
       forKey:UncaughtExceptionHandlerSignalKey]]
     waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler(void)
{
	NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
}
