//
//  HeathyDataItem.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/6.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WQSQLMoelProtocol.h"

@interface HeathyDataItem : NSObject<WQSQLMoelProtocol>


/**
 操作模型必须实现的方法, 通过这个方法获取主键信息
 
 @return 主键字符串
 */
+ (NSString *)primaryKey;

/**
 忽略的字段数组
 
 @return 忽略的字段数组
 */
+ (NSArray *)ignoreColumnNames;


/**
 新字段名称-> 旧的字段名称的映射表格 (数据库迁移的时候使用)
 
 @return 映射表格
 */
+ (NSDictionary *)newNameToOldNameDic;


/** 类自定义表名 */
+ (NSString *)tableName;

/** 解析服务器下载数据的模型(根据请求参数进行) */
+ (NSArray *)parseModelsWithJSON:(id)json error:(NSError **)outError;
@end
