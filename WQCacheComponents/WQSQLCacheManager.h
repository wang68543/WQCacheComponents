//
//  WQBaseSQLCacheManager.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

//MARK: *********全局所有的Class类型都是存储数据模型的Class****************

#import <Foundation/Foundation.h>
#import "WQBaseQueryParam.h"
#import "WQSQLDBTool.h"
#import "WQSQLMoelProtocol.h"
#import <WQHttpTool.h>

typedef void (^WQCacheQueryResponse)( NSError *error, NSArray *results);
@interface WQSQLCacheManager : NSObject
/** 由子类实现 */
+(instancetype)manager;
@property (strong ,nonatomic,readonly) FMDatabase *fmdb;
@property (strong ,atomic,readonly) FMDatabaseQueue *queue;

/** 根据路径创建数据库 子类调用 */
-(void)createDBQueueWithPath:(NSString *)path;



/** 只在本地数据库取 不去服务器取*/
- (NSArray<id<WQSQLMoelProtocol>> *)readDataFromDB:(WQBaseQueryParam *)param;


/**
 根据参数读取第一条跟最后一条(降序在前 升序在后)

 @return 返回第一条跟最后一条的模型 (如若只返回一条说明此区间内同步过数据 可以选择前半段区间也可以选择后半段区间进行同步)
 */
- (NSArray <id <WQSQLMoelProtocol>> *)readFirstAndLast:(WQBaseQueryParam *)param;
///** 通过block 查询*/
//- (void)cacheData:(WQBaseQueryParam *)param compeletion:(WQCacheQueryResponse)compeletion;
///** 根据本地数据库已有的数据去修改参数去服务器拉取 */
//- (WQBaseQueryParam *)changeQueryParamToRequestServer:(WQBaseQueryParam *)queryParam;

///** 去服务器请求数据 */
//- (void)requestDatasWithQueryParam:(WQBaseQueryParam *)queryParam response:(WQCacheQueryResponse)res;

/**将数据存到数据库 表名根据实例去获取 (必须实现t_tableName方法)*/
- (void)saveModelsToDB:(NSArray<id<WQSQLMoelProtocol> > *)models;
/** 将服务器请求的模型保存到数据库*/
- (void)saveModelsToDB:(NSArray<id<WQSQLMoelProtocol> > *)models tableName:(NSString *)t_table;
/** 从数据库查询数据 */
- (NSArray<id<WQSQLMoelProtocol>> *)queryFromDBWithSQL:(NSString *)sql modelClass:(Class)model;
//-(void)requestNewDatas:(WQBaseQueryParam *)modifyParam
//                 param:(WQBaseQueryParam *)param;


/** 从数据库查询数据 转换为模型 */
//- (NSArray<id<WQSQLMoelProtocol>> *)executeQueryModelsWithParam:(WQBaseQueryParam *)param;
//TODO: =========== 基础查询 ============
/** 直接根据SQL语句进行查询 */
- (FMResultSet *)executeQueryWithSQL:(NSString*)sql;

/** 执行数据库更新操作 */
- (BOOL)executeUpdateWithSQL:(NSString *)sql;
/** 批量进行更新操作 采用事务的方式 */
- (BOOL)executeUpdateWithSqls:(NSArray *)sqls;
/**
 批量进行更新操作 采用事务的方式

 @param sqls 多条sql语句
 @param doRollback  是否需要回滚
 @return 是否执行成功
 */
- (BOOL)executeUpdateWithSqls:(NSArray *)sqls rollback:(BOOL)doRollback;


/** 以字典形式返回SQL执行结果 */
- (NSDictionary *)executeStatementsDic:(NSString *)sql;
/** 直接执行SQL语句(以Block形式) */
- (BOOL)executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block;


//TODO: 数据库辅助工具
/**
 获取表格中所有的排序后字段
 
 @param cls 存储模型类名
 @return 字段数组
 */
+ (NSArray *)tableSortedColumnNames:(Class)cls;
+ (NSArray *)tableSortedColumnNames:(Class)cls  tableName:(NSString *)t_table;
/** 查询表是否存在 */
+ (BOOL)isTableExists:(Class)cls;

+ (BOOL)isTableExists:(Class)cls tableName:(NSString *)t_table;

//TODO: 数据库迁移模块================
//
/**
 根据一个模型类, 创建数据库表
 
 @param cls 类名
 @return 是否创建成功
 */
//+ (BOOL)createTable:(Class)cls;


/**
 判断一个表格是否需要更新
 
 @param cls 类名
 @return 是否需要更新
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls;

+ (BOOL)isTableRequiredUpdate:(Class)cls tableName:(NSString *)t_table;

/**
 更新表格
 
 @param cls 类名
 @return 是否更新成功
 */
+ (BOOL)updateTable:(Class)cls;

+ (BOOL)updateTable:(Class)cls tableName:(NSString *)t_table;
//TODO: 数据库迁移模块END================
@end


/**
 * 找出分组后时间最晚的完整记录 select * from test where t in (select max(t) from test group by groupid) group by groupid
 
 */
