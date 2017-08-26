//
//  HeathyCacheManager.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/2.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "HeathyCacheManager.h"
#import "HeathyQueryParam.h"
#import "HeathyDataItem.h"

@implementation HeathyCacheManager
-(Class)queryParamClass{
    return [HeathyQueryParam class];
}
-(Class)modelClass{
    return [HeathyDataItem class];
}
static HeathyCacheManager *_instance;
+(instancetype)manager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createDBQueueWithPath:[[[self queryParamClass] db_cacheDirectory] stringByAppendingPathComponent:[[self queryParamClass] db_name]]];
      NSArray *sql =@[[WQSQLDBTool createTableSQL:[self modelClass]]];
      BOOL success = [self executeUpdateWithSqls:sql rollback:YES];
        if(!success){
            NSLog(@"创表失败");
        }
    }
    return self;
}
@end
