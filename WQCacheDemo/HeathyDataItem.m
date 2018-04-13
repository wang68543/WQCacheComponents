//
//  HeathyDataItem.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/6.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "HeathyDataItem.h"

@implementation HeathyDataItem
/**
 操作模型必须实现的方法, 通过这个方法获取主键信息
 
 @return 主键字符串
 */
+ (NSString *)primaryKey{
    return @"";
}
+(NSString *)t_tableName{
    return @"t_table";
}
/**
 忽略的字段数组
 
 @return 忽略的字段数组
 */
+ (NSArray *)ignoreColumnNames{
    return [NSArray array];
}


/**
 新字段名称-> 旧的字段名称的映射表格 (数据库迁移的时候使用)
 
 @return 映射表格
 */
+ (NSDictionary *)newNameToOldNameDic{
    return [NSDictionary dictionary];
}


/** 类自定义表名 */
+ (NSString *)tableName{
   
    return @"t_heathyDataItem";
}

/** 解析服务器下载数据的模型(根据请求参数进行) */
+ (NSArray *)parseModelsWithJSON:(id)json{
    return [NSArray array];
}
/** 解析本地数据库查询数据的模型(根据请求参数进行) */
+ (NSArray *)parseModelsWithJSON:(id)json error:(NSError **)outError{
    *outError = [NSError errorWithDomain:NSStringFromClass([self class]) code:-500 userInfo:@{NSLocalizedDescriptionKey:@"解析模型失败"}];
    return [NSArray array];
}
@end
