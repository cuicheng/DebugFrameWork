//
//  CCDeug.m
//  DebugFrameWork
//
//  Created by cui on 16/8/1.
//  Copyright © 2016年 ccc. All rights reserved.
//

#import "CCDebug.h"
#import "UncaughtExceptionHandler.h"
@implementation CCDebug
+(void)reallyLog:(NSString *)str
{
    NSString *file=[NSString stringWithFormat:@"%s",__FILE__];
    NSString *line = [NSString stringWithFormat:@"%d",__LINE__];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat=@"HH-mm-ss";
    NSString *result = [NSString stringWithFormat:@"ccc::%@::%@::line%@::     Debug:%@",[formatter stringFromDate:[NSDate date]],[[file componentsSeparatedByString:@"/"] lastObject],line,str];
    printf("%s\n",[result cStringUsingEncoding:NSUTF8StringEncoding]);
}
@end
