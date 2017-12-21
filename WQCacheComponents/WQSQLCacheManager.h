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
/** 直接执行SQL语句(以Block形式) */
- (BOOL)executeStatementsFromDB:(NSString *)sql withResultBlock:(int (^)(NSDictionary *result))block;
- (NSDictionary *)executeStatementsFromDB:(NSString *)sql;
 
@end
/**
 * 找出分组后时间最晚的完整记录 select * from test where t in (select max(t) from test group by groupid) group by groupid
 
 */
