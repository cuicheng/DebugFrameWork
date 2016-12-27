//
//  CCDeug.h
//  DebugFrameWork
//
//  Created by cui on 16/8/1.
//  Copyright © 2016年 ccc. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CCLog(str, ...) [CCDebug reallyLog:[NSString stringWithFormat:str,__VA_ARGS__]];
#define CCString(key)  NSLocalizedStringFromTable(key, @"Localizable", nil)
@interface CCDebug : NSObject
+(void)reallyLog:(NSString *)str;
@end
