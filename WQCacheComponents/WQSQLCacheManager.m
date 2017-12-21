//
//  WQBaseSQLCacheManager.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "WQSQLCacheManager.h"
 
#import <FMDB/FMDB.h> 

@interface WQSQLCacheManager()
@property (strong ,nonatomic,readonly) FMDatabase *fmdb;
@property (strong ,atomic,readonly) FMDatabaseQueue *queue;
@end
@implementation WQSQLCacheManager

+(instancetype)manager{
   return [[self alloc] init];
}
-(void)createDBQueueWithPath:(NSString *)path{
    _queue = [FMDatabaseQueue databaseQueueWithPath:path];
#ifdef DEBUG
    NSLog(@"数据库文件路径:%@",path);
#endif
}
@synthesize fmdb = _fmdb;
-(FMDatabase *)fmdb{
    if(!_fmdb){
        __block FMDatabase *blockFmdb;
        [_queue inDatabase:^(FMDatabase *db) {
            blockFmdb = db;
        }];
        _fmdb = blockFmdb;
    }
    return _fmdb;
}

#pragma mark -- 模型执行方法

-(FMResultSet *)QueryFromDB:(NSString *)sql{
    return [self.fmdb executeQuery:sql];
}
-(void)UpdateToDB:(NSString *)sql isInTransaction:(BOOL)inTransaction{
    if (!self.fmdb.isInTransaction) {
        [self.fmdb beginTransaction];
        [self.fmdb executeUpdate:sql];
        [self.fmdb commit];
    }else{
     [self.fmdb executeUpdate:sql];
    }
    
}
-(void)UpdateToDB:(NSArray *)sqls rollback:(BOOL)doRollback{
    if (self.fmdb.isInTransaction) {
        [self.fmdb beginTransaction];
        for (NSString *sql in sqls) {
            if ([self.fmdb executeUpdate:sql] && doRollback){
                [self.fmdb rollback];
            }
        }
        [self.fmdb commit];
    }else{
        [self.fmdb beginTransaction];
        for (NSString *sql in sqls) {
            [self.fmdb executeUpdate:sql];
        }
        [self.fmdb commit];
    }
}
/** 直接执行SQL语句(以Block形式) */
- (BOOL)executeStatementsFromDB:(NSString *)sql withResultBlock:(int (^)(NSDictionary *result))block{
    return [self.fmdb executeStatements:sql withResultBlock:block];
}
- (NSDictionary *)executeStatementsFromDB:(NSString *)sql{
    __block NSDictionary *results = nil;
    [self.fmdb executeStatements:sql withResultBlock:^int(NSDictionary * _Nonnull resultsDictionary) {
        results = resultsDictionary;
        return 0;
    }];
    return results;
}


@end
