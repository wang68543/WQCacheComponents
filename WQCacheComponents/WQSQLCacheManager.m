//
//  WQBaseSQLCacheManager.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "WQSQLCacheManager.h"
//#import <WQBasicComponents/WQBasicComponents.h>

@interface WQSQLCacheManager()

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
-(Class)queryParamClass{
    return nil;
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
//TODO: 只在本地数据库取 不去服务器取
- (NSArray *)readDataFromDB:(WQBaseQueryParam *)param{
    return [self executeQueryModelsWithParam:param];
}

//TODO: -- -查询第一条与最后一条
- (NSArray <id <WQSQLMoelProtocol>> *)readFirstAndLast:(WQBaseQueryParam *)param{
    //FIXME: -- 这里需要拷贝 参数 具体解决方法需等待。。。
    WQBaseQueryParam *newParam = [param copy];
    newParam.limit = 1;
    NSMutableString *SQL = [NSMutableString string];
    newParam.orderType = kOrderAscending;
    [SQL appendString:[newParam queryParamFormatSQLString]];
    newParam.orderType = kOrderDescending;
    SQL = [[SQL stringByReplacingOccurrencesOfString:@";" withString:@"UNION "] mutableCopy];
    [SQL appendString:[newParam queryParamFormatSQLString]];
    FMResultSet *rs = [self executeQueryWithSQL:SQL];
    return [WQSQLDBTool parseModels:[newParam modelClass] FMResultSet:rs];
}
////TODO: 通过block 查询
//- (void)cacheData:(WQBaseQueryParam *)param compeletion:(WQCacheQueryResponse)compeletion{
//    
//    WQBaseQueryParam *requestParam = [self changeQueryParamToRequestServer:param];
//    __weak typeof(self) weakSelf = self;
//    [self requestDatasWithQueryParam:requestParam response:^(NSError *error, NSArray *results) {
//        if(compeletion){
//            NSError *callBackError;
//            NSArray *models = [weakSelf executeQueryModelsWithParam:param];
//            if(error){
//                if(models.count <= 0){
//                    callBackError = error;
//                }
//            }
//            
//            compeletion(callBackError,models);
//        }
//    }];
//}
////TODO: 根据本地数据库已有的数据去修改参数去服务器拉取
//- (WQBaseQueryParam *)changeQueryParamToRequestServer:(WQBaseQueryParam *)queryParam{
//    WQBaseQueryParam *changeParam = [queryParam wq_copyInstance];
//    
//    
//    return changeParam;
//}
////TODO: 去服务器请求数据
//- (void)requestDatasWithQueryParam:(WQBaseQueryParam *)queryParam response:(WQCacheQueryResponse)res{
//    __weak typeof(self) weakSelf = self;
//    [WQHttpTool postWithPath:[queryParam requestServerApi] params:[queryParam requestServerParams] success:^(NSURLResponse *reponse, id json) {
//        if(res){
//            NSError *error;
//            NSArray *results = [[queryParam modelClass] parseModelsWithJSON:json error:&error];
//            [weakSelf saveModelsToDB:results];
//            res(error,results);
//        }
//    } failure:^(NSURLResponse *reponse, NSError *error) {
//        !res?:res(error,nil);
//    }];
//}

//TODO: 将服务器请求的模型保存到数据库
- (void)saveModelsToDB:(NSArray *)models tableName:(NSString *)t_table{
    NSArray *sqls = [WQSQLDBTool saveModelsSQL:models tableName:t_table];
    if(sqls.count > 0){
       [self executeUpdateWithSqls:sqls rollback:NO];
    }
}


#pragma mark -- 数据库执行方法

//TODO: 从数据库查询数据 转换为模型 private method
- (NSArray *)executeQueryModelsWithParam:(WQBaseQueryParam *)param{
    FMResultSet *rs = [self executeQueryWithSQL:[param queryParamFormatSQLString]];
   return [WQSQLDBTool parseModels:[param modelClass] FMResultSet:rs];
}
//TODO: 批量进行更新操作 采用事务的方式
- (BOOL)executeUpdateWithSqls:(NSArray *)sqls{
    return [self executeUpdateWithSqls:sqls rollback:NO];
}
//TODO: 批量进行更新操作 采用事务的方式 是否需要回滚
- (BOOL)executeUpdateWithSqls:(NSArray *)sqls rollback:(BOOL)doRollback{
    
    BOOL successfully = YES;
    if(!self.fmdb.isInTransaction){
        [self.fmdb beginTransaction];
        for (NSString *sql in sqls) {
            if(![self executeUpdateWithSQL:sql] && doRollback){
                [self.fmdb rollback];
                successfully = NO;
                break;
            }
        }
        [self.fmdb commit];
    }else{
        for (NSString *sql in sqls) {
            if(![self executeUpdateWithSQL:sql] && doRollback){
                [self.fmdb rollback];
                successfully = NO;
                break;
            }
        }
    }
    return successfully;
}

//TODO: 执行SQL数据库更新操作
- (BOOL)executeUpdateWithSQL:(NSString *)sql{
    return  [self.fmdb executeUpdate:sql];
}
//TODO: 直接根据SQL语句进行查询
- (FMResultSet *)executeQueryWithSQL:(NSString*)sql{
    return [self.fmdb executeQuery:sql];
}
//TODO: 以字典形式返回SQL执行结果
- (NSDictionary *)executeStatementsDic:(NSString *)sql{
    __block NSDictionary *execResult = nil;
    [self executeStatements:sql withResultBlock:^int(NSDictionary *resultsDictionary) {
        execResult = resultsDictionary;
        return 1;
    }];
    return execResult;
}
//TODO: 直接执行SQL语句
- (BOOL)executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block{
    return [self.fmdb executeStatements:sql withResultBlock:block];
}


//TODO: -- -数据库迁移使用
+(NSArray *)tableSortedColumnNames:(Class)cls{
    return [self tableSortedColumnNames:cls tableName:nil];
}
//TODO: 获取表格中所有的排序后字段
+ (NSArray *)tableSortedColumnNames:(Class)cls tableName:(NSString *)t_table{
    
    NSString *tableName = t_table;
    if(t_table.length <= 0){
        tableName =  [WQSQLDBTool t_tableName:cls];
    }
    
    // CREATE TABLE XMGStu(age integer,stuNum integer,score real,name text, primary key(stuNum))
    //sqlite_master 每个数据库都默认都有的 (查询数据库中的表)
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", tableName];
    
    //mysql安装成功后可以看到已经存在mysql、information_schema和test这个几个数据库，information_schema库中有一个名为COLUMNS的表，这个表中记录了数据库中所有表的字段信息。知道这个表后，获取任意表的字段就只需要一条select语句即可
//    select COLUMN_NAME from information_schema.COLUMNS where table_name = 'your_table_name';
    
    NSMutableDictionary *dic = [[[self manager] executeStatementsDic:queryCreateSqlStr] mutableCopy];
    
    // 获取查询结果里面的数据库字段
    NSString *createTableSql = dic[@"sql"];
    if (createTableSql.length == 0) {
        return nil;
    }
    createTableSql = [createTableSql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
   //因为OC字典里面有自带的一些格式化美化符号 所以需要去掉
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    // CREATE TABLE XMGStu((stuNum))
    
    // 1. age integer,stuNum integer,score real,name text, primary key
    //    CREATE TABLE "XMGStu" ( \n
    //                           "age2" integer,
    //                           "stuNum" integer,
    //                           "score" real,
    //                           "name" text,
    //                           PRIMARY KEY("stuNum")
    //                           )
    
    
    NSString *nameTypeStr = [createTableSql componentsSeparatedByString:@"("][1];
    
    // age integer
    // stuNum integer
    // score real
    // name text
    // primary key
    NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];
    
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *nameType in nameTypeArray) {
        
        if ([[nameType lowercaseString] containsString:@"primary"]) {
            continue;
        }
        NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
        
        // age integer
        NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
        
        [names addObject:name];
        
    }
    
    [names sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    return names;
}

+(BOOL)isTableExists:(Class)cls{
    return [self isTableExists:cls tableName:nil];
}
+ (BOOL)isTableExists:(Class)cls tableName:(NSString *)t_table{
    
    //FIXME: 这里还需要测试验证 
    NSString *tableName = t_table;
    if(t_table.length <= 0){
        tableName =  [WQSQLDBTool t_tableName:cls];
    }
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", tableName];
    NSDictionary *result = [[self manager] executeStatementsDic:queryCreateSqlStr];
    
    return result.count > 0;
}

/**
 根据一个模型类, 创建数据库表
 // 关于这个工具类的封装
 // 实现方案 2
 // 1. 基于配置
 // 2. runtime动态获取
 @param cls 类名
 @return 是否创建成功
 */
//+ (BOOL)createTable:(Class)cls{
//    NSString *createTableSql = [WQSQLDBTool createTableSQL:cls];
//    return [[self manager] executeUpdateWithSQL:createTableSql];
//    
//}

+(BOOL)isTableRequiredUpdate:(Class)cls{
    return [self isTableRequiredUpdate:cls tableName:nil];
}

/**
 判断一个表格是否需要更新
 
 @param cls 类名
 @return 是否需要更新
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls tableName:(NSString *)t_table{
    // 1. 获取类对应的所有有效成员变量名称, 并排序
    NSArray *modelNames = [WQSQLDBTool allTableSortedIvarNames:cls];
    
    // 2. 获取当前表格, 所有字段名称, 并排序
    NSArray *tableNames = [self tableSortedColumnNames:cls tableName:t_table];
    
    // 3. 通过对比数据判定是否需要更新
    return ![modelNames isEqualToArray:tableNames];
}

+(BOOL)updateTable:(Class)cls{
    return [self updateTable:cls tableName:nil];
}
/**
 更新表格
 
 @param cls 类名
 @return 是否更新成功
 */
+ (BOOL)updateTable:(Class)cls tableName:(NSString *)t_table{
    
    
    // 1. 创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [WQSQLDBTool tmpTableName:cls];
    NSString *tableName = [WQSQLDBTool t_tableName:cls];
    
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return NO;
    }
    NSMutableArray *execSqls = [NSMutableArray array];
    NSString *primaryKey = [cls primaryKey];
    NSString *dropTmpTableSql = [NSString stringWithFormat:@"drop table if exists %@;", tmpTableName];
    [execSqls addObject:dropTmpTableSql];
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@));", tmpTableName, [WQSQLDBTool columnNamesAndTypesStr:cls], primaryKey];
    [execSqls addObject:createTableSql];
    // 2. 根据主键, 插入数据
    // insert into xmgstu_tmp(stuNum) select stuNum from xmgstu;
    NSString *insertPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;", tmpTableName, primaryKey, primaryKey, tableName];
    [execSqls addObject:insertPrimaryKeyData];
    // 3. 根据主键, 把所有的数据更新到新表里面
    NSArray *oldNames = [self tableSortedColumnNames:cls];
    NSArray *newNames = [WQSQLDBTool allTableSortedIvarNames:cls];
    
    // 4. 获取更名字典
    NSDictionary *newNameToOldNameDic = @{};
    //  @{@"age": @"age2"};
    if ([cls respondsToSelector:@selector(newNameToOldNameDic)]) {
        newNameToOldNameDic = [cls newNameToOldNameDic];
    }
    
    for (NSString *columnName in newNames) {
        NSString *oldName = columnName;
        // 找映射的旧的字段名称
        if ([newNameToOldNameDic[columnName] length] != 0) {
            oldName = newNameToOldNameDic[columnName];
        }
        // 如果老表包含了新的列明, 应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && ![oldNames containsObject:oldName]) || [columnName isEqualToString:primaryKey]) {
            continue;
        }
        //        xmgstu_tmp  age
        // update 临时表 set 新字段名称 = (select 旧字段名 from 旧表 where 临时表.主键 = 旧表.主键)
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@);", tmpTableName, columnName, oldName, tableName, tmpTableName, primaryKey, tableName, primaryKey];
        [execSqls addObject:updateSql];
    }
    
    NSString *deleteOldTable = [NSString stringWithFormat:@"drop table if exists %@;", tableName];
    [execSqls addObject:deleteOldTable];
    
    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@;", tmpTableName, tableName];
    [execSqls addObject:renameTableName];
    
    
    return [[self manager] executeUpdateWithSqls:execSqls rollback:YES];
    
}



//+ (BOOL)saveOrUpdateModel:(id)model{
//    
//    // 如果用户再使用过程中, 直接调用这个方法, 去保存模型
//    // 保存一个模型
//    Class cls = [model class];
//    // 1. 判断表格是否存在, 不存在, 则创建
//    if (![self isTableExists:cls]) {
//        [self createTable:cls];
//    }
//    // 2. 检测表格是否需要更新, 需要, 更新
//    if ([self isTableRequiredUpdate:cls]) {
//        BOOL updateSuccess = [self updateTable:cls];
//        if (!updateSuccess) {
//            NSLog(@"更新数据库表结构失败");
//            return NO;
//        }
//    }
//    
//    // 3. 判断记录是否存在, 主键
//    // 从表格里面, 按照主键, 进行查询该记录, 如果能够查询到
//    NSString *tableName = [WQSQLDBTool tableName:cls];
//    
//    if (![cls respondsToSelector:@selector(primaryKey)]) {
//        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
//        return NO;
//    }
//    NSString *primaryKey = [cls primaryKey];
//    id primaryValue = [model valueForKeyPath:primaryKey];
//    
//    NSString *checkSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'", tableName, primaryKey, primaryValue];
//    //FIXME: 这里需要模型转换
//    NSArray *result = [[self manager] executeQueryModelsWithSQL:checkSql];
//    
//    
//    // 获取字段名称数组
//    NSArray *columnNames = [WQSQLDBTool classIvarNameTypeDic:cls].allKeys;
//    
//    // 获取值数组
//    // model keyPath:
//    NSMutableArray *values = [NSMutableArray array];
//    for (NSString *columnName in columnNames) {
//        id value = [model valueForKeyPath:columnName];
//        
//        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
//            // 在这里, 把字典或者数组, 处理成为一个字符串, 保存到数据库里面去
//            
//            // 字典/数组 -> data
//            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
//            
//            // data -> nsstring
//            value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        }
//        
//        
//        [values addObject:value];
//    }
//    
//    NSInteger count = columnNames.count;
//    NSMutableArray *setValueArray = [NSMutableArray array];
//    for (int i = 0; i < count; i++) {
//        NSString *name = columnNames[i];
//        id value = values[i];
//        NSString *setStr = [NSString stringWithFormat:@"%@='%@'", name, value];
//        [setValueArray addObject:setStr];
//    }
//    
//    // 更新
//    // 字段名称, 字段值
//    // update 表名 set 字段1=字段1值,字段2=字段2的值... where 主键 = '主键值'
//    NSString *execSql = @"";
//    if (result.count > 0) {
//        execSql = [NSString stringWithFormat:@"update %@ set %@  where %@ = '%@'", tableName, [setValueArray componentsJoinedByString:@","], primaryKey, primaryValue];
//        
//        
//    }else {
//        // insert into 表名(字段1, 字段2, 字段3) values ('值1', '值2', '值3')
//        // '   值1', '值2', '值3   '
//        // 插入
//        // text sz 'sz' 2 '2'
//        execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')", tableName, [columnNames componentsJoinedByString:@","], [values componentsJoinedByString:@"','"]];
//    }
//    
//    
//    return [[self manager] executeUpdateWithSQL:execSql];
//}
@end
