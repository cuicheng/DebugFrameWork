//
//  UncaughtExceptionHandler.m
//  CrashHandler
//
//  Created by kuangbiao on 13-12-19.
//  Copyright (c) 2013年 kuangbiao. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
#import "CCDebug.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <AudioToolbox/AudioToolbox.h>
#define MODULETAG @"UncaughtExceptionHandler"
#define ENABLELOG true
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Data.h"
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
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
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
    CCLog(@"APP崩溃:%@",strException);
    
    NSString *postStr=[[NSMutableString alloc] initWithString:CCReturnDebug(@"%@",strException)];
    [postStr stringByAppendingFormat:@"\n\n\n\n设备信息：%@",[GetInfo getIphoneInfo]];
    [postStr stringByAppendingFormat:@"\n\n\n\n当时网络信息:%@",[GetInfo getWifiInfo]];
    if([[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/appCrash.txt"]]){
        NSMutableString *ss= [[NSMutableString alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/appCrash.txt"] encoding:NSUTF8StringEncoding error:nil];
        [ss appendString:postStr];
        [ss writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/appCrash.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }else{
        [postStr writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/appCrash.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    
    NSString *saveExceptionPath = [self getSaveExceptionPath];
    [strException writeToFile:saveExceptionPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [[NSUserDefaults standardUserDefaults] setValue:saveExceptionPath forKey:kLastUncaughtException];
    [[NSUserDefaults standardUserDefaults] synchronize];
    

    
    
    UIAlertController *avc=[UIAlertController alertControllerWithTitle:@"很抱歉，程序出现异常" message:@"错误信息已发送，谢谢您的使用" preferredStyle:UIAlertControllerStyleAlert];
    
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
