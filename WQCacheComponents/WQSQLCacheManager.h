//
//  WQBaseSQLCacheManager.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
// 这里 不管SQL语句 所有SQL语句都要DBTool生成
 
#import <Foundation/Foundation.h>
typedef void (^WQCacheQueryResponse)( NSError *error, NSArray *results);
@class FMResultSet;

@interface WQSQLCacheManager : NSObject
/** 由子类实现 */
+(instancetype)manager;
/** 根据路径创建数据库 子类调用 */
-(void)createDBQueueWithPath:(NSString *)path;
-(FMResultSet *)QueryFromDB:(NSString *)sql;
-(void)UpdateToDB:(NSString *)sql isInTransaction:(BOOL)inTransaction;
-(void)UpdateToDB:(NSArray *)sqls rollback:(BOOL)doRollback;


/**
 数据更新包含一些字符串无法表达的类型

 @param sql 数据存储SQL语句
 @param values 参数列表
 */
- (void)Update:(NSString *)sql dataValues:(NSArray *)values;
/**
 主要用于包含NSData类型的数据 无法直接用SQL语句存储
 需要FMDB executeUpdate:withArgumentsInArray:

 @param sqls SQL语句 NSData用`?`占位 
 @param values NSData存值
 */
-(void)UpdateToDB:(NSArray *)sqls dataValues:(NSArray<NSArray *> *)values;


/** 直接执行SQL语句(以Block形式) */
- (BOOL)executeStatementsFromDB:(NSString *)sql withResultBlock:(int (^)(NSDictionary *result))block;
- (NSDictionary *)executeStatementsFromDB:(NSString *)sql;
 
@end
/**
 * 找出分组后时间最晚的完整记录 select * from test where t in (select max(t) from test group by groupid) group by groupid
 
 */
