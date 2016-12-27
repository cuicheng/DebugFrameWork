//
//  UncaughtExceptionHandler.h
//  CrashHandler
//
//  Created by kuangbiao on 13-12-19.
//  Copyright (c) 2013年 kuangbiao. All rights reserved.
//

//  捕获Crash信息
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
extern NSString * const kLastUncaughtException;
extern NSString * const kLastUncaughtExceptionName;

@interface UncaughtExceptionHandler : NSObject{
	BOOL dismissed;
}
+(void)registCrash;
//获取上次未捕获异常
+(NSString*)getLastUncaughtException;
void HandleException(NSException *exception);
void SignalHandler(int signal);
void InstallUncaughtExceptionHandler(void);
@end