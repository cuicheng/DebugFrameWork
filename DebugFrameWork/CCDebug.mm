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
+(void)reallyLog:(NSString*)str
{
    static NSInteger count = 1;
    
    NSString *file=[NSString stringWithFormat:@"%s",__FILE__];
    NSString *line = [NSString stringWithFormat:@"%d",__LINE__];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat=@"HH:mm:ss";
    NSString *result = [NSString stringWithFormat:@"+++++++++\n##%ldCCC:%@\nfile:%@\nline:%@\n----------\n\nDebug:%@\n\n",(long)count,[formatter stringFromDate:[NSDate date]],[[file componentsSeparatedByString:@"/"] lastObject],line,str];
    NSMutableString *ss=[[NSMutableString alloc] initWithString:result];
    [ss replaceOccurrencesOfString:@"%@" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, ss.length)];
    printf("%s\n",[ss cStringUsingEncoding:NSUTF8StringEncoding]);
    count++;
}
+(void)returnStr:(NSString*)str andObject:(NSObject *)object
{
    dispatch_async(dispatch_queue_create("debug", NULL), ^{
        NSMutableString *result = [[NSMutableString alloc] initWithString:str];
        if([object isKindOfClass:[NSDictionary class]]){
            [self changeDic:object andStr:result];
        }else if([object isKindOfClass:[NSArray class]]){
            [self changeArrayWithArray:object andStr:result];
        }else{
            [result appendFormat:@"%@\n\n",object];
        }
        [CCDebug reallyLog:result];
    });
}
+(void)changeDic:(NSObject *)object andStr:(NSMutableString *)result
{
    NSDictionary *dic=(NSDictionary*)object;
    for (NSInteger i=0; i<dic.allKeys.count; i++) {
        NSString *key = dic.allKeys[i];
        if(i==0){
            [result appendString:[NSString stringWithFormat:@"dic={%@=%@",key,[dic objectForKey:key]]];
        }else if(i==dic.allKeys.count-1){
            [result appendString:[NSString stringWithFormat:@",\n             %@=%@}",key,[dic objectForKey:key]]];
        }else{
            [result appendString:[NSString stringWithFormat:@",\n             %@=%@",key,[dic objectForKey:key]]];
        }
    }
}
+(void)changeArrayWithArray:(NSObject *)object andStr:(NSMutableString *)result
{
    NSArray *arr= (NSArray *)object;
    for (NSInteger i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[NSDictionary class]]){
            NSMutableString *result2=[[NSMutableString alloc] init];
            [self changeDic:arr[i] andStr:result2];
            if(i==0){
                [result appendString:[NSString stringWithFormat:@"arr=[%@",result2]];
            }else if(i==arr.count-1){
                [result appendString:[NSString stringWithFormat:@"\n,      %@]",result2]];
            }else{
                [result appendString:[NSString stringWithFormat:@"\n,      %@",result2]];
            }
        }else{
            if(i==0){
                [result appendString:[NSString stringWithFormat:@"arr=[%@",arr[i]]];
            }else if(i==arr.count-1){
                [result appendString:[NSString stringWithFormat:@"\n,      %@]",arr[i]]];
            }else{
                [result appendString:[NSString stringWithFormat:@"\n,      %@",arr[i]]];
            }
        }
    }
}


+(NSString *)returnDebug:(NSString*)str andObject:(NSObject *)object
{
   
    NSMutableString *result = [[NSMutableString alloc] initWithString:str];
    if([object isKindOfClass:[NSDictionary class]]){
        [self changeDic:object andStr:result];
    }else if([object isKindOfClass:[NSArray class]]){
        [self changeArrayWithArray:object andStr:result];
    }else{
        [result appendFormat:@"%@\n\n",object];
    }
    
    
    NSString *file=[NSString stringWithFormat:@"%s",__FILE__];
    NSString *line = [NSString stringWithFormat:@"%d",__LINE__];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat=@"YYYY-MM-dd HH:mm:ss";
    NSString *result2 = [NSString stringWithFormat:@"+++++++++\nCCC:%@\nfile:%@\nline:%@\n----------\n\nDebug:%@",[formatter stringFromDate:[NSDate date]],[[file componentsSeparatedByString:@"/"] lastObject],line,object];
    NSMutableString *ss=[[NSMutableString alloc] initWithString:result2];
    [ss replaceOccurrencesOfString:@"%@" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, ss.length)];
    return ss;
}
+(void)returnStr1:(NSString * )str , ...
{
    NSMutableArray *array = [NSMutableArray array];
    va_list list;
    id tag;
    if(str){
        va_start(list, str);
        [array addObject:str];
        while ((tag = va_arg(list, id))) {
            [array addObject:tag];
        }
        
        NSMutableString *result=[[NSMutableString alloc] init];
        for (id oc in array) {
            if([oc isKindOfClass:[NSDictionary class]]){
                [self changeDic:oc andStr:result];
            }else if([oc isKindOfClass:[NSArray class]]){
                [self changeArrayWithArray:oc andStr:result];
            }else{
                if([oc isKindOfClass:[NSString class]]&&[oc isEqualToString:@"%@"]){
                    continue;
                }
                [result appendFormat:@"%@",oc];
            }
        }
        [CCDebug reallyLog:result];
        va_end(list);
    }
    
}
@end
