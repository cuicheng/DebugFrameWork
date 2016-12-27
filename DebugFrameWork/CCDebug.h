//
//  CCDeug.h
//  DebugFrameWork
//
//  Created by cui on 16/8/1.
//  Copyright © 2016年 ccc. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CCLog(str, ...) [CCDebug returnStr1:str,##__VA_ARGS__,nil]
#define CCString(key)  NSLocalizedStringFromTable(key, @"Localizable", nil)
#define CCReturnDebug(str, ...)   [CCDebug returnDebug:str andObject:__VA_ARGS__]
@interface CCDebug : NSObject
+(void)reallyLog:(NSString *)str;
+(void)returnStr1:(NSString *)str , ...;
+(NSString *)returnDebug:(NSString*)str andObject:(NSObject *)object;
@end
