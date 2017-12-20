//
//  WQSQLDBTableTool.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/3.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//  主要用于数据库SQL语句组合的辅助工具类

#import <Foundation/Foundation.h>
#import "WQSQLMoelProtocol.h"
@class FMResultSet;
@interface WQSQLDBTool : NSObject
//TODO: ==========模型的解析与存储==========
/** 解析本地数据库查询数据的模型(根据请求参数进行) */
+ (NSArray *)parseModels:(Class<WQSQLMoelProtocol>)modelClass FMResultSet:(FMResultSet *)rs;

/**
 批量生成保存SQL语句
 */
+ (NSArray *)saveModelsSQL:(NSArray *)models;
+ (NSArray *)saveModelsSQL:(NSArray *)models tableName:(NSString *)t_table;
/**
 保存模型到数据库

 @return 存储SQL语句
 */
+ (NSString *)saveModelSQL:(id)model;
+ (NSString *)saveModelSQL:(id)model tableName:(NSString *)t_table;
/**
 保存模型到数据库

 @param model 模型
 @param tableName 表名
 @param columnNames 数据中的字段名(即模型的属性名)
 @return 存储SQL语句
 */
+ (NSString *)saveModelSQL:(id)model tableName:(NSString *)tableName columnNames:(NSArray *)columnNames;

//TODO: ==========模型的解析与存储END==========

///**
// 根据类名, 获取表格名称
// 
// @param cls 类名
// @return 表格名称
// */
+ (NSString *)t_tableName:(Class)cls;

/**
 根据类名, 获取临时表格名称
 
 @param cls 类名
 @return 临时表格名称
 */
+ (NSString *)tmpTableName:(Class)cls;

/**
 根据模型生成建表的SQL语句

 @param cls 模型类型
 @return 建表的SQL语句
 */
+ (NSString *)createTableSQL:(Class)cls;
/** 指定表名 */
+ (NSString *)createTableSQL:(Class)cls tableName:(NSString *)tableName;
/**
 所有的有效成员变量, 以及成员变量对应的类型
 
 @param cls 类名
 @return 所有的有效成员变量, 以及成员变量对应的类型
 */
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls;


/**
 所有的成员变量, 以及成员变量映射到数据库里面对应的类型
 
 @param cls 类名
 @return 所有的成员变量, 以及成员变量映射到数据库里面对应的类型
 */
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls;


/**
 字段名称和sql类型, 拼接的用户创建表格的字符串
 
 @param cls 类名
 @return 字符串 如: name text,age integer,score real
 */
+ (NSString *)columnNamesAndTypesStr:(Class)cls;


/**
 排序后的类名对应的成员变量数组, 用于和表格字段进行验证是否需要更新
 
 @param cls 类名
 @return 成员变量数组,
 */
+ (NSArray *)allTableSortedIvarNames:(Class)cls;

@end
