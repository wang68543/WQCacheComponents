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

typedef Class WQDBModelClass;
@interface WQSQLDBTool : NSObject
/**
 根据模型生成建表的SQL语句
 
 @param modelCls 模型类型
 @return 建表的SQL语句
 */
+ (NSString *)createTableSQL:(WQDBModelClass)modelCls;

//TODO: ==========模型的解析与存储==========
+ (NSArray *)parseModels:(WQDBModelClass)modelCls FMResultSet:(FMResultSet *)rs;

/** 多个数据生成一条SQL语句 (待验证字符串长度过长) */
+ (NSString *)saveModelsSql:(NSArray *)models;
/**
 批量生成保存SQL语句
 */
+ (NSArray<NSString *> *)saveModelSqls:(NSArray *)models;
/**
 如果模型中包含NSData类型用这个方法

 @param models 需要存数据库的数据
 @param values 存储的NSData类型的值
 @return SQL语句
 */
+ (NSArray<NSString *> *)saveModelSqls:(NSArray *)models arrayDataValues:(NSArray<NSArray *> **)values;
 
/** 更新单条模型 (根据主键进行更新) */
+ (NSString *)updateModel:(id)model updateKeys:(NSArray *)keys;
/** 更新模型 模型中包含NSData类型的属性 */
+ (NSString *)updateModel:(id)model updateKeys:(NSArray *)keys dataValues:(NSArray **)values;
/** 查询数据表所有的字段 (如果没有字段 说明表不存在 ) */
+ (NSString *)QueryTableInfoSQL:(WQDBModelClass)modelCls;

/**
 数据库表迁移 (需要实现协议里面的newNameToOldNameDic方法)

 @param modelCls 对象类型
 @param dbNames 通过QueryTableInfoSQL查询到旧表对应的字段信息
 @return 进行数据库表迁移的SQL语句
 */
+ (NSArray *)MoveTableSQL:(WQDBModelClass)modelCls dbProperties:(NSDictionary *)dbNames;

+(BOOL)RequiredTableUpdate:(WQDBModelClass)modelCls dbProperties:(NSDictionary *)dbNames;
 

@end
