//
//  WQBaseQueryParam.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "WQBaseQueryParam.h"
#import "WQSQLDBTool.h"
#import <objc/runtime.h>
 
@implementation WQBaseQueryParam
+(NSString *)db_cacheDirectory{
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachePath = [cacheDirectory stringByAppendingPathComponent:@"WQSQLCache"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath     withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cachePath;
}
+(NSString *)db_name{
    return [NSString stringWithFormat:@"%@.sqlite",NSStringFromClass([self class])];
}
-(NSMutableArray *)conditions{
    if (!_conditions) {
        _conditions = [NSMutableArray array];
    }
    return _conditions;
}

-(NSString *)actionSQL:(WQDBAction)actionType{
    NSString *sql = nil;
    switch (actionType) {
        case WQDBActionQuery:
            sql = [WQSQLCondition QuerySQL:self.modelClass conditions:self.conditions limit:self.limit offset:self.offset];
            break;
        case WQDBActionDelete:
            sql = [WQSQLCondition DeleteSQL:self.modelClass conditions:self.conditions];
            break;
        default:
            break;
    }
    return sql;
}

@end
